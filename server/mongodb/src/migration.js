import { createHash } from 'node:crypto';
import { isDeepStrictEqual } from 'node:util';
import { transaction } from './database.js';
import { validVersion_, validateRecord_, FESTIVAL_ID } from './rules.js';
import { festivalName } from './service.js';

export const collections = ['players', 'best_records', 'festival_runs', 'seasons', 'legend_entries'];
export const withoutId = ({ _id, ...rest }) => rest;
export class MigrationError extends Error {}
const required = (condition, message) => { if (!condition) throw new MigrationError(message); };
const finite = value => typeof value === 'number' && Number.isFinite(value);
const score = r => ['endless', 'bosses'].includes(r.mode) && finite(r.seconds) && r.seconds > 0
  && Number.isSafeInteger(r.kills) && r.kills >= 0 && Number.isSafeInteger(r.level) && r.level > 0;
const keys = {
  players: d => ({ player_id: d.player_id }),
  best_records: d => ({ player_id: d.player_id, competitive_version: d.competitive_version, mode: d.mode }),
  festival_runs: d => ({ event_id: d.event_id, run_id: d.run_id }),
  seasons: d => ({ version: d.version }),
  legend_entries: d => ({ competitive_version: d.competitive_version, mode: d.mode, position: d.position }),
};
function table(sheets, name, headers) {
  required(Array.isArray(sheets[name]), `Aba ausente: ${name}`);
  const rows = sheets[name];
  required(rows.length > 0 && Array.isArray(rows[0]), `Cabeçalho ausente: ${name}`);
  for (const h of headers) required(rows[0].includes(h), `Coluna ausente em ${name}: ${h}`);
  required(new Set(rows[0]).size === rows[0].length, `Colunas duplicadas: ${name}`);
  return rows.slice(1).filter(row => row.some(cell => cell !== '' && cell !== null)).map((row, index) => {
    required(Array.isArray(row) && row.length <= rows[0].length, `Linha inválida em ${name}: ${index + 2}`);
    return Object.fromEntries(rows[0].map((h, i) => [h, row[i] ?? '']));
  });
}

