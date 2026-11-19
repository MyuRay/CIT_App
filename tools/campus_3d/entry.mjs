import {showCelebration} from './drive_feedback.mjs';
import {createBuildingLabels} from './building_labels.mjs';
import {selectCampusVehicleSpawns} from './campus_spawn.mjs';
import {createPopWorld} from './pop_scene.mjs';
import {PopMotion} from './pop_motion.mjs';
import {HeldButtons,installGameButtons} from './game_buttons.mjs';
import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {OrbitControls} from 'three/addons/controls/OrbitControls.js';
import {VehicleMotion, overlapsBuilding, clamp} from './vehicle_motion.mjs';
import {makeCar, makePlane,makeBus} from './vehicles.mjs';
import {createMeshCollision} from './mesh_collision.mjs';
import {StickInput,bindSticks} from './sticks.mjs';
import {createRegion} from './region_scene.mjs';
import {createOnlineQueue} from './online_queue.mjs';
import {installQualityDialog} from './quality_dialog.mjs';
import {createBusGame} from './bus_game.mjs';
import {outdoorLighting,shadeCampus} from './visual_quality.mjs';

const params=new URLSearchParams(location.search),gameExperience=params.get('experience')==='game',reducedMotion=params.get('reducedMotion')==='1';
document.body.dataset.experience=gameExperience?'game':'map';
const pedals=new HeldButtons();let labels;
const campus=new URLSearchParams(location.search).get('campus')==='narashino'?'narashino':'tsudanuma';
const model=campus==='narashino'?'shinnarashino-campus.glb':'tsudanuma-campus.glb';
const canvas=document.querySelector('#scene'), message=document.querySelector('#message'), status=document.querySelector('#status'), help=document.querySelector('#help');
const abort=new AbortController();
const options={signal:abort.signal};
const keyboard=new Set(),suppressed=new Set(),sticks=new StickInput();
let renderer,controls,world,motion,scene,camera,car,plane,bus,busGame,pendingBests={},loaded=false,disposed=false,paused=false,frame=0,last=0,lastStatus='',freeHome;
let lastLandingCount=0;
let campusScene,regionMode=false,regionLoading=false,sceneBounds,span=1,cameraYaw=0,cameraPitch=0,swipe=null;
const canvasPointers=new Set();
const onlineQueue=createOnlineQueue({isDisposed:()=>disposed,isLoaded:()=>loaded,getGame:()=>busGame,isRegionLoading:()=>regionLoading,enterRegion,closeOverlay:()=>api.closeOverlay()});
const queueOnline=event=>{if(event?.type==='campus-reset-view'){reset();return;}return onlineQueue.receive(event);},drainOnline=()=>onlineQueue.drain();
const input=()=>{const a=gameExperience?pedals.axes(motion?.mode??'free'):sticks.axes(motion?.mode??'free');if(gameExperience){const brake=a.brake||keyboard.has('brake');return{...a,brake,accelerate:!brake&&(a.accelerate||keyboard.has('accelerate')),throttle:brake?-1:a.accelerate||keyboard.has('accelerate')?1:0,steer:clamp(a.steer+Number(keyboard.has('left'))-Number(keyboard.has('right')),-1,1),lift:clamp(a.lift+Number(keyboard.has('up'))-Number(keyboard.has('down')),-1,1)};}return {throttle:clamp(a.throttle+Number(keyboard.has('accelerate'))-Number(keyboard.has('brake')),-1,1),steer:clamp(a.steer+Number(keyboard.has('left'))-Number(keyboard.has('right')),-1,1),lift:clamp(a.lift+Number(keyboard.has('up'))-Number(keyboard.has('down')),-1,1)};};
const buttonOptions={mode:()=>motion?.mode??'free',enabled:()=>loaded&&!paused&&!disposed&&motion?.mode!=='free'&&!api.overlayOpen,signal:abort.signal};
const clearSticks=gameExperience?installGameButtons(pedals,buttonOptions):bindSticks(sticks,{mode:()=>motion?.mode??'free',enabled:()=>loaded&&!paused&&!disposed&&motion?.mode!=='free'&&!document.querySelector('#quality-dialog').hasAttribute('open'),signal:abort.signal});
const clearInput=()=>{
 keyboard.forEach(action=>suppressed.add(action));keyboard.clear();clearSticks();swipe=null;
 for(const id of [...canvasPointers]){canvas.dispatchEvent(new PointerEvent('pointercancel',{pointerId:id}));if(canvas.hasPointerCapture(id))canvas.releasePointerCapture(id);}
 canvasPointers.clear();
};
canvas.addEventListener('pointerdown',e=>{
 canvasPointers.add(e.pointerId);
 if(!loaded||paused||motion.mode==='free'||swipe)return;
 e.preventDefault();canvas.setPointerCapture(e.pointerId);swipe={id:e.pointerId,x:e.clientX,y:e.clientY};
},options);
canvas.addEventListener('pointermove',e=>{
 if(!swipe||swipe.id!==e.pointerId)return;
 e.preventDefault();cameraYaw-=(e.clientX-swipe.x)*.006;cameraPitch=clamp(cameraPitch+(e.clientY-swipe.y)*.005,-.7,.7);swipe.x=e.clientX;swipe.y=e.clientY;
},options);
for(const type of ['pointerup','pointercancel','lostpointercapture'])canvas.addEventListener(type,e=>{canvasPointers.delete(e.pointerId);if(swipe?.id===e.pointerId)swipe=null;},options);
const stop=()=>{clearInput();motion?.stop();};
const pause=value=>{if(value)busGame?.cancel('バックグラウンドに移動しました');paused=value;stop();last=0;if(!value&&!disposed&&!frame)frame=requestAnimationFrame(animate);};
function disposeObject(object){object?.traverse(o=>{o.geometry?.dispose();const materials=Array.isArray(o.material)?o.material:[o.material];materials.forEach(m=>{if(!m)return;for(const v of Object.values(m))if(v?.isTexture)v.dispose();m.dispose();});});}
function dispose(){if(disposed)return;disposed=true;closeQuality?.();labels?.dispose();onlineQueue.clear();busGame?.dispose();stop();cancelAnimationFrame(frame);frame=0;abort.abort();resizeObserver?.disconnect();controls?.dispose();quality?.dispose();world?.disposeCollision();disposeObject(scene);renderer?.dispose();renderer?.forceContextLoss();loaded=false;}
let resizeObserver,quality,closeQuality;
const api={stop,pause,dispose,closeOverlay:()=>{if(labels?.open){labels.closeDetails();return true;}if(document.querySelector('#quality-dialog').hasAttribute('open')){closeQuality?.();return true;}return false;},get overlayOpen(){return labels?.open||document.querySelector('#quality-dialog').hasAttribute('open');},gameOnline:queueOnline,setRaceBests:values=>{pendingBests=values;busGame?.setRaceBests(values);},startRace:(direction)=>busGame?.start(direction),cancelRace:()=>busGame?.cancel(),recoverRace:()=>busGame?.recover(),get race(){return busGame?.state??null;},setFullscreen,enterRegion,viewLandmark,setMode:mode=>setMode(mode),reset:()=>reset(),get state(){return{experience:gameExperience?'game':'map',sphere:world?.sphere,buildingLabels:labels?.state,course:world?.selectedRoute?.id,campus,loaded,regionMode,regionLoading,region:regionMode?world?.description(motion.mode==='free'?controls.target:motion.position):null,mode:motion?.mode??'free',speed:motion?.speed??0,yaw:motion?.yaw??0,position:motion?{...motion.position}:null,pressed:[...keyboard,...sticks.pointers.values(),...pedals.values],axes:input(),cameraOrbit:{yaw:cameraYaw,pitch:cameraPitch},paused,disposed,blocked:motion?.blocked??'',carVisible:car?.visible??false,planeVisible:plane?.visible??false,busVisible:bus?.visible??false,camera:camera?.position.toArray(),target:controls?.target.toArray(),triangles:renderer?.info.render.triangles??0};},get worldSummary(){return world?{carSpawn:world.carSpawn,carYaw:world.carYaw,planeSpawn:world.planeSpawn,groundBounds:world.groundBounds,flightBounds:world.flightBounds,maxAltitude:world.maxAltitude,groundBase:world.groundBase,buildings:world.buildings,collisionTriangles:world.collisionTriangles}:null;}};
window.campusExplorer=api;
document.querySelectorAll('button[data-mode]').forEach(button=>button.addEventListener('click',()=>setMode(button.dataset.mode),options));
let fullscreen=false;
function viewLandmark(){if(!gameExperience||!world.sphere)return false;setMode('free');const [x,y,z]=world.sphere.position;controls.target.set(x,y,z);camera.position.set(x-100,y+30,z+190);controls.update();return true;}
async function enterRegion(){
 if(!loaded||disposed||regionLoading||regionMode)return;
 stop();regionLoading=true;document.querySelector('#city').disabled=true;
 const progress=text=>{document.querySelector('#region-message').textContent=text;};
 try{
  const previous=world;const next=await createRegion({scene,currentCampus:campus,currentScene:campusScene,currentWorld:world,currentMotion:motion,camera,controls,signal:abort.signal,onProgress:progress,isDisposed:()=>disposed});
  if(disposed){next.disposeCollision();return;}previous.disposeCollision();world=next;motion.world=next;regionMode=true;busGame=createBusGame({world:()=>world,motion:()=>motion,scene,stop,setMode,notifyHost,onActor:()=>updateVehicle(0,true)});busGame.setRaceBests(pendingBests);closeQuality=installQualityDialog({data:world.data,signal:abort.signal,onOpen:()=>{stop();notifyHost(JSON.stringify({type:'campus-overlay',open:true}));},onClose:()=>notifyHost(JSON.stringify({type:'campus-overlay',open:false}))});
  freeHome.position.add(new THREE.Vector3(...[next.data.campuses.find(c=>c.id===campus).offset[0],next.data.campuses.find(c=>c.id===campus).altitude??0,next.data.campuses.find(c=>c.id===campus).offset[1]]));freeHome.target.add(new THREE.Vector3(next.data.campuses.find(c=>c.id===campus).offset[0],next.data.campuses.find(c=>c.id===campus).altitude??0,next.data.campuses.find(c=>c.id===campus).offset[1]));
  controls.maxDistance=6000;document.querySelector('#city').textContent='校内';document.querySelector('#city').setAttribute('aria-label','キャンパス表示に戻る');document.querySelector('#region-bar').hidden=false;
 }catch(error){if(!disposed){console.error(error);progress('周辺データを読み込めません。上部のリセットで再試行してください。');}}
 finally{regionLoading=false;if(!disposed){document.querySelector('#city').disabled=false;if(busGame)drainOnline();}}
}
document.querySelectorAll('.sources a').forEach(a=>a.addEventListener('click',e=>{if(window.CampusHost){e.preventDefault();notifyHost(a.href.includes('openstreetmap')?'campus-source:osm':'campus-source:gsi');}},options));
document.querySelector('#city').addEventListener('click',()=>{if(gameExperience)reset();else if(regionMode)notifyHost('campus-reset-viewer');else enterRegion();},options);
document.querySelectorAll('[data-route]').forEach(b=>b.addEventListener('click',()=>busGame?busGame.select(b.dataset.route):world?.setRoute?.(b.dataset.route),options));
function notifyHost(value){if(window.CampusHost)window.CampusHost.postMessage(value);else window.parent.postMessage(value,location.origin);}
function setFullscreen(value){fullscreen=value;const b=document.querySelector('#fullscreen');b.textContent=value?'⤢':'⛶';b.setAttribute('aria-label',value?'全画面を解除':'全画面にする');b.title=b.getAttribute('aria-label');if(!value&&document.fullscreenElement)document.exitFullscreen().catch(()=>{});}
document.querySelector('#fullscreen').addEventListener('click',()=>{stop();if(!fullscreen&&window.parent!==window&&document.documentElement.requestFullscreen)document.documentElement.requestFullscreen().catch(()=>{});notifyHost('campus-fullscreen-toggle');},options);
document.addEventListener('fullscreenchange',()=>{if(!document.fullscreenElement&&fullscreen)notifyHost('campus-fullscreen-exit');},options);
document.querySelector('#stop').addEventListener('click',stop,options);
document.querySelector('#reset').addEventListener('click',()=>reset(),options);
const keymap={ArrowUp:'accelerate',ArrowDown:'brake',ArrowLeft:'left',ArrowRight:'right',w:'accelerate',s:'brake',a:'left',d:'right',r:'up',f:'down',PageUp:'up',PageDown:'down'};
window.addEventListener('keydown',e=>{if(e.key==='Escape'&&api.overlayOpen){e.preventDefault();api.closeOverlay();return;}if(e.key==='Escape'&&fullscreen){e.preventDefault();notifyHost('campus-fullscreen-exit');return;}if(!loaded||paused||api.overlayOpen)return;if(e.code==='Space'){e.preventDefault();stop();return;}const key=keymap[e.key]??keymap[e.key.toLowerCase()];if(key){e.preventDefault();if(!suppressed.has(key))keyboard.add(key);}},options);
window.addEventListener('keyup',e=>{const key=keymap[e.key]??keymap[e.key.toLowerCase()];keyboard.delete(key);suppressed.delete(key);},options);
window.addEventListener('blur',stop,options);
window.addEventListener('pagehide',dispose,options);
window.addEventListener('message',e=>{if(e.origin===location.origin && e.source===window.parent){if(e.data?.type==='campus-reset-view')reset();if(e.data?.type==='campus-close-overlay')api.closeOverlay();if(e.data?.type==='campus-best-save')api.gameOnline(e.data);if(e.data?.type==='campus-game-response'||e.data?.type==='campus-game-session'||e.data?.type==='campus-game-challenge'||e.data?.type==='campus-game-leave')api.gameOnline(e.data);if(e.data==='campus-dispose')dispose();if(e.data==='campus-stop')stop();if(e.data==='campus-fullscreen:1')setFullscreen(true);if(e.data==='campus-fullscreen:0')setFullscreen(false);}},options);
document.addEventListener('visibilitychange',()=>pause(document.hidden),options);
canvas.addEventListener('webglcontextlost',e=>{e.preventDefault();pause(true);message.hidden=false;message.textContent='3D描画が中断しました。';},options);

