import * as THREE from 'three';
import {overlapsBuilding} from './vehicle_motion.mjs';

// Spawn beside the requested landmark, on ground and clear of both vehicles.
export function selectCampusVehicleSpawns({campus,scene,world}) {
 let landmark;
 scene.traverse(object=>{
  if(landmark)return;
  if(campus==='tsudanuma'&&object.isMesh&&object.material?.name==='sculpture')landmark=object;
  if(campus==='narashino'&&String(object.userData?.building_id)==='12')landmark=object;
 });
 if(!landmark)return null;
 const viewMeshes=[];
 scene.traverse(object=>{if(object.isMesh)viewMeshes.push({mesh:object,box:new THREE.Box3().setFromObject(object)});});
 const viewRay=new THREE.Raycaster(),intersection=new THREE.Vector3();
 function blockedView(distance){
  return viewMeshes.some(({mesh,box})=>{
   if(!viewRay.ray.intersectBox(box,intersection)||(!box.containsPoint(viewRay.ray.origin)&&intersection.distanceTo(viewRay.ray.origin)>distance))return false;
   return viewRay.intersectObject(mesh,false).some(hit=>hit.distance<distance-.3);
  });
 }
 function clearView(point,mode,yaw){
  const car=mode==='car',target=new THREE.Vector3(point.x,point.y+(car?.9:0),point.z);
  const direction=new THREE.Vector3(Math.sin(yaw)*(car?11:24),car?5:32,Math.cos(yaw)*(car?11:24));
  const distance=direction.length(),camera=target.clone().add(direction);
  viewRay.set(target,direction.normalize());viewRay.far=distance;
  if(blockedView(distance))return false;
  viewRay.set(camera,direction.negate());
  return !blockedView(distance);
 }
 const box=new THREE.Box3().setFromObject(landmark),center=box.getCenter(new THREE.Vector3()),points=[];
 if(campus==='tsudanuma'){
  for(const radius of [9,12,16,22])for(let i=0;i<16;i++){
   const angle=i*Math.PI/8;points.push({x:center.x+Math.sin(angle)*radius,z:center.z+Math.cos(angle)*radius});
  }
 }else{
  for(const gap of [8,12,16])for(const fraction of [.2,.35,.5,.65,.8]){
   const x=box.min.x+(box.max.x-box.min.x)*fraction,z=box.min.z+(box.max.z-box.min.z)*fraction;
   points.push({x:box.min.x-gap,z},{x:box.max.x+gap,z},{x,z:box.min.z-gap},{x,z:box.max.z+gap});
  }
 }
 function safe(x,z,y,mode,yaw){
  const margin=mode==='plane'?5.5:2.2,bounds=world.groundBounds;
  if(x<bounds.min.x+margin||x>bounds.max.x-margin||z<bounds.min.z+margin||z>bounds.max.z-margin)return false;
  // Mesh intersections alone cannot identify a fully enclosed building interior.
  if(world.buildings.some(b=>x>b.min.x-margin&&x<b.max.x+margin&&z>b.min.z-margin&&z<b.max.z+margin))return false;
  return !overlapsBuilding({x,y,z},mode,world,yaw);
 }
 let selected=null,best=Infinity;
 for(const point of points){
  const ground=world.terrainHeight(point.x,point.z);if(ground==null)continue;
  const car={...point,y:ground+.8},plane={...point,y:ground+3};
  for(let i=0;i<16;i++){
   const yaw=i*Math.PI/8;if(!safe(point.x,point.z,car.y,'car',yaw)||!safe(point.x,point.z,plane.y,'plane',yaw))continue;
   let clearance=0;
   for(const distance of [3,6,10,15,20]){
    const x=point.x-Math.sin(yaw)*distance,z=point.z-Math.cos(yaw)*distance,h=world.terrainHeight(x,z);
    if(h==null||Math.abs(h-ground)>.65||!safe(x,z,h+.8,'car',yaw)||!safe(x,z,h+3,'plane',yaw))break;
    clearance=distance;
   }
   if(clearance<10)continue;
   const distance=campus==='tsudanuma'?Math.hypot(point.x-center.x,point.z-center.z):box.distanceToPoint(new THREE.Vector3(point.x,box.min.y,point.z));
   const score=distance-clearance*.4;
   if(score<best&&clearView(car,'car',yaw)&&clearView(plane,'plane',yaw)){best=score;selected={carSpawn:car,planeSpawn:plane,carYaw:yaw+Math.PI,planeYaw:yaw+Math.PI};}
  }
 }
 return selected;
}
