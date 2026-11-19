import {terrainQuality} from './terrain_quality.mjs';
import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js';
import {createMeshCollision} from './mesh_collision.mjs';
import {shadeCampus} from './visual_quality.mjs';
import {RoadIndex,insidePolygon,sampleTerrain,unproject} from './geo.mjs';

const building=o=>o.userData.building_id||/^(Building_|Campus_Annex_|Dorm_Common)/.test(o.name);
const groundName=/^(Site_Base|Landscape_Ground|Campus_Ground|Landscape_Paving|Sports_Fields)$/;
const disposeObject=root=>root?.traverse(o=>{o.geometry?.dispose();for(const m of Array.isArray(o.material)?o.material:[o.material]){m?.map?.dispose();m?.dispose();}});
function ribbon(points,width){const positions=[];for(let i=1;i<points.length;i++){const a=points[i-1],b=points[i],dx=b[0]-a[0],dz=b[1]-a[1],len=Math.hypot(dx,dz);if(!len)continue;const x=-dz/len*width/2,z=dx/len*width/2,A=[a[0]+x,a[2],a[1]+z],B=[a[0]-x,a[2],a[1]-z],C=[b[0]+x,b[2],b[1]+z],D=[b[0]-x,b[2],b[1]-z];positions.push(...A,...C,...B,...B,...C,...D);}const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(positions,3));g.computeVertexNormals();return g;}
export function prepareRoads(data){
 const nodePoints=new Map(),adjacency=new Map(),raise=new Map(),queue=[];
 for(const r of data.roads){r.points.forEach((p,i)=>{nodePoints.set(r.nodes[i],p);if(!adjacency.has(r.nodes[i]))adjacency.set(r.nodes[i],[]);});for(let i=1;i<r.nodes.length;i++){const a=r.nodes[i-1],b=r.nodes[i],length=Math.hypot(r.points[i][0]-r.points[i-1][0],r.points[i][1]-r.points[i-1][1]);adjacency.get(a).push([b,length]);adjacency.get(b).push([a,length]);}
  if(r.tags.bridge==='yes'||r.tags.bridge==='viaduct'){const delta=Math.max(3,4.5*Math.max(1,Number(r.tags.layer)||1));r.nodes.forEach(id=>{raise.set(id,Math.max(raise.get(id)||0,delta));queue.push(id);});}
 }
 // Ramps propagate only through shared OSM nodes, never through 2D crossings.
 for(let index=0;index<queue.length;index++){const id=queue[index],height=raise.get(id);for(const [next,length]of adjacency.get(id)??[]){const candidate=height-length*.075;if(candidate>0&&candidate>(raise.get(next)||0)+.001){raise.set(next,candidate);queue.push(next);}}}
 for(const r of data.roads){const original=r.points,points=[];for(let i=1;i<original.length;i++){const a=original[i-1],b=original[i],count=Math.max(1,Math.ceil(Math.hypot(b[0]-a[0],b[1]-a[1])/8));for(let j=0;j<count;j++){const t=j/count,x=a[0]+(b[0]-a[0])*t,z=a[1]+(b[1]-a[1])*t,delta=(raise.get(r.nodes[i-1])||0)*(1-t)+(raise.get(r.nodes[i])||0)*t;points.push([x,z,(sampleTerrain(data.terrain,x,z)??0)+.12+delta]);}}const p=original.at(-1);if(p)points.push([p[0],p[1],(sampleTerrain(data.terrain,p[0],p[1])??0)+.12+(raise.get(r.nodes.at(-1))||0)]);r.points=points;}
 return data.roads;
}
function terrainTile(data,photo,divisions){const positions=[],uv=[],indices=[];const min=photo.min,max=photo.max;for(let iz=0;iz<=divisions;iz++)for(let ix=0;ix<=divisions;ix++){const x=min[0]+(max[0]-min[0])*ix/divisions,z=min[1]+(max[1]-min[1])*iz/divisions;positions.push(x,(sampleTerrain(data.terrain,x,z)??0)+(photo.z===18?.025:.005),z);uv.push(ix/divisions,1-iz/divisions);}for(let z=0;z<divisions;z++)for(let x=0;x<divisions;x++){const a=z*(divisions+1)+x,b=a+1,c=a+divisions+1,d=c+1;indices.push(a,c,b,b,c,d);}const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(positions,3));g.setAttribute('uv',new THREE.Float32BufferAttribute(uv,2));g.setIndex(indices);g.computeVertexNormals();return g;}
function contextGeometry(data){const groups=new Map(),roots=[];const material=new THREE.MeshStandardMaterial({color:0xbcb7ac,roughness:.9});for(const b of data.buildings){const p=b.points;if(p.length<4)continue;const cx=p.reduce((v,p)=>v+p[0],0)/p.length,cz=p.reduce((v,p)=>v+p[1],0)/p.length;const shape=new THREE.Shape(p.map(p=>new THREE.Vector2(p[0]-cx,-(p[1]-cz))));const g=new THREE.ExtrudeGeometry(shape,{depth:b.height,bevelEnabled:false,steps:1});g.rotateX(-Math.PI/2);g.translate(cx,sampleTerrain(data.terrain,cx,cz)??0,cz);const key=`${Math.floor(cx/300)},${Math.floor(cz/300)}`;if(!groups.has(key))groups.set(key,[]);groups.get(key).push(g);}
 for(const [key,geometries]of groups){const merged=mergeGeometries(geometries,false);geometries.forEach(g=>g.dispose());const mesh=new THREE.Mesh(merged,material);mesh.castShadow=true;mesh.userData.cell=key.split(',').map(Number);mesh.receiveShadow=true;roots.push(mesh);}return roots;}

