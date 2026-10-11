/** Private Sheets backend. Deploy as owner; public web-app access. */
const RULESET = 'pesca-1';
const LEGACY_VERSION = '0.3';
const ARCHIVE = ['mode', 'position', 'nickname', 'seconds', 'kills', 'level', 'player_id'];
const SEASONS = ['version', 'closed_at'];
const PLAYERS = ['player_id', 'nickname', 'nickname_key', 'token_hash'];
const RECORDS = ['player_id', 'mode', 'seconds', 'kills', 'level', 'character', 'reason', 'ruleset', 'run_id', 'updated_at', 'competitive_version'];

function setupRanking() {
  const book = SpreadsheetApp.getActiveSpreadsheet();
  if (!book) throw new Error('Abra o Apps Script a partir da planilha.');
  PropertiesService.getScriptProperties().setProperty('SPREADSHEET_ID', book.getId());
  sheet_(book, 'Players', PLAYERS);
  sheet_(book, 'Records', RECORDS);
  sheet_(book, 'Seasons', SEASONS);
  const props = PropertiesService.getScriptProperties();
  if (!props.getProperty('ACTIVE_VERSION')) props.setProperty('ACTIVE_VERSION', LEGACY_VERSION);
}

function sheet_(book, name, headers) {
  const sheet = book.getSheetByName(name) || book.insertSheet(name);
  if (!sheet.getLastRow()) sheet.appendRow(headers);
  else if (sheet.getLastColumn() < headers.length) sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
  return sheet;
}
function rows_(sheet) {
  return sheet.getLastRow() < 2 ? [] : sheet.getRange(2, 1, sheet.getLastRow() - 1, sheet.getLastColumn()).getValues();
}
function hash_(token) {
  return Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, token, Utilities.Charset.UTF_8)
    .map(b => ('0' + ((b + 256) % 256).toString(16)).slice(-2)).join('');
}
function fail_(error, message) { return {ok: false, error, message: message || ''}; }
function json_(data) { return ContentService.createTextOutput(JSON.stringify(data)).setMimeType(ContentService.MimeType.JSON); }

function doPost(e) {
  let lock;
  try {
    if (!e || !e.postData || e.postData.contents.length > 8192) return json_(fail_('invalid_request'));
    const input = JSON.parse(e.postData.contents);
    if (!input || typeof input !== 'object' || Array.isArray(input)) return json_(fail_('invalid_request'));
    const id = PropertiesService.getScriptProperties().getProperty('SPREADSHEET_ID');
    if (!id) return json_(fail_('not_configured'));
    // Keep nickname reservations and compare/write atomic, even with ten players.
    lock = LockService.getScriptLock();
    if (!lock.tryLock(10000)) return json_(fail_('busy'));
    const book = SpreadsheetApp.openById(id);
    const players = sheet_(book, 'Players', PLAYERS);
    const records = sheet_(book, 'Records', RECORDS);
    const accounts = rows_(players);
    const props = PropertiesService.getScriptProperties();
    if (props.getProperty('TRANSITION_VERSION')) return json_(fail_('busy'));
    const active = props.getProperty('ACTIVE_VERSION') || LEGACY_VERSION;
    if (input.action === 'ranking') {
      const version = input.competitive_version || LEGACY_VERSION;
      const result = version === active ? publicRanking_(accounts, rows_(records).filter(row => (row[10] || LEGACY_VERSION) === active)) : archiveRanking_(book, version);
      return json_({...result, competitive_version: version, active_version: active, seasons: rows_(sheet_(book, 'Seasons', SEASONS)).map(row => row[0]).sort(compareVersions_).reverse()});
    }
    if (input.action === 'legends') return json_(archiveRanking_(book, input.competitive_version));
    if (typeof input.token !== 'string' || !/^[a-f0-9]{64}$/.test(input.token)) return json_(fail_('unauthorized'));
    const digest = hash_(input.token);
    const accountIndex = accounts.findIndex(row => row[3] === digest);
    if (input.action === 'register' || input.action === 'rename') {
      if (input.action === 'rename' && (accountIndex < 0 || accounts[accountIndex][0] !== input.player_id)) return json_(fail_('unauthorized'));
      // Registration retry after lost response returns the same account.
      if (input.action === 'register' && accountIndex >= 0) return json_({ok: true, player_id: accounts[accountIndex][0], nickname: accounts[accountIndex][1]});
      const name = typeof input.nickname === 'string' ? input.nickname.trim() : '';
      if (!/^[A-Za-z0-9_]{3,20}$/.test(name)) return json_(fail_('invalid_nickname'));
      const key = name.toLowerCase();
      if (accounts.some((row, index) => index !== accountIndex && row[2] === key)) return json_(fail_('nickname_taken'));
      const playerId = accountIndex < 0 ? Utilities.getUuid() : accounts[accountIndex][0];
      const row = [playerId, name, key, digest];
      if (accountIndex < 0) players.appendRow(row);
      else players.getRange(accountIndex + 2, 1, 1, row.length).setValues([row]);
      SpreadsheetApp.flush();
      return json_({ok: true, player_id: playerId, nickname: name});
    }
    if (accountIndex < 0 || accounts[accountIndex][0] !== input.player_id) return json_(fail_('unauthorized'));
    if (input.action !== 'submit') return json_(fail_('invalid_request'));
    const validation = validateRecord_(input.record);
    if (validation) return json_(validation);
    const result = input.record;
    const version = result.competitive_version || LEGACY_VERSION;
    if (version !== active) return json_(fail_('version_closed', 'Esta versão competitiva não aceita mais recordes.'));
    const existing = rows_(records);
    const index = existing.findIndex(row => row[0] === input.player_id && row[1] === result.mode && (row[10] || LEGACY_VERSION) === active);
    if (index >= 0 && !better_(result, {seconds: existing[index][2], kills: existing[index][3]})) return json_({ok: true, updated: false});
    const row = [input.player_id, result.mode, result.seconds, result.kills, result.level, result.character, result.reason, RULESET, result.run_id, new Date().toISOString(), active];
    if (index < 0) records.appendRow(row);
    else records.getRange(index + 2, 1, 1, row.length).setValues([row]);
    SpreadsheetApp.flush();
    return json_({ok: true, updated: true});
  } catch (_) {
    // Never expose credentials, sheet contents or stack traces to clients.
    return json_(fail_('service_error'));
  } finally {
    if (lock && lock.hasLock()) lock.releaseLock();
  }
}

