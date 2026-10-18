import test from 'node:test';
import assert from 'node:assert/strict';
import { serve } from '../scripts/serve.mjs';
import { evaluateWhenReady, findBrowser } from '../scripts/browser.mjs';

let browser;
try {
  browser = findBrowser();
} catch {
  /* handled by skip below */
}

test('engine behaves correctly in a real browser (selftest page)', { skip: !browser && 'no Chromium-family browser found' }, async () => {
  const { server, port } = await serve();
  try {
    const json = await evaluateWhenReady(browser, `http://127.0.0.1:${port}/demo/selftest.html`, "document.getElementById('result').textContent");
    const result = JSON.parse(json);
    assert.deepEqual(result.errors, []);
    assert.ok(Object.keys(result.checks).length >= 14, `only ${Object.keys(result.checks).length} checks ran`);
  } finally {
    server.close();
  }
});
