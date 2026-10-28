import { connect, initialize } from '../src/database.js';
import { service } from '../src/service.js';
import { validVersion_ } from '../src/rules.js';

let client;
try {
  const connection = await connect(); client = connection.client;
  const { db } = connection, [command, version] = process.argv.slice(2);
  if (command === 'init' && validVersion_(version)) await initialize(db, version);
  else if (command === 'enable' || command === 'disable') {
    const result = await db.collection('service_config').updateOne({ _id: 'ranking' }, { $set: { writes_enabled: command === 'enable' }, $inc: { revision: 1 } });
    if (!result.matchedCount) throw new Error('not initialized');
  } else if (command === 'season' && validVersion_(version)) console.info(await service(client, db).closeSeason(version));
  else if (command === 'status') {
    const cfg = await db.collection('service_config').findOne({ _id: 'ranking' });
    console.info(JSON.stringify(cfg));
    for (const name of ['players', 'best_records', 'festival_runs', 'seasons', 'legend_entries']) console.info(name, await db.collection(name).countDocuments());
  } else throw new Error('invalid command');
  console.info('Admin command completed.');
} catch {
  console.error('Admin failed. Commands: init X.Y | enable | disable | status | season X.Y. Check configuration and database availability.');
  process.exitCode = 1;
} finally { await client?.close(); }
