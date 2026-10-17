// Mascot animation engine: plays a declarative spec (mascot.spec.json) on any SVG whose
// elements carry data-part="<name>". It has no dependency on the host app or framework and
// only needs the Web Animations API, so it can be wrapped by React/Vue/Lit or run in a PWA.

const REST = { x: 0, y: 0, r: 0, sx: 1, sy: 1, o: 1, d: 1 };
const KEYFRAME_PROPS = new Set(['offset', 'ease', 'x', 'y', 'r', 's', 'sx', 'sy', 'o', 'd']);
const DEFAULT_BLEND_MS = 220;

export function validateSpec(spec) {
  const errors = [];
  const parts = spec.parts ?? {};
  if (!spec.states?.[spec.initialState]) errors.push(`initialState "${spec.initialState}" is not a state`);
  for (const [name, state] of Object.entries(spec.states ?? {})) {
    const seen = new Set();
    if (state.next && !spec.states[state.next]) errors.push(`${name}: next "${state.next}" is not a state`);
    if (!state.loop && !state.next) errors.push(`${name}: one-shot state needs "next"`);
    for (const track of state.tracks ?? []) {
      const where = `${name}.${track.part}`;
      if (!parts[track.part]) errors.push(`${where}: part is not declared in "parts"`);
      if (seen.has(track.part)) errors.push(`${where}: more than one track for the same part`);
      seen.add(track.part);
      if ('delay' in track) errors.push(`${where}: "delay" is not supported (hold with keyframes instead)`);
      if (!(track.duration > 0)) errors.push(`${where}: duration must be > 0`);
      const kfs = track.keyframes ?? [];
      if (kfs.length < 2) errors.push(`${where}: needs at least 2 keyframes`);
      if (kfs[0]?.offset !== 0 || kfs.at(-1)?.offset !== 1) errors.push(`${where}: offsets must start at 0 and end at 1`);
      kfs.forEach((kf, i) => {
        if (i && !(kf.offset >= kfs[i - 1].offset)) errors.push(`${where}: offsets must not decrease`);
        for (const key of Object.keys(kf)) if (!KEYFRAME_PROPS.has(key)) errors.push(`${where}: unknown keyframe property "${key}"`);
      });
    }
  }
  return errors;
}

const pose = (kf, rest) => ({
  ...REST,
  ...rest,
  ...kf,
  sx: kf.sx ?? kf.s ?? rest.sx ?? REST.sx,
  sy: kf.sy ?? kf.s ?? rest.sy ?? REST.sy,
});

const toFrame = (p, withDraw) => ({
  transform: `translate(${p.x}px, ${p.y}px) rotate(${p.r}deg) scale(${p.sx}, ${p.sy})`,
  opacity: p.o,
  ...(withDraw ? { strokeDashoffset: 1 - p.d } : {}),
});

