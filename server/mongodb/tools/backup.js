import { mkdir, writeFile } from 'node:fs/promises';
import { connect, transaction } from '../src/database.js';
import { collections, withoutId } from '../src/migration.js';

let client;
try {
  const connection = await connect(); client = connection.client;
  const { db } = connection;
  const backup = await transaction(client, async session => {
    const cfg = await db.collection('service_config').findOne({ _id: 'ranking' }, { session });
    if (!cfg) throw new Error('not initialized');
    const data = {};
    for (const name of collections) data[name] = (await db.collection(name).find({}, { session }).toArray()).map(withoutId);
    return { format: 'pesca-mongo-backup-v1', exported_at: new Date().toISOString(), active_version: cfg.active_version, collections: data };
  });
  await mkdir('backups', { recursive: true });
  const file = `backups/mongo-${Date.now()}.json`;
  await writeFile(file, JSON.stringify(backup, null, 2), { flag: 'wx', mode: 0o600 });
  console.info('Backup privado:', file);
} catch {
  console.error('Backup failed. Check database configuration and output permissions.'); process.exitCode = 1;
} finally { await client?.close(); }
