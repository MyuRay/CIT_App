import * as THREE from 'three';
const material=(color)=>new THREE.MeshStandardMaterial({color,roughness:0.6,metalness:0.15});
const box=(group,size,pos,mat)=>{const mesh=new THREE.Mesh(new THREE.BoxGeometry(...size),mat);mesh.position.set(...pos);group.add(mesh);return mesh;};
export function makeBus(){
 const bus=new THREE.Group();bus.name='OriginalCampusBus';
 const white=material(0xf5f8f8),blue=material(0x087cbe),glass=material(0x152e44),rubber=material(0x162631),light=material(0xffffce),red=material(0xdb3038);
 box(bus,[2.45,2.55,7.8],[0,1.7,0],white);box(bus,[2.48,.5,7.82],[0,1.05,0],blue);box(bus,[2.2,.2,7.4],[0,3.05,0],blue);
 for(const x of [-1.235,1.235])for(const z of [-2.8,-1.4,0,1.4,2.8])box(bus,[.035,.85,1.12],[x,2.2,z],glass);
 box(bus,[2.12,1.05,.035],[0,2.16,-3.915],glass);box(bus,[1.8,.18,.04],[0,2.88,-3.92],glass);
 box(bus,[1.8,.8,.035],[0,2.2,3.915],glass);box(bus,[2.48,.13,.12],[0,.6,3.96],rubber);
 for(const x of [-.85,.85])box(bus,[.27,.32,.06],[x,.9,3.95],red);
 for(const x of [-.85,.85])box(bus,[.38,.22,.06],[x,.9,-3.95],light);
 const wheels=[];for(const x of [-1.25,1.25])for(const z of [-2.65,2.4]){const w=new THREE.Mesh(new THREE.CylinderGeometry(.5,.5,.2,12),rubber);w.rotation.z=Math.PI/2;w.position.set(x,.5,z);bus.add(w);wheels.push(w);}bus.userData.wheels=wheels;return bus;
}
export function makeCar() {
  const car=new THREE.Group();car.name='CampusCar';
  const blue=material(0x126bcc),glass=material(0x243f58),rubber=material(0x172735),white=material(0xf6f6f2);
  box(car,[1.85,0.6,3.8],[0,0.75,0],blue);
  box(car,[1.5,0.65,1.9],[0,1.35,0.15],glass);
  box(car,[1.55,0.1,2],[0,1.72,0.15],blue);
  for(const x of [-0.64,0.64])box(car,[0.38,0.2,0.12],[x,0.8,-1.93],white);
  const wheels=[];
  for(const x of [-1,1])for(const z of [-1.2,1.2]){
    const wheel=new THREE.Mesh(new THREE.CylinderGeometry(0.43,0.43,0.22,12),rubber);
    wheel.rotation.z=Math.PI/2;wheel.position.set(x,0.43,z);car.add(wheel);wheels.push(wheel);
  }
  car.userData.wheels=wheels;return car;
}
export function makePlane() {
  const plane=new THREE.Group();plane.name='CampusPlane';
  const white=material(0xfff8e8),orange=material(0xeb7824),glass=material(0x183f67);
  const body=new THREE.Mesh(new THREE.CylinderGeometry(0.58,0.58,5.8,12),white);body.rotation.x=Math.PI/2;plane.add(body);
  const nose=new THREE.Mesh(new THREE.ConeGeometry(0.58,1.4,12),orange);nose.rotation.x=-Math.PI/2;nose.position.z=-3.6;plane.add(nose);
  box(plane,[10.8,0.16,1.6],[0,0,0],orange);
  box(plane,[3.8,0.14,0.8],[0,0.1,2.5],orange);
  box(plane,[0.18,1.6,1.1],[0,0.85,2.4],orange);
  box(plane,[0.75,0.42,1.25],[0,0.5,-1.65],glass);
  const prop=new THREE.Group();prop.position.z=-4.32;
  box(prop,[2.7,0.15,0.1],[0,0,0],glass);plane.add(prop);plane.userData.propeller=prop;
  return plane;
}
