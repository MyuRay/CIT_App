// Match the four terrain samples used by rendered bilinear interpolation.
// A neighbouring interpolated sample must remain visible in the quality label.
export function terrainQuality(terrain,x,z){
 const fx=(x-terrain.x)/terrain.step,fz=(z-terrain.z)/terrain.step;
 if(fx<0||fz<0||fx>terrain.nx-1||fz>terrain.nz-1)return{terrainEstimated:true,sourceMasks:0,terrainSourceLabel:'範囲外'};
 const ix=Math.min(Math.floor(fx),terrain.nx-2),iz=Math.min(Math.floor(fz),terrain.nz-2),u=fx-ix,v=fz-iz;
 const ids=[iz*terrain.nx+ix,iz*terrain.nx+ix+1,(iz+1)*terrain.nx+ix,(iz+1)*terrain.nx+ix+1],weights=[(1-u)*(1-v),u*(1-v),(1-u)*v,u*v];
 let estimated=false,masks=0;
 ids.forEach((id,i)=>{if(weights[i]<=1e-10)return;if(!terrain.known[id])estimated=true;masks|=terrain.sampleSources?.[id]??(terrain.known[id]?1:0);});
 const labels=[];if(masks&1)labels.push('DEM5A');if(masks&2)labels.push('DEM5B');if(masks&4)labels.push('DEM10B');
 return{terrainEstimated:estimated,sourceMasks:masks,terrainSourceLabel:estimated?'補間含む':labels.join('+')||'補間',sourceDerivedPercent:terrain.sourceDerivedPercent,interpolatedPercent:terrain.interpolatedPercent};
}
