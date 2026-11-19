'use strict';
const {onCall,HttpsError}=require('firebase-functions/v2/https');
const {initializeApp,getApps}=require('firebase-admin/app');
const {getFirestore}=require('firebase-admin/firestore');
const {createGame,GameError}=require('./core.cjs');
if(!getApps().length)initializeApp();
const db=getFirestore();
const store=require('./store.cjs')(db);
const execute=createGame({store,courses:require('./courses.json')});
exports.campusGame=onCall({region:'us-central1',maxInstances:10,timeoutSeconds:30},async request=>{try{if(JSON.stringify(request.data).length>16000)throw new GameError('invalid-argument','Request too large');return await execute(request.auth?.uid,request.data);}catch(error){if(error instanceof GameError)throw new HttpsError(error.code,error.message);console.error('campusGame failure',error.code||error.name);throw new HttpsError('internal','Game service unavailable');}});

const {onSchedule}=require('firebase-functions/v2/scheduler');
exports.campusGameCleanup=onSchedule({region:'us-central1',schedule:'every 60 minutes',timeoutSeconds:120,maxInstances:1},async()=>{for(let i=0;i<10;i++){const expired=await db.collectionGroup('items').where('campusGameExpiresAt','<=',new Date()).limit(500).get();if(expired.empty)return;const batch=db.batch();for(const doc of expired.docs){if(doc.ref.path.startsWith('campusGamePrivate/'))batch.delete(doc.ref);}await batch.commit();if(expired.size<500)return;}});
