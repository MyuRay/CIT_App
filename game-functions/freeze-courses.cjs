'use strict';
const fs=require('node:fs'),path=require('node:path');
const source=JSON.parse(fs.readFileSync(path.join(__dirname,'../assets/models/campus/pop_courses.json'),'utf8'));
function fingerprint(points){let h=2166136261;for(const ch of JSON.stringify(points.map(p=>p.map(v=>Math.round(v*100))))){h^=ch.charCodeAt(0);h=Math.imul(h,16777619);}return(h>>>0).toString(16).padStart(8,'0');}
if(source.family!=='pop'||source.version!==2)throw Error('Expected independent pop course family/version 2');
const required=['outward','return','s_bay','neon_city'];
if(source.courses.length!==4||required.some(id=>source.courses.filter(c=>(c.direction||c.id)===id).length!==1))throw Error('Expected exactly four game course IDs');
const courses=source.courses.map(r=>{const direction=r.direction||r.id;if(!Array.isArray(r.points)||r.points.length<2||r.points.some(p=>!Array.isArray(p)||p.length!==3||!p.every(Number.isFinite)))throw Error('Expected finite [x,z,roadHeight] points for '+direction);const key=`cit_bus_best_v2_pop_${direction}_${fingerprint(r.points)}`,length=r.points.reduce((n,p,i)=>i?n+Math.hypot(p[0]-r.points[i-1][0],p[1]-r.points[i-1][1]):0,0);if(r.key&&r.key!==key)throw Error('Frontend fingerprint mismatch '+direction);if(r.length&&Math.abs(r.length-length)>0.05)throw Error('Frontend horizontal length mismatch '+direction);return {direction,key,family:'pop',version:2,layerAware:true,checkpointSpacing:150,corridor:48,length,points:r.points};});
const target=path.join(__dirname,'courses.json'),archive=path.join(__dirname,'courses.campus-v1.json');
if(fs.existsSync(target)&&!fs.existsSync(archive)){const old=JSON.parse(fs.readFileSync(target,'utf8'));if(old.some(c=>c.key.startsWith('cit_bus_best_v1_')))fs.writeFileSync(archive,JSON.stringify(old));}
fs.writeFileSync(target,JSON.stringify(courses));console.log(courses.map(({points,...c})=>c));
