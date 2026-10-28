import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { connect } from '../src/database.js';
import { prepare, importPrepared, MigrationError } from '../src/migration.js';

let client;
try {
  const args = process.argv.slice(2), file = args.find(a => !a.startsWith('--'));
  if (!file || args.some(a => a.startsWith('--') && !['--apply', '--check-db'].includes(a))) throw new MigrationError('Use arquivo.json [--check-db | --apply].');
  const prepared = prepare(JSON.parse(await readFile(file, 'utf8')));
  let report = { applied: false, database_checked: false, checksum: prepared.checksum, active_version: prepared.active_version,
    duplicate_rows: prepared.duplicate_rows, adaptations: prepared.adaptations,
    counts: Object.fromEntries(Object.entries(prepared.data).map(([k, v]) => [k, v.length])) };
  if (args.includes('--apply') || args.includes('--check-db')) {
    const connection = await connect(); client = connection.client;
    report = { ...await importPrepared(client, connection.db, prepared, args.includes('--apply')), database_checked: true };
  }
  await mkdir('reports', { recursive: true });
  const path = `reports/import-${Date.now()}.json`;
  await writeFile(path, JSON.stringify(report, null, 2), { flag: 'wx', mode: 0o600 });
  console.info(JSON.stringify(report, null, 2)); console.info('Relatório:', path);
} catch (error) {
  // Validation messages are static and exclude source cell contents; driver errors may contain secrets.
  console.error(error instanceof MigrationError ? error.message : error instanceof SyntaxError
    ? 'JSON inválido; confira a exportação. Conteúdo privado omitido.'
    : error.code === 'ENOENT' ? 'Arquivo não encontrado.' : 'Import failed; inspect database configuration and file permissions.');
  process.exitCode = 1;
} finally { await client?.close(); }
