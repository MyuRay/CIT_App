'use strict';

// Never copy unknown future account fields into a readable profile.
const PUBLIC_FIELDS = ['displayName', 'profileImageUrl', 'cwitterId', 'cwitterBio',
  'cwitterTags', 'cwitterSocialLinks', 'cwitterPinnedPostId', 'isActive'];
function publicProfile(uid, data) {
  const result = {uid};
  for (const key of PUBLIC_FIELDS) {
    if (Object.hasOwn(data, key)) result[key] = data[key];
  }
  return result;
}
function createPublicProfileSync({db}) {
  return async uid => db.runTransaction(async tx => {
    const source = db.collection('users').doc(uid);
    const destination = db.collection('public_profiles').doc(uid);
    const [profile, deletion] = await Promise.all([
      tx.get(source), tx.get(db.collection('account_deletion_jobs').doc(uid)),
    ]);
    // Read current state, rather than an event snapshot which can arrive late.
    if (!profile.exists || deletion.exists) tx.delete(destination);
    else tx.set(destination, publicProfile(uid, profile.data()));
  });
}
module.exports = {PUBLIC_FIELDS, publicProfile, createPublicProfileSync};
