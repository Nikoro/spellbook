import { readFile, writeFile, mkdir, copyFile, readdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join, relative, resolve } from 'node:path';


const SIDEBAR_ORDER = [
  'getting-started',
  'manifest',
  'cli',
  'examples',
  'shell-integration',
  'troubleshooting',
];

const SITE_BASE = '/spellbook';

export default function publishContent() {
  return {
    name: 'spellbook:publish-content',
    hooks: {
      'astro:config:setup': async ({ config, logger }) => {
        const here = dirname(fileURLToPath(import.meta.url));
        const websiteRoot = resolve(here, '..', '..');
        const repoRoot = resolve(websiteRoot, '..');

        await publish({ websiteRoot, repoRoot, logger });
      },
    },
  };
}

async function publish({ websiteRoot, repoRoot, logger }) {
  const docsSrcDir = join(websiteRoot, 'src', 'content', 'docs', 'docs');
  const docsPublicDir = join(websiteRoot, 'public', 'docs');
  const publicDir = join(websiteRoot, 'public');

  if (!existsSync(docsSrcDir)) {
    logger?.warn?.(`publish-content: ${docsSrcDir} not found`);
    return;
  }

  await mkdir(docsPublicDir, { recursive: true });

  const mirrored = [];
  for (const slug of SIDEBAR_ORDER) {
    const src = join(docsSrcDir, `${slug}.md`);
    if (!existsSync(src)) continue;
    const dest = join(docsPublicDir, `${slug}.md`);
    await copyFile(src, dest);
    mirrored.push(slug);
  }

  const docs = [];
  for (const slug of mirrored) {
    const src = join(docsSrcDir, `${slug}.md`);
    const raw = await readFile(src, 'utf8');
    const { frontmatter, body } = parseFrontmatter(raw);
    docs.push({
      slug,
      title: frontmatter.title ?? slug,
      description: frontmatter.description ?? '',
      raw,
      body,
    });
  }

  const llms = [
    '# Spellbook Documentation',
    '',
    '> Project-specific shell commands, zero config.',
    '',
    '## Docs',
    '',
    ...docs.map(
      (d) =>
        `- [${d.title}](https://nikoro.github.io${SITE_BASE}/docs/${d.slug}.md): ${d.description}`,
    ),
    '',
  ].join('\n');
  await writeFile(join(publicDir, 'llms.txt'), llms, 'utf8');

  const llmsFull = [
    '# Spellbook Documentation (full)',
    '',
    '> Project-specific shell commands, zero config.',
    '',
    ...docs.flatMap((d) => [`## ${d.title}`, '', d.raw.trim(), '']),
  ].join('\n');
  await writeFile(join(publicDir, 'llms-full.txt'), llmsFull, 'utf8');

  const changelogSrc = join(repoRoot, 'CHANGELOG.md');
  const changelogDest = join(websiteRoot, 'src', 'content', 'docs', 'changelog.md');
  if (existsSync(changelogSrc)) {
    const raw = await readFile(changelogSrc, 'utf8');
    const cleanedBody = stripFirstHeading(raw);
    const wrapped = [
      '---',
      'title: Changelog',
      'description: Release history for Spellbook — mirrored from CHANGELOG.md in the repository root.',
      'tableOfContents: false',
      '---',
      '',
      cleanedBody,
    ].join('\n');
    await writeFile(changelogDest, wrapped, 'utf8');

    await writeFile(join(publicDir, 'changelog.md'), raw, 'utf8');
  }
}

function parseFrontmatter(raw) {
  if (!raw.startsWith('---')) return { frontmatter: {}, body: raw };
  const end = raw.indexOf('\n---', 3);
  if (end === -1) return { frontmatter: {}, body: raw };
  const head = raw.slice(3, end).trim();
  const body = raw.slice(end + 4).replace(/^\n/, '');
  const frontmatter = {};
  for (const line of head.split('\n')) {
    const m = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (!m) continue;
    let value = m[2].trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    frontmatter[m[1]] = value;
  }
  return { frontmatter, body };
}

function stripFirstHeading(raw) {
  const lines = raw.split('\n');
  if (lines[0]?.startsWith('# ')) {
    let i = 1;
    while (i < lines.length && lines[i].trim() === '') i += 1;
    return lines.slice(i).join('\n');
  }
  return raw;
}
