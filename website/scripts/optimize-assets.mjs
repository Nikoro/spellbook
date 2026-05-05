#!/usr/bin/env bun
/**
 * Generate web-sized brand assets from the repo-root source images.
 *
 * Inputs (repo root):
 *   - spellbook-wordmark.png (3168x1344)
 *   - spellbook-icon.png (1024x1024)
 *
 * Outputs (website/public/):
 *   - wordmark.webp, wordmark.png   (under 200 KB, ~960px wide)
 *   - icon.webp, icon.png           (under 50 KB, 256px square)
 *   - favicon.ico                   (32px square, PNG-as-ICO via sharp)
 *   - og.png                        (1200x630, dark canvas + wordmark + tagline)
 *
 * Run: bun run website/scripts/optimize-assets.mjs
 */
import sharp from 'sharp';
import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const websiteRoot = resolve(here, '..');
const repoRoot = resolve(websiteRoot, '..');
const out = join(websiteRoot, 'public');
await mkdir(out, { recursive: true });

const wordmarkSrc = join(repoRoot, 'spellbook-wordmark.png');
const iconSrc = join(repoRoot, 'spellbook-icon.png');

// Wordmark (display width ~480px on hero; 2x = 960px).
await sharp(wordmarkSrc)
  .resize({ width: 960, withoutEnlargement: true })
  .webp({ quality: 88 })
  .toFile(join(out, 'wordmark.webp'));

await sharp(wordmarkSrc)
  .resize({ width: 960, withoutEnlargement: true })
  .png({ compressionLevel: 9, palette: true })
  .toFile(join(out, 'wordmark.png'));

// Icon (favicon + small marks).
await sharp(iconSrc)
  .resize(256, 256)
  .webp({ quality: 90 })
  .toFile(join(out, 'icon.webp'));

await sharp(iconSrc)
  .resize(256, 256)
  .png({ compressionLevel: 9 })
  .toFile(join(out, 'icon.png'));

// favicon.ico — sharp doesn't emit .ico directly; ship a 32x32 PNG and
// rename to .ico (browsers accept PNG content under .ico). For a real
// multi-size ICO, swap to png-to-ico later.
await sharp(iconSrc)
  .resize(32, 32)
  .png({ compressionLevel: 9 })
  .toFile(join(out, 'favicon.ico'));

// og.png — 1200x630 dark canvas with the wordmark centered and a tagline.
const ogBg = '#0E1015';
const tagline = 'Project-specific shell commands, zero config.';
const ogWordmark = await sharp(wordmarkSrc)
  .resize({ width: 720, withoutEnlargement: true })
  .png()
  .toBuffer();
const taglineSvg = Buffer.from(
  `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="80">
    <style>
      .t { font: 600 28px 'Geist', system-ui, -apple-system, sans-serif;
           fill: #a8acba; letter-spacing: 0.5px; }
    </style>
    <text x="50%" y="55" text-anchor="middle" class="t">${tagline}</text>
  </svg>`,
);

await sharp({
  create: {
    width: 1200,
    height: 630,
    channels: 4,
    background: ogBg,
  },
})
  .composite([
    { input: ogWordmark, gravity: 'center', top: 200, left: (1200 - 720) / 2 },
    { input: taglineSvg, top: 430, left: 0 },
  ])
  .png({ compressionLevel: 9 })
  .toFile(join(out, 'og.png'));

console.log('Optimized brand assets written to website/public/.');
