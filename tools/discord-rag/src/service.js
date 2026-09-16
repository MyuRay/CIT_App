'use strict';
const {verifyRequest, validateInteraction, immediate, EPHEMERAL, UNKNOWN, formatAnswer} = require('./discord');
const {retrieve, digest} = require('./knowledge');

function createInteractionHandler({config, enqueue, now = Date.now}) {
  return async (req, res) => {
    if (req.method !== 'POST') return res.status(405).send('Method not allowed');
    if (!verifyRequest(req.rawBody, req.get('X-Signature-Ed25519'), req.get('X-Signature-Timestamp'), config.publicKey, now())) {
      return res.status(401).send('Invalid signature');
    }
    let interaction;
    try { interaction = JSON.parse(req.rawBody.toString()); } catch { return res.status(400).send('Invalid JSON'); }
    if (interaction.type === 1) return res.json({type: 1});
    if (!config.enabled) return res.json(immediate('現在Botを停止しています。docs/handoff/ の資料を確認してください。'));
    const checked = validateInteraction(interaction, config);
    if (checked.error) return res.json(immediate(checked.error));
    try {
      await enqueue({id: interaction.id, applicationId: interaction.application_id,
        guildId: interaction.guild_id, userId: interaction.member.user.id, token: interaction.token,
        question: checked.question, createdAt: now()}, digest(interaction.id));
      return res.json({type: 5, data: {flags: EPHEMERAL}});
    } catch {
      return res.json(immediate('質問の受付に失敗しました。少し待ってから再試行してください。続く場合はBot管理者へ連絡してください。'));
    }
  };
}

function createWorker({config, index, ai, jobs, reply, now = Date.now}) {
  return async job => {
    if (!job || !/^\d{17,20}$/.test(job.id ?? '') || !/^\d{17,20}$/.test(job.userId ?? '') ||
        job.applicationId !== config.applicationId || job.guildId !== config.guildId ||
        typeof job.question !== 'string' || job.question.length > 1000 || !Number.isFinite(job.createdAt) ||
        now() - job.createdAt > 10 * 60 * 1000 || job.createdAt > now() + 10000) return;
    if (!config.enabled) {
      await reply(job, '現在Botを停止しています。docs/handoff/ の資料を確認してください。');
      return;
    }
    const reservation = await jobs.claim(job);
    if (reservation.status === 'busy') throw new Error('Job in progress');
    if (reservation.status === 'limited') {
      await reply(job, '本日の利用上限に達しました。docs/handoff/ の資料を確認するか、Bot管理者へ連絡してください。');
      return;
    }
    if (reservation.status === 'cached') {
      await reply(job, reservation.content);
      return;
    }
    try {
      const vector = await ai.embed(job.question);
      const chunks = retrieve(index, job.question, vector, 4);
      const content = chunks.length ? formatAnswer(await ai.generate(job.question, chunks), chunks, index, config.repositoryUrl) : UNKNOWN;
      // Cache before Discord delivery. Retrying a failed delivery must not buy another AI response.
      await jobs.complete(job, content);
      await reply(job, content);
    } catch {
      await jobs.release(job);
      // This also updates a deferred message if generation fails. Queue retries may replace it with success.
      try { await reply(job, '資料の検索・回答に失敗しました。時間をおいても回答が更新されない場合は、docs/handoff/を確認し、Bot管理者へ連絡してください。'); } catch { /* Retry via durable queue. */ }
      throw new Error('RAG job failed');
    }
  };
}
module.exports = {createInteractionHandler, createWorker};
