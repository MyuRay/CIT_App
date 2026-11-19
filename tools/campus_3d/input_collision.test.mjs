import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from 'three';
import {StickInput,stickVector} from './sticks.mjs';
import {createMeshCollision} from './mesh_collision.mjs';
import {VehicleMotion} from './vehicle_motion.mjs';
test('sticks: dead zone, normalized diagonal, independent pointers and release',()=>{
 assert.deepEqual(stickVector(1,1,30),{x:0,y:0});
 assert(Math.abs(Math.hypot(...Object.values(stickVector(40,40,30)))-1)<1e-9);
 const s=new StickInput();assert(s.begin('left',1));assert(s.begin('right',2));assert(!s.begin('left',3));
 s.move(1,0,-1);s.move(2,-.6,-.8);assert.deepEqual(s.axes('plane'),{throttle:1,steer:.6,lift:.8});
 assert.equal(s.axes('car').lift,0);s.release(1);assert.equal(s.axes('plane').throttle,0);assert.equal(s.axes('plane').lift,.8);
 s.clear();assert.equal(s.pointers.size,0);assert.deepEqual(s.axes('plane'),{throttle:0,steer:0,lift:0});
});
test('actual triangles leave L-shaped courtyard and low roof overhead open',()=>{
 const root=new THREE.Group();
 for(const [x,z,w,d] of [[0,0,2,20],[9,9,20,2]]){const m=new THREE.Mesh(new THREE.BoxGeometry(w,8,d));m.position.set(x,4,z);root.add(m);}
 root.updateMatrixWorld(true);const c=createMeshCollision([root]);
 assert(c.collides({x:0,y:1,z:0},'car'));assert(!c.collides({x:7,y:1,z:0},'car'));
 assert(!c.collides({x:0,y:12,z:0},'car'));assert(c.collides({x:4,y:4,z:0},'plane'));
 c.dispose();
});
test('thin mesh wall stops delayed-frame motion and rejected rotation stays unchanged',()=>{
 const wall=new THREE.Mesh(new THREE.BoxGeometry(100,20,.05));wall.position.set(0,10,0);wall.updateMatrixWorld(true);
 const c=createMeshCollision([wall]);
 const world={carSpawn:{x:0,y:.8,z:5},planeSpawn:{x:0,y:10,z:7},terrainHeight:()=>0,carYaw:0,groundBounds:{min:{x:-100,z:-100},max:{x:100,z:100}},flightBounds:{min:{x:-100,z:-100},max:{x:100,z:100}},maxAltitude:100,groundBase:0,meshCollision:c.collides};
 const motion=new VehicleMotion(world);motion.setMode('car');motion.speed=14;
 for(let i=0;i<10;i++)motion.step(.1,{throttle:1,steer:0,lift:0});
 assert(motion.position.z>2);assert.equal(motion.speed,0);
 world.meshCollision=()=>true;const yaw=motion.yaw;motion.speed=10;motion.step(.1,{steer:1});assert.equal(motion.yaw,yaw);c.dispose();
});
