import { createHash, randomUUID } from 'node:crypto';
import { transaction } from './database.js';
import { fail_, validateRecord_, better_, validVersion_, compareVersions_, LEGACY_VERSION, FESTIVAL_ID } from './rules.js';

export const tokenHash = token => createHash('sha256').update(token).digest('hex');
const empty = () => ({ endless: [], bosses: [] });
const own = (obj, key) => Object.prototype.hasOwnProperty.call(obj, key);
const validName = name => typeof name === 'string' && /^[A-Za-z0-9_]{3,20}$/.test(name);
export const festivalName = name => typeof name === 'string' && /^[\p{L}\p{N}][\p{L}\p{N} _.-]{0,29}$/u.test(name);
const sort = (a, b, mode) => (mode === 'bosses' ? a.seconds - b.seconds : b.seconds - a.seconds)
  || b.kills - a.kills || a.nickname.localeCompare(b.nickname);

// Same localeCompare ordering as the legacy backend; select top 100 after joining current names.
export function rank(entries) {
  const rankings = empty();
  for (const entry of entries) if (own(rankings, entry.mode)) {
    const { mode, ...publicEntry } = entry;
    rankings[mode].push(publicEntry);
  }
  for (const mode of Object.keys(rankings)) rankings[mode] = rankings[mode].sort((a, b) => sort(a, b, mode)).slice(0, 100);
  return rankings;
}

