import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';

test('legacy bridge forwards existing Festival 0.5 JSON and preserves all protocol errors', async () => {
  const source = await readFile(new URL('../legacy/Bridge.gs', import.meta.url), 'utf8');
  const props = new Map([['MONGO_API_URL', 'https://api.example/exec']]);
  let lastRequest, response = { ok: true, event_id: 'festival-high-tech-mt', rankings: { endless: [], bosses: [] } };
  const context = vm.createContext({
    PropertiesService: { getScriptProperties: () => ({ getProperty: key => props.get(key) }) },
    ContentService: { MimeType: { JSON: 'json' }, createTextOutput: text => ({ text, setMimeType() { return this; } }) },
    UrlFetchApp: { fetch: (url, options) => { lastRequest = { url, options }; return { getResponseCode: () => 200, getContentText: () => JSON.stringify(response) }; } },
    console: { error() {} },
  });
  vm.runInContext(source, context);
  const payload = JSON.stringify({ action: 'ranking', event_id: 'festival-high-tech-mt', competitive_version: '0.5' });
  const call = () => JSON.parse(context.doPost({ postData: { contents: payload } }).text);
  assert.deepEqual(call(), response); assert.equal(lastRequest.options.payload, payload);
  assert.equal(lastRequest.options.followRedirects, false);
  response = { ok: false, error: 'invalid_record', message: 'Resultado inválido.' };
  assert.deepEqual(call(), response);
  props.set('MIGRATION_MAINTENANCE', 'true');
  assert.equal(call().error, 'busy');
  assert.equal(context.setupRanking, undefined); assert.equal(context.iniciarNovaVersaoCompetitiva, undefined);
});

test('legacy exporter copies complete private tables and never exposes other script properties', async () => {
  const source = await readFile(new URL('../legacy/Export.gs', import.meta.url), 'utf8');
  const props = new Map([['SPREADSHEET_ID', 'original-book'], ['ACTIVE_VERSION', '0.5'], ['UNRELATED_SECRET', 'never-export']]);
  let result;
  const rows = [['run_id'], ...Array.from({ length: 150 }, (_, i) => [String(i)])];
  const context = vm.createContext({
    PropertiesService: { getScriptProperties: () => ({ getProperty: key => props.get(key) }) },
    SpreadsheetApp: { openById: id => { assert.equal(id, 'original-book'); return { getId: () => id, getSheets: () => [{
      getName: () => 'Festival High Tech MT', getLastRow: () => rows.length, getDataRange: () => ({ getValues: () => rows }),
    }] }; } },
    DriveApp: { createFile: (_, text) => { result = JSON.parse(text); return { getUrl: () => 'private-file' }; } },
    MimeType: { PLAIN_TEXT: 'text/plain' }, console: { log() {} },
  });
  vm.runInContext(source, context); context.exportRankingBackup();
  assert.equal(result.sheets['Festival High Tech MT'].length, 151);
  assert(!JSON.stringify(result).includes('never-export'));
  props.set('TRANSITION_VERSION', '0.6');
  assert.throws(() => context.exportRankingBackup(), /pendente/);
});

test('exporter refuses a misleading empty backup and reports actual tab inventory', async () => {
  const source = await readFile(new URL('../legacy/Export.gs', import.meta.url), 'utf8');
  let created = 0;
  const logs = [];
  let name = 'Outra aba', rows = [['header'], ['data']];
  const context = vm.createContext({
    PropertiesService: { getScriptProperties: () => ({ getProperty: key => key === 'SPREADSHEET_ID' ? 'configured-book' : key === 'ACTIVE_VERSION' ? '0.5' : null }) },
    SpreadsheetApp: { openById: () => ({ getId: () => 'configured-book', getSheets: () => [{
      getName: () => name, getLastRow: () => rows.length, getDataRange: () => ({ getValues: () => rows }),
    }] }) },
    DriveApp: { createFile: () => { created++; return { getUrl: () => 'file' }; } },
    MimeType: { PLAIN_TEXT: 'text/plain' }, console: { log: line => logs.push(line) },
  });
  vm.runInContext(source, context);
  assert.throws(() => context.exportRankingBackup(), /Nenhuma aba reconhecida/);
  assert.equal(created, 0);
  assert(logs.join('').includes('Outra aba'));
  name = 'Players'; rows = [['player_id', 'nickname']];
  assert.throws(() => context.exportRankingBackup(), /Nenhuma linha de dados/);
  assert.equal(created, 0);
});
