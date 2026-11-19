import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {project,unproject,sampleTerrain,insidePolygon,RoadIndex,closestSegment} from './geo.mjs';
import {prepareRoads} from './region_scene.mjs';
const read=()=>JSON.parse(fs.readFileSync(new URL('../../assets/models/campus/region.json',import.meta.url),'utf8'));
test('common coordinate system preserves metres, north and inverse transform',()=>{const o=[140.02138,35.6887746],p=project(140.0145,35.6617,o);assert(p.x<0&&p.z>3000);const q=unproject(p.x,p.z,o);assert(Math.abs(q.lon-140.0145)<1e-10);assert(Math.abs(q.lat-35.6617)<1e-10);});
test('terrain includes distinct campus elevations and labels unavailable data',()=>{const d=read();const a=d.campuses[0],b=d.campuses[1];assert(a.altitude>14&&a.altitude<17);assert(b.altitude>4&&b.altitude<8);assert(d.terrain.missingSamplesBeforeInterpolation>0);assert(d.terrain.known.some(k=>!k));assert(d.terrain.heights.every(Number.isFinite));assert.equal(sampleTerrain(d.terrain,-999999,-99999),null);assert(insidePolygon(a.offset[0],a.offset[1],a.boundary));});
test('independent outward and return shapes retain actual one-way metadata',()=>{const d=read();assert.equal(d.routes.length,2);assert(d.routes[0].distance>4000&&d.routes[0].distance<4200);assert(d.routes[1].distance>3800&&d.routes[1].distance<4000);assert.notDeepEqual(d.routes[0].points,d.routes[1].points.toReversed());for(const id of [1291292745,1291292747,156156300,156185263])assert.equal(d.roads.find(r=>r.id===id).tags.oneway,'yes');assert.equal(d.roads.find(r=>r.id===159937215).private,true);});
test('overpasses do not connect roads at coordinate crossings',()=>{const terrain={x:-100,z:-100,nx:3,nz:3,step:100,heights:Array(9).fill(0)};const roads=[{drive:true,width:8,points:[[-50,0,5],[50,0,5]],tags:{bridge:'yes'},nodes:[1,2]},{drive:true,width:8,points:[[0,-50,.12],[0,50,.12]],tags:{},nodes:[3,4]}];const index=new RoadIndex(roads,terrain);assert(Math.abs(index.surface(0,0,.92).height-.12)<1e-9);assert.equal(index.surface(0,0,5.8).height,5);});
test('route surfaces remain continuous along source coordinates',()=>{
 const d=read();prepareRoads(d);const index=new RoadIndex(d.roads,d.terrain),report={};
 for(const route of d.routes){let samples=0,gaps=0,maxRoadOffset=0,previousHeight=null,maxHeightStep=0;const examples=[];
  for(let i=1;i<route.points.length;i++){const a=route.points[i-1],b=route.points[i],count=Math.max(1,Math.ceil(Math.hypot(b[0]-a[0],b[1]-a[1])/2));for(let j=0;j<count;j++){const x=a[0]+(b[0]-a[0])*j/count,z=a[1]+(b[1]-a[1])*j/count;const surface=index.surface(x,z);samples++;const nearest=index.candidates(x,z)[0];maxRoadOffset=Math.max(maxRoadOffset,nearest?.distance??Infinity);if(!surface){gaps++;if(examples.length<5)examples.push({x,z,distance:nearest?.distance,road:nearest?.road.id});}else{if(previousHeight!=null)maxHeightStep=Math.max(maxHeightStep,Math.abs(surface.height-previousHeight));previousHeight=surface.height;}}}
  report[route.id]={samples,gaps,maxRoadOffset,maxHeightStep,examples};
 }
 fs.writeFileSync(new URL('../../docs/campus_3d/region-route-validation.json',import.meta.url),JSON.stringify(report,null,2));
 for(const result of Object.values(report))assert.equal(result.gaps,0,JSON.stringify(report));
});
