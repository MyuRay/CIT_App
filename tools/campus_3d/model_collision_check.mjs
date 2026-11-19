import fs from 'node:fs';
import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {createMeshCollision} from './mesh_collision.mjs';
import assert from 'node:assert/strict';
const results={};
for(const file of ['tsudanuma-campus.glb','shinnarashino-campus.glb']){
 const bytes=fs.readFileSync(`../../assets/models/campus/${file}`);
 const gltf=await new GLTFLoader().parseAsync(bytes.buffer.slice(bytes.byteOffset,bytes.byteOffset+bytes.byteLength),'');gltf.scene.updateMatrixWorld(true);
 const roots=[],boxes=[];const isBuilding=o=>o.userData.building_id||/^(Building_|Campus_Annex_|Dorm_Common)/.test(o.name);
 gltf.scene.traverse(o=>{if(!isBuilding(o))return;for(let p=o.parent;p&&p!==gltf.scene;p=p.parent)if(isBuilding(p))return;roots.push(o);boxes.push({name:o.name,box:new THREE.Box3().setFromObject(o)});});
 const collision=createMeshCollision(roots);let openSamples=0,wallSamples=0;const examples=[];
 for(const {name,box:b} of boxes){for(let ix=0;ix<=12;ix++)for(let iz=0;iz<=12;iz++){
  const p={x:b.min.x+(b.max.x-b.min.x)*ix/12,y:b.min.y+1,z:b.min.z+(b.max.z-b.min.z)*iz/12};
  if(collision.collides(p,'car'))wallSamples++;else{openSamples++;if(examples.length<4)examples.push({name,p});}
 }}
 assert(wallSamples>0);assert(openSamples>0);results[file]={buildingRoots:roots.length,triangleCount:collision.triangleCount,surfaceContacts:wallSamples,surfaceFreeSamplesWithinCoarseBounds:openSamples,examples,note:'A surface-only test does not classify fully enclosed interior volume. Spawn remains outside conservative bounds; small continuous steps stop surface crossing.'};collision.dispose();
}
fs.writeFileSync('../../docs/campus_3d/mesh-collision-validation.json',JSON.stringify(results,null,2));console.log(JSON.stringify(results,null,2));
