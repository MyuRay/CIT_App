'use strict';
const {createHash} = require('node:crypto');
const normalize = value => typeof value === 'string' ? value.trim().toLowerCase() : '';
const text = value => typeof value === 'string' ? value.trim() : '';

function targetKey(target) {
  const parts = target.type === 'cafeteria' ? ['cafeteria', target.cafeteriaId]
    : text(target.menuItemId) ? ['menu', text(target.menuItemId)]
      : ['menu-name', target.cafeteriaId, normalize(target.menuName)];
  return target.type + '_' + createHash('sha256').update(JSON.stringify(parts)).digest('hex');
}
function targetsFromData(data) {
  if (!data || !['menu', 'cafeteria'].includes(data.type)) return [];
  const target = {type: data.type, cafeteriaId: text(data.cafeteriaId),
    menuItemId: text(data.menuItemId), menuName: text(data.menuName)};
  if (target.type === 'cafeteria') return target.cafeteriaId ? [target] : [];
  const targets = [];
  if (target.menuItemId) targets.push(target);
  if (target.cafeteriaId && target.menuName) targets.push({...target, menuItemId: ''});
  return targets;
}
function matchesTarget(data, target) {
  if (data?.type !== target.type) return false;
  if (target.type === 'cafeteria') return data.cafeteriaId === target.cafeteriaId;
  if (text(target.menuItemId) && text(data.menuItemId)) return text(data.menuItemId) === text(target.menuItemId);
  return !!target.cafeteriaId && data.cafeteriaId === target.cafeteriaId &&
    !!normalize(target.menuName) && normalize(data.menuName) === normalize(target.menuName);
}
function countUniqueUsers(documents, target) {
  const users = new Set();
  for (const doc of documents) {
    const path = doc.ref.path.split('/');
    if (path.length !== 4 || path[0] !== 'users' || path[2] !== 'cafeteria_favorites') continue;
    const data = doc.data();
    if (data.userId === path[1] && matchesTarget(data, target)) users.add(path[1]);
  }
  return users.size;
}
async function resolveTargets(db, records) {
  const targets = new Map();
  const add = t => targets.set(targetKey(t), t);
  for (const record of records) {
    for (const target of targetsFromData(record)) {
      add(target);
      if (target.type !== 'menu') continue;
      if (target.menuItemId && !target.menuItemId.includes('/')) {
        const item = await db.collection('cafeteria_menu_items').doc(target.menuItemId).get();
        if (item.exists) {
          const data = item.data();
          const current = {...target, cafeteriaId: text(data.cafeteriaId), menuName: text(data.menuName)};
          add(current);
          if (current.cafeteriaId && current.menuName) add({...current, menuItemId: ''});
        }
      } else if (!target.menuItemId && target.cafeteriaId) {
        const items = await db.collection('cafeteria_menu_items').where('cafeteriaId', '==', target.cafeteriaId).get();
        for (const item of items.docs) {
          if (normalize(item.data().menuName) === normalize(target.menuName)) add({...target, menuItemId: item.id});
        }
      }
    }
  }
  return [...targets.values()];
}
async function recountTarget(db, target) {
  const ref = db.collection('cafeteria_favorite_stats').doc(targetKey(target));
  return db.runTransaction(async transaction => {
    // Serialize writers on the stats document; delayed/repeated events recount
    // current data instead of applying non-idempotent +/- deltas.
    await transaction.get(ref);
    const group = db.collectionGroup('cafeteria_favorites').where('type', '==', target.type);
    const queries = [];
    if (target.type === 'menu' && target.menuItemId) queries.push(group.where('menuItemId', '==', target.menuItemId));
    if (target.cafeteriaId) queries.push(group.where('cafeteriaId', '==', target.cafeteriaId));
    const docs = [];
    for (const query of queries) docs.push(...(await transaction.get(query)).docs);
    const count = countUniqueUsers(docs, target);
    transaction.set(ref, {count, updatedAt: new Date(), schemaVersion: 1});
    return count;
  });
}
async function syncFavoriteCounts(db, before, after) {
  const targets = await resolveTargets(db, [before, after]);
  for (const target of targets) await recountTarget(db, target);
  return targets.length;
}
async function rebuildFavoriteCounts(db, {write = false} = {}) {
  const [items, favorites] = await Promise.all([
    db.collection('cafeteria_menu_items').get(),
    db.collectionGroup('cafeteria_favorites').get(),
  ]);
  const targets = new Map();
  for (const item of items.docs) {
    for (const target of targetsFromData({...item.data(), type: 'menu', menuItemId: item.id})) targets.set(targetKey(target), target);
  }
  for (const favorite of favorites.docs) {
    for (const target of targetsFromData(favorite.data())) {
      // Prefer current menu names from the menu collection for an ID target.
      if (!targets.has(targetKey(target))) targets.set(targetKey(target), target);
    }
  }
  if (write) for (const target of targets.values()) await recountTarget(db, target);
  return {menus: items.size, favoriteRecords: favorites.size, aggregateDocuments: targets.size, written: write};
}
module.exports = {targetKey, targetsFromData, matchesTarget, countUniqueUsers,
  resolveTargets, recountTarget, syncFavoriteCounts, rebuildFavoriteCounts};
