'use strict';
const crypto = require('node:crypto');
const {hasSecret} = require('./knowledge');
const EPHEMERAL = 64;
const UNKNOWN = '確認済みの資料だけでは答えを確定できません。docs/handoff/ を確認し、不足している手順・担当者・本番反映状況をチームで補ってください。';

function verifyRequest(rawBody, signature, timestamp, publicKey, now = Date.now()) {
  if (!Buffer.isBuffer(rawBody) || rawBody.length > 32000 || !/^[a-f0-9]{128}$/i.test(signature ?? '') ||
      !/^[a-f0-9]{64}$/i.test(publicKey ?? '') || !/^\d{10,}$/.test(timestamp ?? '') || Math.abs(now / 1000 - Number(timestamp)) > 300) return false;
  try {
    const key = crypto.createPublicKey({key: Buffer.concat([Buffer.from('302a300506032b6570032100', 'hex'), Buffer.from(publicKey, 'hex')]), format: 'der', type: 'spki'});
    return crypto.verify(null, Buffer.concat([Buffer.from(timestamp), rawBody]), key, Buffer.from(signature, 'hex'));
  } catch { return false; }
}

function validateInteraction(interaction, config) {
  if (interaction.application_id !== config.applicationId || interaction.guild_id !== config.guildId ||
      !config.channelIds?.includes(interaction.channel_id) || !config.roleIds?.some(role => interaction.member?.roles?.includes(role))) {
    return {error: 'このチャンネル・ロールでは利用できません。チームのBot管理者へ確認してください。'};
  }
  if (interaction.type !== 2 || interaction.data?.name !== 'ask') return {error: '利用できるコマンドは /ask です。'};
  const question = interaction.data.options?.find(option => option.name === 'question' && option.type === 3)?.value;
  if (typeof question !== 'string' || question.trim().length < 2 || question.length > 1000) return {error: '質問は2〜1000文字で入力してください。'};
  if (hasSecret(question)) return {error: '秘密情報のような文字列が含まれています。キーやトークンを除いて質問してください。'};
  if (!/^\d{17,20}$/.test(interaction.id ?? '') || !/^\d{17,20}$/.test(interaction.member?.user?.id ?? '') || typeof interaction.token !== 'string' || interaction.token.length > 2000) return {error: '質問を受け付けられませんでした。'};
  return {question: question.trim()};
}

const immediate = content => ({type: 4, data: {content, flags: EPHEMERAL, allowed_mentions: {parse: []}}});

function safeText(text) {
  return text.replace(/@/g, '@\u200b').replace(/<[^>]*>/g, '').replace(/https?:\/\/[^\s)]+/gi, '[URL省略]');
}

function formatAnswer(result, chunks, index, repositoryUrl = '') {
  if (result?.status !== 'answered' || typeof result.answer !== 'string' || !result.answer.trim() ||
      !Array.isArray(result.citations) || !result.citations.length || result.citations.length > 4 || hasSecret(result.answer)) return UNKNOWN;
  const byId = new Map(chunks.map(chunk => [chunk.id, chunk]));
  if (result.citations.some(id => !byId.has(id))) return UNKNOWN;
  const citations = [...new Set(result.citations)].map(id => {
    const chunk = byId.get(id);
    const label = `${chunk.file}:${chunk.startLine}（確認 ${chunk.reviewedAt}）`;
    const canLink = /^https:\/\/github\.com\/[\w.-]+\/[\w.-]+$/.test(repositoryUrl) && /^[a-f0-9]{40}$/.test(chunk.revision ?? '');
    return canLink ? `・[${label}](${repositoryUrl}/blob/${chunk.revision}/${chunk.file}#L${chunk.startLine})` : `・${label}`;
  });
  const answer = safeText(result.answer).slice(0, 900);
  return `${answer}\n\n出典\n${citations.join('\n')}\n検索データ更新: ${index.builtAt.slice(0, 10)}`.slice(0, 1950);
}

async function editOriginal({applicationId, token, content, fetchImpl = fetch}) {
  if (!/^\d{17,20}$/.test(applicationId) || typeof token !== 'string') throw new Error('Invalid interaction');
  const response = await fetchImpl(`https://discord.com/api/v10/webhooks/${applicationId}/${encodeURIComponent(token)}/messages/@original`, {
    method: 'PATCH', headers: {'Content-Type': 'application/json'}, signal: AbortSignal.timeout(10000),
    body: JSON.stringify({content, allowed_mentions: {parse: []}}),
  });
  if (!response.ok) throw new Error(`Discord response failed (${response.status})`);
}

module.exports = {EPHEMERAL, UNKNOWN, verifyRequest, validateInteraction, immediate, formatAnswer, editOriginal};
