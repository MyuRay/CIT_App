const {readFileSync} = require('node:fs');
const {test, before, after, beforeEach} = require('node:test');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, setDoc, updateDoc, getDoc, deleteField, increment} = require('firebase/firestore');

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-cit-review',
    firestore: {host: '127.0.0.1', port: 8089, rules: readFileSync('firestore.rules', 'utf8')},
  });
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    await setDoc(doc(ctx.firestore(), 'admin_permissions/admin'), {isAdmin: true});
    await setDoc(doc(ctx.firestore(), 'bulletin_posts/post'), post());
  });
});
function db(uid, verified = true, email = `${uid}@s.chibakoudai.jp`) {
  return env.authenticatedContext(uid, {email, email_verified: verified}).firestore();
}
function post() {
  return {authorId: 'owner', title: '授業案内', description: '本文', approvalStatus: 'approved',
    isPinned: false, isActive: true, viewCount: 0, isCoupon: true, couponMaxUses: 2,
    couponUsedCount: 0, couponUsedBy: null, approvedAt: null, approvedBy: null};
}
test('anonymous, unverified and external accounts cannot read protected posts', async () => {
  for (const client of [env.unauthenticatedContext().firestore(), db('owner', false), db('owner', true, 'owner@example.org')]) {
    await assertFails(getDoc(doc(client, 'bulletin_posts/post')));
  }
});
test('all three verified university domains remain supported', async () => {
  for (const domain of ['s.chibakoudai.jp', 'p.chibakoudai.jp', 'chibatech.ac.jp']) {
    await assertSucceeds(getDoc(doc(db('reader', true, `reader@${domain}`), 'bulletin_posts/post')));
  }
});
test('another user cannot edit text, owner identity or approval', async () => {
  const ref = doc(db('reader'), 'bulletin_posts/post');
  for (const patch of [{title: '改変'}, {authorId: 'reader'}, {approvalStatus: 'rejected'}, {isPinned: true}, {description: deleteField()}]) {
    await assertFails(updateDoc(ref, patch));
  }
});
test('owner can edit content but cannot grant approval or change owner', async () => {
  const ref = doc(db('owner'), 'bulletin_posts/post');
  await assertSucceeds(updateDoc(ref, {title: '更新'}));
  await assertSucceeds(updateDoc(ref, {approvalStatus: 'pending', approvedAt: null, approvedBy: null}));
  await assertFails(updateDoc(ref, {approvalStatus: 'approved'}));
  await assertFails(updateDoc(ref, {authorId: 'admin'}));
  await assertFails(updateDoc(ref, {isPinned: true}));
});
test('admin can moderate but cannot replace immutable owner', async () => {
  const ref = doc(db('admin'), 'bulletin_posts/post');
  await assertSucceeds(updateDoc(ref, {approvalStatus: 'rejected', isPinned: true}));
  await assertFails(updateDoc(ref, {authorId: 'admin'}));
});

test('owners can save multiple bulletin images and thumbnail crop while readers cannot', async () => {
  const patch = {imageUrl: 'https://example.com/second.jpg',
    imageUrls: ['https://example.com/first.jpg', 'https://example.com/second.jpg'],
    thumbAlignX: -0.4, thumbAlignY: 0.8, thumbScale: 2.2,
    approvalStatus: 'pending', approvedAt: null, approvedBy: null};
  await assertFails(updateDoc(doc(db('reader'), 'bulletin_posts/post'), patch));
  await assertSucceeds(updateDoc(doc(db('owner'), 'bulletin_posts/post'), patch));
  await assertSucceeds(updateDoc(doc(db('admin'), 'bulletin_posts/post'), {imageUrls: [], imageUrl: '', thumbScale: 1}));
});
test('creating approved posts or forged owners is denied', async () => {
  const ref = doc(db('owner'), 'bulletin_posts/new');
  await assertFails(setDoc(ref, post()));
  await assertFails(setDoc(ref, {...post(), authorId: 'other', approvalStatus: 'pending'}));
  await assertSucceeds(setDoc(ref, {...post(), approvalStatus: 'pending'}));
});
test('view count accepts exactly +1 without piggyback fields', async () => {
  const ref = doc(db('reader'), 'bulletin_posts/post');
  await assertSucceeds(updateDoc(ref, {viewCount: increment(1)}));
  await assertFails(updateDoc(ref, {viewCount: increment(20)}));
  await assertFails(updateDoc(ref, {viewCount: increment(1), extraPermission: true}));
  await assertFails(updateDoc(ref, {viewCount: increment(1), title: deleteField()}));
});

test('sponsor placement is reserved for administrators on create and update', async () => {
  const owner = db('owner');
  await assertFails(setDoc(doc(owner, 'bulletin_posts/forgedSponsor'), {
    ...post(), approvalStatus: 'pending', isSponsored: true, sponsorName: 'Example',
  }));
  const ref = doc(owner, 'bulletin_posts/post');
  await assertFails(updateDoc(ref, {isSponsored: true, sponsorName: 'Example'}));
  await assertFails(updateDoc(ref, {sponsorName: 'Example'}));
  await assertSucceeds(updateDoc(doc(db('admin'), 'bulletin_posts/post'), {
    isSponsored: true, sponsorName: 'スポンサー企業',
  }));
  await assertSucceeds(updateDoc(ref, {
    title: '本文の更新', approvalStatus: 'pending', approvedAt: null, approvedBy: null,
  }));
  await assertFails(updateDoc(ref, {isSponsored: false, sponsorName: ''}));
  await assertFails(updateDoc(ref, {isSponsored: deleteField(), sponsorName: deleteField()}));
  const data = (await getDoc(ref)).data();
  if (data.isSponsored !== true || data.sponsorName !== 'スポンサー企業') throw new Error('Sponsor fields were lost');
});

