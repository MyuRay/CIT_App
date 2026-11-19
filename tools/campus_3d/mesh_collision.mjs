import * as THREE from 'three';
import {MeshBVH, StaticGeometryGenerator} from 'three-mesh-bvh';

const box=(min,max)=>new THREE.Box3(new THREE.Vector3(...min),new THREE.Vector3(...max));
const shapes={bus:[box([-1.38,-1.28,-4.16],[1.38,1.87,4.16])],car:[box([-1.16,-.79,-2.08],[1.16,1.08,2.08])],plane:[box([-.78,-.95,-4.48],[.78,1.02,3.1]),box([-5.6,-1.28,-.98],[5.6,1.28,.98]),box([-2.1,-.8,1.85],[2.1,1.85,3.3])]};
export function createMeshCollision(roots){
  const meshes=[];const seen=new Set();
  for(const root of roots)root.traverse(o=>{if(o.isMesh&&!seen.has(o.uuid)){meshes.push(o);seen.add(o.uuid);}});
  const generator=new StaticGeometryGenerator(meshes);generator.attributes=['position'];generator.useGroups=false;generator.applyWorldTransforms=true;
  const geometry=generator.generate();const bvh=new MeshBVH(geometry,{targetLeafSize:12});
  const matrix=new THREE.Matrix4();
  const collides=(p,mode,yaw=0)=>{
    matrix.makeRotationY(yaw);matrix.setPosition(p.x,p.y,p.z);
    return (shapes[mode]??shapes.car).some(shape=>bvh.intersectsBox(shape,matrix));
  };
  const cameraDistance=(origin,direction,maxDistance)=>{
    const hit=bvh.raycastFirst(new THREE.Ray(origin,direction),THREE.DoubleSide);
    return hit&&hit.distance<maxDistance?Math.max(2,hit.distance-.8):maxDistance;
  };
  return{collides,cameraDistance,triangleCount:geometry.index?geometry.index.count/3:geometry.attributes.position.count/3,dispose:()=>geometry.dispose()};
}