export function service(client, db) {
  const config = () => db.collection('service_config').findOne({ _id: 'ranking' });
  // Shared config document serializes global submissions, account mutations, maintenance and season closure.
  async function write(operation) {
    return transaction(client, async session => {
      const cfg = await db.collection('service_config').findOneAndUpdate(
        { _id: 'ranking', writes_enabled: true }, { $inc: { revision: 1 } }, { session, returnDocument: 'after' });
      return cfg ? operation(cfg, session) : fail_('busy');
    });
  }
  async function globalEntries(version, session) {
    const accounts = await db.collection('players').find({}, { session }).toArray();
    const names = new Map(accounts.map(p => [p.player_id, p.nickname]));
    const records = await db.collection('best_records').find({ competitive_version: version }, { session }).toArray();
    return records.filter(r => names.has(r.player_id) && ['pesca-1', 'pesca-2'].includes(r.ruleset))
      .map(r => ({ mode: r.mode, player_id: r.player_id, nickname: names.get(r.player_id), seconds: r.seconds, kills: r.kills, level: r.level }));
  }
  async function legends(version, session) {
    if (!validVersion_(version)) return fail_('invalid_request');
    if (!await db.collection('seasons').findOne({ version }, { session })) return fail_('unknown_version');
    const entries = await db.collection('legend_entries').find({ competitive_version: version }, { session }).toArray();
    const rankings = empty();
    for (const r of entries) if (own(rankings, r.mode)) rankings[r.mode].push({
      position: r.position, nickname: r.nickname, seconds: r.seconds, kills: r.kills, level: r.level, player_id: r.player_id || '',
    });
    for (const mode of Object.keys(rankings)) rankings[mode].sort((a, b) => a.position - b.position);
    return { ok: true, competitive_version: version, rankings };
  }
  async function festival(input, cfg) {
    if (input.event_id !== FESTIVAL_ID) return fail_('unknown_event');
    if (!cfg.festival_enabled) return fail_('event_not_configured');
    if (input.action === 'ranking') {
      const records = await db.collection('festival_runs').find({ event_id: FESTIVAL_ID }).toArray();
      return { ok: true, event_id: FESTIVAL_ID, competitive_version: input.competitive_version || LEGACY_VERSION,
        rankings: rank(records.filter(r => ['pesca-1', 'pesca-2'].includes(r.ruleset)).map(r => ({
          mode: r.mode, nickname: r.nickname, seconds: r.seconds, kills: r.kills, level: r.level, run_id: r.run_id,
        }))), seasons: [] };
    }
    if (input.action !== 'submit') return fail_('invalid_request');
    const invalid = validateRecord_(input.record);
    if (invalid) return invalid;
    const r = input.record, nickname = typeof r.nickname === 'string' ? r.nickname.trim() : '';
    if (!festivalName(nickname)) return fail_('invalid_nickname', 'Use até 30 letras, números, espaços, ponto, hífen ou _.');
    return write(async (current, session) => {
      if (!current.festival_enabled) return fail_('event_not_configured');
      const key = { event_id: FESTIVAL_ID, run_id: r.run_id };
      if (await db.collection('festival_runs').findOne(key, { session })) return { ok: true, updated: false, event_id: FESTIVAL_ID };
      const { mode, seconds, kills, level, character, reason, ruleset } = r;
      await db.collection('festival_runs').insertOne({ ...key, nickname, mode, seconds, kills, level, character, reason, ruleset,
        submitted_at: new Date().toISOString() }, { session });
      return { ok: true, updated: true, event_id: FESTIVAL_ID };
    });
  }
  async function handle(input) {
    if (!input || typeof input !== 'object' || Array.isArray(input)) return fail_('invalid_request');
    const cfg = await config();
    if (!cfg) return fail_('not_configured');
    if (own(input, 'event_id')) return festival(input, cfg);
    if (input.action === 'ranking') {
      const version = input.competitive_version || LEGACY_VERSION;
      if (!validVersion_(version)) return fail_('invalid_request');
      const result = version === cfg.active_version ? { ok: true, rankings: rank(await globalEntries(version)) } : await legends(version);
      const seasons = (await db.collection('seasons').find({}).toArray()).map(s => s.version).sort(compareVersions_).reverse();
      return { ...result, competitive_version: version, active_version: cfg.active_version, seasons };
    }
    if (input.action === 'legends') return legends(input.competitive_version);
    if (typeof input.token !== 'string' || !/^[a-f0-9]{64}$/.test(input.token)) return fail_('unauthorized');
    const digest = tokenHash(input.token);
    return write(async (current, session) => {
      const players = db.collection('players');
      const account = await players.findOne({ token_hash: digest }, { session });
      if (input.action === 'register' || input.action === 'rename') {
        if (input.action === 'register' && account) return { ok: true, player_id: account.player_id, nickname: account.nickname };
        if (input.action === 'rename' && (!account || account.player_id !== input.player_id)) return fail_('unauthorized');
        const nickname = typeof input.nickname === 'string' ? input.nickname.trim() : '';
        if (!validName(nickname)) return fail_('invalid_nickname');
        const nickname_key = nickname.toLowerCase();
        const reserved = await players.findOne({ nickname_key }, { session });
        if (reserved && reserved.player_id !== account?.player_id) return fail_('nickname_taken');
        const player_id = account?.player_id || randomUUID();
        await players.updateOne({ player_id }, { $set: { nickname, nickname_key, token_hash: digest } }, { upsert: true, session });
        return { ok: true, player_id, nickname };
      }
      if (!account || account.player_id !== input.player_id) return fail_('unauthorized');
      if (input.action !== 'submit') return fail_('invalid_request');
      const invalid = validateRecord_(input.record);
      if (invalid) return invalid;
      const r = input.record, version = r.competitive_version || LEGACY_VERSION;
      if (version !== current.active_version) return fail_('version_closed', 'Esta versão competitiva não aceita mais recordes.');
      const key = { player_id: account.player_id, mode: r.mode, competitive_version: version };
      const previous = await db.collection('best_records').findOne(key, { session });
      if (previous && !better_(r, previous)) return { ok: true, updated: false };
      const { seconds, kills, level, character, reason, ruleset, run_id } = r;
      await db.collection('best_records').updateOne(key, { $set: { seconds, kills, level, character, reason, ruleset, run_id,
        updated_at: new Date().toISOString() } }, { upsert: true, session });
      return { ok: true, updated: true };
    });
  }
  async function closeSeason(next) {
    if (!validVersion_(next)) throw new Error('Use versão X.Y.');
    return transaction(client, async session => {
      const cfg = await db.collection('service_config').findOneAndUpdate({ _id: 'ranking' }, { $inc: { revision: 1 } }, { session, returnDocument: 'after' });
      if (!cfg) throw new Error('Serviço não inicializado.');
      if (cfg.active_version === next) return { changed: false };
      if (compareVersions_(next, cfg.active_version) <= 0) throw new Error('A versão deve avançar.');
      const rankings = rank(await globalEntries(cfg.active_version, session));
      for (const mode of Object.keys(rankings)) for (const [i, entry] of rankings[mode].entries()) {
        await db.collection('legend_entries').insertOne({ ...entry, mode, position: i + 1, competitive_version: cfg.active_version }, { session });
      }
      await db.collection('seasons').insertOne({ version: cfg.active_version, closed_at: new Date().toISOString() }, { session });
      await db.collection('service_config').updateOne({ _id: 'ranking' }, { $set: { active_version: next } }, { session });
      return { changed: true };
    });
  }
  return { handle, closeSeason };
}