test('sponsor names are validated and admins can remove the gold placement', async () => {
  const ref = doc(db('admin'), 'bulletin_posts/post');
  await assertFails(updateDoc(ref, {isSponsored: true, sponsorName: ''}));
  await assertFails(updateDoc(ref, {isSponsored: true, sponsorName: 'x'.repeat(81)}));
  await assertFails(updateDoc(ref, {isSponsored: 'true', sponsorName: 'Example'}));
  await assertSucceeds(updateDoc(ref, {isSponsored: true, sponsorName: 'Example'}));
  await assertSucceeds(updateDoc(ref, {isSponsored: false, sponsorName: ''}));
});

test('sponsored ads remain admin-only and optional campaign fields can be cleared', async () => {
  const data = {title: '広告', body: '紹介文', targetType: 'home_top', actionType: 'external',
    actionPayload: 'https://example.com', isActive: true, weight: 1,
    isSponsored: true, sponsorName: 'Example', startAt: new Date(), endAt: new Date()};
  await assertFails(setDoc(doc(db('owner'), 'in_app_ads/ad'), data));
  const ref = doc(db('admin'), 'in_app_ads/ad');
  await assertSucceeds(setDoc(ref, data));
  await assertFails(updateDoc(doc(db('owner'), 'in_app_ads/ad'), {sponsorName: 'Forged'}));
  await assertFails(updateDoc(ref, {sponsorName: ''}));
  await assertSucceeds(updateDoc(ref, {
    isSponsored: false, sponsorName: '', startAt: null, endAt: null, imageUrl: null, ctaText: null,
  }));
});
test('coupon use supports first use and per-user limit', async () => {
  const ref = doc(db('reader'), 'bulletin_posts/post');
  await assertSucceeds(updateDoc(ref, {couponUsedCount: 1, couponUsedBy: {reader: 1}}));
  await assertSucceeds(updateDoc(ref, {couponUsedCount: 2, couponUsedBy: {reader: 2}}));
  await assertFails(updateDoc(ref, {couponUsedCount: 3, couponUsedBy: {reader: 3}}));
});
test('coupon use cannot add, remove or alter another user', async () => {
  await env.withSecurityRulesDisabled(ctx => updateDoc(doc(ctx.firestore(), 'bulletin_posts/post'), {
    couponUsedCount: 1, couponUsedBy: {owner: 1},
  }));
  const ref = doc(db('reader'), 'bulletin_posts/post');
  for (const couponUsedBy of [{reader: 1}, {owner: 2, reader: 1}, {owner: 1, reader: 1, intruder: 1}]) {
    await assertFails(updateDoc(ref, {couponUsedCount: 2, couponUsedBy}));
  }
  await assertSucceeds(updateDoc(ref, {couponUsedCount: 2, couponUsedBy: {owner: 1, reader: 1}}));
});
test('unverified owner may create/read a profile but cannot self-verify', async () => {
  const client = db('new', false);
  const ref = doc(client, 'users/new');
  await assertFails(setDoc(ref, {uid: 'new', emailVerified: true}));
  await assertSucceeds(setDoc(ref, {uid: 'new', email: 'new@s.chibakoudai.jp', emailVerified: false}));
  await assertSucceeds(getDoc(ref));
  await assertFails(updateDoc(ref, {emailVerified: true}));
  await assertFails(updateDoc(ref, {isEmailVerified: true}));
  await assertFails(updateDoc(ref, {email: 'admin@s.chibakoudai.jp'}));
  await assertFails(getDoc(doc(client, 'users/owner')));
});
test('verified token allows an accurate profile mirror', async () => {
  const ref = doc(db('owner'), 'users/owner');
  await assertSucceeds(setDoc(ref, {emailVerified: true, isEmailVerified: true}));
  await assertFails(updateDoc(ref, {emailVerified: false}));
});
test('unverified admin is denied admin data', async () => {
  await assertFails(getDoc(doc(db('admin', false), 'reports/report')));
});

test('device registrations are private to their owner', async () => {
  const device = doc(db('owner'), 'user_tokens/owner/devices/phone');
  await assertSucceeds(setDoc(device, {fcmToken: 'fake-token', platform: 'android', updatedAt: new Date()}));
  await assertFails(getDoc(doc(db('reader'), 'user_tokens/owner/devices/phone')));
  await assertFails(setDoc(doc(db('reader'), 'user_tokens/owner/devices/tablet'), {fcmToken: 'fake'}));
});

test('unverified owner can remove legacy tokens but cannot replace them', async () => {
  await env.withSecurityRulesDisabled(ctx => setDoc(doc(ctx.firestore(), 'user_tokens/owner'), {fcmToken: 'old'}));
  const ref = doc(db('owner', false), 'user_tokens/owner');
  await assertSucceeds(getDoc(ref));
  await assertFails(updateDoc(ref, {fcmToken: 'new'}));
  await assertSucceeds(updateDoc(ref, {fcmToken: deleteField()}));
});