function better_(next, previous) {
  if (next.seconds !== previous.seconds) return next.mode === 'bosses' ? next.seconds < previous.seconds : next.seconds > previous.seconds;
  return next.kills > previous.kills;
}

function maximumKills_(seconds, mode) {
  // Game ticks clamp dt to 0.05s; spawn batches occur at 0,1,2,... seconds.
  // Sum increasing rates at tick+0.051s, conservatively allowing rounding drift.
  const t = seconds + 0.001;
  const n = Math.floor(t);
  const early = Math.min(n + 1, 300);
  const late = Math.max(0, n - 299);
  const fish = Math.floor(2 * early + (8 / 300) * (early * (early - 1) / 2 + 0.051 * early)
    + 10 * late + (late * (late - 1) / 2 + 0.051 * late) / 30) + 2;
  const waves = Math.floor(t / 90);
  const bosses = mode === 'endless' ? waves * (waves + 1) / 2 : (t >= 300 ? 1 : 0);
  // Simultaneous population cap only reduces possible spawns.
  return fish + bosses;
}

function validateRecord_(r) {
  if (!r || typeof r !== 'object' || Array.isArray(r)) return fail_('invalid_record', 'Resultado inválido.');
  if (r.ruleset !== RULESET) return fail_('unsupported_ruleset', 'Versão das regras não suportada.');
  if (!['endless', 'bosses'].includes(r.mode) || r.character !== 'Pescador') return fail_('invalid_record', 'Modo ou personagem inválido.');
  if (typeof r.seconds !== 'number' || !Number.isFinite(r.seconds) || r.seconds <= 0 || r.seconds > Number.MAX_SAFE_INTEGER / 1000) return fail_('invalid_record', 'Tempo inválido.');
  if (!Number.isSafeInteger(r.kills) || r.kills < 0 || !Number.isSafeInteger(r.level) || r.level < 1) return fail_('invalid_record', 'Eliminações ou nível inválidos.');
  if (typeof r.run_id !== 'string' || !/^[a-f0-9]{32}$/.test(r.run_id)) return fail_('invalid_record', 'Identificador de partida inválido.');
  if (r.mode === 'bosses' && (r.reason !== 'won' || r.seconds + 0.001 < 300)) return fail_('invalid_record', 'Vitória antes do surgimento do chefão.');
  if (r.mode === 'endless' && !['death', 'menu', 'restart', 'quit'].includes(r.reason)) return fail_('invalid_record', 'Encerramento inválido.');
  if (r.kills > maximumKills_(r.seconds, r.mode)) return fail_('invalid_record', 'Eliminações acima do máximo possível nesse tempo.');
  // Preserve the 9-XP allowance for ordinary kills; endless bosses yield 100.
  // Allow +20 percentage points per level-up, with no XP bonus cap.
  const waves = r.mode === 'endless' ? Math.max(0, Math.floor((r.seconds + 0.001 - 180) / 120) + 1) : 0;
  const bossKills = Math.min(r.kills, waves * (waves + 1) / 2);
  const xpMultiplier = Math.max(2, 1 + 0.2 * Math.max(0, r.level - 2));
  const budget = ((r.kills - bossKills) * 9 + bossKills * 100) * xpMultiplier;
  let required = 0;
  for (let level = 1; level < r.level; level++) {
    required += Math.ceil((5 + (level - 1) * 3) * 1.4 * Math.pow(1.05, level - 1));
    if (required > budget) return fail_('invalid_record', 'Nível incompatível com as eliminações.');
  }
  return null;
}

