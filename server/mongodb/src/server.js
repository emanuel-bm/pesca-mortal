import { connect } from './database.js';
import { service } from './service.js';
import { httpServer } from './http.js';

let client;
try {
  const connection = await connect();
  client = connection.client;
  const { db } = connection;
  const api = service(client, db);
  const server = httpServer({ handle: api.handle, ready: async () => {
    await db.command({ ping: 1 });
    return Boolean(await db.collection('service_config').findOne({ _id: 'ranking' }));
  } });
  server.listen(Number(process.env.PORT || 8080), process.env.HOST || '127.0.0.1', () => console.info('Ranking API listening'));
  let closing = false;
  for (const signal of ['SIGTERM', 'SIGINT']) process.on(signal, () => {
    if (closing) return;
    closing = true;
    server.close(async () => { await client.close(); });
  });
} catch {
  console.error('Ranking API startup failed. Check database configuration, network and credentials.');
  await client?.close();
  process.exitCode = 1;
}
