'use strict';
const fs = require('node:fs');
const path = require('node:path');
const {loadSources, buildIndex, checkIndex, retrieve} = require('../src/knowledge');
const {createGemini} = require('../src/gemini');
const root = path.resolve(__dirname, '../../..');
const output = path.resolve(__dirname, '../data/index.json');
const manifest = require('../sources.json');

async function main() {
  const mode = process.argv[2];
  const sources = loadSources(root, manifest);
  const previous = fs.existsSync(output) ? JSON.parse(fs.readFileSync(output, 'utf8')) : {};
  if (mode === 'check') {
    checkIndex(previous, sources, process.argv.includes('--require-vectors'));
    console.log(`Knowledge checked: ${previous.sources.length} files, ${previous.chunks.length} chunks`);
    return;
  }
  if (mode === 'search') {
    checkIndex(previous, sources);
    const question = process.argv.slice(3).join(' ');
    if (!question) throw new Error('Provide a question');
    console.log(JSON.stringify(retrieve(previous, question).map(({file, section, score}) => ({file, section, score})), null, 2));
    return;
  }
  if (!['build', 'embed'].includes(mode)) throw new Error('Use build, embed, check or search');
  const index = buildIndex(sources, previous);
  if (mode === 'embed') {
    const ai = createGemini({apiKey: process.env.RAG_GEMINI_API_KEY});
    for (const chunk of index.chunks) {
      if (!chunk.vector) chunk.vector = await ai.embed(chunk.text, true);
    }
  }
  fs.mkdirSync(path.dirname(output), {recursive: true});
  fs.writeFileSync(`${output}.tmp`, JSON.stringify(index), 'utf8');
  fs.renameSync(`${output}.tmp`, output);
  console.log(`Knowledge built: ${index.sources.length} files, ${index.chunks.length} chunks; vectors ${index.chunks.filter(chunk => chunk.vector).length}`);
}
main().catch(() => { console.error('Knowledge command failed. Check source review dates, approved paths, freshness and API configuration.'); process.exitCode = 1; });