function publicRanking_(accounts, records) {
  const names = new Map(accounts.map(row => [row[0], row[1]]));
  const rankings = {endless: [], bosses: []};
  records.forEach(row => {
    if (!names.has(row[0]) || !rankings[row[1]] || row[7] !== RULESET) return;
    rankings[row[1]].push({player_id: row[0], nickname: names.get(row[0]), seconds: row[2], kills: row[3], level: row[4]});
  });
  Object.keys(rankings).forEach(mode => {
    rankings[mode].sort((a, b) => (mode === 'bosses' ? a.seconds - b.seconds : b.seconds - a.seconds) || b.kills - a.kills || a.nickname.localeCompare(b.nickname));
    rankings[mode] = rankings[mode].slice(0, 100);
  });
  return {ok: true, rankings};
}

function validVersion_(value) { return typeof value === 'string' && /^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$/.test(value); }
function compareVersions_(a, b) {
  const left = a.split('.').map(Number), right = b.split('.').map(Number);
  return left[0] - right[0] || left[1] - right[1];
}
function archiveName_(version) { return 'Lendas_' + version.replace('.', '_'); }
function archiveRanking_(book, version) {
  if (!validVersion_(version)) return fail_('invalid_request');
  if (!rows_(sheet_(book, 'Seasons', SEASONS)).some(row => row[0] === version)) return fail_('unknown_version');
  const sheet = book.getSheetByName(archiveName_(version));
  if (!sheet) return fail_('service_error');
  const rankings = {endless: [], bosses: []};
  rows_(sheet).forEach(row => {
    if (rankings[row[0]]) rankings[row[0]].push({position: row[1], nickname: row[2], seconds: row[3], kills: row[4], level: row[5], player_id: row[6] || ''});
  });
  Object.keys(rankings).forEach(mode => rankings[mode].sort((a, b) => a.position - b.position));
  return {ok: true, competitive_version: version, rankings};
}
// Altere o destino para X.Y da nova publicação e execute pelo editor.
function iniciarNovaVersaoCompetitiva() { activateCompetitiveVersion_('0.4'); }
function activateCompetitiveVersion_(next) {
  if (!validVersion_(next)) throw new Error('Use X.Y, sem patch.');
  const props = PropertiesService.getScriptProperties();
  const lock = LockService.getScriptLock();
  if (!lock.tryLock(10000)) throw new Error('Ranking ocupado. Tente novamente.');
  try {
    const current = props.getProperty('ACTIVE_VERSION') || LEGACY_VERSION;
    const transition = props.getProperty('TRANSITION_VERSION');
    if (transition && transition !== next) throw new Error('Conclua primeiro a transição pendente.');
    if (!transition && current === next) return;
    // A retry can arrive after ACTIVE_VERSION was saved but before the marker was removed.
    if (transition && current === next) { props.deleteProperty('TRANSITION_VERSION'); return; }
    if (compareVersions_(next, current) <= 0) throw new Error('A nova versão deve ser posterior à ativa.');
    const book = SpreadsheetApp.openById(props.getProperty('SPREADSHEET_ID'));
    const seasons = sheet_(book, 'Seasons', SEASONS);
    const records = sheet_(book, 'Records', RECORDS);
    // Blocks submissions after a partial failure until this operation is retried.
    props.setProperty('TRANSITION_VERSION', next);
    if (!rows_(seasons).some(row => row[0] === current)) {
      const ranking = publicRanking_(rows_(sheet_(book, 'Players', PLAYERS)), rows_(records).filter(row => (row[10] || LEGACY_VERSION) === current)).rankings;
      const archive = sheet_(book, archiveName_(current), ARCHIVE);
      archive.clearContents();
      archive.appendRow(ARCHIVE);
      const snapshot = [];
      Object.keys(ranking).forEach(mode => ranking[mode].forEach((entry, index) => snapshot.push([mode, index + 1, entry.nickname, entry.seconds, entry.kills, entry.level, entry.player_id])));
      if (snapshot.length) archive.getRange(2, 1, snapshot.length, ARCHIVE.length).setValues(snapshot);
      SpreadsheetApp.flush();
      seasons.appendRow([current, new Date().toISOString()]);
      SpreadsheetApp.flush();
    }
    records.clearContents();
    records.appendRow(RECORDS);
    SpreadsheetApp.flush();
    props.setProperty('ACTIVE_VERSION', next);
    props.deleteProperty('TRANSITION_VERSION');
  } finally { lock.releaseLock(); }
}