export function createMascot(root, spec, options = {}) {
  const problems = validateSpec(spec);
  if (problems.length) throw new Error(`Invalid mascot spec:\n- ${problems.join('\n- ')}`);

  const opts = {
    speed: 1,
    blendMs: DEFAULT_BLEND_MS,
    reducedMotion: globalThis.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false,
    ...options,
  };
  const listeners = new Set();
  const elements = {};
  const drawable = new Set();
  let current = null;
  let animations = [];
  let timer = null;
  let token = 0;

  for (const [name, cfg] of Object.entries(spec.parts)) {
    const el = root.querySelector(`[data-part="${name}"]`);
    if (!el) throw new Error(`Rig has no element data-part="${name}"`);
    elements[name] = el;
    el.style.transformBox = 'fill-box';
    el.style.transformOrigin = `${(cfg.origin?.[0] ?? 0.5) * 100}% ${(cfg.origin?.[1] ?? 0.5) * 100}%`;
    if (cfg.rest && 'd' in cfg.rest) {
      drawable.add(name);
      el.style.strokeDasharray = '1';
    }
    applyRest(name);
  }

  function restFrame(name) {
    return toFrame(pose({}, spec.parts[name].rest ?? {}), drawable.has(name));
  }

  function applyRest(name) {
    const frame = restFrame(name);
    const el = elements[name];
    el.style.transform = frame.transform;
    el.style.opacity = frame.opacity;
    if ('strokeDashoffset' in frame) el.style.strokeDashoffset = frame.strokeDashoffset;
  }

  function capture(name) {
    const cs = getComputedStyle(elements[name]);
    return {
      transform: cs.transform,
      opacity: cs.opacity,
      ...(drawable.has(name) ? { strokeDashoffset: parseFloat(cs.strokeDashoffset) || 0 } : {}),
    };
  }

  function emit(event, detail) {
    for (const fn of listeners) fn(event, detail);
  }

  function setState(name, { blend = true } = {}) {
    const state = spec.states[name];
    if (!state) throw new Error(`Unknown mascot state "${name}"`);
    const from = current;
    const blendMs = blend && !opts.reducedMotion ? opts.blendMs / opts.speed : 0;
    const snapshot = blendMs ? Object.fromEntries(Object.keys(elements).map((n) => [n, capture(n)])) : null;

    token += 1;
    const mine = token;
    clearTimeout(timer);
    animations.forEach((a) => a.cancel());
    animations = [];
    current = name;

    const tracked = new Map(state.tracks.map((t) => [t.part, t]));
    for (const [part, el] of Object.entries(elements)) {
      const track = tracked.get(part);
      const first = track ? toFrame(pose(track.keyframes[0], spec.parts[part].rest ?? {}), drawable.has(part)) : restFrame(part);
      if (blendMs) {
        animations.push(el.animate([snapshot[part], first], { duration: blendMs, easing: 'ease-out', fill: track ? 'none' : 'forwards' }));
      } else if (!track) {
        applyRest(part);
      }
    }

    const longest = Math.max(...state.tracks.map((t) => t.duration));
    for (const track of state.tracks) {
      const rest = spec.parts[track.part].rest ?? {};
      const frames = track.keyframes.map((kf) => ({
        ...toFrame(pose(kf, rest), drawable.has(track.part)),
        offset: kf.offset,
        easing: kf.ease ?? track.easing ?? 'ease-in-out',
      }));
      const anim = elements[track.part].animate(frames, {
        duration: track.duration,
        delay: blendMs,
        iterations: state.loop ? Infinity : 1,
        fill: state.loop ? 'none' : 'forwards',
      });
      anim.playbackRate = opts.speed;
      animations.push(anim);
      if (!state.loop && track.duration === longest) {
        anim.finished.then(() => token === mine && state.next && setState(state.next)).catch((error) => {
          if (error?.name !== 'AbortError') console.error('mascot: transition failed', error);
        });
      }
    }

    if (opts.reducedMotion) {
      animations.forEach((a) => {
        a.pause();
        a.currentTime = (a.effect.getTiming().duration || 0) * (state.pose ?? 0);
      });
      if (!state.loop) timer = setTimeout(() => token === mine && setState(state.next), state.reducedHoldMs ?? 1500);
    }

    emit('state', { from, to: name });
  }

  setState(spec.initialState, { blend: false });

  return {
    get state() {
      return current;
    },
    setState,
    on(fn) {
      listeners.add(fn);
      return () => listeners.delete(fn);
    },
    // Deterministic control for tests and contact sheets.
    pause() {
      animations.forEach((a) => a.pause());
    },
    play() {
      animations.forEach((a) => a.play());
    },
    seek(ms) {
      animations.forEach((a) => {
        a.pause();
        a.currentTime = ms;
      });
    },
    destroy() {
      token += 1;
      clearTimeout(timer);
      animations.forEach((a) => a.cancel());
      animations = [];
      listeners.clear();
    },
  };
}
