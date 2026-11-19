'use strict';

// Read the parent in every transaction: a delayed delete event must not remove
// mappings from a newly created thread that happens to reuse the document ID.
function createChibaPrivateCleanup({db, now = () => Date.now()}) {
  return async threadId => {
    if (typeof threadId !== 'string' || !/^[^/]{1,1500}$/.test(threadId)) {
      throw Error('Invalid thread ID');
    }
    const parent = db.collection('chiba_channel_threads').doc(threadId);
    const deadline = now() + 240000;
    while (now() < deadline) {
      const more = await db.runTransaction(async tx => {
        const thread = await tx.get(parent);
        if (thread.exists) return false;
        const page = await tx.get(parent.collection('anonymous_ids').limit(100));
        for (const row of page.docs) tx.delete(row.ref);
        return page.size === 100;
      });
      if (!more) return;
    }
    throw Error('Private mapping cleanup requires retry');
  };
}

module.exports = {createChibaPrivateCleanup};
