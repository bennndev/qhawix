import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { buildRig, SOURCE, TARGET } from '../scripts/build-rig.mjs';
import { validateSpec } from '../src/mascot-engine.js';

const spec = JSON.parse(readFileSync(new URL('../src/mascot.spec.json', import.meta.url), 'utf8'));
const rigParts = [...readFileSync(TARGET, 'utf8').matchAll(/data-part="([^"]+)"/g)].map((m) => m[1]);

test('spec passes the engine validator', () => {
  assert.deepEqual(validateSpec(spec), []);
});

test('required states exist', () => {
  for (const name of ['idle', 'thinking', 'working', 'success']) assert.ok(spec.states[name], name);
});

test('every declared part exists in the rig and vice versa for animated ones', () => {
  for (const part of Object.keys(spec.parts)) assert.ok(rigParts.includes(part), `rig lacks ${part}`);
});

test('the committed rig is up to date with behav.svg', () => {
  // behav.svg ships with CRLF and git may rewrite line endings on checkout; compare content only.
  const lf = (text) => text.split(String.fromCharCode(13)).join('');
  assert.equal(lf(readFileSync(TARGET, 'utf8')), lf(buildRig(readFileSync(SOURCE, 'utf8'))));
});

test('validator rejects broken specs', () => {
  const bad = structuredClone(spec);
  bad.states.idle.tracks[0].keyframes[0].offset = 0.2;
  bad.states.idle.tracks[1].delay = 100;
  bad.states.thinking.tracks.push({ ...bad.states.thinking.tracks[0] });
  const errors = validateSpec(bad).join('\n');
  assert.match(errors, /offsets must start at 0/);
  assert.match(errors, /"delay" is not supported/);
  assert.match(errors, /more than one track/);
});

test('one-shot states return somewhere', () => {
  assert.equal(spec.states.success.next, 'idle');
  assert.equal(spec.states.success.loop, false);
});
