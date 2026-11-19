const path = require('node:path');
const {readFileSync} = require('node:fs');
const {test, before, after, beforeEach} = require('node:test');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, setDoc} = require('firebase/firestore');
const {ref, uploadBytes, getBytes, updateMetadata, deleteObject} = require('firebase/storage');
let env;
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-cit-contact-chat',
    firestore: {host: '127.0.0.1', port: 8089, rules: readFileSync(path.join(process.env.CONTACT_CHAT_RULES_DIR || '.', 'firestore.rules'), 'utf8')},
    storage: {host: '127.0.0.1', port: 9199, rules: readFileSync(path.join(process.env.CONTACT_CHAT_RULES_DIR || '.', 'storage.rules'), 'utf8')}});
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore(); await env.clearStorage();
  await env.withSecurityRulesDisabled(async ctx => {
    await setDoc(doc(ctx.firestore(), 'admin_permissions/operator'), {isAdmin: true});
    await setDoc(doc(ctx.firestore(), 'admin_permissions/support'), {canViewContacts: true});
  });
});
const ctx = (uid = 'student', verified = true, email = uid + '@s.chibakoudai.jp') =>
  env.authenticatedContext(uid, {email, email_verified: verified});
const imagePath = 'contact_chat_images/student/student/photo/0.jpg';
const bytes = new Uint8Array([255, 216, 255, 217]);
const upload = (context, p = imagePath, b = bytes, contentType = 'image/jpeg') =>
  uploadBytes(ref(context.storage(), p), b, {contentType});

test('only the owner and inquiry operators can read a private image', async () => {
  await assertSucceeds(upload(ctx()));
  await assertSucceeds(getBytes(ref(ctx().storage(), imagePath)));
  await assertSucceeds(getBytes(ref(ctx('operator').storage(), imagePath)));
  await assertSucceeds(getBytes(ref(ctx('support').storage(), imagePath)));
  for (const other of [ctx('other'), ctx('student', false),
    ctx('student', true, 'student@example.com'), env.unauthenticatedContext()]) {
    await assertFails(getBytes(ref(other.storage(), imagePath)));
  }
});
test('operators may attach a reply, but ordinary users cannot upload into another room', async () => {
  await assertSucceeds(upload(ctx('operator'), 'contact_chat_images/student/operator/reply/0.jpg'));
  await assertFails(upload(ctx('other')));
  await assertFails(upload(ctx(), 'contact_chat_images/other/student/photo/0.jpg'));
  await assertFails(upload(ctx(), 'contact_chat_images/student/operator/photo/0.jpg'));
});
test('image type, size, attachment index and immutable content are enforced', async () => {
  await assertFails(upload(ctx(), imagePath, bytes, 'image/svg+xml'));
  await assertFails(upload(ctx(), 'contact_chat_images/student/student/photo/4.jpg'));
  await assertFails(upload(ctx(), imagePath, new Uint8Array(5 * 1024 * 1024 + 1)));
  await assertSucceeds(upload(ctx()));
  await assertFails(upload(ctx())); // No overwrites, including metadata changes.
  await assertFails(updateMetadata(ref(ctx().storage(), imagePath), {contentType: 'text/html'}));
  await assertSucceeds(deleteObject(ref(ctx().storage(), imagePath)));
});
test('deleting accounts lose image access and upload access immediately', async () => {
  await upload(ctx());
  await env.withSecurityRulesDisabled(c => setDoc(doc(c.firestore(), 'account_deletion_jobs/student'), {}));
  await assertFails(getBytes(ref(ctx().storage(), imagePath)));
  await assertFails(upload(ctx(), 'contact_chat_images/student/student/new/0.jpg'));
});