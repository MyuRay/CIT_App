import * as THREE from 'three';
export const POP_FAMILY='pop',POP_VERSION=2;
export function popCourseKey(direction,points){let hash=2166136261;for(const char of JSON.stringify(points.map(p=>p.map(v=>Math.round(v*100))))){hash^=char.charCodeAt(0);hash=Math.imul(hash,16777619);}return `cit_bus_best_v2_pop_${direction}_${(hash>>>0).toString(16).padStart(8,'0')}`;}
export function generatePopCourses(){
 const sample=(controls,count)=>new THREE.CatmullRomCurve3(controls.map(([x,z,y=0])=>new THREE.Vector3(x,y,z)),false,'centripetal').getSpacedPoints(count).map(p=>[Number(p.x.toFixed(3)),Number(p.z.toFixed(3)),Number(Math.max(0,p.y).toFixed(3))]);
 const outward=sample([[0,0],[0,-110],[80,-250],[100,-390],[-60,-520],[-110,-640],[0,-790],[0,-910]],240);
 const bay=sample([[-160,160],[-190,55],[-135,-70],[-70,-145],[0,-175],[75,-140],[125,-60],[80,15,6],[0,0,12],[-80,-25,6],[-125,70],[-75,150],[0,185],[95,135],[160,40],[135,-65],[60,-20],[0,0],[-80,50],[-160,160]],400);
 const neon=sample([[0,0],[0,-300],[0,-700],[0,-1000],[35,-1120],[110,-1170],[155,-1120],[145,-1060],[105,-1020],[160,-950],[220,-830],[240,-350],[240,-100],[170,20],[0,0]],500);
 return [outward,[...outward].reverse(),bay,neon].map((points,i)=>{const direction=['outward','return','s_bay','neon_city'][i],name=['キャンパス便：津田沼 → 新習志野','キャンパス便：新習志野 → 津田沼','S字ベイサーキット（非公式インスパイア）','ネオンストリート（非公式インスパイア）'][i],length=points.slice(1).reduce((sum,p,j)=>sum+Math.hypot(p[0]-points[j][0],p[1]-points[j][1]),0);return{id:direction,direction,name,family:POP_FAMILY,version:POP_VERSION,key:popCourseKey(direction,points),length,points,checkpointSpacing:150,corridor:48,layerAware:true,...(direction==='neon_city'?{sphere:{x:230,z:-1110}}:{})};});
}
