import { createServer } from 'node:http';
import { randomUUID } from 'node:crypto';
import { fail_ } from './rules.js';

function errorCategory(error) {
  if (error.code === 18 || error.code === 13) return 'database_access';
  if (error.code === 11000) return 'database_conflict';
  if (['MongoNetworkTimeoutError', 'MongoOperationTimeoutError', 'AbortError'].includes(error.name)) return 'database_timeout';
  if (['MongoServerSelectionError', 'MongoNetworkError'].includes(error.name)) return 'database_unavailable';
  return 'backend_error';
}

export function httpServer({ handle, ready, logger = console }) {
  const windows = new Map();
  const server = createServer({ requestTimeout: 15000, headersTimeout: 10000 }, async (req, res) => {
    const request_id = randomUUID(), started = Date.now();
    const send = (data, status = 200) => {
      if (!res.destroyed && !res.writableEnded) {
        res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', 'X-Request-ID': request_id });
        res.end(JSON.stringify(data));
      }
    };
    try {
      if (req.method === 'GET' && req.url === '/health') return send({ ok: true });
      if (req.method === 'GET' && req.url === '/ready') {
        const ok = await ready();
        return send({ ok }, ok ? 200 : 503);
      }
      if (req.method !== 'POST' || !['/', '/exec'].includes(req.url)) return send(fail_('invalid_request'), 404);
      // Do not trust caller-supplied forwarding headers. Limit is per transport peer.
      const now = Date.now();
      for (const [key, slot] of windows) if (slot.until < now) windows.delete(key);
      const peer = req.socket.remoteAddress;
      const slot = windows.get(peer) || { count: 0, until: now + 60000 };
      slot.count++; windows.set(peer, slot);
      if (slot.count > 120) { req.resume(); return send(fail_('busy')); }
      let size = 0, chunks = [];
      for await (const chunk of req) {
        size += chunk.length;
        if (size > 8192) { send(fail_('invalid_request')); return; }
        chunks.push(chunk);
      }
      let input;
      try { input = JSON.parse(Buffer.concat(chunks).toString('utf8')); }
      catch { return send(fail_('invalid_request')); }
      const result = await handle(input);
      send(result);
      logger.info(JSON.stringify({ request_id, operation: ['ranking', 'legends', 'submit', 'register', 'rename'].includes(input?.action) ? input.action : 'invalid',
        ok: result.ok, error: result.error, duration_ms: Date.now() - started }));
    } catch (error) {
      // Error text/stack can contain credentials or document contents; log only safe identifiers.
      logger.error(JSON.stringify({ request_id, category: errorCategory(error), code: typeof error.code === 'number' ? error.code : undefined,
        duration_ms: Date.now() - started }));
      send(fail_('service_error'));
    }
  });
  return server;
}
