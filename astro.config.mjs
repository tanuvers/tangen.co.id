import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://tangen.co.id',
  compressHTML: true,
  build: { inlineStylesheets: 'auto' },
});
