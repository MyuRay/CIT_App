import * as THREE from 'three';
import {Sky} from 'three/addons/objects/Sky.js';
export function outdoorLighting(renderer,scene){
 const sky=new Sky();sky.scale.setScalar(450000);sky.material.uniforms.turbidity.value=3.5;sky.material.uniforms.rayleigh.value=2;sky.material.uniforms.mieCoefficient.value=.005;sky.material.uniforms.mieDirectionalG.value=.8;sky.material.uniforms.sunPosition.value.set(-.45,.75,.4).normalize();
 const environmentScene=new THREE.Scene();environmentScene.add(sky);const pmrem=new THREE.PMREMGenerator(renderer),target=pmrem.fromScene(environmentScene,.05);scene.environment=target.texture;scene.environmentIntensity=.08;renderer.toneMappingExposure=.9;pmrem.dispose();sky.geometry.dispose();sky.material.dispose();
 renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;
 const sun=scene.children.find(o=>o.isDirectionalLight);sun.castShadow=true;sun.shadow.mapSize.set(512,512);sun.shadow.camera.left=sun.shadow.camera.bottom=-140;sun.shadow.camera.right=sun.shadow.camera.top=140;sun.shadow.camera.near=.5;sun.shadow.camera.far=650;sun.shadow.bias=-.0005;sun.shadow.normalBias=.3;
 scene.add(sun.target);sun.intensity=2.5;scene.children.find(o=>o.isHemisphereLight).intensity=1.6;
 return{follow:p=>{sun.position.set(p.x-150,p.y+250,p.z+100);sun.target.position.set(p.x,p.y,p.z);sun.target.updateMatrixWorld();},dispose:()=>{target.dispose();sun.shadow.map?.dispose();}};
}
export function shadeCampus(root){root.traverse(o=>{if(!o.isMesh)return;o.receiveShadow=true;let parent=o,casts=false;while(parent){if(parent.userData.building_id||/^Building_|^Dorm_|^Campus_Annex/.test(parent.name)){casts=true;break;}parent=parent.parent;}o.castShadow=casts;for(const material of Array.isArray(o.material)?o.material:[o.material]){if(!material?.isMeshStandardMaterial)continue;material.envMapIntensity=/glass|spandrel|solar/.test(material.name)?.85:.35;if(/glass/.test(material.name))material.roughness=Math.min(material.roughness,.22);material.needsUpdate=true;}});}
