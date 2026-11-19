export class HeldButtons{
 constructor(){this.owners=new Map();this.values=new Set();}
 begin(action,id){if(this.owners.has(id)||this.values.has(action))return false;this.owners.set(id,action);this.values.add(action);return true;}
 release(id){const action=this.owners.get(id);this.owners.delete(id);if(action)this.values.delete(action);}
 clear(){this.owners.clear();this.values.clear();}
 axes(mode){const brake=this.values.has('brake'),accelerate=!brake&&this.values.has('accelerate');return{brake,accelerate,throttle:brake?-1:accelerate?1:0,steer:Number(this.values.has('left'))-Number(this.values.has('right')),lift:mode==='plane'?Number(this.values.has('up'))-Number(this.values.has('down')):0};}
}
export function installGameButtons(input,{enabled,mode,signal}){
 const parent=document.querySelector('.controls');parent.innerHTML='<div class="drive-buttons" aria-label="方向"><button data-drive="left" aria-label="左に曲がる">◀<small>左</small></button><button data-drive="right" aria-label="右に曲がる">▶<small>右</small></button><button data-drive="up" class="plane-direction" aria-label="上昇">▲<small>上昇</small></button><button data-drive="down" class="plane-direction" aria-label="下降">▼<small>下降</small></button></div><div class="pedals" aria-label="ペダル"><button data-drive="brake" aria-label="ブレーキ">■<small>ブレーキ</small></button><button data-drive="accelerate" aria-label="アクセル">▲<small>アクセル</small></button></div>';
 const buttons=[...parent.querySelectorAll('[data-drive]')],draw=()=>buttons.forEach(b=>b.classList.toggle('held',input.values.has(b.dataset.drive)));
 for(const button of buttons)button.addEventListener('pointerdown',e=>{e.preventDefault();e.stopPropagation();if(!enabled()||!input.begin(button.dataset.drive,e.pointerId))return;try{button.setPointerCapture(e.pointerId);}catch{}draw();},{signal});
 window.addEventListener('pointermove',e=>{if(input.owners.has(e.pointerId)){e.preventDefault();e.stopPropagation();}},{signal,capture:true});
 for(const type of ['pointerup','pointercancel'])window.addEventListener(type,e=>{if(!input.owners.has(e.pointerId))return;e.preventDefault();e.stopPropagation();input.release(e.pointerId);draw();},{signal,capture:true});
 for(const button of buttons)button.addEventListener('lostpointercapture',e=>{if(input.owners.get(e.pointerId)!==button.dataset.drive)return;input.release(e.pointerId);draw();},{signal});
 return()=>{for(const [id,action]of input.owners){const button=buttons.find(b=>b.dataset.drive===action);if(button?.hasPointerCapture(id))button.releasePointerCapture(id);}input.clear();draw();};
}
