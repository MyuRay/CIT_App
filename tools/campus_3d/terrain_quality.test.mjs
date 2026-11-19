import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {terrainQuality} from './terrain_quality.mjs';
test('quality follows every contributing bilinear source rather than nearest point',()=>{
 const t={x:0,z:0,nx:2,nz:2,step:20,known:[true,true,true,false],sampleSources:[1,2,4,0],sourceDerivedPercent:75,interpolatedPercent:25};
 assert.equal(terrainQuality(t,0,0).terrainEstimated,false);
 assert.equal(terrainQuality(t,10,10).terrainEstimated,true);
 assert.equal(terrainQuality(t,10,10).sourceMasks,7);
 assert.equal(terrainQuality(t,10,0).terrainSourceLabel,'DEM5A+DEM5B');
 assert.equal(terrainQuality(t,-1,0).terrainSourceLabel,'範囲外');
});
test('recovered terrain provenance accounts for every grid sample and every tile',()=>{
 const data=JSON.parse(fs.readFileSync(new URL('../../assets/models/campus/region.json',import.meta.url),'utf8')),t=data.terrain;
 assert.equal(t.heights.length,t.nx*t.nz);assert.equal(t.sampleSources.length,t.heights.length);assert.equal(t.known.length,t.heights.length);
 let source=0,estimated=0;
 t.sampleSources.forEach((mask,i)=>{assert(mask>=0&&mask<=7);assert.equal(t.known[i],mask!==0);if(mask)source++;else estimated++;assert(Number.isFinite(t.heights[i]));});
 assert.equal(estimated,t.missingSamplesBeforeInterpolation);assert.equal(+((source/t.heights.length)*100).toFixed(4),t.sourceDerivedPercent);assert(t.sourceDerivedPercent>97&&t.interpolatedPercent>0&&t.interpolatedPercent<3);
 const tiles=Object.values(t.coverageByTile);assert.equal(tiles.reduce((n,v)=>n+v.total,0),t.heights.length);assert.equal(tiles.reduce((n,v)=>n+v.sourceDerived,0),source);assert.equal(tiles.reduce((n,v)=>n+v.interpolated,0),estimated);
 for(const c of data.campuses){assert.equal(c.altitudeEstimated,false);assert.equal(terrainQuality(t,...c.offset).terrainEstimated,false);}
});
