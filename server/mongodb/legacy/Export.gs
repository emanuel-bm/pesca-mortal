/** Add as a SEPARATE file to the existing project. Run exportRankingBackup manually. */
function exportRankingBackup() {
  const props = PropertiesService.getScriptProperties();
  const id = props.getProperty('SPREADSHEET_ID');
  if (!id) throw new Error('SPREADSHEET_ID ausente. Não execute setup para tentar corrigir.');
  if (props.getProperty('TRANSITION_VERSION')) throw new Error('Transição competitiva pendente: confira antes de exportar.');
  const book = SpreadsheetApp.openById(id);
  const inventory = rankingSourceInventory_(book);
  console.log('Fonte consultada: https://docs.google.com/spreadsheets/d/' + book.getId() + '/edit');
  console.log('Abas e linhas (sem conteúdo das células): ' + JSON.stringify(inventory));
  const recognized = inventory.filter(tab => tab.recognized);
  if (!recognized.length) throw new Error('Nenhuma aba reconhecida. Confira o arquivo e os nomes no inventário; nenhum backup foi criado.');
  if (!recognized.some(tab => tab.data_rows > 0)) throw new Error('Nenhuma linha de dados nas abas reconhecidas. Confira a origem; nenhum backup foi criado.');
  const backup = { format: 'pesca-sheets-v1', exported_at: new Date().toISOString(),
    source_id: book.getId(), active_version: props.getProperty('ACTIVE_VERSION') || '0.3', sheets: {} };
  book.getSheets().forEach(sheet => {
    const name = sheet.getName();
    if (rankingExportTab_(name)) {
      backup.sheets[name] = sheet.getLastRow() ? sheet.getDataRange().getValues() : [];
    }
  });
  // File is private by default. Contains account hashes: never publish or commit it.
  const file = DriveApp.createFile('pesca-ranking-backup-' + Date.now() + '.json', JSON.stringify(backup), MimeType.PLAIN_TEXT);
  console.log('Backup privado criado no seu Drive: ' + file.getUrl());
}

function rankingExportTab_(name) {
  return ['Players', 'Records', 'Seasons', 'Festival High Tech MT'].indexOf(name) >= 0 || /^Lendas_\d+_\d+$/.test(name);
}

function rankingSourceInventory_(book) {
  return book.getSheets().map(sheet => ({name: sheet.getName(), recognized: rankingExportTab_(sheet.getName()),
    data_rows: Math.max(0, sheet.getLastRow() - 1)}));
}

/** Read-only diagnosis. Does not create files or change spreadsheet/script settings. */
function diagnosticarFonteRanking() {
  const props = PropertiesService.getScriptProperties();
  const id = props.getProperty('SPREADSHEET_ID');
  if (!id) throw new Error('SPREADSHEET_ID ausente.');
  const book = SpreadsheetApp.openById(id);
  console.log('Fonte configurada: https://docs.google.com/spreadsheets/d/' + book.getId() + '/edit');
  console.log('ACTIVE_VERSION: ' + (props.getProperty('ACTIVE_VERSION') || '0.3'));
  console.log('Abas e linhas (sem conteúdo das células): ' + JSON.stringify(rankingSourceInventory_(book)));
  const active = SpreadsheetApp.getActiveSpreadsheet();
  if (active) console.log('Arquivo vinculado ao editor é o mesmo da configuração: ' + (active.getId() === book.getId()));
}