export function prepare(input) {
  required(input && typeof input === 'object' && validVersion_(input.active_version), 'Versão ativa X.Y ausente ou inválida.');
  const data = Object.fromEntries(collections.map(c => [c, []]));
  const adaptations = [];
  if (input.format === 'pesca-sheets-v1') {
    const s = input.sheets;
    required(s && typeof s === 'object', 'Abas ausentes.');
    data.players = table(s, 'Players', ['player_id', 'nickname', 'nickname_key', 'token_hash']).map((r, index) => {
      const player = { player_id: r.player_id, nickname: r.nickname, nickname_key: r.nickname_key, token_hash: r.token_hash };
      if (typeof r.nickname === 'string' && typeof r.nickname_key === 'string' && r.nickname_key !== r.nickname.toLowerCase()) {
        player.legacy_nickname_key = r.nickname_key;
        player.nickname_key = r.nickname.toLowerCase();
        adaptations.push({ collection: 'players', row: index + 2, field: 'nickname_key', reason: 'rebuilt_from_display_name_original_retained' });
      }
      if (typeof r.nickname === 'string' && !/^[A-Za-z0-9_]{3,20}$/.test(r.nickname)) {
        adaptations.push({ collection: 'players', row: index + 2, field: 'nickname', reason: 'legacy_display_name_preserved' });
      }
      return player;
    });
    data.best_records = table(s, 'Records', ['player_id', 'mode', 'seconds', 'kills', 'level', 'character', 'reason', 'ruleset', 'run_id', 'updated_at']).map(r => ({
      player_id: r.player_id, mode: r.mode, seconds: r.seconds, kills: r.kills, level: r.level, character: r.character,
      reason: r.reason, ruleset: r.ruleset, run_id: r.run_id, updated_at: r.updated_at,
      competitive_version: r.competitive_version || '0.3',
    }));
    data.seasons = table(s, 'Seasons', ['version', 'closed_at']).map(r => ({ version: r.version, closed_at: r.closed_at }));
    data.festival_runs = table(s, 'Festival High Tech MT', ['run_id', 'nickname', 'mode', 'seconds', 'kills', 'level', 'character', 'reason', 'ruleset', 'submitted_at']).map(r => ({
      event_id: FESTIVAL_ID, run_id: r.run_id, nickname: r.nickname, mode: r.mode, seconds: r.seconds, kills: r.kills,
      level: r.level, character: r.character, reason: r.reason, ruleset: r.ruleset, submitted_at: r.submitted_at,
    }));
    for (const name of Object.keys(s).filter(n => n.startsWith('Lendas_'))) {
      required(/^Lendas_\d+_\d+$/.test(name), 'Nome de arquivo Lendas inválido.');
      const competitive_version = name.slice(7).replace('_', '.');
      const rows = table(s, name, ['mode', 'position', 'nickname', 'seconds', 'kills', 'level']);
      data.legend_entries.push(...rows.map(r => ({ competitive_version, mode: r.mode, position: r.position,
        nickname: r.nickname, seconds: r.seconds, kills: r.kills, level: r.level, player_id: r.player_id || '' })));
    }
    for (const season of data.seasons) required(Object.hasOwn(s, 'Lendas_' + String(season.version).replace('.', '_')), 'Arquivo de temporada ausente.');
  } else if (input.format === 'pesca-festival-local-v1') {
    required(input.event_id === FESTIVAL_ID && Array.isArray(input.runs), 'Arquivo local do festival inválido.');
    data.festival_runs = input.runs.map(r => ({ event_id: FESTIVAL_ID, run_id: r.run_id, nickname: r.nickname,
      mode: r.mode, seconds: r.seconds, kills: r.kills, level: r.level, character: r.character,
      reason: r.reason, ruleset: r.ruleset, submitted_at: r.submitted_at }));
  } else if (input.format === 'pesca-mongo-backup-v1') {
    for (const name of collections) {
      required(Array.isArray(input.collections?.[name]), `Coleção ausente: ${name}`);
      data[name] = input.collections[name].map(withoutId);
    }
  } else throw new MigrationError('Formato de exportação desconhecido.');
  const ids = new Set(), names = new Set(), tokens = new Set();
  for (const p of data.players) {
    required(typeof p.player_id === 'string' && p.player_id.length > 0 && festivalName(p.nickname)
      && p.nickname_key === p.nickname.toLowerCase() && /^[a-f0-9]{64}$/.test(p.token_hash), 'Cadastro inválido.');
    required(!ids.has(p.player_id) && !names.has(p.nickname_key) && !tokens.has(p.token_hash), 'Cadastro duplicado ou conflitante.');
    ids.add(p.player_id); names.add(p.nickname_key); tokens.add(p.token_hash);
  }
  for (const r of data.best_records) required(ids.has(r.player_id) && !validateRecord_(r), 'Recorde inválido ou sem jogador.');
  for (const r of data.festival_runs) required(r.event_id === FESTIVAL_ID && festivalName(r.nickname) && !validateRecord_(r), 'Partida do festival inválida.');
  const seasons = new Set(data.seasons.map(s => s.version));
  required(!seasons.has(input.active_version), 'Versão ativa também está encerrada. Confira as propriedades do Apps Script.');
  for (const s of data.seasons) required(validVersion_(s.version) && typeof s.closed_at === 'string', 'Temporada inválida.');
  for (const r of data.legend_entries) required(seasons.has(r.competitive_version) && score(r) && Number.isInteger(r.position)
    && r.position >= 1 && r.position <= 100 && typeof r.nickname === 'string' && typeof r.player_id === 'string', 'Lenda inválida ou sem temporada.');
  const duplicates = [];
  for (const name of collections) {
    const seen = new Map();
    for (const row of data[name]) {
      const key = JSON.stringify(keys[name](row));
      if (seen.has(key)) {
        required(isDeepStrictEqual(seen.get(key), row), `Conteúdo conflitante em ${name}.`);
        duplicates.push(name);
      } else seen.set(key, row);
    }
    data[name] = [...seen.values()];
  }
  return { active_version: input.active_version, data, duplicate_rows: duplicates.length, adaptations,
    checksum: createHash('sha256').update(JSON.stringify(input)).digest('hex') };
}

export async function importPrepared(client, db, prepared, apply = false) {
  return transaction(client, async session => {
    const cfg = apply
      ? await db.collection('service_config').findOneAndUpdate({ _id: 'ranking', writes_enabled: false },
        { $inc: { revision: 1 } }, { session, returnDocument: 'after' })
      : await db.collection('service_config').findOne({ _id: 'ranking', writes_enabled: false }, { session });
    required(cfg, 'Desative envios antes de conferir/importar.');
    required(cfg.active_version === prepared.active_version, 'Versão ativa do destino difere da exportação.');
    const counts = {};
    for (const name of collections) {
      counts[name] = { total: prepared.data[name].length, inserted: 0, unchanged: 0 };
      for (const row of prepared.data[name]) {
        const previous = await db.collection(name).findOne(keys[name](row), { session });
        if (previous) {
          required(isDeepStrictEqual(withoutId(previous), row), `Destino conflitante em ${name}; nenhuma substituição permitida.`);
          counts[name].unchanged++;
        } else {
          counts[name].inserted++;
          if (apply) await db.collection(name).insertOne({ ...row }, { session });
        }
      }
    }
    if (apply) await db.collection('migration_runs').updateOne({ _id: prepared.checksum }, { $setOnInsert: {
      imported_at: new Date().toISOString(), counts, adaptations: prepared.adaptations,
    } }, { session, upsert: true });
    return { applied: apply, checksum: prepared.checksum, duplicate_rows: prepared.duplicate_rows, adaptations: prepared.adaptations, counts };
  });
}
