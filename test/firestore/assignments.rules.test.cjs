const {readFileSync} = require('node:fs');
const {test, before, after, beforeEach} = require('node:test');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, getDocs, collection, updateDoc, deleteDoc, serverTimestamp, Timestamp} = require('firebase/firestore');
let env;
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-cit-assignments', firestore: {
    host: '127.0.0.1', port: 8089, rules: readFileSync('firestore.rules', 'utf8')}});
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => env.clearFirestore());
const db = (uid, verified = true, email = `${uid}@chibatech.ac.jp`) => env.authenticatedContext(uid, {email, email_verified: verified}).firestore();
const task = () => ({title: 'レポート', notes: '', dueAt: Timestamp.fromDate(new Date('2026-09-20T12:00:00Z')),
  hasDueTime: true, course: null, isCompleted: false, createdAt: serverTimestamp(), updatedAt: serverTimestamp()});
test('verified owner can create, list, edit, complete and delete', async () => {
  const owner = db('owner');
  const ref = doc(owner, 'users/owner/assignments/task');
  await assertSucceeds(setDoc(ref, task()));
  await assertSucceeds(getDocs(collection(owner, 'users/owner/assignments')));
  await assertSucceeds(updateDoc(ref, {title: '改訂版', isCompleted: true, updatedAt: serverTimestamp()}));
  await assertSucceeds(updateDoc(ref, {title: '第1回\nレポート', updatedAt: serverTimestamp()}));
  await assertSucceeds(deleteDoc(ref));
});
test('other users, administrators, anonymous, unverified and external users are denied', async () => {
  await setDoc(doc(db('owner'), 'users/owner/assignments/task'), task());
  await env.withSecurityRulesDisabled(ctx => setDoc(doc(ctx.firestore(), 'admin_permissions/admin'), {isAdmin: true}));
  for (const client of [db('other'), db('admin'), env.unauthenticatedContext().firestore(),
    db('owner', false), db('owner', true, 'owner@example.org')]) {
    const ref = doc(client, 'users/owner/assignments/task');
    await assertFails(getDoc(ref));
    await assertFails(getDocs(collection(client, 'users/owner/assignments')));
    await assertFails(setDoc(doc(client, 'users/owner/assignments/new'), task()));
    await assertFails(updateDoc(ref, {isCompleted: true, updatedAt: serverTimestamp()}));
    await assertFails(deleteDoc(ref));
  }
});
test('malformed data, forged timestamps and extra fields are denied', async () => {
  const ref = doc(db('owner'), 'users/owner/assignments/task');
  for (const patch of [{title: ''}, {title: ' '}, {title: 'x'.repeat(121)}, {notes: 'x'.repeat(4001)},
    {dueAt: 'tomorrow'}, {hasDueTime: 'yes'}, {isCompleted: 1}, {extra: true},
    {course: {scheduleId: 'foreign'}}, {createdAt: Timestamp.fromMillis(0)}, {updatedAt: Timestamp.fromMillis(0)}]) {
    await assertFails(setDoc(ref, {...task(), ...patch}));
  }
  await assertSucceeds(setDoc(ref, task()));
  await assertFails(updateDoc(ref, {createdAt: Timestamp.fromMillis(0), updatedAt: serverTimestamp()}));
});
test('lecture metadata is retained independently of timetable deletion', async () => {
  const ref = doc(db('owner'), 'users/owner/assignments/task');
  await assertSucceeds(setDoc(ref, {...task(), course: {scheduleId: 'schedule', classId: 'lecture', subjectName: '情報工学', semester: '2026年度後期'}}));
  await assertSucceeds(updateDoc(ref, {course: null, updatedAt: serverTimestamp()}));
});
