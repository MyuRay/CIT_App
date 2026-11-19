import {raceFeedback,showCelebration} from './drive_feedback.mjs';
import {TraceBuffer} from './trace_buffer.mjs';
import * as THREE from 'three';
import {courseFromRoute,TimeAttack,validBest,formatRaceTime} from './time_attack.mjs';
import {makeBus} from './vehicles.mjs';
// Local times never become public records. Online runs begin with a server challenge.
export function createBusGame({world,motion,scene,stop,setMode,notifyHost,onActor}){
 const racePanel=document.querySelector('#race-panel'),timer=document.querySelector('#race-time'),info=document.querySelector('#race-info'),best=document.querySelector('#race-best');
 const bests=new Map(),requests=new Map(),uploadWaiters=[],ghosts=new Map(),processedChallenges=new Set();let sequence=0,online=null,lastUpload=0,alive=true,saveNotice='',storageNotice='',lastPhase='',markers,lastRoom=null,uploading=false,finishQueued=false,recovering=false,recoveryRequired=false,recoveryAllowed=false,lastRecovery=-Infinity;
 const race=new TimeAttack({onFinish:result=>{
  stop();const old=bests.get(result.key);showCelebration((!validBest(old)||result.milliseconds<old?'自己ベスト更新！':'ゴール！ ナイスラン！')+'\n'+formatRaceTime(result.milliseconds),{goal:true,reducedMotion:world().reducedMotion===true});if(!validBest(old)||result.milliseconds<old){bests.set(result.key,result.milliseconds);storageNotice='';try{localStorage.setItem(result.key,String(result.milliseconds));}catch{storageNotice='端末への保存不可';}notifyHost(JSON.stringify({type:'campus-bus-best',...result}));}
  if(online)upload(true);render();
 }});
 function course(){return courseFromRoute(world().selectedRoute);}
 function request(action,payload={}){return new Promise((resolve,reject)=>{const requestId=`bus-${++sequence}`,sentAt=performance.now();const timeout=setTimeout(()=>{requests.delete(requestId);reject(new Error('通信がタイムアウトしました'));},12000);requests.set(requestId,{resolve,reject,timeout,sentAt});notifyHost(JSON.stringify({type:'campus-game',requestId,action,payload}));});}
 function clearGhosts(){for(const g of ghosts.values()){scene.remove(g.actor);g.actor.traverse(o=>{o.geometry?.dispose();o.material?.map?.dispose();o.material?.dispose();});}ghosts.clear();}
 function cancel(reason='走行を中断しました'){recoveryAllowed=false;recoveryRequired=false;clearGhosts();race.cancel(reason);finishQueued=false;if(online){online.buffer.clearPending();const id=online.challengeId;online=null;request('cancelChallenge',{challengeId:id}).catch(()=>{});}render();}
 function clearMarkers(){if(!markers)return;scene.remove(markers);markers.traverse(o=>{o.geometry?.dispose();o.material?.map?.dispose();o.material?.dispose();});markers=null;}
 function drawMarkers(c){clearMarkers();markers=new THREE.Group();for(const [i,p]of c.checkpoints.entries()){const ring=new THREE.Mesh(new THREE.TorusGeometry(i===c.checkpoints.length-1?8:5,.12,4,24),new THREE.MeshBasicMaterial({color:i===c.checkpoints.length-1?0x18a468:0xffb61e}));ring.rotation.x=Math.PI/2;ring.position.set(p.x,(c.layerAware?p.y:world().roadIndex?.surface(p.x,p.z,null,'bus')?.height??world().terrainHeight(p.x,p.z)??0)+.4,p.z);markers.add(ring);}scene.add(markers);}
 function prepare(direction){recoveryRequired=false;cancel('新しい走行を開始');world().setRoute(direction);const c=course(),s=c.segments[0],y=world().roadIndex?.surface(c.start.x,c.start.z,null,'bus')?.height??world().terrainHeight(c.start.x,c.start.z);if(y==null)throw new Error('スタート地点を読み込めません');world().busSpawn={x:c.start.x,y:y+1.4,z:c.start.z};world().busYaw=Math.atan2(-(s.b[0]-s.a[0]),-(s.b[1]-s.a[1]));setMode('bus');motion().reset();onActor();drawMarkers(c);return c;}
 function start(direction=world().selectedRoute.id,challenge=null){
  const c=prepare(direction);let starts=performance.now()+3000;
  if(challenge){if(challenge.courseKey!==c.key||!Number.isFinite(challenge.startAt)||!Number.isFinite(challenge.serverNow))throw new Error('コースの版が一致しません');starts=performance.now()+challenge.startAt-challenge.serverNow-(challenge.rtt??0)/2;if(starts<performance.now()-250)throw new Error('開始時刻を過ぎました');processedChallenges.add(challenge.challengeId);online={challengeId:challenge.challengeId,roomId:challenge.roomId,serverStart:challenge.startAt,localStart:starts,lastSampleT:0,buffer:new TraceBuffer()};}
  race.arm(c,{...motion().position},starts);recoveryAllowed=true;lastUpload=performance.now();saveNotice='';render();
 }
 function select(direction){stop();cancel('コースを変更しました');world().setRoute(direction);if(world().experience==='game'){motion().reset();onActor();}clearMarkers();render();}
 function suspendTrace(error){if(!online)return;online.buffer.clearPending();if(world().experience==='game'){recoveryRequired=true;recoveryAllowed=true;if(race.phase==='finished')race.phase='invalid';finishQueued=false;stop();saveNotice=`サーバー確認を停止：${error.message}。復帰で再開できます。`;}else{saveNotice=error.message;cancel(error.message);}render();}
 function captureSample(force=false){if(!online||recovering||recoveryRequired||!['running','finished'].includes(race.phase))return;const p=motion().position;try{online.buffer.capture(performance.now(),online.localStart,{x:p.x,z:p.z,y:p.y+(motion().mode==='car'?.6:0)},{force,layerAware:course().layerAware});}catch(error){suspendTrace(error);}}
 async function upload(finish=false,drainForRecovery=false){
  if(!online||recoveryRequired||(recovering&&!drainForRecovery))return;if(finish)finishQueued=true;
  captureSample(finish);if(!online||recoveryRequired||uploading||performance.now()-lastUpload<300)return;
  // A final request includes every remaining captured point plus a fresh goal position.
  if(finishQueued)captureSample(true);if(recoveryRequired)return;
  const active=online,id=active.challengeId;let samples;try{samples=active.buffer.take(performance.now());}catch(error){suspendTrace(error);return;}
  if(!samples.length)return;const final=finishQueued&&active.buffer.size===0;uploading=true;lastUpload=performance.now();online.lastSampleT=samples.at(-1).t;
  try{const response=await request('trace',{challengeId:id,samples,...(final?{finish:true}:{})});if(online!==active)return;if(response.room)updateRoom(response.room);if(final){saveNotice=response.finished?`サーバー確認済み ${formatRaceTime(response.elapsedMs)} ・ 公開設定に従う`:'サーバーで完走を確認できませんでした';finishQueued=false;online=null;}}
  catch(error){if(online===active)suspendTrace(error);}
  finally{lastUpload=performance.now();uploading=false;for(const resolve of uploadWaiters.splice(0))resolve();}
  render();if(alive&&online&&!recovering&&!recoveryRequired)upload();
 }
 async function recover(){
  if(world().experience!=='game'||!recoveryAllowed||recovering||!['running','invalid'].includes(race.phase)||performance.now()-lastRecovery<2000)return false;
  recovering=true;stop();finishQueued=false;render();const id=online?.challengeId;
  try{
   // A pending trace is allowed to settle before the server chooses its checkpoint.
   if(uploading){saveNotice='走行の確認完了を待って復帰しています…';render();await new Promise(resolve=>uploadWaiters.push(resolve));}if(!alive||!recoveryAllowed||!['running','invalid'].includes(race.phase)||(id&&online?.challengeId!==id))return false;
   // Preserve valid captured movement before choosing the latest server-accepted checkpoint.
   // Rejected/stale traces set recoveryRequired and discard their unvalidated queue instead.
   while(online&&online.challengeId===id&&online.buffer.size&&!recoveryRequired){
    const wait=Math.max(0,300-(performance.now()-lastUpload));if(wait)await new Promise(resolve=>setTimeout(resolve,wait));
    if(!alive||!recoveryAllowed||online?.challengeId!==id)return false;
    await upload(false,true);
   }
   if(!alive||!recoveryAllowed||!['running','invalid'].includes(race.phase)||(id&&online?.challengeId!==id))return false;
   online?.buffer.clearPending();
   let progress,position,yaw,penalty,recoveryTooLate=false;
   if(online){const result=await request('recover',{challengeId:id});if(online?.challengeId!==id)return false;progress=result.progress;position={x:result.position.x,z:result.position.z,y:result.position.y+1.4};yaw=result.yaw+Math.PI;penalty=result.penaltyMs;online.lastSampleT=result.t;recoveryTooLate=Math.round(performance.now()-online.localStart)-result.t>5000;online.buffer.reset({baselineT:result.t,now:performance.now()});lastUpload=performance.now();if(result.room)updateRoom(result.room);}
   else{progress=Math.floor(race.progress/150)*150;const c=course(),point=c.pointAt(progress),next=c.pointAt(Math.min(c.length,progress+1));position={x:point.x,z:point.z,y:point.y+1.4};yaw=Math.atan2(-(next.x-point.x),-(next.z-point.z));penalty=race.penaltyMs+5000;}
   world().setProgress?.(progress);motion().position={...position,y:position.y-(motion().mode==='car'?.6:0)};motion().yaw=yaw;motion().stop();race.recover(position,progress,penalty);recoveryRequired=false;lastRecovery=performance.now();
   if(recoveryTooLate){recoveryRequired=true;race.cancel('復帰の応答が5秒以上遅れたため再開を停止しました');saveNotice=`復帰料金は適用済み（合計 ${penalty/1000}秒）。再度復帰してください。`;onActor();return false;}
   // Observe the actual restored pose now. Preserve the original challenge clock; never backfill unseen samples.
   if(online)online.buffer.capture(performance.now(),online.localStart,{x:motion().position.x,z:motion().position.z,y:motion().position.y+(motion().mode==='car'?.6:0)},{force:true,layerAware:course().layerAware});
   saveNotice=`コースへ復帰 +5秒（合計 ${penalty/1000}秒）`;onActor();return true;
  }catch(error){saveNotice=`復帰できませんでした：${error.message}`;return false;}finally{recovering=false;render();}
 }
 function updateGhostName(ghost,value){
  const nickname=String(value??'Player');if(ghost.nickname===nickname)return;ghost.nickname=nickname;
  if(!ghost.nameTexture&&document.createElement){const label=document.createElement('canvas');label.width=256;label.height=48;const ctx=label.getContext('2d');if(ctx){ghost.nameContext=ctx;ghost.nameTexture=new THREE.CanvasTexture(label);const badge=new THREE.Sprite(new THREE.SpriteMaterial({map:ghost.nameTexture,transparent:true,depthTest:false}));badge.scale.set(6,1.13,1);badge.position.y=4;ghost.actor.add(badge);}}
  const ctx=ghost.nameContext;if(ctx){ctx.clearRect(0,0,256,48);ctx.fillStyle='#14324ddd';ctx.fillRect(0,0,256,48);ctx.fillStyle='white';ctx.font='24px system-ui';ctx.textAlign='center';ctx.fillText(nickname,128,33,240);ghost.nameTexture.needsUpdate=true;}
 }
 function updateRoom(room,rtt=0){
  if(!room)return;lastRoom=room;document.querySelector('#race-online').textContent=room.status==='finished'?'対戦結果':'ランキング・対戦';const me=room.players?.find(p=>p.self||p.challengeId);if(me?.status==='left'||(race.phase==='invalid'&&processedChallenges.has(me?.challengeId)&&(world().experience!=='game'||!online))){clearGhosts();return;}if(room.status==='racing'&&me?.challengeId&&me.status==='racing'&&!processedChallenges.has(me.challengeId)){processedChallenges.add(me.challengeId);try{start(room.direction,{...room,challengeId:me.challengeId,roomId:room.roomId,rtt});}catch(e){saveNotice=e.message;cancel(e.message);}}
  const active=new Set();for(const player of room.players??[]){if(player.challengeId||player.status==='left')continue;if(!player.position||!Number.isFinite(player.position.x)||!Number.isFinite(player.position.z))continue;active.add(player.playerId);let ghost=ghosts.get(player.playerId);if(!ghost){const actor=makeBus();actor.traverse(o=>{if(o.material){o.material=o.material.clone();o.material.transparent=true;o.material.opacity=.45;}});scene.add(actor);ghost={actor,target:new THREE.Vector3(),yaw:0};ghosts.set(player.playerId,ghost);}updateGhostName(ghost,player.nickname);const pos=player.position;ghost.target.set(pos.x,(world().experience==='game'&&Number.isFinite(pos.y)?pos.y-1.4:world().roadIndex?.surface(pos.x,pos.z,null,'bus')?.height??world().terrainHeight(pos.x,pos.z)??0),pos.z);if(!ghost.initialized){ghost.actor.position.copy(ghost.target);ghost.initialized=true;}ghost.yaw=Number.isFinite(player.yaw)?player.yaw+Math.PI:ghost.yaw;}
  for(const [id,g]of ghosts)if(!active.has(id)){scene.remove(g.actor);g.actor.traverse(o=>{o.geometry?.dispose();o.material?.map?.dispose();o.material?.dispose();});ghosts.delete(id);}
 }
 function gameOnline(event){if(typeof event==='string'){try{event=JSON.parse(event);}catch{return;}}if(event?.type==='campus-best-save'){if(event.key===race.course?.key){storageNotice=event.ok?'':'端末への保存失敗（この画面内の記録のみ）';render();}return;}const pending=requests.get(event?.requestId);if(pending){requests.delete(event.requestId);clearTimeout(pending.timeout);if(event.error)pending.reject(new Error(event.error.message??event.error));else pending.resolve(event.result??event.data??event.response??{});return;}
  const room=event?.type==='campus-game-session'?event.data:event?.session?.room??event?.session??event?.room;if(room?.players)updateRoom(room,event.rtt??0);if(event?.type==='campus-game-session'&&!event.data){lastRoom=null;document.querySelector('#race-online').textContent='ランキング・対戦';cancel('ルームを退出しました');for(const g of ghosts.values()){scene.remove(g.actor);g.actor.traverse(o=>{o.geometry?.dispose();o.material?.map?.dispose();o.material?.dispose();});}ghosts.clear();}const challenge=event?.challenge??(event?.action==='challenge'&&event?.ok?event.data:null);if(challenge&&!processedChallenges.has(challenge.challengeId)){processedChallenges.add(challenge.challengeId);try{start(event.direction??world().selectedRoute.id,challenge);}catch(e){saveNotice=e.message;render();}}if(event?.type==='campus-game-leave')cancel('ルームを退出しました');
 }
 function render(){const speed=document.querySelector('#race-speed'),progress=document.querySelector('#race-progress');if(speed)speed.textContent=Math.round(Math.abs(motion()?.speed??0)*3.6)+' km/h';if(progress)progress.value=race.course?.length?Math.min(100,race.progress/race.course.length*100):0;racePanel.hidden=motion()?.mode!=='bus'&&!(world().experience==='game'&&motion()?.mode==='car');const c=world()?.selectedRoute?course():null;if(!c)return;const old=bests.get(c.key);timer.textContent=race.phase==='countdown'?`${race.countdown}…`:formatRaceTime(race.elapsed);info.textContent=race.phase==='running'?`CP ${race.nextCheckpoint}/${race.course.checkpoints.length}`:race.phase==='finished'?'ゴール！':race.phase==='invalid'?race.reason:'練習・端末記録';best.textContent=`自己ベスト ${formatRaceTime(old)}${[saveNotice,storageNotice].filter(Boolean).length?' · '+[saveNotice,storageNotice].filter(Boolean).join(' / '):''}`;const recovery=document.querySelector('#race-recover');if(recovery){recovery.hidden=world().experience!=='game';recovery.disabled=!recoveryAllowed||recovering||!['running','invalid'].includes(race.phase)||performance.now()-lastRecovery<2000;}if(recoveryRequired)info.textContent='復帰でサーバー確認を再開';if(recovering)info.textContent='確認完了を待って復帰しています…';document.querySelector('#race-start').disabled=race.phase==='countdown'||race.phase==='running';}
 function tick(dt){if(!alive)return;const previous=race.phase,beforeCheckpoint=race.nextCheckpoint;race.tick({...motion().position,y:motion().position.y+(world().experience==='game'&&motion().mode==='car'?.6:0)},{mode:motion().mode,foreground:!document.hidden,onCourse:world().terrainHeight(motion().position.x,motion().position.z,motion().position.y,'bus')!=null});const feedback=raceFeedback(previous,race.phase,beforeCheckpoint,race.nextCheckpoint);if(feedback)showCelebration(feedback,{reducedMotion:world().reducedMotion===true});if(race.phase==='running'||race.phase==='finished'&&online){captureSample();upload();}if(previous!==race.phase&&race.phase==='invalid'){if(world().experience==='game'){recoveryRequired=Boolean(online);stop();}else cancel(race.reason);}for(const g of ghosts.values()){g.actor.position.lerp(g.target,1-Math.exp(-dt*6));g.actor.rotation.y=g.yaw;}render();lastPhase=race.phase;}
 function setRaceBests(values){for(const [key,value]of Object.entries(values??{}))if(/^(cit_bus_best_v1_(outward|return)|cit_bus_best_v2_pop_(outward|return|s_bay|neon_city))_[0-9a-f]{8}$/.test(key)&&validBest(value))bests.set(key,value);render();}
 for(const r of world().data.routes){const key=courseFromRoute(r).key;try{const value=Number(localStorage.getItem(key));if(validBest(value))bests.set(key,value);}catch{}}
 document.querySelector('#race-recover')?.addEventListener('click',()=>recover());
 document.querySelector('#race-start').addEventListener('click',()=>start());document.querySelector('#race-cancel').addEventListener('click',()=>cancel('中断しました'));
 document.querySelector('#race-online').addEventListener('click',()=>notifyHost(JSON.stringify({type:'campus-game-open',direction:world().selectedRoute.id})));
 return{start,select,cancel,recover,tick,gameOnline,setRaceBests,get state(){return{...race.state,best:bests.get(race.course?.key),online:Boolean(online),pendingSamples:online?.buffer.size??0,roomStatus:lastRoom?.status??null,opponents:[...ghosts].map(([playerId,g])=>({playerId,nickname:g.nickname,position:g.actor.position.toArray(),target:g.target.toArray()}))};},get frozen(){return race.phase==='countdown'||recovering||recoveryRequired;},dispose(){alive=false;cancel('画面を閉じました');clearMarkers();for(const p of requests.values()){clearTimeout(p.timeout);p.reject(new Error('画面を閉じました'));}requests.clear();for(const g of ghosts.values()){scene.remove(g.actor);g.actor.traverse(o=>{o.geometry?.dispose();o.material?.map?.dispose();o.material?.dispose();});}ghosts.clear();}};
}
