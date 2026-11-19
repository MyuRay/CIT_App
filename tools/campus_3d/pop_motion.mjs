import {clamp}from './vehicle_motion.mjs';
export class PopMotion{
 constructor(world){this.world=world;this.mode='bus';this.reset();}
 setMode(mode){if(['free','car','bus','plane'].includes(mode)){this.mode=mode;this.reset();}}
 reset(){this.position={...(this.mode==='plane'?this.world.planeSpawn:this.mode==='bus'?this.world.busSpawn:this.world.carSpawn)};this.yaw=this.world.busYaw??0;this.speed=0;this.steering=0;this.blocked='';}
 stop(){this.speed=0;this.steering=0;this.blocked='';}
 step(elapsed,input){if(this.mode==='free')return;const dt=clamp(elapsed,0,.1),steps=Math.max(1,Math.ceil(dt/.01));for(let i=0;i<steps;i++)this._step(dt/steps,input);}
 _step(dt,input){const ground=this.mode!=='plane',bus=this.mode==='bus',brake=Boolean(input.brake)||input.throttle<0,accelerate=!brake&&(Boolean(input.accelerate)||input.throttle>0);const roadDistance=this.world.roadDistance(this.position.x,this.position.z),max=ground?(roadDistance<=12?22:roadDistance<=24?12:6):32;
  if(brake)this.speed=Math.max(0,this.speed-14*dt);else if(accelerate)this.speed=Math.min(max,this.speed+(bus?7:9)*dt);else this.speed=Math.max(0,this.speed-2.2*dt);if(this.speed>max)this.speed=Math.max(max,this.speed-12*dt);
  this.steering+=(clamp(input.steer??0,-1,1)-this.steering)*(1-Math.exp(-dt*9));this.yaw+=this.steering*dt*(ground?(bus?1.3:1.5)*(.45+.55*Math.min(this.speed/5,1)):1);
  const p={x:this.position.x-Math.sin(this.yaw)*this.speed*dt,z:this.position.z-Math.cos(this.yaw)*this.speed*dt,y:this.position.y};const bounds=this.world.flightBounds,margin=ground?3:5;const oldX=p.x,oldZ=p.z;p.x=clamp(p.x,bounds.min.x+margin,bounds.max.x-margin);p.z=clamp(p.z,bounds.min.z+margin,bounds.max.z-margin);this.blocked=oldX!==p.x||oldZ!==p.z?'境界に沿って走行':ground&&roadDistance>12?'路肩・ゆっくり走行':'';
  const height=this.world.terrainHeight(p.x,p.z,ground?this.position.y:null,this.mode);p.y=ground?height+(bus?1.4:.8):clamp(p.y+(input.lift??0)*9*dt,height+4,90);this.position=p;
 }
}
