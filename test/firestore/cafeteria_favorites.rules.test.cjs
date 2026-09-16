const {readFileSync} = require('node:fs');
const assert = require('node:assert/strict');
const {test, before, after, beforeEach} = require('node:test');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, setDoc, updateDoc, deleteDoc, getDoc, collectionGroup, query, where, getCountFromServer} = require('firebase/firestore');
const admin = require('firebase-admin');
const {targetKey, syncFavoriteCounts, rebuildFavoriteCounts} = require('../../functions/cafeteria_favorites');
let env, app, server;
const curry = {type: 'menu', cafeteriaId: 'tsudanuma', menuItemId: 'curry', menuName: 'カレー'};
const named = {...curry, menuItemId: null};
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-cit-favorites',
    firestore: {host: '127.0.0.1', port: 8089, rules: readFileSync('firestore.rules', 'utf8')},
  });
  app = admin.initializeApp({projectId: 'demo-cit-favorites'}, 'favorite-tests');
  server = app.firestore();
});
after(async () => { await env?.cleanup(); await app?.delete(); });
beforeEach(async () => {
  await env.clearFirestore();
  await server.doc('cafeteria_menu_items/curry').set({cafeteriaId: 'tsudanuma', menuName: 'カレー'});
});
const client = uid => env.authenticatedContext(uid, {email: uid + '@s.chibakoudai.jp', email_verified: true}).firestore();
const favorite = (uid, target = curry) => ({...target, userId: uid, createdAt: new Date()});
const stats = async target => (await server.doc('cafeteria_favorite_stats/' + targetKey(target)).get()).data();

test('private favorites stay private while count-only stats are readable', async () => {
  await assertSucceeds(setDoc(doc(client('u1'), 'users/u1/cafeteria_favorites/a'), favorite('u1')));
  await assertFails(getDoc(doc(client('u2'), 'users/u1/cafeteria_favorites/a')));
  await assertFails(getCountFromServer(query(collectionGroup(client('u2'), 'cafeteria_favorites'), where('menuItemId', '==', 'curry'))));
  await syncFavoriteCounts(server, null, favorite('u1'));
  const publicRef = doc(client('u2'), 'cafeteria_favorite_stats/' + targetKey(curry));
  await assertSucceeds(getDoc(publicRef));
  await assertFails(setDoc(publicRef, {count: 1000}));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'cafeteria_favorite_stats/' + targetKey(curry))));
  assert.deepEqual(Object.keys((await getDoc(publicRef)).data()).sort(), ['count', 'schemaVersion', 'updatedAt']);
});
test('favorites cannot forge an owner on create/update and deletion is idempotent', async () => {
  const ref = doc(client('u1'), 'users/u1/cafeteria_favorites/a');
  await assertFails(setDoc(ref, favorite('u2')));
  await assertSucceeds(setDoc(ref, favorite('u1')));
  await assertFails(updateDoc(ref, {userId: 'u2'}));
  await assertFails(deleteDoc(doc(client('u2'), 'users/u1/cafeteria_favorites/a')));
  await assertSucceeds(deleteDoc(ref));
  await assertSucceeds(deleteDoc(ref));
});
test('counts deduplicate users across old auto-IDs and name-only favorites', async () => {
  await server.doc('users/u1/cafeteria_favorites/a').set(favorite('u1'));
  await server.doc('users/u1/cafeteria_favorites/b').set(favorite('u1', named));
  await server.doc('users/u2/cafeteria_favorites/a').set(favorite('u2', named));
  await server.doc('users/u3/cafeteria_favorites/a').set(favorite('u3', {...named, menuName: 'ラーメン'}));
  await server.doc('users/u4/cafeteria_favorites/a').set(favorite('u4', {...named, cafeteriaId: 'narashino_1f'}));
  await syncFavoriteCounts(server, null, named);
  assert.equal((await stats(curry)).count, 2);
  assert.equal((await stats(named)).count, 2);
});
test('duplicate, delayed and deletion events recount the current truth', async () => {
  await server.doc('users/u1/cafeteria_favorites/a').set(favorite('u1'));
  await server.doc('users/u1/cafeteria_favorites/b').set(favorite('u1'));
  await server.doc('users/u2/cafeteria_favorites/a').set(favorite('u2'));
  await syncFavoriteCounts(server, null, curry);
  await server.doc('users/u1/cafeteria_favorites/a').delete();
  await syncFavoriteCounts(server, curry, null);
  assert.equal((await stats(curry)).count, 2);
  await server.doc('users/u1/cafeteria_favorites/b').delete();
  await syncFavoriteCounts(server, null, curry);
  await syncFavoriteCounts(server, null, curry);
  assert.equal((await stats(curry)).count, 1);
  await server.doc('users/u2/cafeteria_favorites/a').delete();
  await syncFavoriteCounts(server, curry, null);
  assert.equal((await stats(curry)).count, 0);
});
test('backfill initializes legacy and zero-count menus and dry run does not write', async () => {
  await server.doc('cafeteria_menu_items/ramen').set({cafeteriaId: 'tsudanuma', menuName: 'ラーメン'});
  await server.doc('users/u1/cafeteria_favorites/legacy').set(favorite('u1', named));
  const preview = await rebuildFavoriteCounts(server);
  assert.equal(preview.written, false);
  assert.equal((await server.collection('cafeteria_favorite_stats').get()).size, 0);
  await rebuildFavoriteCounts(server, {write: true});
  assert.equal((await stats(curry)).count, 1);
  assert.equal((await stats({...curry, menuItemId: 'ramen', menuName: 'ラーメン'})).count, 0);
});
test('renamed menu ID keeps its favorite count and new name-only favorites join it', async () => {
  await server.doc('users/u1/cafeteria_favorites/a').set(favorite('u1'));
  const renamed = {...curry, menuName: '特製カレー'};
  await server.doc('cafeteria_menu_items/curry').update({menuName: renamed.menuName});
  await server.doc('users/u2/cafeteria_favorites/a').set(favorite('u2', {...renamed, menuItemId: null}));
  await syncFavoriteCounts(server, curry, renamed);
  assert.equal((await stats(renamed)).count, 2);
});
