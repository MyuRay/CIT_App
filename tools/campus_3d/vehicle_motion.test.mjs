import {test} from 'node:test';
import assert from 'node:assert/strict';
import {VehicleMotion,overlapsBuilding} from './vehicle_motion.mjs';
const empty=new Set();
function world(overrides={}){return{groundBounds:{min:{x:-500,z:-500},max:{x:500,z:500}},flightBounds:{min:{x:-700,z:-700},max:{x:700,z:700}},groundBase:0,maxAltitude:250,terrainHeight:()=>0,buildings:[],carSpawn:{x:0,y:.8,z:0},carYaw:0,planeSpawn:{x:0,y:120,z:0},...overrides};}
function advance(v,input,seconds){for(let i=0;i<Math.round(seconds*60);i++)v.step(1/60,new Set(input));}
test('car accelerates, steers only while moving, brakes and reverses',()=>{const v=new VehicleMotion(world());v.setMode('car');advance(v,['left'],1);assert.equal(v.yaw,0);advance(v,['accelerate'],2);assert(v.speed>0&&v.position.z<0);advance(v,['accelerate','left'],1);assert(v.yaw>0);advance(v,['brake'],5);assert(v.speed<0&&v.speed>=-4);assert.equal(v.position.y,.8);});
test('building bounds prevent ground tunnelling with delayed frames',()=>{const w=world({buildings:[{min:{x:-4,y:0,z:-30},max:{x:4,y:30,z:-20}}]});const v=new VehicleMotion(w);v.setMode('car');for(let i=0;i<150;i++)v.step(1,new Set(['accelerate']));assert(!overlapsBuilding(v.position,'car',w));assert(v.position.z>=-17.8);assert.equal(v.speed,0);assert.equal(v.blocked,'建物の手前');});
test('missing ground and excessive steps stop cars',()=>{for(const terrainHeight of [(x,z)=>z<-8?null:0,(x,z)=>z<-8?2:0]){const v=new VehicleMotion(world({terrainHeight}));v.setMode('car');advance(v,['accelerate'],6);assert(v.position.z>=-8);assert.equal(v.speed,0);}});
test('campus bounds stop car and aircraft',()=>{const b={min:{x:-12,z:-12},max:{x:12,z:12}};const v=new VehicleMotion(world({groundBounds:b,flightBounds:b}));for(const mode of ['car','plane']){v.setMode(mode);advance(v,['accelerate'],10);assert(v.position.z>=b.min.z+(mode==='car'?2.2:5.5));assert.equal(v.speed,0);}});
test('aircraft ascend and descend with floor and ceiling limits',()=>{const v=new VehicleMotion(world());v.setMode('plane');advance(v,['up'],20);assert.equal(v.position.y,250);advance(v,['down'],30);assert.equal(v.position.y,3);advance(v,['accelerate'],1);assert(v.speed>0);advance(v,['brake'],5);assert(v.speed<0&&v.speed>=-8);});
test('aircraft can fly above buildings but cannot descend through roofs',()=>{const w=world({buildings:[{min:{x:-15,y:0,z:-15},max:{x:15,y:100,z:15}}]});const v=new VehicleMotion(w);v.setMode('plane');advance(v,['down'],5);assert(v.position.y>=101.2);assert(!overlapsBuilding(v.position,'plane',w));assert.equal(v.position.y,103);assert.equal(v.landingCount,1);assert.equal(v.blocked,'');});
test('stop, reset and repeated modes discard momentum and remain finite',()=>{const v=new VehicleMotion(world());for(let i=0;i<100;i++){v.setMode(i%2?'car':'plane');advance(v,['accelerate','left','up'],.2);v.stop();assert.equal(v.speed,0);v.reset();assert.equal(v.speed,0);assert.equal(v.yaw,0);assert(Number.isFinite(v.position.x)&&Number.isFinite(v.position.y)&&Number.isFinite(v.position.z));}v.setMode('free');const p={...v.position};advance(v,['accelerate'],1);assert.deepEqual(v.position,p);});

test('aircraft pitch follows actual climb and descent, lands only once per flight, and reverses out of a trap',()=>{
 const v=new VehicleMotion(world({planeSpawn:{x:0,y:3,z:0}}));v.setMode('plane');
 advance(v,['down'],1);assert.equal(v.landingCount,0);
 advance(v,['up'],2);assert(v.pitch>0);advance(v,['down'],1);assert(v.pitch<0);
 advance(v,['down'],2);assert.equal(v.landingCount,1);advance(v,['down'],2);assert.equal(v.landingCount,1);
 const before=v.position.z;advance(v,['brake'],1);assert(v.speed<0);assert(v.position.z>before);
 v.step(0,empty);assert(Number.isFinite(v.pitch));
});
