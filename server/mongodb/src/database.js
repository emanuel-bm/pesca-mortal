import { MongoClient } from 'mongodb';

export async function connect(env = process.env) {
  if (!env.MONGODB_URI || !env.MONGODB_DATABASE) throw new Error('Defina MONGODB_URI e MONGODB_DATABASE no servidor.');
  const client = new MongoClient(env.MONGODB_URI, {
    maxPoolSize: 5, serverSelectionTimeoutMS: 5000, connectTimeoutMS: 5000,
    socketTimeoutMS: 10000, timeoutMS: 12000,
  });
  await client.connect();
  return { client, db: client.db(env.MONGODB_DATABASE) };
}

export async function indexes(db) {
  await db.collection('players').createIndexes([
    { key: { player_id: 1 }, unique: true },
    { key: { nickname_key: 1 }, unique: true },
    { key: { token_hash: 1 }, unique: true },
  ]);
  await db.collection('best_records').createIndex({ player_id: 1, competitive_version: 1, mode: 1 }, { unique: true });
  await db.collection('best_records').createIndex({ competitive_version: 1, mode: 1 });
  await db.collection('festival_runs').createIndex({ event_id: 1, run_id: 1 }, { unique: true });
  await db.collection('festival_runs').createIndex({ event_id: 1, mode: 1 });
  await db.collection('seasons').createIndex({ version: 1 }, { unique: true });
  await db.collection('legend_entries').createIndex({ competitive_version: 1, mode: 1, position: 1 }, { unique: true });
  // All collections exist before transactions, including on an empty installation.
  for (const name of ['service_config', 'migration_runs']) {
    if (!(await db.listCollections({ name }).hasNext())) await db.createCollection(name);
  }
}

export const transactionOptions = {
  readConcern: { level: 'snapshot' }, writeConcern: { w: 'majority' }, maxCommitTimeMS: 5000,
};

export function transaction(client, operation) {
  return client.withSession(session => session.withTransaction(() => operation(session), transactionOptions));
}

// CLI-only initialization. Starting the public API never invents an active season.
export async function initialize(db, version) {
  await indexes(db);
  await db.collection('service_config').updateOne({ _id: 'ranking' }, { $setOnInsert: {
    active_version: version, festival_enabled: true, writes_enabled: false, revision: 0,
  } }, { upsert: true });
}
