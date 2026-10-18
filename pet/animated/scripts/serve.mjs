// Zero-dependency static server for the demo (fetch() of the spec/rig does not work over file://).
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.svg': 'image/svg+xml', '.css': 'text/css' };

// The untouched original artwork lives outside the served root; the tests read it through this alias.
const ORIGINAL = normalize(join(ROOT, '..', 'behav.svg'));

export function serve(port = 0) {
  const server = createServer(async (req, res) => {
    const url = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    const file = url === '/original.svg' ? ORIGINAL : normalize(join(ROOT, url.endsWith('/') ? `${url}index.html` : url));
    if (!file.startsWith(ROOT) && file !== ORIGINAL) return res.writeHead(403).end();
    let body;
    try {
      body = await readFile(file);
    } catch {
      return res.writeHead(404).end('not found');
    }
    res.writeHead(200, { 'content-type': TYPES[extname(file)] ?? 'application/octet-stream' }).end(body);
  });
  return new Promise((resolve) => server.listen(port, '127.0.0.1', () => resolve({ server, port: server.address().port })));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const { port } = await serve(Number(process.env.PORT) || 5173);
  console.log(`Mascot demo: http://127.0.0.1:${port}/demo/`);
}
