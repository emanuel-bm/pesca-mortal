// Run with Node.js; --serve also exposes the real handlers through a local HTTP mock.
const fs = require('node:fs');
const vm = require('node:vm');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const http = require('node:http');
class Sheet {
  constructor() { this.data = []; }
  clearContents() { this.data = []; }
  getLastRow() { return this.data.length; }
  getLastColumn() { return this.data[0]?.length || 0; }
  appendRow(row) { this.data.push([...row]); }
  getRange(start, column, count, width) {
    return {
      getValues: () => this.data.slice(start - 1, start - 1 + count).map(row => row.slice(column - 1, column - 1 + width)),
      setValues: rows => rows.forEach((row, i) => { this.data[start - 1 + i] = [...row]; })
    };
  }
}
function backend() {
  const sheets = new Map();
  let locked = false;
  const book = {getId: () => 'private-sheet', getSheetByName: name => sheets.get(name), insertSheet: name => { const sheet = new Sheet(); sheets.set(name, sheet); return sheet; }};
  const properties = new Map();
  const context = vm.createContext({
    SpreadsheetApp: {getActiveSpreadsheet: () => book, openById: () => book, flush() {}},
    PropertiesService: {getScriptProperties: () => ({getProperty: key => properties.get(key), setProperty: (key, value) => properties.set(key, value), deleteProperty: key => properties.delete(key)})},
    LockService: {getScriptLock: () => ({tryLock: () => { if (locked) return false; locked = true; return true; }, hasLock: () => locked, releaseLock: () => { locked = false; }})},
    Utilities: {getUuid: () => crypto.randomUUID(), DigestAlgorithm: {SHA_256: 'sha256'}, Charset: {UTF_8: 'utf8'}, computeDigest: (_, text) => [...crypto.createHash('sha256').update(text).digest()]},
    ContentService: {MimeType: {JSON: 'application/json'}, createTextOutput: text => ({text, setMimeType() { return this; }})}
  });
  vm.runInContext(fs.readFileSync(__dirname + '/Code.gs', 'utf8'), context);
  context.setupRanking();
  return {context, sheets, properties, call: input => JSON.parse(context.doPost({postData: {contents: JSON.stringify(input)}}).text)};
}
function tests() {
  const api = backend();
  const token = 'a'.repeat(64), otherToken = 'b'.repeat(64);
  const account = api.call({action: 'register', nickname: 'Pescador', token});
  assert.equal(account.ok, true);
  assert.equal(api.call({action: 'register', nickname: 'pescador', token: otherToken}).error, 'nickname_taken');
  assert.equal(api.call({action: 'register', nickname: 'Outra', token}).player_id, account.player_id, 'Registration retries do not create orphan accounts');
  const record = {mode: 'endless', seconds: 60, kills: 10, level: 1, character: 'Pescador', reason: 'death', ruleset: 'pesca-1', run_id: '1'.repeat(32)};
  const send = r => api.call({action: 'submit', player_id: account.player_id, token, record: r});
  assert.equal(api.context.validateRecord_({...record, seconds: 180, kills: 1, level: 8}), null, 'A 100-XP boss pickup with XP bonus can grant multiple levels');
  assert.equal(api.context.validateRecord_({...record, seconds: 179, kills: 1, level: 8}).error, 'invalid_record', 'Boss XP allowance starts at the first boss wave');
  assert.equal(send(record).updated, true);
  assert.equal(send(record).updated, false, 'Repeated score is idempotent');
  assert.equal(send({...record, seconds: 50}).updated, false);
  assert.equal(send({...record, kills: 11}).updated, true, 'Kills break equal-time ties');
  assert.equal(api.call({action: 'submit', player_id: account.player_id, token: otherToken, record}).error, 'unauthorized');
  for (const invalid of [{kills: -1}, {kills: 1000000}, {kills: 1.5}, {seconds: '60'}, {level: 9999999}, {character: '=IMPORTXML()'}, {mode: 'horde'}, {reason: 'won'}, {run_id: 'x'}, {level: 2, kills: 0}]) {
    assert.equal(send({...record, ...invalid}).error, 'invalid_record', JSON.stringify(invalid));
  }
  assert.equal(send({...record, ruleset: 'unknown'}).error, 'unsupported_ruleset');
  assert.equal(send({...record, mode: 'bosses', reason: 'won', seconds: 299}).error, 'invalid_record');
  assert.equal(send({...record, mode: 'bosses', reason: 'won', seconds: 400}).updated, true);
  assert.equal(send({...record, mode: 'bosses', reason: 'won', seconds: 450}).updated, false);
  assert.equal(send({...record, mode: 'bosses', reason: 'won', seconds: 350}).updated, true);
  assert.equal(api.call({action: 'rename', player_id: account.player_id, token, nickname: 'NovoNome'}).ok, true);
  assert.equal(api.call({action: 'register', nickname: 'Pescador', token: otherToken}).ok, true, 'Old nickname is released');
  const ranking = api.call({action: 'ranking'});
  assert.equal(ranking.rankings.endless[0].nickname, 'NovoNome');
  assert.equal(ranking.rankings.bosses[0].seconds, 350);
  assert(!JSON.stringify(ranking).includes('token_hash'));
  assert(!JSON.stringify(ranking).includes(token));
  // Independently accumulate increasing spawn rates using frame jitter and carry.
  for (const dt of [1 / 60, 0.05, 1 / 30, 0.017]) {
    let t = 0, timer = 0, carry = 0, spawned = 0;
    while (t < 1200) {
      t += dt; timer -= dt;
      if (timer <= 0) {
        timer += 1;
        const rate = t <= 300 ? 2 + 8 * t / 300 : 10 + (t - 300) / 30;
        const amount = Math.floor(rate + carry);
        carry = rate + carry - amount; spawned += amount;
      }
      const waves = Math.floor(t / 90);
      assert(spawned + waves * (waves + 1) / 2 <= api.context.maximumKills_(t, 'endless'));
    }
  }
  // Preserve only the best 100 per mode, snapshot names and retire legacy clients.
  const sheet = api.sheets.get('Records');
  for (let i = 0; i < 105; i++) {
    const id = 'seed-' + i;
    api.sheets.get('Players').appendRow([id, 'Seed_' + i, 'seed_' + i, 'hidden']);
    sheet.appendRow([id, 'endless', 1000 + i, 10, 1, 'Pescador', 'death', 'pesca-1', 'seed', '', '0.3']);
    sheet.appendRow([id, 'bosses', 500 + i, 10, 1, 'Pescador', 'won', 'pesca-1', 'seed', '', '0.3']);
  }
  api.context.activateCompetitiveVersion_('0.4');
  const old = api.call({action: 'legends', competitive_version: '0.3'});
  assert.equal(old.rankings.endless.length, 100);
  assert.equal(old.rankings.bosses.length, 100);
  assert.equal(old.rankings.endless[0].nickname, 'Seed_104');
  assert.equal(old.rankings.bosses[0].nickname, 'NovoNome');
  assert.equal(old.rankings.bosses[0].position, 1);
  assert.equal(sheet.getLastRow(), 1, 'Active Records must not retain archived results beyond top 100');
  assert.equal(send(record).error, 'version_closed', 'A legacy client cannot enter the new ranking');
  assert.equal(send({...record, competitive_version: '0.3'}).error, 'version_closed');
  assert.equal(send({...record, competitive_version: '0.4', seconds: 30}).updated, true, 'A fresh version accepts a lower personal best');
  assert.equal(api.call({action: 'ranking', competitive_version: '0.4'}).rankings.endless[0].seconds, 30);
  api.call({action: 'rename', player_id: account.player_id, token, nickname: 'Depois'});
  assert.equal(api.call({action: 'legends', competitive_version: '0.3'}).rankings.bosses[0].nickname, 'NovoNome');
  api.context.activateCompetitiveVersion_('0.4');
  assert.equal(sheet.getLastRow(), 2, 'Retry of a completed activation must preserve new scores');
  assert.throws(() => api.context.activateCompetitiveVersion_('0.3'));
  assert.throws(() => api.context.activateCompetitiveVersion_('0.4.1'));
  assert.equal(api.call({action: 'legends', competitive_version: '9.9'}).error, 'unknown_version');
  assert.deepEqual(api.call({action: 'ranking', competitive_version: '0.4'}).seasons, ['0.3']);
  // Simulate failure after archive persistence, before clearing the active sheet.
  const clear = sheet.clearContents;
  sheet.clearContents = () => { throw new Error('Interrupted'); };
  assert.throws(() => api.context.activateCompetitiveVersion_('1.0'));
  assert.equal(api.call({action: 'ranking', competitive_version: '0.4'}).error, 'busy');
  sheet.clearContents = clear;
  api.context.activateCompetitiveVersion_('1.0');
  assert.equal(api.call({action: 'legends', competitive_version: '0.4'}).rankings.endless[0].nickname, 'Depois');
  assert.equal(api.sheets.get('Seasons').getLastRow(), 3, 'Interrupted retries do not duplicate archives');
  assert.equal(api.call({action: 'ranking', competitive_version: '1.0'}).rankings.endless.length, 0);
  api.properties.set('TRANSITION_VERSION', '1.0');
  api.context.activateCompetitiveVersion_('1.0');
  assert.equal(api.properties.has('TRANSITION_VERSION'), false);
  console.log('BACKEND PASS: unique names, rename, credential ownership, record ordering, replayed requests, field/rules/XP validation, spawn bounds, public data');
}
if (process.argv.includes('--serve')) {
  const api = backend();
  const responses = new Map();
  let submissions = 0;
  const server = http.createServer((req, res) => {
    if (req.url === '/stats') { res.end(JSON.stringify({submissions})); return; }
    if (req.method === 'GET' && responses.has(req.url)) {
      if (Number(req.headers['content-length'] || 0) > 0) { res.writeHead(400); res.end('GET response must not retain POST body'); return; }
      res.setHeader('Content-Type', 'application/json'); res.end(responses.get(req.url)); responses.delete(req.url); return;
    }
    let body = '';
    req.on('data', data => { body += data; });
    req.on('end', () => {
      try {
        const input = JSON.parse(body);
        if (input.action === 'submit') submissions++;
        const location = '/response/' + crypto.randomUUID();
        if (input.action === '__test_activate') api.context.activateCompetitiveVersion_('0.4');
        responses.set(location, JSON.stringify(input.action === '__test_activate' ? {ok: true} : api.call(input)));
        res.writeHead(302, {Location: location}); res.end();
      } catch { res.writeHead(400); res.end(); }
    });
  });
  server.listen(18745, '127.0.0.1', () => console.log('MOCK READY http://127.0.0.1:18745/exec'));
} else tests();
