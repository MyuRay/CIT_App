'use strict';

const {createHash, randomUUID} = require('node:crypto');
const COLLECTION = 'discord_notifications';
const JOBS = 'account_deletion_jobs';
const LEASE_MS = 10 * 60 * 1000;

function webhookAddress(value) {
  const url = new URL(value);
  const match = /^\/api(?:\/v\d+)?\/webhooks\/(\d+)\/([\w.-]+)\/?$/.exec(url.pathname);
  if (url.protocol !== 'https:' || url.hostname !== 'discord.com' ||
      url.port || url.username || url.password || !match) {
    throw Error('Invalid Discord webhook destination');
  }
  const threadId = url.searchParams.get('thread_id');
  if (threadId && !/^\d+$/.test(threadId)) throw Error('Invalid Discord thread');
  return {id: match[1], base: `${url.origin}${url.pathname.replace(/\/$/, '')}`, threadId};
}

function messageAddress(address, messageId) {
  if (!/^\d+$/.test(messageId)) throw Error('Invalid Discord message ID');
  const url = new URL(`${address.base}/messages/${messageId}`);
  if (address.threadId) url.searchParams.set('thread_id', address.threadId);
  return url.toString();
}

function maskNotificationEmail(value) {
  const email = String(value || '');
  const at = email.lastIndexOf('@');
  if (at <= 0) return '（未設定）';
  const visible = Math.min(3, Math.max(0, at - 1));
  return `${email.slice(0, visible)}${'*'.repeat(at - visible)}${email.slice(at)}`;
}

