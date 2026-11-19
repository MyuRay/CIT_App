import {closestSegment} from './geo.mjs';
export function courseFromRoute(route){
 const segments=[],checkpoints=[],points=route.points;if(!Array.isArray(points)||points.length<2)throw new Error('Invalid course');let length=0;
 for(let i=1;i<points.length;i++){const a=points[i-1],b=points[i],distance=Math.hypot(b[0]-a[0],b[1]-a[1]);if(!distance)continue;segments.push({a,b,start:length,end:length+distance});length+=distance;}
 if(!segments.length)throw new Error('Empty course');const at=progress=>{const s=segments.find(s=>s.end>=progress)??segments.at(-1),t=Math.max(0,Math.min(1,(progress-s.start)/(s.end-s.start)));return{x:s.a[0]+(s.b[0]-s.a[0])*t,z:s.a[1]+(s.b[1]-s.a[1])*t,y:(s.a[2]??0)+((s.b[2]??0)-(s.a[2]??0))*t,progress};};
 for(let distance=150;distance<length-25;distance+=150)checkpoints.push(at(distance));checkpoints.push(at(length));
 let hash=2166136261;for(const char of JSON.stringify(points.map(p=>p.map(v=>Math.round(v*100))))){hash^=char.charCodeAt(0);hash=Math.imul(hash,16777619);}
 return{id:route.id,length,segments,checkpoints,start:at(0),goal:at(length),family:route.family??'campus',corridor:route.corridor??7,layerAware:route.layerAware??false,pointAt:at,key:route.key??`cit_bus_best_v1_${route.id}_${(hash>>>0).toString(16).padStart(8,'0')}`};
}
export class TimeAttack {
 constructor({clock=()=>performance.now(),onFinish=()=>{}}={}){this.clock=clock;this.onFinish=onFinish;this.phase='idle';this.reason='';this.course=null;this.elapsed=0;this.nextCheckpoint=0;this.progress=0;this.lastTime=null;this.lastPosition=null;this.penaltyMs=0;}
 arm(course,position,startTime=this.clock()+3000){this.course=course;this.phase='countdown';this.reason='';this.elapsed=0;this.nextCheckpoint=0;this.progress=0;this.penaltyMs=0;this.startTime=startTime;this.lastTime=this.clock();this.lastPosition={...position};}
 cancel(reason='中断'){if(this.phase==='countdown'||this.phase==='running'){this.phase='invalid';this.reason=reason;}}
 get countdown(){return this.phase==='countdown'?Math.max(1,Math.ceil((this.startTime-this.clock())/1000)):0;}
 tick(position,{mode='bus',onCourse=true,foreground=true}={}){
  if(!['countdown','running'].includes(this.phase))return;
  const now=this.clock();if(!Number.isFinite(now)||now<this.lastTime){this.cancel('時計が変更されました');return;}
  if((mode!=='bus'&&!(this.course.family==='pop'&&mode==='car'))||!foreground){this.cancel('走行が中断されました');return;}
  const distance=Math.hypot(position.x-this.lastPosition.x,position.z-this.lastPosition.z),vertical=Math.abs(position.y-this.lastPosition.y),dt=now-this.lastTime;
  if(this.phase==='countdown'){
   if(distance>.1||vertical>.1){this.cancel('スタート前に移動しました');return;}
   if(now<this.startTime){this.lastTime=now;return;}this.phase='running';this.lastTime=this.startTime;
  }
  if(now-this.startTime>3600000){this.cancel('制限時間（60分）を超えました');return;}
  if(now-this.lastTime>1500){this.cancel('処理が長く止まりました');return;}
  if(distance>22*Math.max(dt,0)/1000+.8||vertical>4+8*Math.max(dt,0)/1000){this.cancel('位置が飛びました');return;}
  if(!onCourse){this.cancel('コース外へ出ました');return;}
  const maxAdvance=distance*1.5+6;let nearest=null;
  for(const segment of this.course.segments){if(segment.end<this.progress-35||segment.start>this.progress+maxAdvance+25)continue;const p=closestSegment(position.x,position.z,segment.a,segment.b);if(this.course.layerAware&&Math.abs(position.y-1.4-((segment.a[2]??0)+((segment.b[2]??0)-(segment.a[2]??0))*p.t))>5)continue;const progress=segment.start+(segment.end-segment.start)*p.t;if(!nearest||p.distance<nearest.distance)nearest={...p,progress};}
  if(!nearest||nearest.distance>this.course.corridor){this.cancel('コースから外れました');return;}
  if(nearest.progress>this.progress+maxAdvance){this.cancel('チェックポイントを飛ばしました');return;}
  const checkpoint=this.course.checkpoints[this.nextCheckpoint];
  if(checkpoint&&nearest.progress>checkpoint.progress+18){this.cancel('チェックポイント未通過');return;}
  if(checkpoint&&nearest.progress>=checkpoint.progress-14&&Math.hypot(position.x-checkpoint.x,position.z-checkpoint.z)<=14)this.nextCheckpoint++;
  this.progress=Math.max(this.progress,nearest.progress);this.elapsed=now-this.startTime+this.penaltyMs;this.lastTime=now;this.lastPosition={...position};
  if(this.nextCheckpoint===this.course.checkpoints.length&&Math.hypot(position.x-this.course.goal.x,position.z-this.course.goal.z)<=8&&this.progress>=this.course.length-8){
   if(this.elapsed<this.course.length/22*1000-1000){this.cancel('計測を確認できません');return;}
   this.phase='finished';this.onFinish({key:this.course.key,milliseconds:Math.round(this.elapsed),routeId:this.course.id});
  }
 }
 recover(position,progress,penaltyMs){if(this.course?.family!=='pop'||!['running','invalid'].includes(this.phase)||!Number.isFinite(progress)||progress<0||progress>this.course.length||!Number.isFinite(penaltyMs)||penaltyMs<this.penaltyMs)return false;this.phase='running';this.reason='';this.progress=progress;this.penaltyMs=penaltyMs;this.nextCheckpoint=this.course.checkpoints.findIndex(c=>c.progress>progress+.01);if(this.nextCheckpoint<0)this.nextCheckpoint=this.course.checkpoints.length;this.lastPosition={...position};this.lastTime=this.clock();this.elapsed=this.lastTime-this.startTime+this.penaltyMs;return true;}
 get state(){return{penaltyMs:this.penaltyMs,phase:this.phase,reason:this.reason,elapsed:this.elapsed,countdown:this.countdown,progress:this.progress,nextCheckpoint:this.nextCheckpoint,checkpointCount:this.course?.checkpoints.length??0,routeId:this.course?.id??null,key:this.course?.key??null};}
}
export function validBest(value){return typeof value==='number'&&Number.isFinite(value)&&value>0&&value<=3600000;}
export function formatRaceTime(milliseconds){if(!validBest(milliseconds))return'—';const total=Math.floor(milliseconds/10),minutes=Math.floor(total/6000),seconds=Math.floor(total/100)%60,hundredths=total%100;return`${minutes}:${String(seconds).padStart(2,'0')}.${String(hundredths).padStart(2,'0')}`;}
