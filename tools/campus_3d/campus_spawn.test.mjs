import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {createMeshCollision} from './mesh_collision.mjs';
import {selectCampusVehicleSpawns} from './campus_spawn.mjs';
import {VehicleMotion} from './vehicle_motion.mjs';

for(const [campus,file] of [['tsudanuma','tsudanuma-campus.glb'],['narashino','shinnarashino-campus.glb']]){
 test(`${campus}: both vehicles begin beside the requested real GLB landmark and can leave safely`,async()=>{
  const bytes=fs.readFileSync(new URL(`../../assets/models/campus/${file}`,import.meta.url));
  const {scene}=await new GLTFLoader().parseAsync(bytes.buffer.slice(bytes.byteOffset,bytes.byteOffset+bytes.byteLength),'');
  scene.updateMatrixWorld(true);
  const ground=[],roots=[],buildings=[];
  const isBuilding=o=>o.userData.building_id||/^(Building_|Campus_Annex_|Dorm_Common)/.test(o.name);
  scene.traverse(o=>{
   if(/^(Site_Base|Landscape_Ground|Campus_Ground|Landscape_Paving|Sports_Fields)$/.test(o.name))ground.push(o);
   if(!isBuilding(o))return;
   for(let p=o.parent;p&&p!==scene;p=p.parent)if(isBuilding(p))return;
   roots.push(o);const box=new THREE.Box3().setFromObject(o);buildings.push({min:box.min,max:box.max});
  });
  const groundBox=new THREE.Box3();ground.forEach(o=>groundBox.union(new THREE.Box3().setFromObject(o)));
  const ray=new THREE.Raycaster(),top=new THREE.Box3().setFromObject(scene).max.y+50;
  const terrainHeight=(x,z)=>{ray.set(new THREE.Vector3(x,top,z),new THREE.Vector3(0,-1,0));return ray.intersectObjects(ground,true)[0]?.point.y??null;};
  const collision=createMeshCollision(roots);
  try{
   const world={groundBounds:{min:groundBox.min,max:groundBox.max},flightBounds:{min:groundBox.min,max:groundBox.max},terrainHeight,buildings,
    groundBase:0,maxAltitude:top+200,meshCollision:collision.collides};
   const spawn=selectCampusVehicleSpawns({campus,scene,world});assert(spawn,'safe landmark spawn must exist');Object.assign(world,spawn);
   let reference;scene.traverse(o=>{if(campus==='tsudanuma'&&o.material?.name==='sculpture'||campus==='narashino'&&String(o.userData.building_id)==='12')reference=o;});
   const box=new THREE.Box3().setFromObject(reference),point=new THREE.Vector3(spawn.carSpawn.x,box.min.y,spawn.carSpawn.z);
   assert(box.distanceToPoint(point)<=22);
   assert.equal(spawn.carSpawn.x,spawn.planeSpawn.x);assert.equal(spawn.carSpawn.z,spawn.planeSpawn.z);
   assert(Math.abs(spawn.carSpawn.y-terrainHeight(point.x,point.z)-.8)<1e-6);
   assert(Math.abs(spawn.planeSpawn.y-terrainHeight(point.x,point.z)-3)<1e-6);
   for(const mode of ['car','plane']){
    const motion=new VehicleMotion(world);motion.setMode(mode);const initial={...motion.position},yaw=motion.yaw;
    assert(!collision.collides(initial,mode,yaw));
    for(let i=0;i<15;i++)motion.step(.1,{throttle:1,steer:0,lift:0});
    assert(motion.speed>0,`${mode} must not immediately hit a building`);
    assert(Math.hypot(motion.position.x-initial.x,motion.position.z-initial.z)>3);
    motion.reset();assert.deepEqual(motion.position,initial);assert.equal(motion.yaw,yaw);
   }
  }finally{collision.dispose();}
 });
}

test('a missing landmark keeps the existing fallback available',()=>{
 assert.equal(selectCampusVehicleSpawns({campus:'tsudanuma',scene:new THREE.Scene(),world:{}}),null);
});
