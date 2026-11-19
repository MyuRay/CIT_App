export const clamp=(n,min,max)=>Math.max(min,Math.min(max,n));
export function stickVector(dx,dy,radius,horizontalOnly=false){
  let x=dx/radius,y=horizontalOnly?0:dy/radius;
  const length=Math.hypot(x,y);
  if(length<.12)return{x:0,y:0};
  if(length>1){x/=length;y/=length;}
  return{x,y};
}
export class StickInput {
  constructor(){this.values={left:{x:0,y:0},right:{x:0,y:0}};this.pointers=new Map();}
  begin(side,id){if(this.pointers.has(id)||[...this.pointers.values()].includes(side))return false;this.pointers.set(id,side);return true;}
  move(id,x,y){const side=this.pointers.get(id);if(!side)return false;this.values[side]={x:clamp(x,-1,1),y:clamp(y,-1,1)};return true;}
  release(id){const side=this.pointers.get(id);if(side)this.values[side]={x:0,y:0};this.pointers.delete(id);}
  clear(){this.pointers.clear();this.values={left:{x:0,y:0},right:{x:0,y:0}};}
  axes(mode){return{throttle:-this.values.left.y||0,steer:-this.values.right.x||0,lift:['car','bus'].includes(mode)?0:(-this.values.right.y||0)};}
}
export function bindSticks(input,{mode,enabled,signal}){
  const pads=[...document.querySelectorAll('[data-stick]')];
  const options={signal},moves=new Map();
  const draw=()=>pads.forEach(p=>{const v=input.values[p.dataset.stick];const r=p.clientWidth*.28;p.querySelector('.knob').style.transform=`translate(${v.x*r}px,${v.y*r}px)`;p.classList.toggle('active',Math.hypot(v.x,v.y)>.01);});
  const release=(pad,id)=>{if(input.pointers.get(id)!==pad.dataset.stick)return;input.release(id);if(pad.hasPointerCapture(id))pad.releasePointerCapture(id);draw();};
  for(const pad of pads){
    const move=e=>{
      if(input.pointers.get(e.pointerId)!==pad.dataset.stick)return;
      e.preventDefault();e.stopPropagation();const b=pad.getBoundingClientRect();
      const v=stickVector(e.clientX-(b.left+b.width/2),e.clientY-(b.top+b.height/2),b.width*.3,pad.dataset.stick==='left'||['car','bus'].includes(mode()));
      // The throttle stick is vertical, not horizontal.
      if(pad.dataset.stick==='left'){const a=stickVector(0,e.clientY-(b.top+b.height/2),b.height*.3);v.x=0;v.y=a.y;}
      input.move(e.pointerId,v.x,v.y);draw();
    };
    pad.addEventListener('pointerdown',e=>{e.preventDefault();e.stopPropagation();if(!enabled()||!input.begin(pad.dataset.stick,e.pointerId))return;try{pad.setPointerCapture(e.pointerId);}catch{/* Global pointer tracking retains ownership if capture is unavailable. */}move(e);},options);
    moves.set(pad.dataset.stick,move);
    ['pointerup','pointercancel','lostpointercapture'].forEach(type=>pad.addEventListener(type,e=>release(pad,e.pointerId),options));
  }
  // Route by the original pointer owner, including moves outside the pad.
  window.addEventListener('pointermove',e=>moves.get(input.pointers.get(e.pointerId))?.(e),{signal,capture:true});
  for(const type of ['pointerup','pointercancel'])window.addEventListener(type,e=>{const side=input.pointers.get(e.pointerId);if(!side)return;e.preventDefault();e.stopPropagation();release(pads.find(p=>p.dataset.stick===side),e.pointerId);},{signal,capture:true});
  return()=>{for(const pad of pads){for(const[id,side]of input.pointers)if(side===pad.dataset.stick&&pad.hasPointerCapture(id))pad.releasePointerCapture(id);}input.clear();draw();};
}
