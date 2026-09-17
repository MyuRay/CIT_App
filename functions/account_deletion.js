'use strict';
const {createHash, randomUUID} = require('node:crypto');
const {FieldPath, FieldValue, Timestamp} = require('firebase-admin/firestore');
const JOBS = 'account_deletion_jobs';
// Collection-group scans also cover orphaned replies and nested private data.
const GROUPS = ['bulletin_posts', 'bulletin_comments', 'cafeteria_reviews',
  'cwitter_posts', 'replies', 'cwitter_replies', 'chiba_channel_threads', 'comments',
  'anonymous_ids', 'cwitter_likes', 'cwitter_recweets', 'cwitter_following',
  'cwitter_followers', 'notifications', 'hidden_posts', 'hidden_comments',
  'blocked_users', 'contact_forms', 'schedules', 'attendance_records',
  'excel_import_training_submissions', 'cwitter_ids'];
const PRIVATE = ['users', 'user_settings', 'user_tokens', 'admins', 'admin_permissions'];
const PREFIXES = ['profile_images', 'cwitter_post_images', 'cwitter_reply_images',
  'chiba_channel_comment_images', 'excel_import_training'];
function ownedPath(path, uid) {
  return PREFIXES.some(p => path.startsWith(`${p}/${uid}/`)) ||
    path.startsWith(`bulletin_images/${uid}_`);
}
function belongsTo(path, data, uid) {
  const p = path.split('/');
  if (p[0] === 'users' && p[1] === uid) return true;
  if (['anonymous_ids', 'cwitter_following', 'cwitter_followers'].includes(p.at(-2)) && p.at(-1) === uid) return true;
  return ['userId', 'authorId', 'ownerId', 'uid', 'fromUserId', 'blockedUserId', 'originalAuthorId']
    .some(k => data[k] === uid);
}
function storagePaths(data, bucketName) {
  const paths = new Set();
  function visit(value) {
    if (typeof value === 'string') {
      try {
        const u = new URL(value);
        const prefix = `/v0/b/${bucketName}/o/`;
        const raw = u.hostname === 'firebasestorage.googleapis.com' && u.pathname.startsWith(prefix)
          ? u.pathname.slice(prefix.length)
          : u.hostname === 'storage.googleapis.com' && u.pathname.startsWith(`/${bucketName}/`)
            ? u.pathname.slice(bucketName.length + 2) : null;
        if (u.protocol === 'https:' && raw) {
          const path = decodeURIComponent(raw);
          if (['bulletin_images/', ...PREFIXES.map(p => p + '/')].some(p => path.startsWith(p))) paths.add(path);
        }
      } catch (_) { /* Plain text is not a storage URL. */ }
    } else if (Array.isArray(value)) value.forEach(visit);
    else if (value && typeof value === 'object' && !(value instanceof Timestamp)) Object.values(value).forEach(visit);
  }
  visit(data);
  return [...paths];
}
function createDeletionApi({auth, db, now = () => Date.now()}) {
  return async (req, res) => {
    res.set('Cache-Control', 'no-store');
    if (req.method !== 'POST') return res.status(405).json({error: 'method-not-allowed'});
    const bearer = /^Bearer (.+)$/.exec(req.get('authorization') || '');
    if (!bearer) return res.status(401).json({error: 'unauthenticated'});
    let token;
    try { token = await auth.verifyIdToken(bearer[1], true); }
    catch (_) { return res.status(401).json({error: 'unauthenticated'}); }
    // Never accept a target UID from the caller.
    if (!token.uid || !Number.isFinite(token.auth_time) || now() / 1000 - token.auth_time > 300 || token.auth_time > now() / 1000 + 60) {
      return res.status(401).json({error: 'requires-recent-login'});
    }
    if (req.body?.confirm !== true || Object.keys(req.body || {}).some(k => k !== 'confirm')) {
      return res.status(400).json({error: 'confirmation-required'});
    }
    try {
      const job = db.collection(JOBS).doc(token.uid);
      await db.runTransaction(async tx => {
        const snap = await tx.get(job);
        if (!snap.exists) tx.create(job, {status: 'queued', stage: 0, cursor: null,
          createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp()});
      });
      return res.status(202).json({status: 'queued'});
    } catch (_) { return res.status(503).json({error: 'temporarily-unavailable'}); }
  };
}

