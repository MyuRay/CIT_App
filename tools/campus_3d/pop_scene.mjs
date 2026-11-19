import * as THREE from 'three';
import {closestSegment}from './geo.mjs';
const mat=(color,emissive=0)=>new THREE.MeshStandardMaterial({color,emissive,emissiveIntensity:.35,roughness:.85});
function meshBox(group,size,pos,material){const mesh=new THREE.Mesh(new THREE.BoxGeometry(...size),material);mesh.position.set(...pos);group.add(mesh);return mesh;}
function dispose(group){group.traverse(o=>{o.geometry?.dispose();o.material?.map?.dispose();o.material?.dispose();});}
function ribbon(points,width,offset,color){const positions=[];for(let i=1;i<points.length;i++){const a=points[i-1],b=points[i],dx=b[0]-a[0],dz=b[1]-a[1],n=Math.hypot(dx,dz)||1,x=-dz/n*width/2,z=dx/n*width/2,ay=(a[2]??0)+offset,by=(b[2]??0)+offset;positions.push(a[0]+x,ay,a[1]+z,a[0]-x,ay,a[1]-z,b[0]+x,by,b[1]+z,b[0]+x,by,b[1]+z,a[0]-x,ay,a[1]-z,b[0]-x,by,b[1]-z);}const geometry=new THREE.BufferGeometry();geometry.setAttribute('position',new THREE.Float32BufferAttribute(positions,3));geometry.computeVertexNormals();const material=mat(color);material.side=THREE.DoubleSide;return new THREE.Mesh(geometry,material);}
export function projectPopCourse(course,x,z,{currentY=null,progress=null,offset=1.4}={}){
 let nearest=null,along=0;for(let i=1;i<course.points.length;i++){const a=course.points[i-1],b=course.points[i],length=Math.hypot(b[0]-a[0],b[1]-a[1]),end=along+length,p=closestSegment(x,z,a,b),y=(a[2]??0)+((b[2]??0)-(a[2]??0))*p.t,target=along+length*p.t;
  if((progress==null||end>=progress-100&&along<=progress+120)&&(currentY==null||Math.abs(y+offset-currentY)<4)&&(!nearest||p.distance<nearest.distance))nearest={...p,y,progress:target,index:i};along=end;
 }return nearest;
}
function campus(group,name,x,z,blue){const white=mat(0xfff8eb),color=mat(blue),glass=mat(0x405972);const root=new THREE.Group();root.name=name;root.position.set(x,0,z);group.add(root);if(name==='PopTsudanuma'){for(const [i,height]of [62,50,30].entries()){meshBox(root,[16,height,18],[i*21-21,height/2,0],white);meshBox(root,[17,3,19],[i*21-21,height-4,0],color);for(let row=8;row<height-7;row+=8)meshBox(root,[16.2,2,18.2],[i*21-21,row,0],glass);}}else{for(let i=0;i<5;i++){meshBox(root,[20,12+i%2*6,26],[i%3*24-24,6+i%2*3,Math.floor(i/3)*32],white);meshBox(root,[21,2,27],[i%3*24-24,13+i%2*6,Math.floor(i/3)*32],color);}meshBox(root,[60,.1,34],[0,.1,-45],mat(0x45dcb1));}return root;}
export async function createPopWorld({scene,signal,reducedMotion=false,onCourse=()=>{}}){
 const response=await fetch('pop_courses.json',{signal});if(!response.ok)throw new Error('Game course unavailable');const file=await response.json();let group=null,selectedRoute=null,sphere=null,pathProgress=0;const routes=file.courses.map(c=>({...c,id:c.direction,distance:c.length}));
 const world={experience:'game',reducedMotion,data:{routes,family:'pop',version:2},groundBase:0,maxAltitude:90,buildings:[],collisionTriangles:0,carSpawn:null,busSpawn:null,planeSpawn:null,carYaw:0,busYaw:0,selectedRoute:null,
 roadDistance(x,z){return projectPopCourse(selectedRoute,x,z)?.distance??Infinity;},
 terrainHeight(x,z,currentY=null,mode='bus'){const offset=mode==='car'?.8:1.4;const p=projectPopCourse(selectedRoute,x,z,{currentY,progress:currentY==null?null:pathProgress,offset});if(p&&p.distance<48){if(currentY!=null)pathProgress=p.progress;return p.y;}return 0;},
 meshCollision:()=>false,cameraDistance:(_origin,_direction,max)=>max,
 description(position){const p=projectPopCourse(selectedRoute,position.x,position.z);return{course:selectedRoute.id,progress:p?.progress??0,roadDistance:p?.distance??Infinity,theme:'fictional game',campusesLoaded:['pop-tsudanuma','pop-narashino']};},
 setProgress:progress=>pathProgress=progress,
 update(){if(sphere&&!reducedMotion)sphere.material.uniforms.phase.value=performance.now()/18000;},
 disposeCollision(){if(group){scene.remove(group);dispose(group);group=null;}},
 get sphere(){return sphere?{position:sphere.position.toArray(),radius:38,originalPattern:true,reducedMotion}:null;},
 };
 world.roadIndex={surface:(x,z,currentY=null,mode='bus')=>{const p=projectPopCourse(selectedRoute,x,z,{currentY,offset:mode==='car'?.8:1.4});return p?{height:p.y,road:{name:selectedRoute.name}}:null;}};
 world.setRoute=id=>{
  const course=routes.find(r=>r.id===id);if(!course)return;world.disposeCollision();group=new THREE.Group();group.name='OriginalPopGameWorld';scene.add(group);selectedRoute=world.selectedRoute=course;pathProgress=0;sphere=null;const xs=course.points.map(p=>p[0]),zs=course.points.map(p=>p[1]),bounds={min:{x:Math.min(...xs)-180,z:Math.min(...zs)-180},max:{x:Math.max(...xs)+180,z:Math.max(...zs)+180}};world.groundBounds=world.flightBounds=bounds;
  const start=course.points[0],next=course.points[1],yaw=Math.atan2(-(next[0]-start[0]),-(next[1]-start[1]));world.busSpawn={x:start[0],y:start[2]+1.4,z:start[1]};world.carSpawn={x:start[0],y:start[2]+.8,z:start[1]};world.planeSpawn={x:start[0],y:start[2]+25,z:start[1]};world.carYaw=world.busYaw=yaw;
  const neon=id==='neon_city';scene.background=new THREE.Color(neon?0x18224d:0xb4ecff);scene.fog=new THREE.Fog(scene.background,450,1800);
  meshBox(group,[bounds.max.x-bounds.min.x,.4,bounds.max.z-bounds.min.z],[(bounds.max.x+bounds.min.x)/2,-.3,(bounds.max.z+bounds.min.z)/2],mat(neon?0x344263:0x93deb0));
  const startBack=[start[0]+Math.sin(yaw)*28,start[1]+Math.cos(yaw)*28,start[2]],roadPoints=[startBack,...course.points];group.add(ribbon(roadPoints,48,.015,neon?0x444c91:0xf3d59b),ribbon(roadPoints,24,.04,neon?0x263259:0x52657b),ribbon(roadPoints,.25,.08,0xffeabb));
  for(let i=0;i<course.points.length;i+=8){const p=course.points[i],n=course.points[Math.min(i+1,course.points.length-1)],angle=Math.atan2(n[0]-p[0],n[1]-p[1]);for(const sign of [-1,1]){const x=p[0]+Math.cos(angle)*14*sign,z=p[1]-Math.sin(angle)*14*sign;const bollard=meshBox(group,[.45,1.4,.45],[x,p[2]+.7,z],mat(i%16?0xffffff:0xffac73));if(neon)bollard.material.emissive.set(0x6ccfff);}}
  const a=course.points[0],b=course.points.at(-1);campus(group,id==='return'?'PopNarashino':'PopTsudanuma',a[0]-85,a[1]+25,id==='return'?0x09c5a5:0x5077ee);campus(group,id==='return'?'PopTsudanuma':'PopNarashino',b[0]+90,b[1]-25,id==='return'?0x5077ee:0x09c5a5);
  for(let i=0;i<36;i++){const p=course.points[Math.floor(i*course.points.length/36)],angle=i*2.399,x=p[0]+Math.cos(angle)*75,z=p[1]+Math.sin(angle)*75;if(world.roadDistance(x,z)<32)continue;const cone=new THREE.Mesh(new THREE.ConeGeometry(5,12,6),mat(neon?0x615c91:0x38b589));cone.position.set(x,8,z);group.add(cone);meshBox(group,[1.5,3,1.5],[x,1.5,z],mat(0xc49d75));}
  if(neon){const location=course.sphere??{x:125,z:-280};const material=new THREE.ShaderMaterial({uniforms:{phase:{value:0}},vertexShader:'varying vec3 v;void main(){v=position;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}',fragmentShader:'varying vec3 v;uniform float phase;void main(){float k=.5+.5*sin(v.y*.13+v.x*.08+phase);vec3 c=mix(vec3(.2,.82,1.),vec3(.96,.38,.7),k);gl_FragColor=vec4(c,1.);}'});sphere=new THREE.Mesh(new THREE.SphereGeometry(38,40,24),material);sphere.name='OriginalNeonSphere';sphere.position.set(location.x,38,location.z);group.add(sphere);for(let i=0;i<12;i++){const p=course.points[Math.floor(i*course.points.length/12)],side=i%2?1:-1,x=p[0]+side*85;if((p[1]<0&&p[1]>location.z&&Math.abs(x-location.x*p[1]/location.z)<25)||(p[0]<30&&p[1]>-1000&&side>0)||Math.hypot(x-location.x,p[1]-location.z)<80)continue;meshBox(group,[18,25+(i%4)*12,20],[x,(25+(i%4)*12)/2,p[1]],mat(i%2?0x6973c9:0xba68ba,i%2?0x1e274e:0x4b214b));}}
  onCourse(course);return course;
 };
 world.setRoute('outward');return world;
}
