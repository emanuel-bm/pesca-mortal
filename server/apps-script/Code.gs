/** Private Sheets backend. Deploy as owner; public web-app access. */
const RULESET = 'pesca-1';
const PLAYERS = ['player_id', 'nickname', 'nickname_key', 'token_hash'];
const RECORDS = ['player_id', 'mode', 'seconds', 'kills', 'level', 'character', 'reason', 'ruleset', 'run_id', 'updated_at'];

function setupRanking() {
  const book = SpreadsheetApp.getActiveSpreadsheet();
  if (!book) throw new Error('Abra o Apps Script a partir da planilha.');
  PropertiesService.getScriptProperties().setProperty('SPREADSHEET_ID', book.getId());
  sheet_(book, 'Players', PLAYERS);
  sheet_(book, 'Records', RECORDS);
}

function sheet_(book, name, headers) {
  const sheet = book.getSheetByName(name) || book.insertSheet(name);
  if (!sheet.getLastRow()) sheet.appendRow(headers);
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
    if (input.action === 'ranking') return json_(publicRanking_(accounts, rows_(records)));
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
    const existing = rows_(records);
    const index = existing.findIndex(row => row[0] === input.player_id && row[1] === result.mode);
    if (index >= 0 && !better_(result, {seconds: existing[index][2], kills: existing[index][3]})) return json_({ok: true, updated: false});
    const row = [input.player_id, result.mode, result.seconds, result.kills, result.level, result.character, result.reason, RULESET, result.run_id, new Date().toISOString()];
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
  // +100% XP doubles both allowances.
  const waves = r.mode === 'endless' ? Math.max(0, Math.floor((r.seconds + 0.001 - 180) / 120) + 1) : 0;
  const bossKills = Math.min(r.kills, waves * (waves + 1) / 2);
  const budget = (r.kills - bossKills) * 18 + bossKills * 200;
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
    rankings[row[1]].push({nickname: names.get(row[0]), seconds: row[2], kills: row[3], level: row[4]});
  });
  Object.keys(rankings).forEach(mode => {
    rankings[mode].sort((a, b) => (mode === 'bosses' ? a.seconds - b.seconds : b.seconds - a.seconds) || b.kills - a.kills || a.nickname.localeCompare(b.nickname));
    rankings[mode] = rankings[mode].slice(0, 100);
  });
  return {ok: true, rankings};
}
