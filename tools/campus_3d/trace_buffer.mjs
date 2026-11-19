// Capture is independent of network requests. Never omit intermediate movement to hide a gap.
export class TraceBuffer {
 constructor({limit=32,cadenceMs=750,maxAgeMs=22000}={}){this.limit=limit;this.cadenceMs=cadenceMs;this.maxAgeMs=maxAgeMs;this.reset();}
 reset({baselineT=0,now=null}={}){this.samples=[];this.lastT=baselineT;this.lastCapturedAt=now;}
 clearPending(){this.samples=[];}
 capture(now,localStart,position,{force=false,layerAware=false}={}){
  if(this.lastCapturedAt!==null&&!force&&now-this.lastCapturedAt<this.cadenceMs)return false;
  const t=Math.max(1,Math.round(now-localStart));if(t<=this.lastT)return false;
  if(!Number.isFinite(t)||!Number.isFinite(position.x)||!Number.isFinite(position.z)||(layerAware&&!Number.isFinite(position.y)))throw new Error('走行位置を確認できません。復帰してください。');
  if(this.lastCapturedAt!==null&&now-this.lastCapturedAt>5000)throw new Error('位置記録の間隔が空きました。復帰してください。');
  if(this.samples.length>=this.limit)throw new Error('送信待ちの記録が上限に達しました。復帰してください。');
  this.samples.push({t,x:position.x,z:position.z,...(layerAware?{y:position.y}:{}),capturedAt:now});this.lastT=t;this.lastCapturedAt=now;return true;
 }
 take(now){if(this.samples.length&&now-this.samples[0].capturedAt>this.maxAgeMs)throw new Error('送信待ちの記録が古くなりました。復帰してください。');return this.samples.splice(0,32).map(({capturedAt,...sample})=>sample);}
 get size(){return this.samples.length;}
}
