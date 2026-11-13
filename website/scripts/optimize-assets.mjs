#!/usr/bin/env bun
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

await sharp(wordmarkSrc)
  .resize({ width: 960, withoutEnlargement: true })
  .webp({ quality: 88 })
  .toFile(join(out, 'wordmark.webp'));

await sharp(wordmarkSrc)
  .resize({ width: 960, withoutEnlargement: true })
  .png({ compressionLevel: 9, palette: true })
  .toFile(join(out, 'wordmark.png'));

await sharp(iconSrc)
  .resize(256, 256)
  .webp({ quality: 90 })
  .toFile(join(out, 'icon.webp'));

await sharp(iconSrc)
  .resize(256, 256)
  .png({ compressionLevel: 9 })
  .toFile(join(out, 'icon.png'));

await sharp(iconSrc)
  .resize(32, 32)
  .png({ compressionLevel: 9 })
  .toFile(join(out, 'favicon.ico'));

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
