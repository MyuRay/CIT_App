const path = require('node:path');
const {readFileSync} = require('node:fs');
const {test, before, after, beforeEach} = require('node:test');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp} = require('firebase/firestore');
let env;
before(async () => { env = await initializeTestEnvironment({
  projectId: 'demo-cit-contact-chat',
  firestore: {host: '127.0.0.1', port: 8089, rules: readFileSync(path.join(process.env.CONTACT_CHAT_RULES_DIR || '.', 'firestore.rules'), 'utf8')},
}); });
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    await setDoc(doc(ctx.firestore(), 'admin_permissions/operator'), {isAdmin: true});
    await setDoc(doc(ctx.firestore(), 'admin_permissions/support'), {isAdmin: false, canViewContacts: true});
  });
});
const client = (uid = 'student', verified = true, email = uid + '@s.chibakoudai.jp') =>
  env.authenticatedContext(uid, {email, email_verified: verified}).firestore();
const room = (db, uid = 'student') => doc(db, 'contact_chats/' + uid);
const message = (db, id, uid = 'student') => doc(db, 'contact_chats/' + uid + '/messages/' + id);

async function create(db, uid = 'student', {role = 'user', sender = 'student', patch = {}, messagePatch = {}} = {}) {
  const batch = writeBatch(db);
  batch.set(room(db, uid), {userId: uid, displayName: '学生', email: 'student@s.chibakoudai.jp',
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(), lastMessageId: 'first',
    lastMessage: 'こんにちは', lastSenderRole: role, messageCount: 1,
    userMessageCount: 1, adminMessageCount: 0, userReadCount: 0, adminReadCount: 0, status: 'pending', ...patch});
  batch.set(message(db, 'first', uid), {userId: uid, senderId: sender, senderRole: role,
    text: 'こんにちは', sequence: 1, senderSequence: 1, createdAt: serverTimestamp(), ...messagePatch});
  return batch.commit();
}
async function append(db, id, role = 'user', sender = 'student', patch = {}, messagePatch = {}) {
  const current = (await getDoc(room(db))).data();
  const count = role === 'user' ? 'userMessageCount' : 'adminMessageCount';
  const batch = writeBatch(db);
  batch.update(room(db), {updatedAt: serverTimestamp(), lastMessageId: id, lastMessage: '続き',
    lastSenderRole: role, messageCount: current.messageCount + 1,
    [count]: current[count] + 1, status: role === 'user' ? 'pending' : 'in_progress', ...patch});
  batch.set(message(db, id), {userId: 'student', senderId: sender, senderRole: role, text: '続き',
    createdAt: serverTimestamp(), sequence: current.messageCount + 1,
    senderSequence: current[count] + 1, ...messagePatch});
  return batch.commit();
}

