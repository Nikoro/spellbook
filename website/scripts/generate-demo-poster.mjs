#!/usr/bin/env bun
/**
 * Generates a temporary demo-poster.png until the real demo video is recorded
 * (US-005). The poster is a 1280x720 dark canvas with the wordmark centered
 * and a "demo coming soon" line so the hero <video> element shows something
 * meaningful before demo.webm/demo.mp4 are committed.
 *
 * Replace this output with a real frame from the recorded demo video before
 * launch.
 */
import sharp from 'sharp';
import { mkdir } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const websiteRoot = resolve(here, '..');
const repoRoot = resolve(websiteRoot, '..');
const out = join(websiteRoot, 'public');
await mkdir(out, { recursive: true });

const wordmark = await sharp(join(repoRoot, 'spellbook-wordmark.png'))
  .resize({ width: 600, withoutEnlargement: true })
  .png()
  .toBuffer();

const caption = Buffer.from(
  `<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="60">
    <style>.t { font: 500 22px 'Geist', system-ui, sans-serif; fill: #6c7080; }</style>
    <text x="50%" y="38" text-anchor="middle" class="t">Terminal demo coming soon — try the install one-liner →</text>
  </svg>`,
);

await sharp({
  create: { width: 1280, height: 720, channels: 4, background: '#0E1015' },
})
  .composite([
    { input: wordmark, top: 240, left: (1280 - 600) / 2 },
    { input: caption, top: 470, left: 0 },
  ])
  .png({ compressionLevel: 9 })
  .toFile(join(out, 'demo-poster.png'));

console.log('Wrote website/public/demo-poster.png (placeholder).');
