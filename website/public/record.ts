import { chromium } from 'playwright';
import { mkdirSync, rmSync } from 'node:fs';

const URL = process.env.SPELLBOOK_URL ?? 'https://nikoro.github.io/spellbook/';
const OUT_DIR = '/tmp/spellbook-record/frames';
const TARGET_SELECTOR = '[data-demo-window]';
const FPS = 15;
const DURATION_S = 52;
const TOTAL_FRAMES = FPS * DURATION_S;
const FRAME_INTERVAL_MS = Math.round(1000 / FPS);

rmSync(OUT_DIR, { recursive: true, force: true });
mkdirSync(OUT_DIR, { recursive: true });

const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  viewport: { width: 1280, height: 800 },
  deviceScaleFactor: 2,
});
const page = await context.newPage();

console.log(`Navigating to ${URL}…`);
await page.goto(URL, { waitUntil: 'networkidle' });

const target = page.locator(TARGET_SELECTOR);
await target.waitFor({ state: 'visible', timeout: 10_000 });

// Sync recording start with the beginning of step 1 so the loop closes cleanly.
// We wait for any non-1 step (proves the loop is running), then for step 1 to come back.
console.log('Syncing to start of cycle (step 1)…');
await page.waitForFunction(
  () => document.querySelector<HTMLElement>('[data-demo-window]')?.dataset.demoStep !== '1',
  null,
  { timeout: 30_000 },
);
await page.waitForFunction(
  () => document.querySelector<HTMLElement>('[data-demo-window]')?.dataset.demoStep === '1',
  null,
  { timeout: 60_000 },
);
// Let the step 1 cross-fade settle so the very first frame is fully step 1.
await page.waitForTimeout(600);
console.log('Cycle is at step 1, beginning recording.');

console.log(`Recording ${TOTAL_FRAMES} frames @ ${FPS} fps (${DURATION_S}s)…`);

const start = Date.now();
for (let i = 0; i < TOTAL_FRAMES; i++) {
  const frameStart = Date.now();
  const filename = `${OUT_DIR}/frame_${String(i).padStart(4, '0')}.png`;
  await target.screenshot({ path: filename, type: 'png' });
  const elapsed = Date.now() - frameStart;
  const wait = FRAME_INTERVAL_MS - elapsed;
  if (wait > 0) await page.waitForTimeout(wait);
  if (i % 30 === 0) {
    process.stdout.write(`  frame ${i}/${TOTAL_FRAMES} (${Date.now() - start}ms total)\n`);
  }
}

await browser.close();
console.log(`Done. ${TOTAL_FRAMES} frames in ${Date.now() - start}ms → ${OUT_DIR}`);
