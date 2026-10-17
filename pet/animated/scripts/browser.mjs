// Locates a Chromium-family browser for headless runs. Override with BROWSER=<path>.
import { spawn, spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const CANDIDATES = [
  process.env.BROWSER,
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  'C:/Program Files/Microsoft/Edge/Application/msedge.exe',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
];

export function findBrowser() {
  const found = CANDIDATES.find((p) => p && existsSync(p));
  if (!found) throw new Error('No Chromium-family browser found; set BROWSER=<path>');
  return found;
}

// --disable-threaded-animation: in headless + virtual time, compositor-driven (transform) animations
// stay "pending" forever waiting for a compositor ack. Running them on the main thread fixes the tests.
// Async on purpose: the page is served by this same process, so the event loop must stay free.
export function runBrowser(browser, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(browser, ['--headless', '--disable-gpu', '--no-first-run', '--disable-threaded-animation', ...args], { stdio: ['ignore', 'pipe', 'pipe'] });
    let stdout = '';
    let stderr = '';
    const timer = setTimeout(() => child.kill(), 60_000);
    child.stdout.on('data', (d) => (stdout += d));
    child.stderr.on('data', (d) => (stderr += d));
    child.on('close', (code) => {
      clearTimeout(timer);
      code === 0 ? resolve(stdout) : reject(new Error(`browser exited ${code}\n${stderr}`));
    });
  });
}

// Real-time page run over the DevTools protocol: unlike --dump-dom/--virtual-time-budget, the page
// gets real frames, so Animation.finished and requestAnimationFrame behave as in a normal browser.
// Resolves with the string value of `expression` once it stops being "pending".
export async function evaluateWhenReady(browser, url, expression, { timeoutMs = 20_000 } = {}) {
  const profile = await mkdtemp(join(tmpdir(), 'mascot-browser-'));
  const child = spawn(browser, ['--headless', '--disable-gpu', '--no-first-run', `--user-data-dir=${profile}`, '--remote-debugging-port=0', 'about:blank'], { stdio: 'ignore' });
  const deadline = Date.now() + timeoutMs;
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  try {
    let port;
    while (!port) {
      if (Date.now() > deadline) throw new Error('browser did not expose DevTools in time');
      port = await readFile(join(profile, 'DevToolsActivePort'), 'utf8').then((t) => t.split('\n')[0], () => null);
      if (!port) await sleep(100);
    }
    const target = await (await fetch(`http://127.0.0.1:${port}/json/new?${encodeURIComponent(url)}`, { method: 'PUT' })).json();
    const ws = new WebSocket(target.webSocketDebuggerUrl);
    await new Promise((resolve, reject) => {
      ws.onopen = resolve;
      ws.onerror = () => reject(new Error('DevTools websocket failed'));
    });
    let id = 0;
    const pending = new Map();
    ws.onmessage = ({ data }) => {
      const msg = JSON.parse(data);
      pending.get(msg.id)?.(msg);
    };
    const call = (method, params) =>
      new Promise((resolve) => {
        pending.set(++id, resolve);
        ws.send(JSON.stringify({ id, method, params }));
      });
    while (Date.now() < deadline) {
      const { result } = await call('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
      const value = result?.result?.value;
      if (typeof value === 'string' && value !== 'pending') {
        ws.close();
        return value;
      }
      await sleep(100);
    }
    throw new Error(`page did not finish within ${timeoutMs} ms`);
  } finally {
    if (process.platform === 'win32') spawnSync('taskkill', ['/PID', String(child.pid), '/T', '/F'], { stdio: 'ignore' });
    else child.kill();
    await sleep(200);
    await rm(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 }).catch(() => {});
  }
}