test('owner has exactly one room, can send follow-ups, and operators can reply', async () => {
  await assertSucceeds(getDoc(room(client()))); // Empty conversations can be opened.
  await assertSucceeds(create(client()));
  await assertSucceeds(append(client(), 'follow-up'));
  await assertSucceeds(append(client('operator'), 'reply', 'admin', 'operator'));
  await assertSucceeds(getDocs(collection(client(), 'contact_chats/student/messages')));
  await assertFails(create(client(), 'another-room'));
});
test('other users, anonymous, unverified and external accounts cannot read chats', async () => {
  await create(client());
  for (const db of [client('other'), env.unauthenticatedContext().firestore(),
    client('student', false), client('student', true, 'external@example.com')]) {
    await assertFails(getDoc(room(db)));
    await assertFails(getDoc(message(db, 'first')));
    await assertFails(getDocs(collection(db, 'contact_chats/student/messages')));
  }
  await assertFails(getDocs(collection(client(), 'contact_chats')));
  await assertSucceeds(getDocs(collection(client('operator'), 'contact_chats')));
});
test('contact-only operators can read and reply but ordinary users cannot impersonate them', async () => {
  await create(client());
  await assertSucceeds(append(client('support'), 'support-reply', 'admin', 'support'));
  await assertFails(append(client(), 'spoof', 'admin', 'student'));
  await assertFails(append(client(), 'spoof-id', 'user', 'operator'));
});
test('messages cannot be edited, removed or detached from their atomic summary', async () => {
  await create(client());
  await assertFails(updateDoc(message(client(), 'first'), {text: '書き換え'}));
  await assertFails(deleteDoc(message(client('operator'), 'first')));
  await assertFails(deleteDoc(room(client('operator'))));
  await assertFails(setDoc(message(client(), 'orphan'), {userId: 'student', senderId: 'student',
    senderRole: 'user', text: 'x', sequence: 2, senderSequence: 2, createdAt: serverTimestamp()}));
  await assertFails(updateDoc(room(client()), {lastMessage: '偽造'}));
});
test('forged counters, identities and message sequences are rejected', async () => {
  await create(client());
  await assertFails(append(client(), 'counter', 'user', 'student', {userMessageCount: 999}));
  await assertFails(append(client(), 'sequence', 'user', 'student', {}, {sequence: 500}));
  await assertFails(append(client(), 'sender-sequence', 'user', 'student', {}, {senderSequence: 500}));
  await assertFails(updateDoc(room(client()), {email: 'other@s.chibakoudai.jp'}));
  await assertFails(updateDoc(room(client()), {userId: 'other'}));
  await assertFails(updateDoc(room(client()), {createdAt: serverTimestamp()}));
});
test('read markers are independent, monotonic and bounded by actual messages', async () => {
  await create(client());
  await append(client('operator'), 'reply1', 'admin', 'operator');
  await append(client('operator'), 'reply2', 'admin', 'operator');
  await assertSucceeds(updateDoc(room(client()), {userReadCount: 1}));
  await assertFails(updateDoc(room(client()), {userReadCount: 0}));
  await assertFails(updateDoc(room(client()), {userReadCount: 3}));
  await assertFails(updateDoc(room(client()), {adminReadCount: 1}));
  await assertSucceeds(updateDoc(room(client('operator')), {adminReadCount: 1}));
  await assertFails(updateDoc(room(client('operator')), {userReadCount: 2}));
});
test('only operators change status, but follow-ups reopen resolved chats', async () => {
  await create(client());
  await assertFails(updateDoc(room(client()), {status: 'resolved'}));
  await assertSucceeds(updateDoc(room(client('operator')), {status: 'resolved'}));
  await assertSucceeds(append(client(), 'reopen'));
});
test('initial messages must be authentic and within the length limit', async () => {
  await assertFails(create(client(), 'student', {role: 'admin'}));
  await assertFails(create(client(), 'student', {patch: {userReadCount: 3}}));
  await assertFails(create(client(), 'student', {patch: {lastMessage: 'x'.repeat(2001)},
    messagePatch: {text: 'x'.repeat(2001)}}));
});
test('deleting accounts lose both read and send access immediately', async () => {
  await create(client());
  await env.withSecurityRulesDisabled(ctx => setDoc(doc(ctx.firestore(), 'account_deletion_jobs/student'), {}));
  await assertFails(getDoc(room(client())));
  await assertFails(updateDoc(room(client()), {userReadCount: 0}));
});
test('images may be sent without text, but only from this sender and message path', async () => {
  await assertSucceeds(create(client(), 'student', {patch: {lastMessage: '📷 画像'},
    messagePatch: {text: '', imagePaths: ['contact_chat_images/student/student/first/0.jpg']}}));
  await assertFails(append(client(), 'image-spoof', 'user', 'student', {},
    {imagePaths: ['contact_chat_images/other/student/image-spoof/0.jpg']}));
  await assertFails(append(client(), 'public-url', 'user', 'student', {},
    {imagePaths: ['https://example.com/private.jpg']}));
});
const diagnostics = db => doc(db, 'users/student/support_info/client');
const appInfo = () => ({os:'android',osVersion:'15',platform:'android',appVersion:'2.3.3',buildNumber:'42',
  packageName:'jp.ac.chibakoudai.citapp',locale:'ja-JP',updatedAt:serverTimestamp()});
test('app diagnostics are private to the owner and authorized support operators', async () => {
  await assertSucceeds(setDoc(diagnostics(client()),appInfo()));
  await assertSucceeds(getDoc(diagnostics(client())));
  await assertSucceeds(getDoc(diagnostics(client('operator'))));
  await assertSucceeds(getDoc(diagnostics(client('support'))));
  for(const db of [client('other'),client('student',false),env.unauthenticatedContext().firestore()]) {
    await assertFails(getDoc(diagnostics(db)));
  }
  await assertFails(setDoc(diagnostics(client('other')),appInfo()));
  await assertFails(setDoc(diagnostics(client('operator')),appInfo()));
});
test('app diagnostics reject arbitrary private fields and oversized strings', async () => {
  await assertFails(setDoc(diagnostics(client()),{...appInfo(),unrelated:'x'}));
  await assertFails(setDoc(diagnostics(client()),{...appInfo(),osVersion:'x'.repeat(241)}));
  await assertFails(setDoc(diagnostics(client()),{...appInfo(),updatedAt:new Date(0)}));
  await assertFails(setDoc(doc(client(),'users/student/support_info/other'),appInfo()));
});
