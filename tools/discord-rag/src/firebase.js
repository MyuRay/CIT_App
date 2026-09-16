'use strict';
const fs = require('node:fs');
const path = require('node:path');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {getFunctions} = require('firebase-admin/functions');
const {onRequest} = require('firebase-functions/v2/https');
const {onTaskDispatched} = require('firebase-functions/v2/tasks');
const {defineString, defineSecret, defineInt, defineBoolean} = require('firebase-functions/params');
const {createInteractionHandler, createWorker} = require('./service');
const {createGemini} = require('./gemini');
const {createJobStore} = require('./jobs');
const {editOriginal} = require('./discord');

initializeApp();
const region = defineString('RAG_REGION', {default: 'us-central1'});
const serviceAccount = defineString('RAG_SERVICE_ACCOUNT');
const publicKey = defineString('RAG_DISCORD_PUBLIC_KEY');
const applicationId = defineString('RAG_DISCORD_APPLICATION_ID');
const guildId = defineString('RAG_DISCORD_GUILD_ID');
const channelIds = defineString('RAG_DISCORD_CHANNEL_IDS');
const roleIds = defineString('RAG_DISCORD_ROLE_IDS');
const enabled = defineBoolean('RAG_ENABLED', {default: false});
const repositoryUrl = defineString('RAG_REPOSITORY_URL', {default: ''});
const model = defineString('RAG_GENERATION_MODEL', {default: 'gemini-3.1-flash-lite'});
const apiKey = defineSecret('RAG_GEMINI_API_KEY');
const minInstances = defineInt('RAG_MIN_INSTANCES', {default: 0});
const userDailyLimit = defineInt('RAG_USER_DAILY_LIMIT', {default: 30});
const guildDailyLimit = defineInt('RAG_GUILD_DAILY_LIMIT', {default: 150});

function config() {
  return {publicKey: publicKey.value(), applicationId: applicationId.value(), guildId: guildId.value(),
    channelIds: channelIds.value().split(',').map(value => value.trim()).filter(Boolean),
    roleIds: roleIds.value().split(',').map(value => value.trim()).filter(Boolean),
    enabled: enabled.value(), repositoryUrl: repositoryUrl.value()};
}

exports.handoffAsk = onRequest({region, serviceAccount, invoker: 'public', minInstances,
  maxInstances: 2, concurrency: 20, timeoutSeconds: 15, memory: '256MiB'}, async (req, res) => {
  const start = Date.now();
  const handler = createInteractionHandler({config: config(), enqueue: async (job, id) => {
    const queue = getFunctions().taskQueue(`locations/${region.value()}/functions/handoffAnswer`);
    try {
      await queue.enqueue(job, {id, scheduleDelaySeconds: 3, dispatchDeadlineSeconds: 120});
    } catch (error) {
      if (error.code !== 'functions/task-already-exists') throw error;
    }
  }});
  await handler(req, res);
  // Numeric timing only: never log request bodies, questions or interaction tokens.
  if (Date.now() - start > 2000) console.warn('RAG interaction acknowledgement exceeded 2 seconds');
});

let index;
exports.handoffAnswer = onTaskDispatched({region, serviceAccount, invoker: 'private',
  secrets: [apiKey], maxInstances: 2, concurrency: 1, timeoutSeconds: 120, memory: '512MiB',
  retryConfig: {maxAttempts: 3, minBackoffSeconds: 60, maxBackoffSeconds: 120},
  rateLimits: {maxConcurrentDispatches: 2, maxDispatchesPerSecond: 1}}, async request => {
  index ??= JSON.parse(fs.readFileSync(path.join(__dirname, '../data/index.json'), 'utf8'));
  if (!index.chunks?.length || index.chunks.some(chunk => chunk.vector?.length !== index.dimensions)) throw new Error('Knowledge index has no valid embeddings');
  const worker = createWorker({config: config(), index,
    ai: createGemini({apiKey: apiKey.value(), model: model.value()}),
    jobs: createJobStore(getFirestore(), {userDailyLimit: userDailyLimit.value(), guildDailyLimit: guildDailyLimit.value()}),
    reply: (job, content) => editOriginal({applicationId: job.applicationId, token: job.token, content}),
  });
  await worker(request.data);
});