// No webhook tokens, message bodies or email addresses are stored in receipts.
// POST creates a non-personal placeholder. PII is PATCHed only after its message
// ID is durable, so a crash between Discord and Firestore cannot orphan PII.
function createDiscordNotifications({db, auth, http, getWebhook,
  getHistoricalWebhooks = () => [], now = () => Date.now()}) {
  const records = db.collection(COLLECTION);

  async function usersStillActive(userIds) {
    for (const uid of userIds) {
      try {
        if ((await auth.getUser(uid)).disabled) return false;
      } catch (error) {
        if (error.code === 'auth/user-not-found') return false;
        throw Error('Could not verify Discord notification owner');
      }
    }
    return true;
  }

  async function deletionRequested(tx, userIds) {
    const jobs = await Promise.all(userIds.map(uid => tx.get(db.collection(JOBS).doc(uid))));
    return jobs.some(job => job.exists);
  }

  function resolveAddress(record) {
    const candidates = [getWebhook(record.kind), ...getHistoricalWebhooks()];
    for (const candidate of candidates) {
      if (!candidate) continue;
      const address = webhookAddress(candidate);
      if (address.id === record.webhookId) return {...address, threadId: record.threadId || null};
    }
    throw Error('Discord deletion credential unavailable');
  }

  async function removeMessage(address, messageId) {
    try {
      await http.delete(messageAddress(address, messageId), {timeout: 8000});
    } catch (error) {
      // Only Discord's explicit missing-message/webhook codes are terminal.
      // 401/403, rate limits and unclassified 404s must be retried.
      if (error.response?.status === 404 &&
          [10008, 10015].includes(error.response?.data?.code)) return;
      throw Error('Discord message deletion requires retry');
    }
  }

  async function send(kind, payload, {userIds, eventId}) {
    const owners = [...new Set(userIds.filter(uid => typeof uid === 'string' && uid &&
      !uid.includes('/') && !['unknown', '不明'].includes(uid)))].sort();
    if (!owners.length || typeof eventId !== 'string' || !eventId) {
      throw Error('Discord notification requires owners and an event ID');
    }
    const destination = getWebhook(kind);
    if (!destination || !await usersStillActive(owners)) return false;
    const proposedAddress = webhookAddress(destination);
    const ref = records.doc(createHash('sha256').update(`${kind}:${eventId}`).digest('hex'));
    const lease = randomUUID();
    const record = await db.runTransaction(async tx => {
      const existing = await tx.get(ref);
      const data = existing.data();
      const knownOwners = [...new Set([...owners, ...(data?.ownerIds || [])])].sort();
      const deleting = await deletionRequested(tx, knownOwners);
      if (deleting || data?.state === 'sent' || (data?.leaseUntilMs || 0) > now()) return null;
      // A retry reuses the original webhook and message, even after config changes.
      const next = {...(data || {}), kind, ownerIds: knownOwners,
        webhookId: data?.webhookId || proposedAddress.id,
        threadId: data ? data.threadId ?? null : proposedAddress.threadId,
        state: 'preparing', lease, leaseUntilMs: now() + LEASE_MS,
        createdAtMs: data?.createdAtMs ?? now()};
      tx.set(ref, next);
      return next;
    });
    if (!record) return false;
    try {
      const address = resolveAddress(record);
      let messageId = record.messageId;
      if (!messageId) {
        const url = new URL(address.base);
        url.searchParams.set('wait', 'true');
        if (address.threadId) url.searchParams.set('thread_id', address.threadId);
        const response = await http.post(url.toString(), {
          content: '運営通知を準備しています。', allowed_mentions: {parse: []},
        }, {timeout: 8000});
        messageId = response.data?.id;
        if (typeof messageId !== 'string' || !/^\d+$/.test(messageId)) {
          throw Error('Discord did not return a message ID');
        }
      }
      const canPublish = await db.runTransaction(async tx => {
        const current = await tx.get(ref);
        const deleting = await deletionRequested(tx, record.ownerIds);
        const data = current.data();
        if (!data || data.lease !== lease || data.leaseUntilMs <= now()) return false;
        tx.update(ref, {messageId, ...(deleting ? {state: 'pending_delete', leaseUntilMs: 0} : {})});
        return !deleting;
      });
      if (!canPublish) {
        // This is still a harmless placeholder; no personal content was sent.
        await removeMessage(address, messageId);
        return false;
      }
      // Editing cannot recreate a message already removed by the deletion worker.
      await http.patch(messageAddress(address, messageId), {
        ...payload, content: payload.content ?? null, allowed_mentions: {parse: []},
      }, {timeout: 8000});
      await db.runTransaction(async tx => {
        const current = await tx.get(ref);
        if (current.data()?.lease === lease) {
          tx.update(ref, {state: 'sent', leaseUntilMs: 0, sentAtMs: now()});
        }
      });
      return true;
    } catch (_) {
      await db.runTransaction(async tx => {
        const current = await tx.get(ref);
        if (current.data()?.lease === lease) tx.update(ref, {state: 'retry', leaseUntilMs: 0});
      });
      // Do not propagate Axios errors: they may contain tokens and private bodies.
      throw Error('Discord notification requires retry');
    }
  }

  async function purgeUser(uid, {deadline = now() + 60000} = {}) {
    while (now() < deadline) {
      const page = await records.where('ownerIds', 'array-contains', uid).limit(100).get();
      if (page.empty) return true;
      for (const snapshot of page.docs) {
        if (now() + 10000 >= deadline) return false;
        // Cancel stale reservations atomically. An in-flight sender cannot later
        // publish using a lease which the cleanup has invalidated.
        const record = await db.runTransaction(async tx => {
          const current = await tx.get(snapshot.ref);
          const data = current.data();
          if (!data) return null;
          if (data.state === 'preparing' && data.leaseUntilMs > now()) return false;
          tx.update(snapshot.ref, {state: 'pending_delete', lease: null, leaseUntilMs: 0});
          return data;
        });
        if (record === false) return false;
        if (!record) continue;
        if (record.messageId) await removeMessage(resolveAddress(record), record.messageId);
        await snapshot.ref.delete();
      }
    }
    return false;
  }

  return {send, purgeUser};
}

module.exports = {COLLECTION, LEASE_MS, webhookAddress, maskNotificationEmail, createDiscordNotifications};