function createDeletionWorker({auth, db, bucket, now = () => Date.now()}) {
  return async uid => {
    if (typeof uid !== 'string' || !uid || uid.includes('/')) throw Error('Invalid job UID');
    const job = db.collection(JOBS).doc(uid);
    const lease = randomUUID();
    const acquired = await db.runTransaction(async tx => {
      const snap = await tx.get(job);
      if (!snap.exists || snap.data().status === 'complete') return false;
      if ((snap.data().leaseUntil?.toMillis() || 0) > now()) return false;
      tx.update(job, {lease, leaseUntil: Timestamp.fromMillis(now() + 600000), status: 'running'});
      return true;
    });
    if (!acquired) return;
    const deadline = now() + 420000;
    const manifest = job.collection('files');
    async function checkpoint(stage, cursor) {
      await job.update({stage, cursor, updatedAt: FieldValue.serverTimestamp()});
    }
    async function recordFiles(data, owned) {
      for (const path of storagePaths(data, bucket.name)) {
        await manifest.doc(createHash('sha256').update(path).digest('hex'))
          .set({path, ...(owned ? {owned: true} : {shared: true})}, {merge: true});
      }
    }
    async function cleanDocument(snap) {
      const data = snap.data();
      const owned = belongsTo(snap.ref.path, data, uid);
      await recordFiles(data, owned);
      if (owned) {
        // Delete only this author's document. Other people's replies survive.
        // Private subcollections are removed separately with recursiveDelete.
        const p = snap.ref.path.split('/');
        let counter;
        if (p[0] === 'cwitter_posts' && p[2] === 'replies') counter = [`cwitter_posts/${p[1]}`, 'replyCount'];
        if (p[0] === 'users' && p[2] === 'cwitter_recweets' && p[1] === uid) counter = [`cwitter_posts/${p[3]}`, 'recweetCount'];
        if (p[0] === 'users' && ['cwitter_followers', 'cwitter_following'].includes(p[2])) {
          counter = [`users/${p[1]}/cwitter_social/stats`, p[2] === 'cwitter_followers' ? 'followerCount' : 'followingCount'];
        }
        if (!counter) await snap.ref.delete();
        else await db.runTransaction(async tx => {
          const current = await tx.get(snap.ref);
          const stats = await tx.get(db.doc(counter[0]));
          if (!current.exists) return;
          tx.delete(snap.ref);
          if (stats.exists) tx.update(stats.ref, {[counter[1]]: Math.max(0, (Number(stats.data()[counter[1]]) || 0) - 1)});
        });
      } else if ([data.likedBy, data.couponUsedBy, data.poll?.votedBy].some(m => m && Object.hasOwn(m, uid))) {
        await db.runTransaction(async tx => {
          const current = await tx.get(snap.ref);
          const d = current.data();
          if (!d) return;
          const patch = {};
          if (d.likedBy && Object.hasOwn(d.likedBy, uid)) {
            const likedBy = {...d.likedBy}; delete likedBy[uid];
            Object.assign(patch, {likedBy, likeCount: Object.values(likedBy).filter(v => v === true).length});
          }
          if (d.couponUsedBy && Object.hasOwn(d.couponUsedBy, uid)) {
            const couponUsedBy = {...d.couponUsedBy}; delete couponUsedBy[uid];
            Object.assign(patch, {couponUsedBy, couponUsedCount: Object.values(couponUsedBy).reduce((a, n) => a + (Number(n) || 0), 0)});
          }
          if (d.poll?.votedBy && Object.hasOwn(d.poll.votedBy, uid)) {
            const votedBy = {...d.poll.votedBy}; const option = votedBy[uid]; delete votedBy[uid];
            patch.poll = {...d.poll, votedBy, options: d.poll.options.map(o => o.id === option ? {...o, voteCount: Math.max(0, o.voteCount - 1)} : o)};
          }
          if (Object.keys(patch).length) tx.update(snap.ref, patch);
        });
      }
    }
    try {
      try { await auth.updateUser(uid, {disabled: true}); await auth.revokeRefreshTokens(uid); }
      catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
      let {stage = 0, cursor = null} = (await job.get()).data();
      while (stage < GROUPS.length && now() < deadline) {
        let query = db.collectionGroup(GROUPS[stage]).orderBy(FieldPath.documentId()).limit(100);
        if (cursor) query = query.startAfter(db.doc(cursor));
        const page = await query.get();
        for (const snap of page.docs) {
          await cleanDocument(snap);
          // Every deletion/aggregate change is idempotent. Checkpoint a page
          // rather than writing one job update for every unrelated document.
          cursor = snap.ref.path;
          if (now() >= deadline) break;
        }
        await checkpoint(stage, cursor);
        if (page.empty || page.size < 100 && now() < deadline) {
          stage++; cursor = null; await checkpoint(stage, cursor);
        }
      }
      if (stage < GROUPS.length) return;
      // Remove private subcollections, including favorites, assignments, tokens.
      for (const root of PRIVATE) await db.recursiveDelete(db.collection(root).doc(uid));
      // User-namespaced uploads can include abandoned drafts with no document.
      for (const prefix of [...PREFIXES.map(p => `${p}/${uid}/`), `bulletin_images/${uid}_`]) {
        await bucket.deleteFiles({prefix, force: false});
      }
      // Legacy bulletin uploads lack UID paths; only remove unshared references.
      for await (const file of manifest.stream()) {
        const d = file.data();
        if (d.owned && !d.shared) await bucket.file(d.path).delete({ignoreNotFound: true});
        await file.ref.delete();
      }
      try { await auth.deleteUser(uid); }
      catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
      await job.update({status: 'complete', completedAt: FieldValue.serverTimestamp(),
        leaseUntil: FieldValue.delete(), lease: FieldValue.delete(), cursor: FieldValue.delete()});
    } catch (e) {
      await job.update({status: 'retry', updatedAt: FieldValue.serverTimestamp()});
      throw e;
    } finally {
      await db.runTransaction(async tx => {
        const snap = await tx.get(job);
        if (snap.data()?.lease === lease) tx.update(job, {
          status: snap.data().status === 'running' ? 'queued' : snap.data().status,
          leaseUntil: FieldValue.delete(), lease: FieldValue.delete(),
        });
      });
    }
  };
}
module.exports = {JOBS, GROUPS, belongsTo, ownedPath, storagePaths, createDeletionApi, createDeletionWorker};