function setMode(mode){
  if(gameExperience&&mode!=='bus')return;
  if(!loaded||disposed||!['free','car','plane','bus'].includes(mode)||(mode==='car'&&!world.carSpawn)||(mode==='bus'&&!regionMode))return;
  busGame?.cancel('モードを変更しました');stop();if(mode==='bus'&&!world.busSpawn){const r=world.selectedRoute,a=r.points[0],b=r.points[1];world.busSpawn={x:a[0],y:(world.roadIndex.surface(a[0],a[1],null,'bus')?.height??world.terrainHeight(a[0],a[1])??0)+1.4,z:a[1]};world.busYaw=Math.atan2(-(b[0]-a[0]),-(b[1]-a[1]));}motion.setMode(mode);if(gameExperience){camera.fov=['bus','car'].includes(mode)?65:50;camera.updateProjectionMatrix();}controls.enabled=mode==='free';
  car.visible=mode==='car';plane.visible=mode==='plane';bus.visible=mode==='bus';document.body.dataset.mode=mode;
  document.querySelectorAll('button[data-mode]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.mode===mode)));
  if(!gameExperience)document.querySelector('#right-label').textContent=['car','bus'].includes(mode)?'左右で操舵':'上下左右で操縦';
  help.textContent=mode==='free'?'ドラッグで回転・ピンチで拡大・2本指で移動':'左：加減速／右：'+(['car','bus'].includes(mode)?'左右の操舵':'上下左右の操縦')+'／空いている画面をスワイプで視点移動';
  reset();if(gameExperience)help.textContent='左：左右ボタン／右：アクセル・ブレーキ。画面ドラッグで視点移動。';
}
function reset(){
  if(!loaded||disposed)return;
  busGame?.cancel('リセットしました');stop();motion.reset();cameraYaw=cameraPitch=0;
  plane.rotation.x=plane.rotation.z=0;
  if(motion.mode==='free'){if(gameExperience){const b=world.flightBounds,c=new THREE.Vector3((b.min.x+b.max.x)/2,0,(b.min.z+b.max.z)/2),d=Math.max(b.max.x-b.min.x,b.max.z-b.min.z)/Math.tan(THREE.MathUtils.degToRad(camera.fov/2))*.6;freeHome={position:c.clone().add(new THREE.Vector3(0,d*.85,d*.55)),target:c};}camera.position.copy(freeHome.position);controls.target.copy(freeHome.target);controls.update();}
  else updateVehicle(0,true);
}
function updateVehicle(dt,instant=false){
  const isBus=motion.mode==='bus',isCar=motion.mode==='car'||isBus,actor=isBus?bus:isCar?car:plane,p=motion.position;
  actor.position.set(p.x,p.y-(isBus?1.4:isCar?.8:0),p.z);actor.rotation.y=motion.yaw;
  const keys=input();
  if(isCar)actor.userData.wheels.forEach(w=>w.rotateY(motion.speed*dt/0.43));
  else {plane.rotation.z=THREE.MathUtils.lerp(plane.rotation.z,keys.steer*0.18,Math.min(1,dt*6));plane.rotation.order='YXZ';plane.rotation.x=motion.pitch??0;if((motion.landingCount??0)>lastLandingCount){lastLandingCount=motion.landingCount;showCelebration('ナイスランディング！',{reducedMotion,goal:true});}plane.userData.propeller.rotation.z+=dt*(8+Math.abs(motion.speed));}
  const target=new THREE.Vector3(p.x,p.y+(isCar?0.9:0),p.z);
  const pitch=clamp((gameExperience&&isCar?.12:isCar?Math.atan2(5,11):Math.atan2(32,24))+cameraPitch,.12,1.45),radius=isBus?19:isCar?Math.hypot(11,5):40;
  const heading=motion.yaw+cameraYaw;
  const desired=target.clone().add(new THREE.Vector3(Math.sin(heading)*Math.cos(pitch)*radius,Math.sin(pitch)*radius,Math.cos(heading)*Math.cos(pitch)*radius));
  const ground=world.terrainHeight(desired.x,desired.z);if(ground!=null)desired.y=Math.max(desired.y,ground+1.5);
  const direction=desired.clone().sub(target);const length=direction.length();direction.normalize();
  const distance=world.cameraDistance(target,direction,length);
  desired.copy(target).addScaledVector(direction,distance);
  if(instant)camera.position.copy(desired);else camera.position.lerp(desired,1-Math.exp(-dt*8));
  camera.lookAt(target);controls.target.copy(target);
}
function moveFree(dt){
  const keys=input();if(!keys.throttle&&!keys.steer&&!keys.lift)return;
  const forward=new THREE.Vector3();camera.getWorldDirection(forward);forward.y=0;forward.normalize();
  const right=new THREE.Vector3().crossVectors(forward,new THREE.Vector3(0,1,0));
  const delta=new THREE.Vector3().addScaledVector(forward,keys.throttle).addScaledVector(right,-keys.steer);
  delta.y=keys.lift;if(!delta.lengthSq())return;delta.normalize().multiplyScalar(span*0.15*dt);
  const old=controls.target.clone();controls.target.add(delta);
  controls.target.x=clamp(controls.target.x,world.flightBounds.min.x,world.flightBounds.max.x);controls.target.z=clamp(controls.target.z,world.flightBounds.min.z,world.flightBounds.max.z);controls.target.y=clamp(controls.target.y,world.groundBase,world.maxAltitude);
  camera.position.add(controls.target.clone().sub(old));
}
function animate(now){
  frame=0;if(disposed||paused)return;
  const dt=Math.min((now-(last||now))/1000,0.05);last=now;
  if(loaded){if(motion.mode==='free'){moveFree(dt);controls.update();}else{if(!busGame?.frozen)motion.step(dt,input());updateVehicle(dt);}labels?.update();if(regionMode){world.update(motion.mode==='free'?camera.position:motion.position);if(!gameExperience){const description=world.description(motion.mode==='free'?controls.target:motion.position);document.querySelector('#region-quality').textContent=`DEM由来20m ${Number(description.sourceDerivedPercent??0).toFixed(2)}% / 補間 ${Number(description.interpolatedPercent??0).toFixed(2)}% · 現在 ${description.terrainSourceLabel??'確認中'} · 外観に推定を含む`;}}
    busGame?.tick(dt);
    quality?.follow(motion.mode==='free'?controls.target:motion.position);
    const text=motion.mode==='free'?'自由視点':`${motion.mode==='bus'?'バス':motion.mode==='car'?'車':'飛行機'} ${Math.round(Math.abs(motion.speed)*3.6)} km/h${motion.mode==='plane'?` · 高さ ${Math.round(motion.position.y-world.groundBase)} m`:''}${motion.blocked?` · ${motion.blocked}`:''}`;
    if(text!==lastStatus){status.textContent=text;lastStatus=text;}}
  renderer.render(scene,camera);frame=requestAnimationFrame(animate);
}
function terrainWorld(campusScene){
  const ground=[],buildings=[],buildingRoots=[];
  const isBuilding=o=>o.userData.building_id || /^(Building_|Campus_Annex_|Dorm_Common)/.test(o.name);
  campusScene.traverse(o=>{
    if(/^(Site_Base|Landscape_Ground|Campus_Ground|Landscape_Paving|Sports_Fields)$/.test(o.name))ground.push(o);
    if(isBuilding(o)){
      for(let parent=o.parent;parent&&parent!==campusScene;parent=parent.parent){if(isBuilding(parent))return;}
      const b=new THREE.Box3().setFromObject(o);if(!b.isEmpty()){buildings.push({name:o.name,id:o.userData.building_id??o.name,min:{...b.min},max:{...b.max}});buildingRoots.push(o);}}
  });
  if(!ground.length)throw Error('Ground meshes not found');
  const groundBox=new THREE.Box3();ground.forEach(o=>groundBox.union(new THREE.Box3().setFromObject(o)));
  const s=groundBox.getSize(new THREE.Vector3()),c=groundBox.getCenter(new THREE.Vector3()),width=Math.max(s.x,s.z);
  const down=new THREE.Vector3(0,-1,0),ray=new THREE.Raycaster();
  const terrainHeight=(x,z)=>{ray.set(new THREE.Vector3(x,sceneBounds.max.y+50,z),down);const hits=ray.intersectObjects(ground,true);return hits.length?hits[0].point.y:null;};
  const base=ground.find(o=>/^(Site_Base|Campus_Ground)$/.test(o.name))??ground[0];
  const w={terrainHeight,groundBounds:{min:{...groundBox.min},max:{...groundBox.max}},flightBounds:{min:{x:groundBox.min.x-width*.4,z:groundBox.min.z-width*.4},max:{x:groundBox.max.x+width*.4,z:groundBox.max.z+width*.4}},groundBase:new THREE.Box3().setFromObject(base).max.y,maxAltitude:sceneBounds.max.y+250,buildings,carSpawn:null,carYaw:0,planeSpawn:{x:c.x,y:sceneBounds.max.y+25,z:c.z}};
  const collision=createMeshCollision(buildingRoots);w.meshCollision=collision.collides;w.cameraDistance=collision.cameraDistance;w.collisionTriangles=collision.triangleCount;w.disposeCollision=collision.dispose;
  const preferred=selectCampusVehicleSpawns({campus,scene:campusScene,world:w});
  if(preferred)Object.assign(w,preferred);
  let best=Infinity;
  if(!preferred)for(let ix=1;ix<24;ix++)for(let iz=1;iz<24;iz++){
    const x=groundBox.min.x+s.x*ix/24,z=groundBox.min.z+s.z*iz/24,y=terrainHeight(x,z);if(y==null)continue;
    const p={x,y:y+0.8,z};if(overlapsBuilding(p,'car',w))continue;
    let clearance=0,yaw=0;
    for(let dir=0;dir<8;dir++){const angle=dir*Math.PI/4;let d=0;for(const distance of [3,6,10,15]){const test={x:x-Math.sin(angle)*distance,y:p.y,z:z-Math.cos(angle)*distance};const h=terrainHeight(test.x,test.z);if(h==null||Math.abs(h-y)>.65||overlapsBuilding(test,'car',w))break;d=distance;}if(d>clearance){clearance=d;yaw=angle;}}
    const score=(x-c.x)**2+(z-c.z)**2-clearance*80;
    if(score<best){best=score;w.carSpawn=p;w.carYaw=yaw;}
  }
  if(!w.carSpawn){document.querySelector('[data-mode=car]').disabled=true;w.carSpawn={x:c.x,y:groundBox.max.y+0.8,z:c.z};}
  return w;
}
async function start(){
  try{
    renderer=new THREE.WebGLRenderer({canvas,antialias:true,alpha:false,powerPreference:'high-performance'});renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;
    scene=new THREE.Scene();scene.background=new THREE.Color(0xe8eef2);camera=new THREE.PerspectiveCamera(50,1,0.2,10000);
    scene.add(new THREE.HemisphereLight(0xffffff,0x789574,2.4));const sun=new THREE.DirectionalLight(0xfff9ec,3);sun.position.set(-150,250,100);scene.add(sun);quality=outdoorLighting(renderer,scene);
    controls=new OrbitControls(camera,canvas);controls.enableDamping=false;controls.minDistance=2;controls.maxPolarAngle=Math.PI*.49;
    let lastWidth=0,lastHeight=0;
    const resize=()=>{const width=document.body.clientWidth,height=document.body.clientHeight;if(!width||!height)return;if(lastWidth&&(width!==lastWidth||height!==lastHeight))stop();lastWidth=width;lastHeight=height;camera.aspect=width/height;camera.updateProjectionMatrix();renderer.setSize(width,height,false);};
    resizeObserver=new ResizeObserver(resize);resizeObserver.observe(document.body);resize();
    if(gameExperience){
      document.body.dataset.experience='game';document.querySelector('#scene').setAttribute('aria-label','ポップドライブ');
      document.querySelector('.toolbar').remove();
      document.querySelector('#region-bar').innerHTML='<select id="game-course" aria-label="コース選択"><option value="outward">キャンパス往路</option><option value="return">キャンパス復路</option><option value="s_bay">S字ベイ（非公式）</option><option value="neon_city">ネオンストリート（非公式）</option></select><span id="region-quality">オリジナルゲームコース</span>';
      world=await createPopWorld({scene,signal:abort.signal,reducedMotion,onCourse:c=>{notifyHost(JSON.stringify({type:'campus-course',direction:c.id}));document.querySelector('#game-course').value=c.id;const landmark=document.querySelector('#sphere-view');if(landmark)landmark.hidden=c.id!=='neon_city';}});
      motion=new PopMotion(world);regionMode=true;car=makeCar();plane=makePlane();bus=makeBus();scene.add(car,plane,bus);car.visible=plane.visible=false;
      freeHome={position:new THREE.Vector3(0,110,110),target:new THREE.Vector3()};span=300;controls.maxDistance=2000;loaded=true;
      setMode('bus');busGame=createBusGame({world:()=>world,motion:()=>motion,scene,stop,setMode,notifyHost,onActor:()=>updateVehicle(0,true)});busGame.setRaceBests(pendingBests);
      document.querySelector('#game-course').addEventListener('change',e=>busGame.select(e.target.value),options);
      document.querySelector('#region-bar').hidden=false;document.querySelector('.sources').innerHTML='オリジナルコース<br>実際の道路ではありません';
      message.hidden=true;document.body.dataset.ready='true';drainOnline();if(!paused&&!frame)frame=requestAnimationFrame(animate);return;
    }
    labels=createBuildingLabels({scene,camera,canvas,onOpen:stop,onOverlay:open=>notifyHost(JSON.stringify({type:'campus-overlay',open}))});
    const gltf=await new GLTFLoader().loadAsync(model);if(disposed){disposeObject(gltf.scene);return;}
    shadeCampus(gltf.scene);campusScene=gltf.scene;scene.add(gltf.scene);gltf.scene.updateMatrixWorld(true);sceneBounds=new THREE.Box3().setFromObject(gltf.scene);
    const size=sceneBounds.getSize(new THREE.Vector3()),center=sceneBounds.getCenter(new THREE.Vector3());span=Math.max(size.x,size.z);
    world=terrainWorld(gltf.scene);motion=new VehicleMotion(world);car=makeCar();plane=makePlane();bus=makeBus();scene.add(car,plane,bus);car.visible=plane.visible=bus.visible=false;
    const distance=Math.max(size.x/camera.aspect,size.z,size.y)*0.68/Math.tan(THREE.MathUtils.degToRad(camera.fov/2));
    camera.position.copy(center).add(new THREE.Vector3(0,0.8,1).normalize().multiplyScalar(distance));controls.target.copy(center);controls.maxDistance=distance*3;controls.update();freeHome={position:camera.position.clone(),target:center.clone()};
    loaded=true;message.hidden=true;document.body.dataset.ready='true';setMode('free');last=0;drainOnline();
    if(!paused&&!frame)frame=requestAnimationFrame(animate);
  }catch(error){console.error(error);message.hidden=false;message.textContent='3Dモデルを表示できません。';status.textContent='読み込み失敗';}
}
start();
