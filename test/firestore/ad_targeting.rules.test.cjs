const {readFileSync} = require('node:fs');
const {test, before, after, beforeEach} = require('node:test');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, collection, getDocs, setDoc, updateDoc, deleteDoc, serverTimestamp, Timestamp} = require('firebase/firestore');
let env;
before(async () => {env = await initializeTestEnvironment({projectId:'demo-cit-ad-targeting', firestore:{host:'127.0.0.1',port:8089,rules:readFileSync('firestore.rules','utf8')}});});
after(async () => {if(env) await env.cleanup();});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    await setDoc(doc(ctx.firestore(),'admin_permissions/admin'),{isAdmin:true});
    await setDoc(doc(ctx.firestore(),'in_app_ads/ad1'),ad());
  });
});
const client = (uid='student', email='26c1001@chibatech.ac.jp', verified=true) => env.authenticatedContext(uid,{email,email_verified:verified}).firestore();
const ad = (patch={}) => ({title:'広告',body:'本文',targetType:'home_top',actionType:'external',actionPayload:'https://example.com',isActive:true,weight:1,targetGrades:['1'],...patch});
const event = (patch={}) => ({adId:'ad1',placement:'home_top',grade:'1',kind:'click',slotIndex:0,createdAt:serverTimestamp(),...patch});
const save = (db, patch={}) => setDoc(doc(db,'ad_events/event1'),event(patch));

test('verified CIT clients create events; only admins read them',async()=>{
  await assertSucceeds(save(client()));
  await assertSucceeds(getDocs(collection(client('admin'),'ad_events')));
  await assertFails(getDocs(collection(client(),'ad_events')));
  await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(),'ad_events')));
});
test('anonymous, external, unverified and deleting accounts cannot create events',async()=>{
  await env.withSecurityRulesDisabled(ctx=>setDoc(doc(ctx.firestore(),'account_deletion_jobs/deleting'),{}));
  for(const db of [env.unauthenticatedContext().firestore(),client('external','x@example.com'),client('unverified',undefined,false),client('deleting')]) await assertFails(save(db));
});
test('event schema prevents PII, invalid attributes and arbitrary timestamps',async()=>{
  for(const patch of [{email:'private@chibatech.ac.jp'},{uid:'student'},{grade:'6'},{grade:'2'},{kind:'view'},{slotIndex:-1},{slotIndex:100000},{slotIndex:1.5},{placement:'cafeteria'},{adId:'missing'},{createdAt:Timestamp.fromMillis(1)}]) await assertFails(save(client(),patch));
});
test('events are immutable even for administrators',async()=>{
  await save(client());
  for(const db of [client(),client('admin')]) {
    await assertFails(updateDoc(doc(db,'ad_events/event1'),{grade:'2'}));
    await assertFails(deleteDoc(doc(db,'ad_events/event1')));
  }
});
test('inactive, expired and future ads do not accept events',async()=>{
  for(const patch of [{isActive:false},{endAt:Timestamp.fromMillis(1)},{startAt:Timestamp.fromMillis(4102444800000)}]) {
    await env.withSecurityRulesDisabled(ctx=>setDoc(doc(ctx.firestore(),'in_app_ads/ad1'),ad(patch)));
    await assertFails(save(client()));
  }
});
test('only admins edit targeting; missing grades retains legacy untargeted behavior',async()=>{
  await assertFails(updateDoc(doc(client(),'in_app_ads/ad1'),{targetGrades:['2']}));
  await assertSucceeds(updateDoc(doc(client('admin'),'in_app_ads/ad1'),{targetGrades:['2','4','unknown']}));
  await assertSucceeds(save(client(),{grade:'unknown'}));
  for(const targetGrades of [['6'],'1',null,[1],['1','1','1','1','1','1','1']]) await assertFails(updateDoc(doc(client('admin'),'in_app_ads/ad1'),{targetGrades}));
  await assertSucceeds(updateDoc(doc(client('admin'),'in_app_ads/ad1'),{targetGrades:[]}));
  await assertSucceeds(setDoc(doc(client(),'ad_events/all'),event({grade:'3'})));
  const legacy = ad(); delete legacy.targetGrades;
  await env.withSecurityRulesDisabled(ctx=>setDoc(doc(ctx.firestore(),'in_app_ads/ad1'),legacy));
  await assertSucceeds(setDoc(doc(client(),'ad_events/legacy'),event({grade:'4'})));
});
