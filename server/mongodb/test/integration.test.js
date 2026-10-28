import { test, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { existsSync } from 'node:fs';
import { mkdtemp, writeFile, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { MongoMemoryReplSet } from 'mongodb-memory-server';
import { MongoClient } from 'mongodb';
import { initialize } from '../src/database.js';
import { service, tokenHash } from '../src/service.js';
import { httpServer } from '../src/http.js';
import { prepare, importPrepared, collections, withoutId } from '../src/migration.js';

let repl, client, db, api, server, url;
const token = 'a'.repeat(64), event_id = 'festival-high-tech-mt';
const record = { mode: 'endless', seconds: 60, kills: 10, level: 1, character: 'Pescador', reason: 'death',
  ruleset: 'pesca-2', competitive_version: '0.5', run_id: '1'.repeat(32) };
const festival = (r = record) => ({ action: 'submit', event_id, record: { ...r, nickname: 'João Silva' } });
const call = input => api.handle(input);
const register = (nickname = 'Teste', t = token) => call({ action: 'register', nickname, token: t });
const submit = (account, r = record, t = token) => call({ action: 'submit', token: t, player_id: account.player_id, record: r });
const query = (version = '0.5') => call({ action: 'ranking', competitive_version: version });

before(async () => {
  repl = await MongoMemoryReplSet.create({ binary: { version: '8.0.17' }, replSet: { count: 1, storageEngine: 'wiredTiger' } });
  client = await new MongoClient(repl.getUri(), { timeoutMS: 15000 }).connect();
  db = client.db('ranking_test');
  api = service(client, db);
  server = httpServer({ handle: call, ready: async () => { await db.command({ ping: 1 }); return true; }, logger: { info() {}, error() {} } });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  url = `http://127.0.0.1:${server.address().port}`;
});
after(async () => {
  await new Promise(resolve => server?.close(resolve));
  await client?.close(); await repl?.stop();
});
beforeEach(async () => {
  await db.dropDatabase(); await initialize(db, '0.5');
  await db.collection('service_config').updateOne({ _id: 'ranking' }, { $set: { writes_enabled: true } });
});

test('normal: token ownership, retry, name uniqueness, rename and public privacy', async () => {
  const a = await register(); assert.equal(a.ok, true);
  assert.equal((await register('Ignored')).player_id, a.player_id);
  assert.equal((await register('teste', 'b'.repeat(64))).error, 'nickname_taken');
  assert.equal((await submit(a)).updated, true);
  assert.equal((await submit(a, record, 'b'.repeat(64))).error, 'unauthorized');
  assert.equal((await call({ action: 'rename', token, player_id: a.player_id, nickname: 'NovoNome' })).ok, true);
  const ranking = await query(); assert.equal(ranking.rankings.endless[0].nickname, 'NovoNome');
  assert(!JSON.stringify(ranking).includes(token)); assert(!JSON.stringify(ranking).includes(tokenHash(token)));
  assert.equal((await register('Teste', 'b'.repeat(64))).ok, true);
});

test('concurrent registrations cannot reserve a name twice; same token retry returns same identity', async () => {
  const [a, b] = await Promise.all([register('Mesmo'), register('mesmo', 'b'.repeat(64))]);
  assert.equal([a, b].filter(r => r.ok).length, 1); assert.equal([a, b].filter(r => r.error === 'nickname_taken').length, 1);
  const ids = await Promise.all(Array.from({ length: 4 }, () => register('Outro', 'c'.repeat(64))));
  assert.equal(new Set(ids.map(r => r.player_id)).size, 1);
});

test('concurrent best submissions, ties, bosses ordering and replayed request', async () => {
  const a = await register();
  await Promise.all([100, 90, 110, 70].map(seconds => submit(a, { ...record, seconds })));
  assert.equal((await query()).rankings.endless[0].seconds, 110);
  assert.equal((await submit(a, { ...record, seconds: 110 })).updated, false);
  assert.equal((await submit(a, { ...record, seconds: 110, kills: 11 })).updated, true);
  for (const seconds of [300, 250, 400]) await submit(a, { ...record, mode: 'bosses', reason: 'won', seconds });
  assert.equal((await query()).rankings.bosses[0].seconds, 250);
});

test('festival: independent entries, Unicode, repeated names and exactly once after response loss', async () => {
  const results = await Promise.all(Array.from({ length: 4 }, () => call(festival())));
  assert.equal(results.filter(r => r.updated).length, 1);
  assert.equal((await call(festival({ ...record, run_id: '2'.repeat(32), seconds: 30 }))).updated, true);
  assert.equal((await db.collection('players').countDocuments()), 0);
  assert.equal((await query()).rankings.endless.length, 0);
  const ranks = await call({ action: 'ranking', event_id, competitive_version: '0.5' });
  assert.equal(ranks.event_id, event_id); assert.equal(ranks.rankings.endless.length, 2); assert.equal(ranks.rankings.endless[0].seconds, 60);
  assert.equal((await call(festival({ ...record, mode: 'bosses', reason: 'death' }))).error, 'invalid_record');
  assert.equal((await call({ ...festival(), event_id: 'unknown' })).error, 'unknown_event');
});

test('input validation rejects operators and impossible results; event handling cannot inject query', async () => {
  const a = await register();
  for (const change of [{ kills: 1e6 }, { kills: -1 }, { seconds: '60' }, { level: 9999 }, { ruleset: 'unknown' }, { competitive_version: { $ne: '' } }]) {
    assert.equal((await submit(a, { ...record, ...change })).ok, false);
  }
  assert.equal((await call({ action: 'ranking', competitive_version: { $ne: '' } })).error, 'invalid_request');
  assert.equal((await call({ action: 'register', token: { $ne: '' }, nickname: 'Injected' })).error, 'unauthorized');
  assert.equal((await call({ ...festival(), record: { ...record, nickname: '=IMPORTXML()' } })).error, 'invalid_nickname');
  assert.equal((await call({ action: 'ranking', event_id: { $ne: '' } })).error, 'unknown_event');
});

test('maintenance preserves data; close season is atomic, retains original records and freezes names', async () => {
  const a = await register(); await submit(a); await call(festival());
  await Promise.all([api.closeSeason('0.6'), submit(a, { ...record, seconds: 70 })]);
  assert.equal((await db.collection('best_records').countDocuments()), 1);
  assert.equal((await submit(a)).error, 'version_closed');
  await call({ action: 'rename', token, player_id: a.player_id, nickname: 'Renomeado' });
  const old = await call({ action: 'legends', competitive_version: '0.5' });
  assert.equal(old.rankings.endless[0].nickname, 'Teste');
  assert.equal((await api.closeSeason('0.6')).changed, false);
  assert.equal((await call({ action: 'ranking', event_id })).rankings.endless.length, 1);
  await db.collection('service_config').updateOne({ _id: 'ranking' }, { $set: { writes_enabled: false } });
  assert.equal((await call(festival({ ...record, run_id: '3'.repeat(32) }))).error, 'busy');
  assert.equal((await call({ action: 'ranking', event_id })).rankings.endless.length, 1);
});

test('season failure rolls back snapshots and active version together', async () => {
  const a = await register(); await submit(a);
  await db.collection('seasons').insertOne({ version: '0.5', closed_at: 'conflict' });
  await assert.rejects(api.closeSeason('0.6'));
  assert.equal((await db.collection('service_config').findOne({ _id: 'ranking' })).active_version, '0.5');
  assert.equal(await db.collection('legend_entries').countDocuments(), 0);
  assert.equal((await submit(a, { ...record, seconds: 80 })).updated, true);
});

function backupInput() {
  return { format: 'pesca-mongo-backup-v1', active_version: '0.5', collections: {
    players: [{ player_id: 'original', nickname: 'Original', nickname_key: 'original', token_hash: tokenHash(token) }],
    best_records: [{ ...record, player_id: 'original', updated_at: '2026-10-21T00:00:00.000Z' }],
    festival_runs: [{ ...record, event_id, nickname: 'João Silva', submitted_at: '2026-10-21T00:00:00.000Z' }],
    seasons: [], legend_entries: [],
  } };
}

test('dry run, import twice, migrated credentials and conflicting destination rollback', async () => {
  await db.collection('service_config').updateOne({ _id: 'ranking' }, { $set: { writes_enabled: false } });
  const input = backupInput(), prepared = prepare(input);
  await importPrepared(client, db, prepared);
  assert.equal(await db.collection('players').countDocuments(), 0);
  assert.equal((await importPrepared(client, db, prepared, true)).counts.players.inserted, 1);
  assert.equal((await importPrepared(client, db, prepared, true)).counts.players.unchanged, 1);
  const conflicting = backupInput(); conflicting.collections.best_records[0].seconds = 61;
  conflicting.collections.players.push({ player_id: 'new', nickname: 'Novato', nickname_key: 'novato', token_hash: tokenHash('b'.repeat(64)) });
  await assert.rejects(importPrepared(client, db, prepare(conflicting), true), /conflitante/);
  assert.equal(await db.collection('players').countDocuments(), 1);
  await db.collection('service_config').updateOne({ _id: 'ranking' }, { $set: { writes_enabled: true } });
  assert.equal((await register('Ignored')).player_id, 'original');
  assert.equal((await submit({ player_id: 'original' }, { ...record, seconds: 90 })).updated, true);
  await assert.rejects(importPrepared(client, db, prepared, true), /Desative/);
});

test('backup roundtrip restores all public results in a fresh database', async () => {
  const a = await register(); await submit(a); await call(festival()); await api.closeSeason('0.6');
  const input = { format: 'pesca-mongo-backup-v1', active_version: '0.6', collections: {} };
  for (const name of collections) input.collections[name] = (await db.collection(name).find().toArray()).map(withoutId);
  const restored = client.db('restored_test'); await restored.dropDatabase(); await initialize(restored, '0.6');
  await importPrepared(client, restored, prepare(input), true);
  const other = service(client, restored);
  for (const request of [{ action: 'ranking', competitive_version: '0.6' }, { action: 'legends', competitive_version: '0.5' }, { action: 'ranking', event_id }]) {
    assert.deepEqual(await other.handle(request), await call(request));
  }
});

test('future local festival export imports into Mongo without duplicating original festival runs', async () => {
  const initial = backupInput();
  delete initial.collections.festival_runs[0].competitive_version;
  await db.collection('service_config').updateOne({ _id: 'ranking' }, { $set: { writes_enabled: false } });
  await importPrepared(client, db, prepare(initial), true);
  const original = initial.collections.festival_runs[0];
  const local = { format: 'pesca-festival-local-v1', event_id, active_version: '0.5', runs: [
    { ...original, competitive_version: '0.5', ruleset: 'pesca-2' },
    { ...original, run_id: '9'.repeat(32), competitive_version: '0.5' },
  ] };
  const prepared = prepare(local);
  const result = await importPrepared(client, db, prepared, true);
  assert.equal(result.counts.festival_runs.unchanged, 1);
  assert.equal(result.counts.festival_runs.inserted, 1);
  assert.equal(await db.collection('players').countDocuments(), 1);
});

test('export validation blocks missing tabs, orphan records and duplicate identities', () => {
  const input = backupInput(); input.collections.players = [];
  assert.throws(() => prepare(input), /sem jogador/);
  const dup = backupInput(); dup.collections.players.push({ ...dup.collections.players[0], player_id: 'other' });
  assert.throws(() => prepare(dup), /duplicado/);
  assert.throws(() => prepare({ format: 'pesca-sheets-v1', active_version: '0.5', sheets: {} }), /Aba ausente/);
});

test('actual Sheets export format preserves accounts, archived names and festival rules', async () => {
  const input = JSON.parse(await readFile(new URL('../examples/sheets-backup.example.json', import.meta.url), 'utf8'));
  const prepared = prepare(input);
  assert.equal(prepared.data.players.length, 1);
  assert.equal(prepared.data.legend_entries[0].nickname, 'NomeAntigo');
  await db.collection('service_config').updateOne({ _id: 'ranking' }, { $set: { writes_enabled: false } });
  await importPrepared(client, db, prepared, true);
  assert.equal((await query()).rankings.endless[0].nickname, 'Exemplo');
  assert.equal((await call({ action: 'legends', competitive_version: '0.4' })).rankings.endless[0].nickname, 'NomeAntigo');
  assert.equal((await call({ action: 'ranking', event_id })).rankings.endless[0].nickname, 'João Exemplo');
});

test('legacy display names survive import and restore; stale reservation key is audited, collisions abort', async () => {
  const input = JSON.parse(await readFile(new URL('../examples/sheets-backup.example.json', import.meta.url), 'utf8'));
  input.sheets.Players[1][1] = 'Legacy.DEV'; input.sheets.Players[1][2] = 'legacy';
  const prepared = prepare(input);
  assert.equal(prepared.adaptations.length, 2);
  assert.equal(prepared.data.players[0].nickname, 'Legacy.DEV');
  assert.equal(prepared.data.players[0].nickname_key, 'legacy.dev');
  assert.equal(prepared.data.players[0].legacy_nickname_key, 'legacy');
  assert.equal(input.sheets.Players[1][2], 'legacy', 'Source input is never modified');
  await db.collection('service_config').updateOne({ _id: 'ranking' }, { $set: { writes_enabled: false } });
  await importPrepared(client, db, prepared, true);
  assert.equal((await query()).rankings.endless[0].nickname, 'Legacy.DEV');
  const backup = { format: 'pesca-mongo-backup-v1', active_version: '0.5', collections: prepared.data };
  assert.deepEqual(prepare(backup).data.players, prepared.data.players);
  input.sheets.Players.push(['another-player', 'legacy.dev', 'other', tokenHash('b'.repeat(64))]);
  assert.throws(() => prepare(input), /duplicado/);
});

test('CLI init, dry run, apply, backup and restore execute end to end', async () => {
  const folder = await mkdtemp(join(tmpdir(), 'pesca-mongo-cli-'));
  const tools = fileURLToPath(new URL('../tools/', import.meta.url));
  const source = fileURLToPath(new URL('../examples/sheets-backup.example.json', import.meta.url));
  let database = 'cli_test';
  const run = (tool, ...args) => promisify(execFile)(process.execPath, [tools + tool + '.js', ...args], {
    cwd: folder, env: { ...process.env, MONGODB_URI: repl.getUri(), MONGODB_DATABASE: database }, timeout: 20000,
  });
  try {
    await run('admin', 'init', '0.5');
    const dry = await run('import', source);
    assert(dry.stdout.includes('"database_checked": false'));
    await run('import', source, '--check-db');
    await run('import', source, '--apply');
    assert.equal(await client.db(database).collection('festival_runs').countDocuments(), 1);
    await run('backup');
    const backup = join(folder, 'backups', (await readdir(join(folder, 'backups')))[0]);
    database = 'cli_restore_test';
    await run('admin', 'init', '0.5'); await run('import', backup, '--apply');
    assert.equal(await client.db(database).collection('players').countDocuments(), 1);
    await run('admin', 'enable');
    const status = await run('admin', 'status'); assert(status.stdout.includes('"writes_enabled":true'));
    await writeFile(join(folder, 'broken.json'), '{"private":"secret-cell-contents" broken');
    await assert.rejects(run('import', join(folder, 'broken.json')), error => !error.stderr.includes('secret-cell-contents'));
  } finally {
    const target = resolve(folder), base = resolve(tmpdir());
    assert(target.startsWith(base + '\\') || target.startsWith(base + '/'));
    assert(target.includes('pesca-mongo-cli-'));
    await rm(target, { recursive: true, force: true });
  }
});

test('HTTP direct JSON, invalid body, oversize body, readiness, and backend failure preserve protocol', async () => {
  const post = body => fetch(url + '/exec', { method: 'POST', body });
  assert.equal((await (await post(JSON.stringify({ action: 'ranking', event_id }))).json()).ok, true);
  assert.equal((await (await post('{bad')).json()).error, 'invalid_request');
  assert.equal((await (await post('x'.repeat(8193))).json()).error, 'invalid_request');
  assert.equal((await fetch(url + '/ready')).status, 200);
  const logs = [];
  const broken = httpServer({ handle: () => { throw new Error('secret-token'); }, ready: async () => false, logger: { error: s => logs.push(s), info() {} } });
  await new Promise(resolve => broken.listen(0, '127.0.0.1', resolve));
  try {
    const result = await fetch(`http://127.0.0.1:${broken.address().port}`, { method: 'POST', body: '{}' });
    assert.equal(result.status, 200); assert.equal((await result.json()).error, 'service_error');
    assert(!logs.join('').includes('secret-token'));
    assert.equal((await fetch(`http://127.0.0.1:${broken.address().port}/ready`)).status, 503);
  } finally { await new Promise(resolve => broken.close(resolve)); }
});

test('legacy main contract matches MongoDB for normal account, records, rename and closed version', async () => {
  const path = fileURLToPath(new URL('../../apps-script/', import.meta.url));
  const referenceSource = (await readFile(path + '/test.cjs', 'utf8')).replace('else tests();', 'else {};');
  const reference = new Function('require', '__dirname', referenceSource + '\nreturn backend;')(createRequire(import.meta.url), path)();
  reference.properties.set('ACTIVE_VERSION', '0.5');
  const a = await register(), b = reference.call({ action: 'register', nickname: 'Teste', token });
  const requests = [
    { action: 'submit', record }, { action: 'submit', record }, { action: 'submit', record: { ...record, kills: 11 } },
    { action: 'rename', nickname: 'NovoNome' }, { action: 'submit', record: { ...record, competitive_version: '0.3' } },
  ];
  for (const request of requests) {
    const actual = await call({ ...request, token, player_id: a.player_id });
    const expected = reference.call({ ...request, token, player_id: b.player_id });
    if (actual.player_id) actual.player_id = expected.player_id;
    assert.deepEqual(actual, expected);
  }
  const actual = await query(), expected = reference.call({ action: 'ranking', competitive_version: '0.5' });
  actual.rankings.endless[0].player_id = expected.rankings.endless[0].player_id;
  assert.deepEqual(actual, expected);
});

const root = fileURLToPath(new URL('../../../', import.meta.url));
const godot = process.env.GODOT_BIN || root + '.tools/godot/Godot_v4.7.2-stable_win64_console.exe';
test('real Godot client persists offline queue and synchronizes with MongoDB over HTTP', { skip: !existsSync(godot) }, async () => {
  const { stdout, stderr } = await promisify(execFile)(godot, ['--headless', '--path', root, '--script', 'res://scripts/test_mongodb_ranking.gd'], {
    env: { ...process.env, MONGO_TEST_ENDPOINT: url + '/exec' }, timeout: 30000,
  });
  assert(stdout.includes('MONGODB GODOT PASS'), stdout + stderr);
  assert(!stderr.includes('SCRIPT ERROR'), stderr);
  assert.equal(await db.collection('best_records').countDocuments(), 1);
});