export async function createRegion({scene,currentCampus,currentScene,currentWorld,currentMotion,camera,controls,signal,onProgress,isDisposed,preloadedCampuses=[]}){
 onProgress('道路・地形を準備中…');const response=await fetch('region.json',{signal});if(!response.ok)throw Error('Region asset unavailable');const data=await response.json();if(isDisposed())throw Error('Disposed');
 const group=new THREE.Group();group.name='ConnectedRegion';const height=(x,z)=>sampleTerrain(data.terrain,x,z),roads=prepareRoads(data),roadIndex=new RoadIndex(roads,data.terrain);
 const context=contextGeometry(data);context.forEach(o=>group.add(o));const contextCollision=createMeshCollision(context);
 const materials={road:new THREE.MeshStandardMaterial({color:0x41474b,roughness:.95,side:THREE.DoubleSide}),private:new THREE.MeshStandardMaterial({color:0x747870,roughness:.95,side:THREE.DoubleSide}),walk:new THREE.MeshStandardMaterial({color:0xb9afa0,roughness:1,side:THREE.DoubleSide})};
 const batches={road:[],private:[],walk:[]};for(const r of roads){if(r.points.length<2)continue;const key=r.drive?(r.private?'private':'road'):(r.highway.startsWith('motorway')?'road':'walk');batches[key].push(ribbon(r.points,r.width));}
 for(const [key,geometries]of Object.entries(batches)){if(!geometries.length)continue;const merged=mergeGeometries(geometries);geometries.forEach(g=>g.dispose());const mesh=new THREE.Mesh(merged,materials[key]);mesh.receiveShadow=true;group.add(mesh);}
 const coarsePhoto={min:[data.terrain.x,data.terrain.z],max:[data.terrain.x+(data.terrain.nx-1)*data.terrain.step,data.terrain.z+(data.terrain.nz-1)*data.terrain.step],z:0};
 const base=new THREE.Mesh(terrainTile(data,coarsePhoto,128),new THREE.MeshStandardMaterial({color:0x8d977d,roughness:1,side:THREE.DoubleSide}));base.receiveShadow=true;group.add(base);
 const tiles=data.photos.map(photo=>({photo,mesh:null,loading:false,failed:false,center:new THREE.Vector3((photo.min[0]+photo.max[0])/2,0,(photo.min[1]+photo.max[1])/2)}));let tileLoads=0,alive=true;
 const textureLoader=new THREE.TextureLoader();const refreshTiles=position=>{if(typeof document==='undefined')return;for(const tile of tiles){const distance=Math.hypot(position.x-tile.center.x,position.z-tile.center.z),range=tile.photo.z===18?500:1600;if(tile.mesh){tile.mesh.visible=distance<range;continue;}if(!alive||tile.failed||tile.loading||distance>range||tileLoads>=3)continue;tile.loading=true;tileLoads++;textureLoader.load(`region/${tile.photo.file}`,texture=>{tileLoads--;if(!alive){texture.dispose();return;}texture.colorSpace=THREE.SRGBColorSpace;texture.anisotropy=4;const mesh=new THREE.Mesh(terrainTile(data,tile.photo,tile.photo.z===18?12:24),new THREE.MeshStandardMaterial({map:texture,roughness:1,side:THREE.DoubleSide}));mesh.receiveShadow=true;tile.mesh=mesh;group.add(mesh);},undefined,()=>{tileLoads--;tile.failed=true;});}};
 const campuses=new Map();let startedOther=false;
 const blockedGates=(data.gates??[]).filter(g=>g.motorcarNo||g.locked);
 const barrierMaterial=new THREE.MeshStandardMaterial({color:0xc1463d,roughness:.8});
 for(const g of blockedGates){const mesh=new THREE.Mesh(new THREE.BoxGeometry(3,.18,.18),barrierMaterial);mesh.position.set(g.point[0],(height(...g.point)??0)+.75,g.point[1]);group.add(mesh);}

 function placeCampus(id,root){const definition=data.campuses.find(c=>c.id===id),offset=definition.offset;root.position.x=offset[0];root.position.z=offset[1];root.updateMatrixWorld(true);
  for(const o of root.children){if(building(o)){const b=new THREE.Box3().setFromObject(o),c=b.getCenter(new THREE.Vector3());o.position.y+=(height(c.x,c.z)??definition.altitude??0);}
   else o.traverse(mesh=>{if(!mesh.isMesh)return;if(groundName.test(o.name)){mesh.visible=false;return;}const p=mesh.geometry.attributes.position;for(let i=0;i<p.count;i++)p.setY(i,p.getY(i)+(height(p.getX(i)+offset[0],p.getZ(i)+offset[1])??definition.altitude??0));p.needsUpdate=true;mesh.geometry.computeVertexNormals();mesh.geometry.computeBoundingBox();mesh.geometry.computeBoundingSphere();});}
  root.updateMatrixWorld(true);const buildingRoots=root.children.filter(building),collision=createMeshCollision(buildingRoots);campuses.set(id,{root,collision,definition});
 }
 placeCampus(currentCampus,currentScene);for(const c of preloadedCampuses){scene.add(c.scene);shadeCampus(c.scene);placeCampus(c.id,c.scene);}const definition=data.campuses.find(c=>c.id===currentCampus),offset=definition.offset;
 const shift=new THREE.Vector3(offset[0],0,offset[1]);camera.position.add(shift);controls.target.add(shift);currentMotion.position.x+=offset[0];currentMotion.position.z+=offset[1];currentMotion.position.y+=(height(currentMotion.position.x,currentMotion.position.z)??definition.altitude??0);
 const carSpawn={x:currentWorld.carSpawn.x+offset[0],z:currentWorld.carSpawn.z+offset[1]};carSpawn.y=(height(carSpawn.x,carSpawn.z)??definition.altitude??0)+.8;
 const maxAltitude=400,groundBounds={min:{x:coarsePhoto.min[0],z:coarsePhoto.min[1]},max:{x:coarsePhoto.max[0],z:coarsePhoto.max[1]}},planeSpawn={x:offset[0],y:(definition.altitude??0)+140,z:offset[1]};
 const allCollisions=()=>[contextCollision,...[...campuses.values()].map(c=>c.collision)];
 const world={carSpawn,carYaw:currentWorld.carYaw,planeSpawn,groundBounds,flightBounds:groundBounds,groundBase:0,maxAltitude,buildings:currentWorld.buildings,collisionTriangles:contextCollision.triangleCount+campuses.get(currentCampus).collision.triangleCount,
  terrainHeight:(x,z,currentY=null,mode='car')=>{const ground=height(x,z);if(currentY==null)return ground;if(data.campuses.some(c=>insidePolygon(x,z,c.boundary)))return ground;return roadIndex.surface(x,z,currentY,mode)?.height??null;},
  meshCollision:(p,mode,yaw)=>(['car','bus'].includes(mode)&&blockedGates.some(g=>Math.hypot(p.x-g.point[0],p.z-g.point[1])<2.5))||allCollisions().some(c=>c.collides(p,mode,yaw)),cameraDistance:(origin,direction,max)=>allCollisions().reduce((distance,c)=>Math.min(distance,c.cameraDistance(origin,direction,max)),max),
  disposeCollision:()=>{alive=false;allCollisions().forEach(c=>c.dispose());disposeObject(group);for(const c of campuses.values())if(c.root!==currentScene){scene.remove(c.root);disposeObject(c.root);}scene.remove(group);},
  update:position=>{refreshTiles(position);context.forEach(mesh=>{const [x,z]=mesh.userData.cell;mesh.visible=Math.hypot(position.x-(x+.5)*300,position.z-(z+.5)*300)<1800;});for(const c of campuses.values())c.root.visible=Math.hypot(position.x-c.definition.offset[0],position.z-c.definition.offset[1])<1400;
   if(!startedOther&&campuses.size<2){const other=data.campuses.find(c=>c.id!==currentCampus);if(Math.hypot(position.x-other.offset[0],position.z-other.offset[1])<1000){startedOther=true;onProgress('到着先の建物を読み込み中…');new GLTFLoader().loadAsync(other.id==='narashino'?'shinnarashino-campus.glb':'tsudanuma-campus.glb').then(gltf=>{if(!alive){disposeObject(gltf.scene);return;}shadeCampus(gltf.scene);scene.add(gltf.scene);placeCampus(other.id,gltf.scene);onProgress('');}).catch(()=>{startedOther=false;onProgress('到着先モデルを読み込めませんでした');});}}
  },
  description:position=>{const geo=unproject(position.x,position.z,data.origin);return{...geo,elevation:height(position.x,position.z),...terrainQuality(data.terrain,position.x,position.z),campusesLoaded:[...campuses.keys()],road:roadIndex.surface(position.x,position.z)?.road.name??''};},
  data,roadIndex,group
 };
 const routeMaterial=new THREE.LineBasicMaterial({color:0x087cce,transparent:true,opacity:.9,depthTest:false});let guide;
 world.setRoute=id=>{if(guide){group.remove(guide);guide.geometry.dispose();}const route=data.routes.find(r=>r.id===id);if(!route)return;const positions=route.points.flatMap(p=>[p[0],(roadIndex.surface(p[0],p[1])?.height??height(p[0],p[1])??0)+.35,p[1]]);const geometry=new THREE.BufferGeometry();geometry.setAttribute('position',new THREE.Float32BufferAttribute(positions,3));guide=new THREE.Line(geometry,routeMaterial);guide.renderOrder=5;group.add(guide);world.selectedRoute=route;};
 world.setRoute(currentCampus==='tsudanuma'?'outward':'return');scene.add(group);refreshTiles(currentMotion.position);onProgress('');return world;
}
