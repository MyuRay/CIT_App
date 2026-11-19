export const clamp = (v, a, b) => Math.max(a, Math.min(b, v));

export function overlapsBuilding(p, mode, world, yaw=0) {
  if(world.meshCollision) return world.meshCollision(p,mode,yaw);
  const r = mode === 'car' ? 2.2 : 5.5;
  const h = mode === 'car' ? 0.9 : 1.2;
  return world.buildings.some(b => p.x > b.min.x-r && p.x < b.max.x+r && p.z > b.min.z-r && p.z < b.max.z+r && p.y+h > b.min.y && p.y-h < b.max.y);
}

export class VehicleMotion {
  constructor(world) { this.world=world; this.mode='free'; this.position={...world.carSpawn}; this.yaw=world.carYaw??0; this.speed=0; this.blocked=''; this.pitch=0; this.landingCount=0; this.airborne=false; }
  setMode(mode) {
    if (!['free','car','plane','bus'].includes(mode)) return;
    this.mode=mode; this.reset();
  }
  reset() {
    this.speed=0; this.blocked=''; this.pitch=0; this.airborne=false;
    this.position={...(this.mode==='plane'?this.world.planeSpawn:this.mode==='bus'?this.world.busSpawn:this.world.carSpawn)};
    this.yaw=this.mode==='plane'?(this.world.planeYaw??0):(this.mode==='bus'?(this.world.busYaw??0):(this.world.carYaw??0));
  }
  stop() { this.speed=0; this.blocked=''; }
  step(elapsed, input) {
    if(this.mode==='free') return;
    const dt=clamp(elapsed,0,0.1);
    const count=Math.max(1,Math.ceil(dt/0.01));
    for(let i=0;i<count;i++) this._step(dt/count,input);
  }
  _step(dt, input) {
    if(dt<=0)return;
    let landed=false,nextAirborne=this.airborne,nextPitch=this.pitch;
    const bus=this.mode==='bus',car=this.mode==='car'||bus,offset=bus?1.4:.8;
    const throttle=input instanceof Set?Number(input.has('accelerate'))-Number(input.has('brake')):clamp(input.throttle??0,-1,1);
    const steer=input instanceof Set?Number(input.has('left'))-Number(input.has('right')):clamp(input.steer??0,-1,1);
    const lift=input instanceof Set?Number(input.has('up'))-Number(input.has('down')):clamp(input.lift??0,-1,1);
    const acceleration=bus?4:car?7:9;
    if(throttle) this.speed+=throttle*acceleration*dt;
    else if(car) this.speed*=Math.exp(-0.8*dt);
    this.speed=clamp(this.speed,car?(bus?-3:-4):-8,bus?22:car?14:40);
    if(Math.abs(this.speed)<0.02) this.speed=0;
    // Ground steering requires motion; aircraft yaw is intentionally arcade-like.
    const yaw=this.yaw+steer*dt*(car?(bus?.9:1.1)*Math.min(Math.abs(this.speed)/3,1)*Math.sign(this.speed):0.75);
    const p={x:this.position.x-Math.sin(yaw)*this.speed*dt,y:this.position.y+(car?0:lift*12*dt),z:this.position.z-Math.cos(yaw)*this.speed*dt};
    const ground=this.world.terrainHeight(p.x,p.z,car?this.position.y:null,this.mode);
    const b=car?this.world.groundBounds:this.world.flightBounds;
    const margin=bus?4.2:car?2.2:5.5;
    if(p.x<b.min.x+margin || p.x>b.max.x-margin || p.z<b.min.z+margin || p.z>b.max.z-margin || (car&&ground==null)) {
      this.speed=0; this.blocked='範囲の端'; return;
    }
    if(car) {
      if(Math.abs((ground+offset)-this.position.y)>0.65) {this.speed=0;this.blocked='段差';return;}
      p.y=ground+offset;
    } else {
      let surface=ground??this.world.groundBase;
      for(const building of this.world.buildings){
        if(p.x>building.min.x&&p.x<building.max.x&&p.z>building.min.z&&p.z<building.max.z&&this.position.y>=building.max.y+2.9)
          surface=Math.max(surface,building.max.y);
      }
      const floor=surface+3;
      p.y=clamp(p.y,floor,this.world.maxAltitude);
      if(p.y>floor+2)nextAirborne=true;
      if(nextAirborne&&p.y<=floor+.001&&lift<=0){landed=true;nextAirborne=false;}
      const vertical=(p.y-this.position.y)/dt;
      const targetPitch=p.y<=floor+.001?0:clamp(Math.atan2(vertical,Math.abs(this.speed)+8),-.42,.42);
      nextPitch+=(targetPitch-this.pitch)*(1-Math.exp(-dt*7));
    }
    if(overlapsBuilding(p,this.mode,this.world,yaw)) {this.speed=0;this.blocked='建物の手前';return;}
    this.airborne=nextAirborne;this.pitch=nextPitch;if(landed){this.landingCount++;this.speed*=.45;}
    this.position=p; this.yaw=yaw; this.blocked='';
  }
}
