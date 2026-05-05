import { defineConfig } from 'astro/config';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import starlight from '@astrojs/starlight';
import sitemap from '@astrojs/sitemap';

import publishContent from './src/integrations/publish-content.mjs';

const spellbookTheme = JSON.parse(
  readFileSync(fileURLToPath(new URL('./src/styles/spellbook-shiki-theme.json', import.meta.url)), 'utf8'),
);

export default defineConfig({
  site: 'https://nikoro.github.io/spellbook',
  base: '/spellbook',
  trailingSlash: 'ignore',
  integrations: [
    publishContent(),
    starlight({
      title: 'Spellbook',
      favicon: '/favicon.ico',
      head: [
        {
          tag: 'meta',
          attrs: { property: 'og:image', content: 'https://nikoro.github.io/spellbook/og.png' },
        },
        {
          tag: 'meta',
          attrs: { name: 'twitter:image', content: 'https://nikoro.github.io/spellbook/og.png' },
        },
        {
          tag: 'meta',
          attrs: { name: 'twitter:card', content: 'summary_large_image' },
        },
      ],
      customCss: ['./src/styles/globals.css', './src/styles/starlight-overrides.css'],
      components: {
        PageTitle: './src/components/PageTitleWithActions.astro',
        SiteTitle: './src/components/SiteTitleBrand.astro',
        SocialIcons: './src/components/HeaderNav.astro',
        ThemeSelect: './src/components/ThemeToggle.astro',
      },
      defaultLocale: 'root',
      locales: {
        root: { label: 'English', lang: 'en' },
      },
      sidebar: [
        {
          label: 'Documentation',
          items: [
            { label: 'Getting Started', slug: 'docs/getting-started' },
            { label: 'Manifest', slug: 'docs/manifest' },
            { label: 'CLI', slug: 'docs/cli' },
            { label: 'Examples', slug: 'docs/examples' },
            { label: 'Shell Integration', slug: 'docs/shell-integration' },
            { label: 'Troubleshooting', slug: 'docs/troubleshooting' },
          ],
        },
      ],
      pagination: false,
      lastUpdated: false,
      pagefind: true,
      expressiveCode: {
        themes: [spellbookTheme],
        defaultProps: {
          overridesByLang: {
            'sh,bash,zsh,fish,shell,console,text': { frame: 'terminal' },
            'yaml,yml,json,toml,javascript,js,typescript,ts,swift,python,py,go,rust,rs,html,css,sql,diff': { frame: 'code' },
          },
        },
        styleOverrides: {
          borderRadius: '0.5rem',
          borderColor: 'rgba(255, 255, 255, 0.06)',
          codeBackground: 'rgba(0, 0, 0, 0.4)',
          frames: {
            editorActiveTabBackground: 'rgba(0, 0, 0, 0.5)',
            editorTabBarBackground: 'rgba(0, 0, 0, 0.3)',
            editorTabBarBorderBottomColor: 'rgba(255, 255, 255, 0.06)',
            terminalBackground: 'rgba(0, 0, 0, 0.4)',
            terminalTitlebarBackground: 'rgba(0, 0, 0, 0.3)',
            terminalTitlebarBorderBottomColor: 'rgba(255, 255, 255, 0.06)',
            frameBoxShadowCssValue: '0 8px 20px -10px rgba(0, 0, 0, 0.6)',
          },
        },
      },
    }),
    sitemap(),
  ],
});
