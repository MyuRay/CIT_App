import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {createRegion} from './region_scene.mjs';
import {VehicleMotion,clamp} from './vehicle_motion.mjs';
import {TimeAttack,courseFromRoute} from './time_attack.mjs';
const load=async name=>{const b=fs.readFileSync(new URL(`../../assets/models/campus/${name}`,import.meta.url));return(await new GLTFLoader().parseAsync(b.buffer.slice(b.byteOffset,b.byteOffset+b.byteLength),'')).scene;};
test('bus travels both real courses continuously with actual loaded building triangles',async()=>{
 const data=JSON.parse(fs.readFileSync(new URL('../../assets/models/campus/region.json',import.meta.url),'utf8'));const savedFetch=globalThis.fetch;globalThis.fetch=async()=>new Response(JSON.stringify(data));
 const scene=new THREE.Scene(),camera=new THREE.PerspectiveCamera(),currentScene=await load('tsudanuma-campus.glb'),otherScene=await load('shinnarashino-campus.glb');scene.add(currentScene);
 const dummy={carSpawn:{x:0,y:.8,z:0},carYaw:0,terrainHeight:()=>0,planeSpawn:{x:0,y:120,z:0},groundBounds:{min:{x:-100,z:-100},max:{x:100,z:100}}};const initialMotion=new VehicleMotion(dummy);
 const world=await createRegion({scene,currentCampus:'tsudanuma',currentScene,currentWorld:dummy,currentMotion:initialMotion,camera,controls:{target:new THREE.Vector3()},signal:new AbortController().signal,onProgress:()=>{},isDisposed:()=>false,preloadedCampuses:[{id:'narashino',scene:otherScene}]});
 try{const report={};for(const route of world.data.routes){const points=route.points,first=points[0];world.busSpawn={x:first[0],y:world.roadIndex.surface(...first).height+1.4,z:first[1]};world.busYaw=Math.atan2(-(points[1][0]-first[0]),-(points[1][1]-first[1]));const motion=new VehicleMotion(world);motion.setMode('bus');let now=0;const race=new TimeAttack({clock:()=>now});race.arm(courseFromRoute(route),motion.position,0);race.tick(motion.position);let target=1,travel=0,blocked=0,maxStep=0;
  for(let step=0;step<40000&&target<points.length;step++){
   while(target<points.length-1&&Math.hypot(points[target][0]-motion.position.x,points[target][1]-motion.position.z)<3.5)target++;
   const goal=points[target],dx=goal[0]-motion.position.x,dz=goal[1]-motion.position.z,desired=Math.atan2(-dx,-dz),error=Math.atan2(Math.sin(desired-motion.yaw),Math.cos(desired-motion.yaw)),desiredSpeed=Math.abs(error)>.15?1:4;
   const old={...motion.position};motion.step(.1,{throttle:motion.speed<desiredSpeed?1:-1,steer:clamp(error*4,-1,1),lift:0});const distance=Math.hypot(motion.position.x-old.x,motion.position.z-old.z);travel+=distance;maxStep=Math.max(maxStep,distance);if(motion.blocked)blocked++;now+=100;race.tick(motion.position,{onCourse:world.terrainHeight(motion.position.x,motion.position.z,motion.position.y,'bus')!=null});
   if(target===points.length-1&&Math.hypot(dx,dz)<3){target=points.length;break;}
  }
  report[route.id]={race:race.state,arrived:target===points.length,travelledMeters:travel,sourceDistance:route.distance,blockedFrames:blocked,maxFrameDistance:maxStep,lastPosition:motion.position,lastBlocked:motion.blocked,lastYaw:motion.yaw,nextPoint:points[target],nearestRoad:world.roadIndex.candidates(motion.position.x,motion.position.z)[0],targetIndex:target,pointCount:points.length};
 }
 fs.writeFileSync(new URL('../../docs/campus_3d/bus-drive-validation.json',import.meta.url),JSON.stringify(report,null,2));for(const result of Object.values(report)){assert(result.arrived,JSON.stringify(report));assert.equal(result.race.phase,'finished',JSON.stringify(report));assert(result.travelledMeters>3500);assert(result.maxFrameDistance<1.5);}
 }finally{world.disposeCollision();globalThis.fetch=savedFetch;}
});
