// Renders demo/sheet.html (every state sampled at fixed instants) to docs/contact-sheet.png.
import { fileURLToPath } from 'node:url';
import { serve } from './serve.mjs';
import { findBrowser, runBrowser } from './browser.mjs';

const out = fileURLToPath(new URL('../docs/contact-sheet.png', import.meta.url));
const { server, port } = await serve();
try {
  await runBrowser(findBrowser(), ['--hide-scrollbars', `--screenshot=${out}`, '--window-size=1230,820', '--virtual-time-budget=3000', `http://127.0.0.1:${port}/demo/sheet.html`]);
  console.log(`wrote ${out}`);
} finally {
  server.close();
}
