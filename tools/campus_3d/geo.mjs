export const EARTH_RADIUS=6378137;
export function project(lon,lat,origin){return{x:(lon-origin[0])*Math.PI/180*EARTH_RADIUS*Math.cos(origin[1]*Math.PI/180),z:-(lat-origin[1])*Math.PI/180*EARTH_RADIUS};}
export function unproject(x,z,origin){return{lon:origin[0]+x/(EARTH_RADIUS*Math.cos(origin[1]*Math.PI/180))*180/Math.PI,lat:origin[1]-z/EARTH_RADIUS*180/Math.PI};}
export function insidePolygon(x,z,poly){let inside=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const a=poly[i],b=poly[j];if((a[1]>z)!==(b[1]>z)&&x<(b[0]-a[0])*(z-a[1])/(b[1]-a[1])+a[0])inside=!inside;}return inside;}
export function sampleTerrain(terrain,x,z){const fx=(x-terrain.x)/terrain.step,fz=(z-terrain.z)/terrain.step;if(fx<0||fz<0||fx>terrain.nx-1||fz>terrain.nz-1)return null;const ix=Math.min(Math.floor(fx),terrain.nx-2),iz=Math.min(Math.floor(fz),terrain.nz-2),u=fx-ix,v=fz-iz;const ids=[iz*terrain.nx+ix,iz*terrain.nx+ix+1,(iz+1)*terrain.nx+ix,(iz+1)*terrain.nx+ix+1],weights=[(1-u)*(1-v),u*(1-v),(1-u)*v,u*v];let sum=0,total=0;ids.forEach((id,i)=>{const h=terrain.heights[id];if(h!=null){sum+=h*weights[i];total+=weights[i];}});return total?sum/total:null;}
export function closestSegment(x,z,a,b){const dx=b[0]-a[0],dz=b[1]-a[1],length=dx*dx+dz*dz,t=length?Math.max(0,Math.min(1,((x-a[0])*dx+(z-a[1])*dz)/length)):0;const px=a[0]+dx*t,pz=a[1]+dz*t;return{distance:Math.hypot(x-px,z-pz),t,x:px,z:pz};}
export class RoadIndex {
 constructor(roads,terrain){this.terrain=terrain;this.cells=new Map();this.segments=[];
  for(const road of roads){if(!road.drive)continue;for(let i=1;i<road.points.length;i++){const a=road.points[i-1],b=road.points[i],s={a,b,road};this.segments.push(s);for(let x=Math.floor((Math.min(a[0],b[0])-road.width)/80);x<=Math.floor((Math.max(a[0],b[0])+road.width)/80);x++)for(let z=Math.floor((Math.min(a[1],b[1])-road.width)/80);z<=Math.floor((Math.max(a[1],b[1])+road.width)/80);z++){const key=`${x},${z}`;if(!this.cells.has(key))this.cells.set(key,[]);this.cells.get(key).push(s);}}}
 }
 candidates(x,z){return(this.cells.get(`${Math.floor(x/80)},${Math.floor(z/80)}`)??[]).map(s=>({...s,...closestSegment(x,z,s.a,s.b)})).sort((a,b)=>a.distance-b.distance);}
 surface(x,z,currentY=null,mode='car'){const ground=sampleTerrain(this.terrain,x,z);if(ground==null)return null;for(const s of this.candidates(x,z)){if(s.distance>Math.max(.3,s.road.width/2-(mode==='bus'?1.4:1.15)))continue;const height=s.a[2]+(s.b[2]-s.a[2])*s.t;if(currentY!=null&&Math.abs(height+(mode==='bus'?1.4:.8)-currentY)>.65)continue;return{height,road:s.road};}return null;}
}
