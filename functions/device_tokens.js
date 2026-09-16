'use strict';

async function getUserTokenEntries(firestore, userId) {
  const owner = firestore.collection('user_tokens').doc(userId);
  const [legacy, devices] = await Promise.all([owner.get(), owner.collection('devices').get()]);
  const byToken = new Map();
  const legacyToken = legacy.data()?.fcmToken;
  if (typeof legacyToken === 'string' && legacyToken) {
    byToken.set(legacyToken, {token: legacyToken, userId, ref: owner, legacy: true});
  }
  for (const device of devices.docs) {
    const token = device.data()?.fcmToken;
    if (typeof token === 'string' && token) {
      byToken.set(token, {token, userId, ref: device.ref, legacy: false});
    }
  }
  return [...byToken.values()];
}

async function removeInvalidToken(firestore, entry, deleteField) {
  // A late failed send must not delete a token refreshed in the meantime.
  await firestore.runTransaction(async transaction => {
    const snapshot = await transaction.get(entry.ref);
    if (snapshot.data()?.fcmToken !== entry.token) return;
    if (entry.legacy) transaction.update(entry.ref, {fcmToken: deleteField()});
    else transaction.delete(entry.ref);
  });
}

module.exports = {getUserTokenEntries, removeInvalidToken};
