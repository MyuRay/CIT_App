'use strict';
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const {execFileSync} = require('node:child_process');

const EMBEDDING_MODEL = 'gemini-embedding-001';
const DIMENSIONS = 768;
const digest = value => crypto.createHash('sha256').update(value).digest('hex');

function hasSecret(text) {
  return /-----BEGIN [A-Z ]*PRIVATE KEY-----|AIza[\w-]{30,}|\bsk-[\w-]{20,}|discord(?:app)?\.com\/api\/webhooks\/\d+\/[\w-]+|\bgh[pousr]_[\w]{25,}|\bgithub_pat_[\w]{25,}|\bBearer\s+[\w.-]{20,}|[\w-]{20,}\.[\w-]{6}\.[\w-]{25,}/i.test(text);
}

function normalize(vector) {
  if (!Array.isArray(vector) || !vector.length || !vector.every(Number.isFinite)) {
    throw new Error('Invalid embedding');
  }
  const norm = Math.hypot(...vector);
  if (!norm) throw new Error('Empty embedding');
  return vector.map(value => value / norm);
}

function loadSources(root, manifest) {
  const realRoot = fs.realpathSync(root);
  if (!Array.isArray(manifest.files) || !manifest.files.length) throw new Error('No sources');
  return manifest.files.map(file => {
    if (!/^docs\/handoff\/[a-zA-Z0-9_.-]+\.md$/.test(file)) throw new Error('Source is not approved');
    const resolved = fs.realpathSync(path.join(realRoot, file));
    const relative = path.relative(realRoot, resolved);
    if (relative.startsWith('..') || path.isAbsolute(relative)) throw new Error('Source escapes repository');
    if (fs.statSync(resolved).size > 64000) throw new Error('Source exceeds 64 KB');
    const text = fs.readFileSync(resolved, 'utf8').replace(/\r\n/g, '\n');
    if (hasSecret(text)) throw new Error(`Secret-like content detected in ${file}`);
    const reviewedAt = text.match(/^確認日: (\d{4}-\d{2}-\d{2})$/m)?.[1];
    if (!reviewedAt || !/^状態: /m.test(text)) throw new Error(`Review metadata missing: ${file}`);
    let revision = null;
    try {
      const committed = execFileSync('git', ['show', `HEAD:${file}`], {cwd: realRoot, stdio: ['ignore', 'pipe', 'ignore']}).toString().replace(/\r\n/g, '\n');
      if (committed === text) revision = execFileSync('git', ['rev-parse', 'HEAD'], {cwd: realRoot}).toString().trim();
    } catch { /* Uncommitted sources get file references, never invented commit links. */ }
    return {file, text, reviewedAt, revision, hash: digest(text)};
  });
}

function chunkSource(source) {
  const lines = source.text.split('\n');
  const title = lines[0].replace(/^#\s*/, '');
  const state = lines.find(line => line.startsWith('状態: '));
  const chunks = [];
  let section = title;
  let start = 0;
  let buffer = [];
  function flush() {
    if (!buffer.some(line => line.trim())) return;
    const body = buffer.join('\n');
    const text = `${title}\n確認日: ${source.reviewedAt}\n${state}\n${section}\n${body}`;
    chunks.push({id: digest(`${source.file}:${start}:${text}`).slice(0, 24), file: source.file,
      title, section, reviewedAt: source.reviewedAt, revision: source.revision,
      startLine: start + 1, endLine: start + buffer.length, text});
    buffer = [];
  }
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('## ') || buffer.join('\n').length + lines[i].length > 1200) {
      flush();
      start = i;
      if (lines[i].startsWith('## ')) section = lines[i].slice(3);
    }
    // A single unusually long line must not silently exceed the model limit.
    if (lines[i].length > 1200) throw new Error(`Split long line in ${source.file}:${i + 1}`);
    buffer.push(lines[i]);
  }
  flush();
  return chunks;
}

function buildIndex(sources, previous = {}) {
  const cached = new Map((previous.embeddingModel === EMBEDDING_MODEL ? previous.chunks ?? [] : []).map(chunk => [chunk.id, chunk.vector]));
  return {schemaVersion: 1, builtAt: new Date().toISOString(), embeddingModel: EMBEDDING_MODEL,
    dimensions: DIMENSIONS, sources: sources.map(({text, ...metadata}) => metadata),
    chunks: sources.flatMap(chunkSource).map(chunk => ({...chunk, vector: cached.get(chunk.id) ?? null}))};
}

function checkIndex(index, sources, requireVectors = false) {
  if (index.schemaVersion !== 1 || index.embeddingModel !== EMBEDDING_MODEL || index.dimensions !== DIMENSIONS || !index.chunks?.length) throw new Error('Rebuild knowledge index');
  const expected = buildIndex(sources);
  if (JSON.stringify(index.sources.map(({file, hash}) => [file, hash])) !== JSON.stringify(expected.sources.map(({file, hash}) => [file, hash])) ||
      JSON.stringify(index.chunks.map(chunk => [chunk.id, chunk.text])) !== JSON.stringify(expected.chunks.map(chunk => [chunk.id, chunk.text]))) {
    throw new Error('Knowledge index is stale; rebuild it');
  }
  if (requireVectors && index.chunks.some(chunk => chunk.vector?.length !== DIMENSIONS || !chunk.vector.every(Number.isFinite) || Math.abs(Math.hypot(...chunk.vector) - 1) > 0.01)) {
    throw new Error('Embeddings missing or invalid; run knowledge:embed');
  }
  return true;
}

function terms(text) {
  const normalized = text.toLowerCase().normalize('NFKC');
  const tokens = normalized.match(/[a-z0-9_./-]+/g) ?? [];
  for (const sequence of normalized.match(/[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}]+/gu) ?? []) {
    for (let i = 0; i < sequence.length - 1; i++) tokens.push(sequence.slice(i, i + 2));
  }
  return [...new Set(tokens)];
}

function retrieve(index, question, queryVector = null, limit = 5) {
  const queryTerms = terms(question);
  const vector = queryVector ? normalize(queryVector) : null;
  if (vector && vector.length !== index.dimensions) throw new Error('Embedding model mismatch');
  return index.chunks.map(chunk => {
    const body = new Set(terms(chunk.text));
    const lexical = queryTerms.reduce((sum, word) => sum + (body.has(word) ? 1 : 0), 0) / Math.max(1, queryTerms.length);
    const semantic = vector && chunk.vector ? vector.reduce((sum, n, i) => sum + n * chunk.vector[i], 0) : 0;
    return {...chunk, score: vector ? semantic * 0.8 + lexical * 0.2 : lexical, lexical, semantic};
  }).filter(chunk => vector ? chunk.semantic >= 0.5 || chunk.lexical >= 0.3 : chunk.lexical >= 0.15)
    .sort((a, b) => b.score - a.score).slice(0, limit);
}

module.exports = {EMBEDDING_MODEL, DIMENSIONS, digest, hasSecret, normalize, loadSources, chunkSource, buildIndex, checkIndex, retrieve};
