'use strict';
const {digest} = require('./knowledge');

function createJobStore(db, {userDailyLimit = 30, guildDailyLimit = 150, now = Date.now} = {}) {
  const jobRef = job => db.collection('handoff_rag_jobs').doc(digest(job.id));
  return {
    async claim(job) {
      return db.runTransaction(async tx => {
        const ref = jobRef(job);
        const snapshot = await tx.get(ref);
        const existing = snapshot.data();
        if (existing?.content) return {status: 'cached', content: existing.content};
        if (existing?.leaseUntil > now()) return {status: 'busy'};
        if ((existing?.attempts ?? 0) >= 3) return {status: 'limited'};
        if (!existing) {
          const day = new Date(now()).toISOString().slice(0, 10);
          const user = db.collection('handoff_rag_usage').doc(digest(`${day}:${job.guildId}:${job.userId}`));
          const guild = db.collection('handoff_rag_usage').doc(digest(`${day}:${job.guildId}`));
          const [userSnapshot, guildSnapshot] = await Promise.all([tx.get(user), tx.get(guild)]);
          const userCount = userSnapshot.data()?.count ?? 0;
          const guildCount = guildSnapshot.data()?.count ?? 0;
          if (userCount >= userDailyLimit || guildCount >= guildDailyLimit) return {status: 'limited'};
          const expiresAt = new Date(now() + 7 * 86400000);
          tx.set(user, {count: userCount + 1, expiresAt});
          tx.set(guild, {count: guildCount + 1, expiresAt});
        }
        tx.set(ref, {attempts: (existing?.attempts ?? 0) + 1, leaseUntil: now() + 120000,
          expiresAt: new Date(now() + 86400000)}, {merge: true});
        return {status: 'claimed'};
      });
    },
    async complete(job, content) {
      await jobRef(job).set({content, leaseUntil: 0}, {merge: true});
    },
    async release(job) {
      await jobRef(job).set({leaseUntil: 0}, {merge: true});
    },
  };
}
module.exports = {createJobStore};
