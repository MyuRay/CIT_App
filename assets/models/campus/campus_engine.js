(()=>{function Vp(i,e,t,n){return i==="countdown"&&e==="running"?"GO!":e==="running"&&n>t?"CHECKPOINT!":null}function Po(i,{reducedMotion:e=!1,goal:t=!1}={}){if(typeof document>"u")return;document.querySelector("#drive-celebration")?.remove();let n=document.createElement("div");n.id="drive-celebration",n.setAttribute("role","status"),Object.assign(n.style,{position:"fixed",inset:"0",display:"grid",placeItems:"center",pointerEvents:"none",zIndex:"100",overflow:"hidden"});let s=document.createElement("div");if(s.textContent=i,Object.assign(s.style,{whiteSpace:"pre-line",textAlign:"center",fontSize:t?"clamp(24px,6vw,48px)":"clamp(22px,5vw,38px)",fontWeight:"900",color:"#fff",textShadow:"0 3px 0 #4d3191, 0 0 18px #ed64c0",background:"#452b80dd",border:"3px solid #ffe27b",borderRadius:"22px",padding:"18px 24px",transform:"rotate(-3deg)",boxShadow:"0 0 40px #ffc84a88"}),n.append(s),document.body.append(n),!e&&(s.animate([{transform:"scale(.6) rotate(-8deg)",opacity:0},{transform:"scale(1.08) rotate(2deg)",opacity:1,offset:.22},{transform:"scale(1) rotate(-3deg)",opacity:1}],{duration:550,easing:"ease-out"}),t))for(let r=0;r<32;r++){let o=document.createElement("i");Object.assign(o.style,{position:"absolute",left:r*3.13+"%",top:"45%",width:"10px",height:"18px",background:["#ffda5c","#fb7ac0","#65e8d0","#86adff"][r%4],borderRadius:"3px"}),n.append(o),o.animate([{transform:"translate(0,0) rotate(0)",opacity:1},{transform:"translate("+(r%7-3)*35+"px,-180px) rotate(220deg)",opacity:1,offset:.4},{transform:"translate("+(r%7-3)*55+"px,380px) rotate(700deg)",opacity:0}],{duration:1800+r%5*100,easing:"ease-out",fill:"forwards"})}setTimeout(()=>n.remove(),t?2800:1100)}var ms={LEFT:0,MIDDLE:1,RIGHT:2,ROTATE:0,DOLLY:1,PAN:2},gs={ROTATE:0,PAN:1,DOLLY_PAN:2,DOLLY_ROTATE:3},Fm=0,hf=1,Om=2;var Ca=1,wl=2,$r=3,kn=0,jt=1,Dt=2,Si=0,jr=1,ff=2,df=3,pf=4,Bm=5;var qs=100,zm=101,km=102,Vm=103,Hm=104,Gm=200,Wm=201,Xm=202,qm=203,mf=204,gf=205,Ym=206,Zm=207,Km=208,Jm=209,$m=210,jm=211,Qm=212,eg=213,tg=214,Yc=0,Zc=1,Kc=2,Lr=3,Jc=4,$c=5,jc=6,Qc=7,xf=0,ng=1,ig=2,oi=0,_f=1,yf=2,vf=3,Pa=4,Sf=5,bf=6,Mf=7,Yh="attached",sg="detached",Tf=300,xs=301,Ys=302,El=303,Al=304,Ia=306,cs=1e3,Zn=1001,Nr=1002,Ht=1003,Rl=1004;var Zs=1005;var Gt=1006,Qr=1007;var ai=1008;var Dn=1009,wf=1010,Ef=1011,eo=1012,Cl=1013,ci=1014,Vn=1015,li=1016,Pl=1017,Il=1018,to=1020,Af=35902,Rf=35899,Cf=1021,Pf=1022,Hn=1023,_i=1026,_s=1027,Ll=1028,Nl=1029,ys=1030,Dl=1031;var Ul=1033,La=33776,Na=33777,Da=33778,Ua=33779,Fl=35840,Ol=35841,Bl=35842,zl=35843,kl=36196,Vl=37492,Hl=37496,Gl=37488,Wl=37489,Fa=37490,Xl=37491,ql=37808,Yl=37809,Zl=37810,Kl=37811,Jl=37812,$l=37813,jl=37814,Ql=37815,eu=37816,tu=37817,nu=37818,iu=37819,su=37820,ru=37821,ou=36492,au=36494,cu=36495,lu=36283,uu=36284,Oa=36285,hu=36286;var Us=2300,Fs=2301,Wc=2302,Zh=2303,Kh=2400,Jh=2401,$h=2402,rg=2500;var If=0,Ba=1,no=2,og=3200;var fu=0,ag=1,Xi="",Ft="srgb",bn="srgb-linear",Yo="linear",yt="srgb";var Xc=7680;var cg=519,lg=512,ug=513,hg=514,du=515,fg=516,dg=517,pu=518,pg=519,Lf=35044;var Nf="300 es",si=2e3,Dr=2001;function Bx(i){for(let e=i.length-1;e>=0;--e)if(i[e]>=65535)return!0;return!1}function zx(i){return ArrayBuffer.isView(i)&&!(i instanceof DataView)}function Ur(i){return document.createElementNS("http://www.w3.org/1999/xhtml",i)}function mg(){let i=Ur("canvas");return i.style.display="block",i}var Hp={},Fr=null;function Zo(...i){let e="THREE."+i.shift();Fr?Fr("log",e,...i):console.log(e,...i)}function gg(i){let e=i[0];if(typeof e=="string"&&e.startsWith("TSL:")){let t=i[1];t&&t.isStackTrace?i[0]+=" "+t.getLocation():i[1]='Stack trace not available. Enable "THREE.Node.captureStackTrace" to capture stack traces.'}return i}function Fe(...i){i=gg(i);let e="THREE."+i.shift();if(Fr)Fr("warn",e,...i);else{let t=i[0];t&&t.isStackTrace?console.warn(t.getError(e)):console.warn(e,...i)}}function We(...i){i=gg(i);let e="THREE."+i.shift();if(Fr)Fr("error",e,...i);else{let t=i[0];t&&t.isStackTrace?console.error(t.getError(e)):console.error(e,...i)}}function Ds(...i){let e=i.join(" ");e in Hp||(Hp[e]=!0,Fe(...i))}function xg(i,e,t){return new Promise(function(n,s){function r(){switch(i.clientWaitSync(e,i.SYNC_FLUSH_COMMANDS_BIT,0)){case i.WAIT_FAILED:s();break;case i.TIMEOUT_EXPIRED:setTimeout(r,t);break;default:n()}}setTimeout(r,t)})}var _g={[Yc]:Zc,[Kc]:jc,[Jc]:Qc,[Lr]:$c,[Zc]:Yc,[jc]:Kc,[Qc]:Jc,[$c]:Lr},ri=class{addEventListener(e,t){this._listeners===void 0&&(this._listeners={});let n=this._listeners;n[e]===void 0&&(n[e]=[]),n[e].indexOf(t)===-1&&n[e].push(t)}hasEventListener(e,t){let n=this._listeners;return n===void 0?!1:n[e]!==void 0&&n[e].indexOf(t)!==-1}removeEventListener(e,t){let n=this._listeners;if(n===void 0)return;let s=n[e];if(s!==void 0){let r=s.indexOf(t);r!==-1&&s.splice(r,1)}}dispatchEvent(e){let t=this._listeners;if(t===void 0)return;let n=t[e.type];if(n!==void 0){e.target=this;let s=n.slice(0);for(let r=0,o=s.length;r<o;r++)s[r].call(this,e);e.target=null}}},fn=["00","01","02","03","04","05","06","07","08","09","0a","0b","0c","0d","0e","0f","10","11","12","13","14","15","16","17","18","19","1a","1b","1c","1d","1e","1f","20","21","22","23","24","25","26","27","28","29","2a","2b","2c","2d","2e","2f","30","31","32","33","34","35","36","37","38","39","3a","3b","3c","3d","3e","3f","40","41","42","43","44","45","46","47","48","49","4a","4b","4c","4d","4e","4f","50","51","52","53","54","55","56","57","58","59","5a","5b","5c","5d","5e","5f","60","61","62","63","64","65","66","67","68","69","6a","6b","6c","6d","6e","6f","70","71","72","73","74","75","76","77","78","79","7a","7b","7c","7d","7e","7f","80","81","82","83","84","85","86","87","88","89","8a","8b","8c","8d","8e","8f","90","91","92","93","94","95","96","97","98","99","9a","9b","9c","9d","9e","9f","a0","a1","a2","a3","a4","a5","a6","a7","a8","a9","aa","ab","ac","ad","ae","af","b0","b1","b2","b3","b4","b5","b6","b7","b8","b9","ba","bb","bc","bd","be","bf","c0","c1","c2","c3","c4","c5","c6","c7","c8","c9","ca","cb","cc","cd","ce","cf","d0","d1","d2","d3","d4","d5","d6","d7","d8","d9","da","db","dc","dd","de","df","e0","e1","e2","e3","e4","e5","e6","e7","e8","e9","ea","eb","ec","ed","ee","ef","f0","f1","f2","f3","f4","f5","f6","f7","f8","f9","fa","fb","fc","fd","fe","ff"],Gp=1234567,Go=Math.PI/180,Os=180/Math.PI;function Kn(){let i=Math.random()*4294967295|0,e=Math.random()*4294967295|0,t=Math.random()*4294967295|0,n=Math.random()*4294967295|0;return(fn[i&255]+fn[i>>8&255]+fn[i>>16&255]+fn[i>>24&255]+"-"+fn[e&255]+fn[e>>8&255]+"-"+fn[e>>16&15|64]+fn[e>>24&255]+"-"+fn[t&63|128]+fn[t>>8&255]+"-"+fn[t>>16&255]+fn[t>>24&255]+fn[n&255]+fn[n>>8&255]+fn[n>>16&255]+fn[n>>24&255]).toLowerCase()}function qe(i,e,t){return Math.max(e,Math.min(t,i))}function Df(i,e){return(i%e+e)%e}function kx(i,e,t,n,s){return n+(i-e)*(s-n)/(t-e)}function Vx(i,e,t){return i!==e?(t-i)/(e-i):0}function Wo(i,e,t){return(1-t)*i+t*e}function Hx(i,e,t,n){return Wo(i,e,1-Math.exp(-t*n))}function Gx(i,e=1){return e-Math.abs(Df(i,e*2)-e)}function Wx(i,e,t){return i<=e?0:i>=t?1:(i=(i-e)/(t-e),i*i*(3-2*i))}function Xx(i,e,t){return i<=e?0:i>=t?1:(i=(i-e)/(t-e),i*i*i*(i*(i*6-15)+10))}function qx(i,e){return i+Math.floor(Math.random()*(e-i+1))}function Yx(i,e){return i+Math.random()*(e-i)}function Zx(i){return i*(.5-Math.random())}function Kx(i){i!==void 0&&(Gp=i);let e=Gp+=1831565813;return e=Math.imul(e^e>>>15,e|1),e^=e+Math.imul(e^e>>>7,e|61),((e^e>>>14)>>>0)/4294967296}function Jx(i){return i*Go}function $x(i){return i*Os}function jx(i){return i>0&&Number.isInteger(i)&&2**Math.round(Math.log2(i))===i}function Qx(i){return Math.pow(2,Math.ceil(Math.log(i)/Math.LN2))}function e_(i){return Math.pow(2,Math.floor(Math.log(i)/Math.LN2))}function t_(i,e,t,n,s){let r=Math.cos,o=Math.sin,a=r(t/2),c=o(t/2),l=r((e+n)/2),u=o((e+n)/2),h=r((e-n)/2),f=o((e-n)/2),d=r((n-e)/2),m=o((n-e)/2);switch(s){case"XYX":i.set(a*u,c*h,c*f,a*l);break;case"YZY":i.set(c*f,a*u,c*h,a*l);break;case"ZXZ":i.set(c*h,c*f,a*u,a*l);break;case"XZX":i.set(a*u,c*m,c*d,a*l);break;case"YXY":i.set(c*d,a*u,c*m,a*l);break;case"ZYZ":i.set(c*m,c*d,a*u,a*l);break;default:Fe("MathUtils: .setQuaternionFromProperEuler() encountered an unknown order: "+s)}}function ii(i,e){switch(e.constructor){case Float32Array:return i;case Uint32Array:return i/4294967295;case Uint16Array:return i/65535;case Uint8Array:case Uint8ClampedArray:return i/255;case Int32Array:return Math.max(i/2147483647,-1);case Int16Array:return Math.max(i/32767,-1);case Int8Array:return Math.max(i/127,-1);default:throw new Error("THREE.MathUtils: Invalid component type.")}}function St(i,e){switch(e.constructor){case Float32Array:return i;case Uint32Array:return Math.round(i*4294967295);case Uint16Array:return Math.round(i*65535);case Uint8Array:case Uint8ClampedArray:return Math.round(i*255);case Int32Array:return Math.round(i*2147483647);case Int16Array:return Math.round(i*32767);case Int8Array:return Math.round(i*127);default:throw new Error("THREE.MathUtils: Invalid component type.")}}var qi={DEG2RAD:Go,RAD2DEG:Os,generateUUID:Kn,clamp:qe,euclideanModulo:Df,mapLinear:kx,inverseLerp:Vx,lerp:Wo,damp:Hx,pingpong:Gx,smoothstep:Wx,smootherstep:Xx,randInt:qx,randFloat:Yx,randFloatSpread:Zx,seededRandom:Kx,degToRad:Jx,radToDeg:$x,isPowerOfTwo:jx,ceilPowerOfTwo:Qx,floorPowerOfTwo:e_,setQuaternionFromProperEuler:t_,normalize:St,denormalize:ii},kf=class kf{constructor(e=0,t=0){this.x=e,this.y=t}get width(){return this.x}set width(e){this.x=e}get height(){return this.y}set height(e){this.y=e}set(e,t){return this.x=e,this.y=t,this}setScalar(e){return this.x=e,this.y=e,this}setX(e){return this.x=e,this}setY(e){return this.y=e,this}setComponent(e,t){switch(e){case 0:this.x=t;break;case 1:this.y=t;break;default:throw new Error("THREE.Vector2: index is out of range: "+e)}return this}getComponent(e){switch(e){case 0:return this.x;case 1:return this.y;default:throw new Error("THREE.Vector2: index is out of range: "+e)}}clone(){return new this.constructor(this.x,this.y)}copy(e){return this.x=e.x,this.y=e.y,this}add(e){return this.x+=e.x,this.y+=e.y,this}addScalar(e){return this.x+=e,this.y+=e,this}addVectors(e,t){return this.x=e.x+t.x,this.y=e.y+t.y,this}addScaledVector(e,t){return this.x+=e.x*t,this.y+=e.y*t,this}sub(e){return this.x-=e.x,this.y-=e.y,this}subScalar(e){return this.x-=e,this.y-=e,this}subVectors(e,t){return this.x=e.x-t.x,this.y=e.y-t.y,this}multiply(e){return this.x*=e.x,this.y*=e.y,this}multiplyScalar(e){return this.x*=e,this.y*=e,this}divide(e){return this.x/=e.x,this.y/=e.y,this}divideScalar(e){return this.multiplyScalar(1/e)}applyMatrix3(e){let t=this.x,n=this.y,s=e.elements;return this.x=s[0]*t+s[3]*n+s[6],this.y=s[1]*t+s[4]*n+s[7],this}min(e){return this.x=Math.min(this.x,e.x),this.y=Math.min(this.y,e.y),this}max(e){return this.x=Math.max(this.x,e.x),this.y=Math.max(this.y,e.y),this}clamp(e,t){return this.x=qe(this.x,e.x,t.x),this.y=qe(this.y,e.y,t.y),this}clampScalar(e,t){return this.x=qe(this.x,e,t),this.y=qe(this.y,e,t),this}clampLength(e,t){let n=this.length();return this.divideScalar(n||1).multiplyScalar(qe(n,e,t))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this}negate(){return this.x=-this.x,this.y=-this.y,this}dot(e){return this.x*e.x+this.y*e.y}cross(e){return this.x*e.y-this.y*e.x}lengthSq(){return this.x*this.x+this.y*this.y}length(){return Math.sqrt(this.x*this.x+this.y*this.y)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)}normalize(){return this.divideScalar(this.length()||1)}angle(){return Math.atan2(-this.y,-this.x)+Math.PI}angleTo(e){let t=Math.sqrt(this.lengthSq()*e.lengthSq());if(t===0)return Math.PI/2;let n=this.dot(e)/t;return Math.acos(qe(n,-1,1))}distanceTo(e){return Math.sqrt(this.distanceToSquared(e))}distanceToSquared(e){let t=this.x-e.x,n=this.y-e.y;return t*t+n*n}manhattanDistanceTo(e){return Math.abs(this.x-e.x)+Math.abs(this.y-e.y)}setLength(e){return this.normalize().multiplyScalar(e)}lerp(e,t){return this.x+=(e.x-this.x)*t,this.y+=(e.y-this.y)*t,this}lerpVectors(e,t,n){return this.x=e.x+(t.x-e.x)*n,this.y=e.y+(t.y-e.y)*n,this}equals(e){return e.x===this.x&&e.y===this.y}fromArray(e,t=0){return this.x=e[t],this.y=e[t+1],this}toArray(e=[],t=0){return e[t]=this.x,e[t+1]=this.y,e}fromBufferAttribute(e,t){return this.x=e.getX(t),this.y=e.getY(t),this}rotateAround(e,t){let n=Math.cos(t),s=Math.sin(t),r=this.x-e.x,o=this.y-e.y;return this.x=r*n-o*s+e.x,this.y=r*s+o*n+e.y,this}random(){return this.x=Math.random(),this.y=Math.random(),this}*[Symbol.iterator](){yield this.x,yield this.y}};kf.prototype.isVector2=!0;var ce=kf,pn=class{constructor(e=0,t=0,n=0,s=1){this.isQuaternion=!0,this._x=e,this._y=t,this._z=n,this._w=s}static slerpFlat(e,t,n,s,r,o,a){let c=n[s+0],l=n[s+1],u=n[s+2],h=n[s+3],f=r[o+0],d=r[o+1],m=r[o+2],x=r[o+3];if(h!==x||c!==f||l!==d||u!==m){let g=c*f+l*d+u*m+h*x;g<0&&(f=-f,d=-d,m=-m,x=-x,g=-g);let p=1-a;if(g<.9995){let v=Math.acos(g),b=Math.sin(v);p=Math.sin(p*v)/b,a=Math.sin(a*v)/b,c=c*p+f*a,l=l*p+d*a,u=u*p+m*a,h=h*p+x*a}else{c=c*p+f*a,l=l*p+d*a,u=u*p+m*a,h=h*p+x*a;let v=1/Math.sqrt(c*c+l*l+u*u+h*h);c*=v,l*=v,u*=v,h*=v}}e[t]=c,e[t+1]=l,e[t+2]=u,e[t+3]=h}static multiplyQuaternionsFlat(e,t,n,s,r,o){let a=n[s],c=n[s+1],l=n[s+2],u=n[s+3],h=r[o],f=r[o+1],d=r[o+2],m=r[o+3];return e[t]=a*m+u*h+c*d-l*f,e[t+1]=c*m+u*f+l*h-a*d,e[t+2]=l*m+u*d+a*f-c*h,e[t+3]=u*m-a*h-c*f-l*d,e}get x(){return this._x}set x(e){this._x=e,this._onChangeCallback()}get y(){return this._y}set y(e){this._y=e,this._onChangeCallback()}get z(){return this._z}set z(e){this._z=e,this._onChangeCallback()}get w(){return this._w}set w(e){this._w=e,this._onChangeCallback()}set(e,t,n,s){return this._x=e,this._y=t,this._z=n,this._w=s,this._onChangeCallback(),this}clone(){return new this.constructor(this._x,this._y,this._z,this._w)}copy(e){return this._x=e.x,this._y=e.y,this._z=e.z,this._w=e.w,this._onChangeCallback(),this}setFromEuler(e,t=!0){let n=e._x,s=e._y,r=e._z,o=e._order,a=Math.cos,c=Math.sin,l=a(n/2),u=a(s/2),h=a(r/2),f=c(n/2),d=c(s/2),m=c(r/2);switch(o){case"XYZ":this._x=f*u*h+l*d*m,this._y=l*d*h-f*u*m,this._z=l*u*m+f*d*h,this._w=l*u*h-f*d*m;break;case"YXZ":this._x=f*u*h+l*d*m,this._y=l*d*h-f*u*m,this._z=l*u*m-f*d*h,this._w=l*u*h+f*d*m;break;case"ZXY":this._x=f*u*h-l*d*m,this._y=l*d*h+f*u*m,this._z=l*u*m+f*d*h,this._w=l*u*h-f*d*m;break;case"ZYX":this._x=f*u*h-l*d*m,this._y=l*d*h+f*u*m,this._z=l*u*m-f*d*h,this._w=l*u*h+f*d*m;break;case"YZX":this._x=f*u*h+l*d*m,this._y=l*d*h+f*u*m,this._z=l*u*m-f*d*h,this._w=l*u*h-f*d*m;break;case"XZY":this._x=f*u*h-l*d*m,this._y=l*d*h-f*u*m,this._z=l*u*m+f*d*h,this._w=l*u*h+f*d*m;break;default:Fe("Quaternion: .setFromEuler() encountered an unknown order: "+o)}return t===!0&&this._onChangeCallback(),this}setFromAxisAngle(e,t){let n=t/2,s=Math.sin(n);return this._x=e.x*s,this._y=e.y*s,this._z=e.z*s,this._w=Math.cos(n),this._onChangeCallback(),this}setFromRotationMatrix(e){let t=e.elements,n=t[0],s=t[4],r=t[8],o=t[1],a=t[5],c=t[9],l=t[2],u=t[6],h=t[10],f=n+a+h;if(f>0){let d=.5/Math.sqrt(f+1);this._w=.25/d,this._x=(u-c)*d,this._y=(r-l)*d,this._z=(o-s)*d}else if(n>a&&n>h){let d=2*Math.sqrt(1+n-a-h);this._w=(u-c)/d,this._x=.25*d,this._y=(s+o)/d,this._z=(r+l)/d}else if(a>h){let d=2*Math.sqrt(1+a-n-h);this._w=(r-l)/d,this._x=(s+o)/d,this._y=.25*d,this._z=(c+u)/d}else{let d=2*Math.sqrt(1+h-n-a);this._w=(o-s)/d,this._x=(r+l)/d,this._y=(c+u)/d,this._z=.25*d}return this._onChangeCallback(),this}setFromUnitVectors(e,t){let n=e.dot(t)+1;return n<1e-8?(n=0,Math.abs(e.x)>Math.abs(e.z)?(this._x=-e.y,this._y=e.x,this._z=0,this._w=n):(this._x=0,this._y=-e.z,this._z=e.y,this._w=n)):(this._x=e.y*t.z-e.z*t.y,this._y=e.z*t.x-e.x*t.z,this._z=e.x*t.y-e.y*t.x,this._w=n),this.normalize()}angleTo(e){return 2*Math.acos(Math.abs(qe(this.dot(e),-1,1)))}rotateTowards(e,t){let n=this.angleTo(e);if(n===0)return this;let s=Math.min(1,t/n);return this.slerp(e,s),this}identity(){return this.set(0,0,0,1)}invert(){return this.conjugate()}conjugate(){return this._x*=-1,this._y*=-1,this._z*=-1,this._onChangeCallback(),this}dot(e){return this._x*e._x+this._y*e._y+this._z*e._z+this._w*e._w}lengthSq(){return this._x*this._x+this._y*this._y+this._z*this._z+this._w*this._w}length(){return Math.sqrt(this._x*this._x+this._y*this._y+this._z*this._z+this._w*this._w)}normalize(){let e=this.length();return e===0?(this._x=0,this._y=0,this._z=0,this._w=1):(e=1/e,this._x=this._x*e,this._y=this._y*e,this._z=this._z*e,this._w=this._w*e),this._onChangeCallback(),this}multiply(e){return this.multiplyQuaternions(this,e)}premultiply(e){return this.multiplyQuaternions(e,this)}multiplyQuaternions(e,t){let n=e._x,s=e._y,r=e._z,o=e._w,a=t._x,c=t._y,l=t._z,u=t._w;return this._x=n*u+o*a+s*l-r*c,this._y=s*u+o*c+r*a-n*l,this._z=r*u+o*l+n*c-s*a,this._w=o*u-n*a-s*c-r*l,this._onChangeCallback(),this}slerp(e,t){let n=e._x,s=e._y,r=e._z,o=e._w,a=this.dot(e);a<0&&(n=-n,s=-s,r=-r,o=-o,a=-a);let c=1-t;if(a<.9995){let l=Math.acos(a),u=Math.sin(l);c=Math.sin(c*l)/u,t=Math.sin(t*l)/u,this._x=this._x*c+n*t,this._y=this._y*c+s*t,this._z=this._z*c+r*t,this._w=this._w*c+o*t,this._onChangeCallback()}else this._x=this._x*c+n*t,this._y=this._y*c+s*t,this._z=this._z*c+r*t,this._w=this._w*c+o*t,this.normalize();return this}slerpQuaternions(e,t,n){return this.copy(e).slerp(t,n)}random(){let e=2*Math.PI*Math.random(),t=2*Math.PI*Math.random(),n=Math.random(),s=Math.sqrt(1-n),r=Math.sqrt(n);return this.set(s*Math.sin(e),s*Math.cos(e),r*Math.sin(t),r*Math.cos(t))}equals(e){return e._x===this._x&&e._y===this._y&&e._z===this._z&&e._w===this._w}fromArray(e,t=0){return this._x=e[t],this._y=e[t+1],this._z=e[t+2],this._w=e[t+3],this._onChangeCallback(),this}toArray(e=[],t=0){return e[t]=this._x,e[t+1]=this._y,e[t+2]=this._z,e[t+3]=this._w,e}fromBufferAttribute(e,t){return this._x=e.getX(t),this._y=e.getY(t),this._z=e.getZ(t),this._w=e.getW(t),this._onChangeCallback(),this}toJSON(){return this.toArray()}_onChange(e){return this._onChangeCallback=e,this}_onChangeCallback(){}*[Symbol.iterator](){yield this._x,yield this._y,yield this._z,yield this._w}},Vf=class Vf{constructor(e=0,t=0,n=0){this.x=e,this.y=t,this.z=n}set(e,t,n){return n===void 0&&(n=this.z),this.x=e,this.y=t,this.z=n,this}setScalar(e){return this.x=e,this.y=e,this.z=e,this}setX(e){return this.x=e,this}setY(e){return this.y=e,this}setZ(e){return this.z=e,this}setComponent(e,t){switch(e){case 0:this.x=t;break;case 1:this.y=t;break;case 2:this.z=t;break;default:throw new Error("THREE.Vector3: index is out of range: "+e)}return this}getComponent(e){switch(e){case 0:return this.x;case 1:return this.y;case 2:return this.z;default:throw new Error("THREE.Vector3: index is out of range: "+e)}}clone(){return new this.constructor(this.x,this.y,this.z)}copy(e){return this.x=e.x,this.y=e.y,this.z=e.z,this}add(e){return this.x+=e.x,this.y+=e.y,this.z+=e.z,this}addScalar(e){return this.x+=e,this.y+=e,this.z+=e,this}addVectors(e,t){return this.x=e.x+t.x,this.y=e.y+t.y,this.z=e.z+t.z,this}addScaledVector(e,t){return this.x+=e.x*t,this.y+=e.y*t,this.z+=e.z*t,this}sub(e){return this.x-=e.x,this.y-=e.y,this.z-=e.z,this}subScalar(e){return this.x-=e,this.y-=e,this.z-=e,this}subVectors(e,t){return this.x=e.x-t.x,this.y=e.y-t.y,this.z=e.z-t.z,this}multiply(e){return this.x*=e.x,this.y*=e.y,this.z*=e.z,this}multiplyScalar(e){return this.x*=e,this.y*=e,this.z*=e,this}multiplyVectors(e,t){return this.x=e.x*t.x,this.y=e.y*t.y,this.z=e.z*t.z,this}applyEuler(e){return this.applyQuaternion(Wp.setFromEuler(e))}applyAxisAngle(e,t){return this.applyQuaternion(Wp.setFromAxisAngle(e,t))}applyMatrix3(e){let t=this.x,n=this.y,s=this.z,r=e.elements;return this.x=r[0]*t+r[3]*n+r[6]*s,this.y=r[1]*t+r[4]*n+r[7]*s,this.z=r[2]*t+r[5]*n+r[8]*s,this}applyNormalMatrix(e){return this.applyMatrix3(e).normalize()}applyMatrix4(e){let t=this.x,n=this.y,s=this.z,r=e.elements,o=1/(r[3]*t+r[7]*n+r[11]*s+r[15]);return this.x=(r[0]*t+r[4]*n+r[8]*s+r[12])*o,this.y=(r[1]*t+r[5]*n+r[9]*s+r[13])*o,this.z=(r[2]*t+r[6]*n+r[10]*s+r[14])*o,this}applyQuaternion(e){let t=this.x,n=this.y,s=this.z,r=e.x,o=e.y,a=e.z,c=e.w,l=2*(o*s-a*n),u=2*(a*t-r*s),h=2*(r*n-o*t);return this.x=t+c*l+o*h-a*u,this.y=n+c*u+a*l-r*h,this.z=s+c*h+r*u-o*l,this}project(e){return this.applyMatrix4(e.matrixWorldInverse).applyMatrix4(e.projectionMatrix)}unproject(e){return this.applyMatrix4(e.projectionMatrixInverse).applyMatrix4(e.matrixWorld)}transformDirection(e){let t=this.x,n=this.y,s=this.z,r=e.elements;return this.x=r[0]*t+r[4]*n+r[8]*s,this.y=r[1]*t+r[5]*n+r[9]*s,this.z=r[2]*t+r[6]*n+r[10]*s,this.normalize()}divide(e){return this.x/=e.x,this.y/=e.y,this.z/=e.z,this}divideScalar(e){return this.multiplyScalar(1/e)}min(e){return this.x=Math.min(this.x,e.x),this.y=Math.min(this.y,e.y),this.z=Math.min(this.z,e.z),this}max(e){return this.x=Math.max(this.x,e.x),this.y=Math.max(this.y,e.y),this.z=Math.max(this.z,e.z),this}clamp(e,t){return this.x=qe(this.x,e.x,t.x),this.y=qe(this.y,e.y,t.y),this.z=qe(this.z,e.z,t.z),this}clampScalar(e,t){return this.x=qe(this.x,e,t),this.y=qe(this.y,e,t),this.z=qe(this.z,e,t),this}clampLength(e,t){let n=this.length();return this.divideScalar(n||1).multiplyScalar(qe(n,e,t))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this.z=Math.floor(this.z),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this.z=Math.ceil(this.z),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this.z=Math.round(this.z),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this.z=Math.trunc(this.z),this}negate(){return this.x=-this.x,this.y=-this.y,this.z=-this.z,this}dot(e){return this.x*e.x+this.y*e.y+this.z*e.z}lengthSq(){return this.x*this.x+this.y*this.y+this.z*this.z}length(){return Math.sqrt(this.x*this.x+this.y*this.y+this.z*this.z)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)+Math.abs(this.z)}normalize(){return this.divideScalar(this.length()||1)}setLength(e){return this.normalize().multiplyScalar(e)}lerp(e,t){return this.x+=(e.x-this.x)*t,this.y+=(e.y-this.y)*t,this.z+=(e.z-this.z)*t,this}lerpVectors(e,t,n){return this.x=e.x+(t.x-e.x)*n,this.y=e.y+(t.y-e.y)*n,this.z=e.z+(t.z-e.z)*n,this}cross(e){return this.crossVectors(this,e)}crossVectors(e,t){let n=e.x,s=e.y,r=e.z,o=t.x,a=t.y,c=t.z;return this.x=s*c-r*a,this.y=r*o-n*c,this.z=n*a-s*o,this}projectOnVector(e){let t=e.lengthSq();if(t===0)return this.set(0,0,0);let n=e.dot(this)/t;return this.copy(e).multiplyScalar(n)}projectOnPlane(e){return _h.copy(this).projectOnVector(e),this.sub(_h)}reflect(e){return this.sub(_h.copy(e).multiplyScalar(2*this.dot(e)))}angleTo(e){let t=Math.sqrt(this.lengthSq()*e.lengthSq());if(t===0)return Math.PI/2;let n=this.dot(e)/t;return Math.acos(qe(n,-1,1))}distanceTo(e){return Math.sqrt(this.distanceToSquared(e))}distanceToSquared(e){let t=this.x-e.x,n=this.y-e.y,s=this.z-e.z;return t*t+n*n+s*s}manhattanDistanceTo(e){return Math.abs(this.x-e.x)+Math.abs(this.y-e.y)+Math.abs(this.z-e.z)}setFromSpherical(e){return this.setFromSphericalCoords(e.radius,e.phi,e.theta)}setFromSphericalCoords(e,t,n){let s=Math.sin(t)*e;return this.x=s*Math.sin(n),this.y=Math.cos(t)*e,this.z=s*Math.cos(n),this}setFromCylindrical(e){return this.setFromCylindricalCoords(e.radius,e.theta,e.y)}setFromCylindricalCoords(e,t,n){return this.x=e*Math.sin(t),this.y=n,this.z=e*Math.cos(t),this}setFromMatrixPosition(e){let t=e.elements;return this.x=t[12],this.y=t[13],this.z=t[14],this}setFromMatrixScale(e){let t=this.setFromMatrixColumn(e,0).length(),n=this.setFromMatrixColumn(e,1).length(),s=this.setFromMatrixColumn(e,2).length();return this.x=t,this.y=n,this.z=s,this}setFromMatrixColumn(e,t){return this.fromArray(e.elements,t*4)}setFromMatrix3Column(e,t){return this.fromArray(e.elements,t*3)}setFromEuler(e){return this.x=e._x,this.y=e._y,this.z=e._z,this}setFromColor(e){return this.x=e.r,this.y=e.g,this.z=e.b,this}equals(e){return e.x===this.x&&e.y===this.y&&e.z===this.z}fromArray(e,t=0){return this.x=e[t],this.y=e[t+1],this.z=e[t+2],this}toArray(e=[],t=0){return e[t]=this.x,e[t+1]=this.y,e[t+2]=this.z,e}fromBufferAttribute(e,t){return this.x=e.getX(t),this.y=e.getY(t),this.z=e.getZ(t),this}random(){return this.x=Math.random(),this.y=Math.random(),this.z=Math.random(),this}randomDirection(){let e=Math.random()*Math.PI*2,t=Math.random()*2-1,n=Math.sqrt(1-t*t);return this.x=n*Math.cos(e),this.y=t,this.z=n*Math.sin(e),this}*[Symbol.iterator](){yield this.x,yield this.y,yield this.z}};Vf.prototype.isVector3=!0;var I=Vf,_h=new I,Wp=new pn,Hf=class Hf{constructor(e,t,n,s,r,o,a,c,l){this.elements=[1,0,0,0,1,0,0,0,1],e!==void 0&&this.set(e,t,n,s,r,o,a,c,l)}set(e,t,n,s,r,o,a,c,l){let u=this.elements;return u[0]=e,u[1]=s,u[2]=a,u[3]=t,u[4]=r,u[5]=c,u[6]=n,u[7]=o,u[8]=l,this}identity(){return this.set(1,0,0,0,1,0,0,0,1),this}copy(e){let t=this.elements,n=e.elements;return t[0]=n[0],t[1]=n[1],t[2]=n[2],t[3]=n[3],t[4]=n[4],t[5]=n[5],t[6]=n[6],t[7]=n[7],t[8]=n[8],this}extractBasis(e,t,n){return e.setFromMatrix3Column(this,0),t.setFromMatrix3Column(this,1),n.setFromMatrix3Column(this,2),this}setFromMatrix4(e){let t=e.elements;return this.set(t[0],t[4],t[8],t[1],t[5],t[9],t[2],t[6],t[10]),this}multiply(e){return this.multiplyMatrices(this,e)}premultiply(e){return this.multiplyMatrices(e,this)}multiplyMatrices(e,t){let n=e.elements,s=t.elements,r=this.elements,o=n[0],a=n[3],c=n[6],l=n[1],u=n[4],h=n[7],f=n[2],d=n[5],m=n[8],x=s[0],g=s[3],p=s[6],v=s[1],b=s[4],_=s[7],S=s[2],M=s[5],E=s[8];return r[0]=o*x+a*v+c*S,r[3]=o*g+a*b+c*M,r[6]=o*p+a*_+c*E,r[1]=l*x+u*v+h*S,r[4]=l*g+u*b+h*M,r[7]=l*p+u*_+h*E,r[2]=f*x+d*v+m*S,r[5]=f*g+d*b+m*M,r[8]=f*p+d*_+m*E,this}multiplyScalar(e){let t=this.elements;return t[0]*=e,t[3]*=e,t[6]*=e,t[1]*=e,t[4]*=e,t[7]*=e,t[2]*=e,t[5]*=e,t[8]*=e,this}determinant(){let e=this.elements,t=e[0],n=e[1],s=e[2],r=e[3],o=e[4],a=e[5],c=e[6],l=e[7],u=e[8];return t*o*u-t*a*l-n*r*u+n*a*c+s*r*l-s*o*c}invert(){let e=this.elements,t=e[0],n=e[1],s=e[2],r=e[3],o=e[4],a=e[5],c=e[6],l=e[7],u=e[8],h=u*o-a*l,f=a*c-u*r,d=l*r-o*c,m=t*h+n*f+s*d;if(m===0)return this.set(0,0,0,0,0,0,0,0,0);let x=1/m;return e[0]=h*x,e[1]=(s*l-u*n)*x,e[2]=(a*n-s*o)*x,e[3]=f*x,e[4]=(u*t-s*c)*x,e[5]=(s*r-a*t)*x,e[6]=d*x,e[7]=(n*c-l*t)*x,e[8]=(o*t-n*r)*x,this}transpose(){let e,t=this.elements;return e=t[1],t[1]=t[3],t[3]=e,e=t[2],t[2]=t[6],t[6]=e,e=t[5],t[5]=t[7],t[7]=e,this}getNormalMatrix(e){return this.setFromMatrix4(e).invert().transpose()}transposeIntoArray(e){let t=this.elements;return e[0]=t[0],e[1]=t[3],e[2]=t[6],e[3]=t[1],e[4]=t[4],e[5]=t[7],e[6]=t[2],e[7]=t[5],e[8]=t[8],this}setUvTransform(e,t,n,s,r,o,a){let c=Math.cos(r),l=Math.sin(r);return this.set(n*c,n*l,-n*(c*o+l*a)+o+e,-s*l,s*c,-s*(-l*o+c*a)+a+t,0,0,1),this}scale(e,t){return Ds("Matrix3: .scale() is deprecated. Use .makeScale() instead."),this.premultiply(yh.makeScale(e,t)),this}rotate(e){return Ds("Matrix3: .rotate() is deprecated. Use .makeRotation() instead."),this.premultiply(yh.makeRotation(-e)),this}translate(e,t){return Ds("Matrix3: .translate() is deprecated. Use .makeTranslation() instead."),this.premultiply(yh.makeTranslation(e,t)),this}makeTranslation(e,t){return e.isVector2?this.set(1,0,e.x,0,1,e.y,0,0,1):this.set(1,0,e,0,1,t,0,0,1),this}makeRotation(e){let t=Math.cos(e),n=Math.sin(e);return this.set(t,-n,0,n,t,0,0,0,1),this}makeScale(e,t){return this.set(e,0,0,0,t,0,0,0,1),this}equals(e){let t=this.elements,n=e.elements;for(let s=0;s<9;s++)if(t[s]!==n[s])return!1;return!0}fromArray(e,t=0){for(let n=0;n<9;n++)this.elements[n]=e[n+t];return this}toArray(e=[],t=0){let n=this.elements;return e[t]=n[0],e[t+1]=n[1],e[t+2]=n[2],e[t+3]=n[3],e[t+4]=n[4],e[t+5]=n[5],e[t+6]=n[6],e[t+7]=n[7],e[t+8]=n[8],e}clone(){return new this.constructor().fromArray(this.elements)}};Hf.prototype.isMatrix3=!0;var Ye=Hf,yh=new Ye,Xp=new Ye().set(.4123908,.3575843,.1804808,.212639,.7151687,.0721923,.0193308,.1191948,.9505322),qp=new Ye().set(3.2409699,-1.5373832,-.4986108,-.9692436,1.8759675,.0415551,.0556301,-.203977,1.0569715);function n_(){let i={enabled:!0,workingColorSpace:bn,spaces:{},convert:function(s,r,o){return this.enabled===!1||r===o||!r||!o||(this.spaces[r].transfer===yt&&(s.r=Fi(s.r),s.g=Fi(s.g),s.b=Fi(s.b)),this.spaces[r].primaries!==this.spaces[o].primaries&&(s.applyMatrix3(this.spaces[r].toXYZ),s.applyMatrix3(this.spaces[o].fromXYZ)),this.spaces[o].transfer===yt&&(s.r=Ir(s.r),s.g=Ir(s.g),s.b=Ir(s.b))),s},workingToColorSpace:function(s,r){return this.convert(s,this.workingColorSpace,r)},colorSpaceToWorking:function(s,r){return this.convert(s,r,this.workingColorSpace)},getPrimaries:function(s){return this.spaces[s].primaries},getTransfer:function(s){return s===Xi?Yo:this.spaces[s].transfer},getToneMappingMode:function(s){return this.spaces[s].outputColorSpaceConfig.toneMappingMode||"standard"},getLuminanceCoefficients:function(s,r=this.workingColorSpace){return s.fromArray(this.spaces[r].luminanceCoefficients)},define:function(s){Object.assign(this.spaces,s)},_getMatrix:function(s,r,o){return s.copy(this.spaces[r].toXYZ).multiply(this.spaces[o].fromXYZ)},_getDrawingBufferColorSpace:function(s){return this.spaces[s].outputColorSpaceConfig.drawingBufferColorSpace},_getUnpackColorSpace:function(s=this.workingColorSpace){return this.spaces[s].workingColorSpaceConfig.unpackColorSpace},fromWorkingColorSpace:function(s,r){return Ds("ColorManagement: .fromWorkingColorSpace() has been renamed to .workingToColorSpace()."),i.workingToColorSpace(s,r)},toWorkingColorSpace:function(s,r){return Ds("ColorManagement: .toWorkingColorSpace() has been renamed to .colorSpaceToWorking()."),i.colorSpaceToWorking(s,r)}},e=[.64,.33,.3,.6,.15,.06],t=[.2126,.7152,.0722],n=[.3127,.329];return i.define({[bn]:{primaries:e,whitePoint:n,transfer:Yo,toXYZ:Xp,fromXYZ:qp,luminanceCoefficients:t,workingColorSpaceConfig:{unpackColorSpace:Ft},outputColorSpaceConfig:{drawingBufferColorSpace:Ft}},[Ft]:{primaries:e,whitePoint:n,transfer:yt,toXYZ:Xp,fromXYZ:qp,luminanceCoefficients:t,outputColorSpaceConfig:{drawingBufferColorSpace:Ft}}}),i}var tt=n_();function Fi(i){return i<.04045?i*.0773993808:Math.pow(i*.9478672986+.0521327014,2.4)}function Ir(i){return i<.0031308?i*12.92:1.055*Math.pow(i,.41666)-.055}var hr,el=class{static getDataURL(e,t="image/png"){if(/^data:/i.test(e.src)||typeof HTMLCanvasElement>"u")return e.src;let n;if(e instanceof HTMLCanvasElement)n=e;else{hr===void 0&&(hr=Ur("canvas")),hr.width=e.width,hr.height=e.height;let s=hr.getContext("2d");e instanceof ImageData?s.putImageData(e,0,0):s.drawImage(e,0,0,e.width,e.height),n=hr}return n.toDataURL(t)}static sRGBToLinear(e){if(typeof HTMLImageElement<"u"&&e instanceof HTMLImageElement||typeof HTMLCanvasElement<"u"&&e instanceof HTMLCanvasElement||typeof ImageBitmap<"u"&&e instanceof ImageBitmap){let t=Ur("canvas");t.width=e.width,t.height=e.height;let n=t.getContext("2d");n.drawImage(e,0,0,e.width,e.height);let s=n.getImageData(0,0,e.width,e.height),r=s.data;for(let o=0;o<r.length;o++)r[o]=Fi(r[o]/255)*255;return n.putImageData(s,0,0),t}else if(e.data){let t=e.data.slice(0);for(let n=0;n<t.length;n++)t instanceof Uint8Array||t instanceof Uint8ClampedArray?t[n]=Math.floor(Fi(t[n]/255)*255):t[n]=Fi(t[n]);return{data:t,width:e.width,height:e.height}}else return Fe("ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied."),e}},i_=0,Or=class{constructor(e=null){this.isTextureSource=!0,Object.defineProperty(this,"id",{value:i_++}),this.uuid=Kn(),this.data=e,this.dataReady=!0,this.version=0}getSize(e){let t=this.data;return typeof HTMLVideoElement<"u"&&t instanceof HTMLVideoElement?e.set(t.videoWidth,t.videoHeight,0):typeof VideoFrame<"u"&&t instanceof VideoFrame?e.set(t.displayWidth,t.displayHeight,0):t!==null?e.set(t.width,t.height,t.depth||0):e.set(0,0,0),e}set needsUpdate(e){e===!0&&this.version++}toJSON(e){let t=e===void 0||typeof e=="string";if(!t&&e.images[this.uuid]!==void 0)return e.images[this.uuid];let n={uuid:this.uuid,url:""},s=this.data;if(s!==null){let r;if(Array.isArray(s)){r=[];for(let o=0,a=s.length;o<a;o++)s[o].isDataTexture?r.push(vh(s[o].image)):r.push(vh(s[o]))}else r=vh(s);n.url=r}return t||(e.images[this.uuid]=n),n}};function vh(i){return typeof HTMLImageElement<"u"&&i instanceof HTMLImageElement||typeof HTMLCanvasElement<"u"&&i instanceof HTMLCanvasElement||typeof ImageBitmap<"u"&&i instanceof ImageBitmap?el.getDataURL(i):i.data?{data:Array.from(i.data),width:i.width,height:i.height,type:i.data.constructor.name}:(Fe("Texture: Unable to serialize Texture."),{})}var s_=0,Sh=new I,Jt=class i extends ri{constructor(e=i.DEFAULT_IMAGE,t=i.DEFAULT_MAPPING,n=Zn,s=Zn,r=Gt,o=ai,a=Hn,c=Dn,l=i.DEFAULT_ANISOTROPY,u=Xi){super(),this.isTexture=!0,Object.defineProperty(this,"id",{value:s_++}),this.uuid=Kn(),this.name="",this.source=new Or(e),this.mipmaps=[],this.mapping=t,this.channel=0,this.wrapS=n,this.wrapT=s,this.magFilter=r,this.minFilter=o,this.anisotropy=l,this.format=a,this.internalFormat=null,this.type=c,this.offset=new ce(0,0),this.repeat=new ce(1,1),this.center=new ce(0,0),this.rotation=0,this.matrixAutoUpdate=!0,this.matrix=new Ye,this.generateMipmaps=!0,this.premultiplyAlpha=!1,this.flipY=!0,this.unpackAlignment=4,this.colorSpace=u,this.userData={},this.updateRanges=[],this.version=0,this.onUpdate=null,this.renderTarget=null,this.isRenderTargetTexture=!1,this.isArrayTexture=!!(e&&e.depth&&e.depth>1),this.pmremVersion=0,this.normalized=!1}get width(){return this.source.getSize(Sh).x}get height(){return this.source.getSize(Sh).y}get depth(){return this.source.getSize(Sh).z}get image(){return this.source.data}set image(e){this.source.data=e}updateMatrix(){this.matrix.setUvTransform(this.offset.x,this.offset.y,this.repeat.x,this.repeat.y,this.rotation,this.center.x,this.center.y)}addUpdateRange(e,t){this.updateRanges.push({start:e,count:t})}clearUpdateRanges(){this.updateRanges.length=0}clone(){return new this.constructor().copy(this)}copy(e){return this.name=e.name,this.source=e.source,this.mipmaps=e.mipmaps.slice(0),this.mapping=e.mapping,this.channel=e.channel,this.wrapS=e.wrapS,this.wrapT=e.wrapT,this.magFilter=e.magFilter,this.minFilter=e.minFilter,this.anisotropy=e.anisotropy,this.format=e.format,this.internalFormat=e.internalFormat,this.type=e.type,this.normalized=e.normalized,this.offset.copy(e.offset),this.repeat.copy(e.repeat),this.center.copy(e.center),this.rotation=e.rotation,this.matrixAutoUpdate=e.matrixAutoUpdate,this.matrix.copy(e.matrix),this.generateMipmaps=e.generateMipmaps,this.premultiplyAlpha=e.premultiplyAlpha,this.flipY=e.flipY,this.unpackAlignment=e.unpackAlignment,this.colorSpace=e.colorSpace,this.renderTarget=e.renderTarget,this.isRenderTargetTexture=e.isRenderTargetTexture,this.isArrayTexture=e.isArrayTexture,this.userData=JSON.parse(JSON.stringify(e.userData)),this.needsUpdate=!0,this}setValues(e){for(let t in e){let n=e[t];if(n===void 0){Fe(`Texture.setValues(): parameter '${t}' has value of undefined.`);continue}let s=this[t];if(s===void 0){Fe(`Texture.setValues(): property '${t}' does not exist.`);continue}s&&n&&s.isVector2&&n.isVector2||s&&n&&s.isVector3&&n.isVector3||s&&n&&s.isMatrix3&&n.isMatrix3?s.copy(n):this[t]=n}}toJSON(e){let t=e===void 0||typeof e=="string";if(!t&&e.textures[this.uuid]!==void 0)return e.textures[this.uuid];let n={metadata:{version:4.7,type:"Texture",generator:"Texture.toJSON"},uuid:this.uuid,name:this.name,image:this.source.toJSON(e).uuid,mapping:this.mapping,channel:this.channel,repeat:[this.repeat.x,this.repeat.y],offset:[this.offset.x,this.offset.y],center:[this.center.x,this.center.y],rotation:this.rotation,wrap:[this.wrapS,this.wrapT],format:this.format,internalFormat:this.internalFormat,type:this.type,normalized:this.normalized,colorSpace:this.colorSpace,minFilter:this.minFilter,magFilter:this.magFilter,anisotropy:this.anisotropy,flipY:this.flipY,generateMipmaps:this.generateMipmaps,premultiplyAlpha:this.premultiplyAlpha,unpackAlignment:this.unpackAlignment};return Object.keys(this.userData).length>0&&(n.userData=this.userData),t||(e.textures[this.uuid]=n),n}dispose(){this.dispatchEvent({type:"dispose"})}transformUv(e){if(this.mapping!==Tf)return e;if(e.applyMatrix3(this.matrix),e.x<0||e.x>1)switch(this.wrapS){case cs:e.x=e.x-Math.floor(e.x);break;case Zn:e.x=e.x<0?0:1;break;case Nr:Math.abs(Math.floor(e.x)%2)===1?e.x=Math.ceil(e.x)-e.x:e.x=e.x-Math.floor(e.x);break}if(e.y<0||e.y>1)switch(this.wrapT){case cs:e.y=e.y-Math.floor(e.y);break;case Zn:e.y=e.y<0?0:1;break;case Nr:Math.abs(Math.floor(e.y)%2)===1?e.y=Math.ceil(e.y)-e.y:e.y=e.y-Math.floor(e.y);break}return this.flipY&&(e.y=1-e.y),e}set needsUpdate(e){e===!0&&(this.version++,this.source.needsUpdate=!0)}set needsPMREMUpdate(e){e===!0&&this.pmremVersion++}};Jt.DEFAULT_IMAGE=null;Jt.DEFAULT_MAPPING=Tf;Jt.DEFAULT_ANISOTROPY=1;var Gf=class Gf{constructor(e=0,t=0,n=0,s=1){this.x=e,this.y=t,this.z=n,this.w=s}get width(){return this.z}set width(e){this.z=e}get height(){return this.w}set height(e){this.w=e}set(e,t,n,s){return this.x=e,this.y=t,this.z=n,this.w=s,this}setScalar(e){return this.x=e,this.y=e,this.z=e,this.w=e,this}setX(e){return this.x=e,this}setY(e){return this.y=e,this}setZ(e){return this.z=e,this}setW(e){return this.w=e,this}setComponent(e,t){switch(e){case 0:this.x=t;break;case 1:this.y=t;break;case 2:this.z=t;break;case 3:this.w=t;break;default:throw new Error("THREE.Vector4: index is out of range: "+e)}return this}getComponent(e){switch(e){case 0:return this.x;case 1:return this.y;case 2:return this.z;case 3:return this.w;default:throw new Error("THREE.Vector4: index is out of range: "+e)}}clone(){return new this.constructor(this.x,this.y,this.z,this.w)}copy(e){return this.x=e.x,this.y=e.y,this.z=e.z,this.w=e.w!==void 0?e.w:1,this}add(e){return this.x+=e.x,this.y+=e.y,this.z+=e.z,this.w+=e.w,this}addScalar(e){return this.x+=e,this.y+=e,this.z+=e,this.w+=e,this}addVectors(e,t){return this.x=e.x+t.x,this.y=e.y+t.y,this.z=e.z+t.z,this.w=e.w+t.w,this}addScaledVector(e,t){return this.x+=e.x*t,this.y+=e.y*t,this.z+=e.z*t,this.w+=e.w*t,this}sub(e){return this.x-=e.x,this.y-=e.y,this.z-=e.z,this.w-=e.w,this}subScalar(e){return this.x-=e,this.y-=e,this.z-=e,this.w-=e,this}subVectors(e,t){return this.x=e.x-t.x,this.y=e.y-t.y,this.z=e.z-t.z,this.w=e.w-t.w,this}multiply(e){return this.x*=e.x,this.y*=e.y,this.z*=e.z,this.w*=e.w,this}multiplyScalar(e){return this.x*=e,this.y*=e,this.z*=e,this.w*=e,this}applyMatrix4(e){let t=this.x,n=this.y,s=this.z,r=this.w,o=e.elements;return this.x=o[0]*t+o[4]*n+o[8]*s+o[12]*r,this.y=o[1]*t+o[5]*n+o[9]*s+o[13]*r,this.z=o[2]*t+o[6]*n+o[10]*s+o[14]*r,this.w=o[3]*t+o[7]*n+o[11]*s+o[15]*r,this}divide(e){return this.x/=e.x,this.y/=e.y,this.z/=e.z,this.w/=e.w,this}divideScalar(e){return this.multiplyScalar(1/e)}setAxisAngleFromQuaternion(e){this.w=2*Math.acos(e.w);let t=Math.sqrt(1-e.w*e.w);return t<1e-4?(this.x=1,this.y=0,this.z=0):(this.x=e.x/t,this.y=e.y/t,this.z=e.z/t),this}setAxisAngleFromRotationMatrix(e){let t,n,s,r,c=e.elements,l=c[0],u=c[4],h=c[8],f=c[1],d=c[5],m=c[9],x=c[2],g=c[6],p=c[10];if(Math.abs(u-f)<.01&&Math.abs(h-x)<.01&&Math.abs(m-g)<.01){if(Math.abs(u+f)<.1&&Math.abs(h+x)<.1&&Math.abs(m+g)<.1&&Math.abs(l+d+p-3)<.1)return this.set(1,0,0,0),this;t=Math.PI;let b=(l+1)/2,_=(d+1)/2,S=(p+1)/2,M=(u+f)/4,E=(h+x)/4,y=(m+g)/4;return b>_&&b>S?b<.01?(n=0,s=.707106781,r=.707106781):(n=Math.sqrt(b),s=M/n,r=E/n):_>S?_<.01?(n=.707106781,s=0,r=.707106781):(s=Math.sqrt(_),n=M/s,r=y/s):S<.01?(n=.707106781,s=.707106781,r=0):(r=Math.sqrt(S),n=E/r,s=y/r),this.set(n,s,r,t),this}let v=Math.sqrt((g-m)*(g-m)+(h-x)*(h-x)+(f-u)*(f-u));return Math.abs(v)<.001&&(v=1),this.x=(g-m)/v,this.y=(h-x)/v,this.z=(f-u)/v,this.w=Math.acos((l+d+p-1)/2),this}setFromMatrixPosition(e){let t=e.elements;return this.x=t[12],this.y=t[13],this.z=t[14],this.w=t[15],this}min(e){return this.x=Math.min(this.x,e.x),this.y=Math.min(this.y,e.y),this.z=Math.min(this.z,e.z),this.w=Math.min(this.w,e.w),this}max(e){return this.x=Math.max(this.x,e.x),this.y=Math.max(this.y,e.y),this.z=Math.max(this.z,e.z),this.w=Math.max(this.w,e.w),this}clamp(e,t){return this.x=qe(this.x,e.x,t.x),this.y=qe(this.y,e.y,t.y),this.z=qe(this.z,e.z,t.z),this.w=qe(this.w,e.w,t.w),this}clampScalar(e,t){return this.x=qe(this.x,e,t),this.y=qe(this.y,e,t),this.z=qe(this.z,e,t),this.w=qe(this.w,e,t),this}clampLength(e,t){let n=this.length();return this.divideScalar(n||1).multiplyScalar(qe(n,e,t))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this.z=Math.floor(this.z),this.w=Math.floor(this.w),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this.z=Math.ceil(this.z),this.w=Math.ceil(this.w),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this.z=Math.round(this.z),this.w=Math.round(this.w),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this.z=Math.trunc(this.z),this.w=Math.trunc(this.w),this}negate(){return this.x=-this.x,this.y=-this.y,this.z=-this.z,this.w=-this.w,this}dot(e){return this.x*e.x+this.y*e.y+this.z*e.z+this.w*e.w}lengthSq(){return this.x*this.x+this.y*this.y+this.z*this.z+this.w*this.w}length(){return Math.sqrt(this.x*this.x+this.y*this.y+this.z*this.z+this.w*this.w)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)+Math.abs(this.z)+Math.abs(this.w)}normalize(){return this.divideScalar(this.length()||1)}setLength(e){return this.normalize().multiplyScalar(e)}lerp(e,t){return this.x+=(e.x-this.x)*t,this.y+=(e.y-this.y)*t,this.z+=(e.z-this.z)*t,this.w+=(e.w-this.w)*t,this}lerpVectors(e,t,n){return this.x=e.x+(t.x-e.x)*n,this.y=e.y+(t.y-e.y)*n,this.z=e.z+(t.z-e.z)*n,this.w=e.w+(t.w-e.w)*n,this}equals(e){return e.x===this.x&&e.y===this.y&&e.z===this.z&&e.w===this.w}fromArray(e,t=0){return this.x=e[t],this.y=e[t+1],this.z=e[t+2],this.w=e[t+3],this}toArray(e=[],t=0){return e[t]=this.x,e[t+1]=this.y,e[t+2]=this.z,e[t+3]=this.w,e}fromBufferAttribute(e,t){return this.x=e.getX(t),this.y=e.getY(t),this.z=e.getZ(t),this.w=e.getW(t),this}random(){return this.x=Math.random(),this.y=Math.random(),this.z=Math.random(),this.w=Math.random(),this}*[Symbol.iterator](){yield this.x,yield this.y,yield this.z,yield this.w}};Gf.prototype.isVector4=!0;var ut=Gf,tl=class extends ri{constructor(e=1,t=1,n={}){super(),n=Object.assign({generateMipmaps:!1,internalFormat:null,minFilter:Gt,depthBuffer:!0,stencilBuffer:!1,resolveColorBuffer:!0,resolveDepthBuffer:!0,resolveStencilBuffer:!0,storeMultisampledColorBuffer:!0,storeMultisampledDepthBuffer:!0,storeMultisampledStencilBuffer:!0,depthTexture:null,samples:0,count:1,depth:1,multiview:!1,useArrayDepthTexture:!1},n),this.isRenderTarget=!0,this.width=e,this.height=t,this.depth=n.depth,this.scissor=new ut(0,0,e,t),this.scissorTest=!1,this.viewport=new ut(0,0,e,t),this.textures=[];let s={width:e,height:t,depth:n.depth},r=new Jt(s),o=n.count;for(let a=0;a<o;a++)this.textures[a]=r.clone(),this.textures[a].isRenderTargetTexture=!0,this.textures[a].renderTarget=this;this._setTextureOptions(n),this.depthBuffer=n.depthBuffer,this.stencilBuffer=n.stencilBuffer,this.resolveColorBuffer=n.resolveColorBuffer,this.resolveDepthBuffer=n.resolveDepthBuffer,this.resolveStencilBuffer=n.resolveStencilBuffer,this.storeMultisampledColorBuffer=n.storeMultisampledColorBuffer,this.storeMultisampledDepthBuffer=n.storeMultisampledDepthBuffer,this.storeMultisampledStencilBuffer=n.storeMultisampledStencilBuffer,this._depthTexture=null,this.depthTexture=n.depthTexture,this.samples=n.samples,this.multiview=n.multiview,this.useArrayDepthTexture=n.useArrayDepthTexture}_setTextureOptions(e={}){let t={minFilter:Gt,generateMipmaps:!1,flipY:!1,internalFormat:null};e.mapping!==void 0&&(t.mapping=e.mapping),e.wrapS!==void 0&&(t.wrapS=e.wrapS),e.wrapT!==void 0&&(t.wrapT=e.wrapT),e.wrapR!==void 0&&(t.wrapR=e.wrapR),e.magFilter!==void 0&&(t.magFilter=e.magFilter),e.minFilter!==void 0&&(t.minFilter=e.minFilter),e.format!==void 0&&(t.format=e.format),e.type!==void 0&&(t.type=e.type),e.anisotropy!==void 0&&(t.anisotropy=e.anisotropy),e.colorSpace!==void 0&&(t.colorSpace=e.colorSpace),e.flipY!==void 0&&(t.flipY=e.flipY),e.generateMipmaps!==void 0&&(t.generateMipmaps=e.generateMipmaps),e.internalFormat!==void 0&&(t.internalFormat=e.internalFormat);for(let n=0;n<this.textures.length;n++)this.textures[n].setValues(t)}get texture(){return this.textures[0]}set texture(e){this.textures[0]=e}set depthTexture(e){this._depthTexture!==null&&this._depthTexture.renderTarget===this&&(this._depthTexture.renderTarget=null),e!==null&&e.renderTarget===null&&(e.renderTarget=this),this._depthTexture=e}get depthTexture(){return this._depthTexture}setSize(e,t,n=1){if(this.width!==e||this.height!==t||this.depth!==n){this.width=e,this.height=t,this.depth=n;for(let s=0,r=this.textures.length;s<r;s++)this.textures[s].image.width=e,this.textures[s].image.height=t,this.textures[s].image.depth=n,this.textures[s].isData3DTexture!==!0&&(this.textures[s].isArrayTexture=this.textures[s].image.depth>1);this.dispose()}this.viewport.set(0,0,e,t),this.scissor.set(0,0,e,t)}clone(){return new this.constructor().copy(this)}copy(e){this.width=e.width,this.height=e.height,this.depth=e.depth,this.scissor.copy(e.scissor),this.scissorTest=e.scissorTest,this.viewport.copy(e.viewport),this.textures.length=0;for(let t=0,n=e.textures.length;t<n;t++){this.textures[t]=e.textures[t].clone(),this.textures[t].isRenderTargetTexture=!0,this.textures[t].renderTarget=this;let s=Object.assign({},e.textures[t].image);this.textures[t].source=new Or(s)}if(this.depthBuffer=e.depthBuffer,this.stencilBuffer=e.stencilBuffer,this.resolveColorBuffer=e.resolveColorBuffer,this.resolveDepthBuffer=e.resolveDepthBuffer,this.resolveStencilBuffer=e.resolveStencilBuffer,this.storeMultisampledColorBuffer=e.storeMultisampledColorBuffer,this.storeMultisampledDepthBuffer=e.storeMultisampledDepthBuffer,this.storeMultisampledStencilBuffer=e.storeMultisampledStencilBuffer,e.depthTexture!==null)if(e.depthTexture.renderTarget===e){let t=e.depthTexture.clone();t.renderTarget=null,this.depthTexture=t}else this.depthTexture=e.depthTexture;return this.samples=e.samples,this.multiview=e.multiview,this.useArrayDepthTexture=e.useArrayDepthTexture,this}dispose(){this.dispatchEvent({type:"dispose"})}},Rn=class extends tl{constructor(e=1,t=1,n={}){super(e,t,n),this.isWebGLRenderTarget=!0}},Ko=class extends Jt{constructor(e=null,t=1,n=1,s=1){super(null),this.isDataArrayTexture=!0,this.image={data:e,width:t,height:n,depth:s},this.magFilter=Ht,this.minFilter=Ht,this.wrapR=Zn,this.generateMipmaps=!1,this.flipY=!1,this.unpackAlignment=1,this.layerUpdates=new Set}copy(e){return super.copy(e),this.wrapR=e.wrapR,this}addLayerUpdate(e){this.layerUpdates.add(e)}clearLayerUpdates(){this.layerUpdates.clear()}};var nl=class extends Jt{constructor(e=null,t=1,n=1,s=1){super(null),this.isData3DTexture=!0,this.image={data:e,width:t,height:n,depth:s},this.magFilter=Ht,this.minFilter=Ht,this.wrapR=Zn,this.generateMipmaps=!1,this.flipY=!1,this.unpackAlignment=1}copy(e){return super.copy(e),this.wrapR=e.wrapR,this}};var Tl=class Tl{constructor(e,t,n,s,r,o,a,c,l,u,h,f,d,m,x,g){this.elements=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1],e!==void 0&&this.set(e,t,n,s,r,o,a,c,l,u,h,f,d,m,x,g)}set(e,t,n,s,r,o,a,c,l,u,h,f,d,m,x,g){let p=this.elements;return p[0]=e,p[4]=t,p[8]=n,p[12]=s,p[1]=r,p[5]=o,p[9]=a,p[13]=c,p[2]=l,p[6]=u,p[10]=h,p[14]=f,p[3]=d,p[7]=m,p[11]=x,p[15]=g,this}identity(){return this.set(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1),this}clone(){return new Tl().fromArray(this.elements)}copy(e){let t=this.elements,n=e.elements;return t[0]=n[0],t[1]=n[1],t[2]=n[2],t[3]=n[3],t[4]=n[4],t[5]=n[5],t[6]=n[6],t[7]=n[7],t[8]=n[8],t[9]=n[9],t[10]=n[10],t[11]=n[11],t[12]=n[12],t[13]=n[13],t[14]=n[14],t[15]=n[15],this}copyPosition(e){let t=this.elements,n=e.elements;return t[12]=n[12],t[13]=n[13],t[14]=n[14],this}setFromMatrix3(e){let t=e.elements;return this.set(t[0],t[3],t[6],0,t[1],t[4],t[7],0,t[2],t[5],t[8],0,0,0,0,1),this}extractBasis(e,t,n){return this.determinantAffine()===0?(e.set(1,0,0),t.set(0,1,0),n.set(0,0,1),this):(e.setFromMatrixColumn(this,0),t.setFromMatrixColumn(this,1),n.setFromMatrixColumn(this,2),this)}makeBasis(e,t,n){return this.set(e.x,t.x,n.x,0,e.y,t.y,n.y,0,e.z,t.z,n.z,0,0,0,0,1),this}extractRotation(e){if(e.determinantAffine()===0)return this.identity();let t=this.elements,n=e.elements,s=1/fr.setFromMatrixColumn(e,0).length(),r=1/fr.setFromMatrixColumn(e,1).length(),o=1/fr.setFromMatrixColumn(e,2).length();return t[0]=n[0]*s,t[1]=n[1]*s,t[2]=n[2]*s,t[3]=0,t[4]=n[4]*r,t[5]=n[5]*r,t[6]=n[6]*r,t[7]=0,t[8]=n[8]*o,t[9]=n[9]*o,t[10]=n[10]*o,t[11]=0,t[12]=0,t[13]=0,t[14]=0,t[15]=1,this}makeRotationFromEuler(e){let t=this.elements,n=e.x,s=e.y,r=e.z,o=Math.cos(n),a=Math.sin(n),c=Math.cos(s),l=Math.sin(s),u=Math.cos(r),h=Math.sin(r);if(e.order==="XYZ"){let f=o*u,d=o*h,m=a*u,x=a*h;t[0]=c*u,t[4]=-c*h,t[8]=l,t[1]=d+m*l,t[5]=f-x*l,t[9]=-a*c,t[2]=x-f*l,t[6]=m+d*l,t[10]=o*c}else if(e.order==="YXZ"){let f=c*u,d=c*h,m=l*u,x=l*h;t[0]=f+x*a,t[4]=m*a-d,t[8]=o*l,t[1]=o*h,t[5]=o*u,t[9]=-a,t[2]=d*a-m,t[6]=x+f*a,t[10]=o*c}else if(e.order==="ZXY"){let f=c*u,d=c*h,m=l*u,x=l*h;t[0]=f-x*a,t[4]=-o*h,t[8]=m+d*a,t[1]=d+m*a,t[5]=o*u,t[9]=x-f*a,t[2]=-o*l,t[6]=a,t[10]=o*c}else if(e.order==="ZYX"){let f=o*u,d=o*h,m=a*u,x=a*h;t[0]=c*u,t[4]=m*l-d,t[8]=f*l+x,t[1]=c*h,t[5]=x*l+f,t[9]=d*l-m,t[2]=-l,t[6]=a*c,t[10]=o*c}else if(e.order==="YZX"){let f=o*c,d=o*l,m=a*c,x=a*l;t[0]=c*u,t[4]=x-f*h,t[8]=m*h+d,t[1]=h,t[5]=o*u,t[9]=-a*u,t[2]=-l*u,t[6]=d*h+m,t[10]=f-x*h}else if(e.order==="XZY"){let f=o*c,d=o*l,m=a*c,x=a*l;t[0]=c*u,t[4]=-h,t[8]=l*u,t[1]=f*h+x,t[5]=o*u,t[9]=d*h-m,t[2]=m*h-d,t[6]=a*u,t[10]=x*h+f}return t[3]=0,t[7]=0,t[11]=0,t[12]=0,t[13]=0,t[14]=0,t[15]=1,this}makeRotationFromQuaternion(e){return this.compose(r_,e,o_)}lookAt(e,t,n){let s=this.elements;return Fn.subVectors(e,t),Fn.lengthSq()===0&&(Fn.z=1),Fn.normalize(),ns.crossVectors(n,Fn),ns.lengthSq()===0&&(Math.abs(n.z)===1?Fn.x+=1e-4:Fn.z+=1e-4,Fn.normalize(),ns.crossVectors(n,Fn)),ns.normalize(),dc.crossVectors(Fn,ns),s[0]=ns.x,s[4]=dc.x,s[8]=Fn.x,s[1]=ns.y,s[5]=dc.y,s[9]=Fn.y,s[2]=ns.z,s[6]=dc.z,s[10]=Fn.z,this}multiply(e){return this.multiplyMatrices(this,e)}premultiply(e){return this.multiplyMatrices(e,this)}multiplyMatrices(e,t){let n=e.elements,s=t.elements,r=this.elements,o=n[0],a=n[4],c=n[8],l=n[12],u=n[1],h=n[5],f=n[9],d=n[13],m=n[2],x=n[6],g=n[10],p=n[14],v=n[3],b=n[7],_=n[11],S=n[15],M=s[0],E=s[4],y=s[8],w=s[12],A=s[1],P=s[5],C=s[9],D=s[13],L=s[2],U=s[6],G=s[10],Z=s[14],oe=s[3],K=s[7],te=s[11],se=s[15];return r[0]=o*M+a*A+c*L+l*oe,r[4]=o*E+a*P+c*U+l*K,r[8]=o*y+a*C+c*G+l*te,r[12]=o*w+a*D+c*Z+l*se,r[1]=u*M+h*A+f*L+d*oe,r[5]=u*E+h*P+f*U+d*K,r[9]=u*y+h*C+f*G+d*te,r[13]=u*w+h*D+f*Z+d*se,r[2]=m*M+x*A+g*L+p*oe,r[6]=m*E+x*P+g*U+p*K,r[10]=m*y+x*C+g*G+p*te,r[14]=m*w+x*D+g*Z+p*se,r[3]=v*M+b*A+_*L+S*oe,r[7]=v*E+b*P+_*U+S*K,r[11]=v*y+b*C+_*G+S*te,r[15]=v*w+b*D+_*Z+S*se,this}multiplyScalar(e){let t=this.elements;return t[0]*=e,t[4]*=e,t[8]*=e,t[12]*=e,t[1]*=e,t[5]*=e,t[9]*=e,t[13]*=e,t[2]*=e,t[6]*=e,t[10]*=e,t[14]*=e,t[3]*=e,t[7]*=e,t[11]*=e,t[15]*=e,this}determinant(){let e=this.elements,t=e[0],n=e[4],s=e[8],r=e[12],o=e[1],a=e[5],c=e[9],l=e[13],u=e[2],h=e[6],f=e[10],d=e[14],m=e[3],x=e[7],g=e[11],p=e[15],v=c*d-l*f,b=a*d-l*h,_=a*f-c*h,S=o*d-l*u,M=o*f-c*u,E=o*h-a*u;return t*(x*v-g*b+p*_)-n*(m*v-g*S+p*M)+s*(m*b-x*S+p*E)-r*(m*_-x*M+g*E)}determinantAffine(){let e=this.elements,t=e[0],n=e[4],s=e[8],r=e[1],o=e[5],a=e[9],c=e[2],l=e[6],u=e[10];return t*(o*u-a*l)-n*(r*u-a*c)+s*(r*l-o*c)}transpose(){let e=this.elements,t;return t=e[1],e[1]=e[4],e[4]=t,t=e[2],e[2]=e[8],e[8]=t,t=e[6],e[6]=e[9],e[9]=t,t=e[3],e[3]=e[12],e[12]=t,t=e[7],e[7]=e[13],e[13]=t,t=e[11],e[11]=e[14],e[14]=t,this}setPosition(e,t,n){let s=this.elements;return e.isVector3?(s[12]=e.x,s[13]=e.y,s[14]=e.z):(s[12]=e,s[13]=t,s[14]=n),this}invert(){let e=this.elements,t=e[0],n=e[1],s=e[2],r=e[3],o=e[4],a=e[5],c=e[6],l=e[7],u=e[8],h=e[9],f=e[10],d=e[11],m=e[12],x=e[13],g=e[14],p=e[15],v=t*a-n*o,b=t*c-s*o,_=t*l-r*o,S=n*c-s*a,M=n*l-r*a,E=s*l-r*c,y=u*x-h*m,w=u*g-f*m,A=u*p-d*m,P=h*g-f*x,C=h*p-d*x,D=f*p-d*g,L=v*D-b*C+_*P+S*A-M*w+E*y;if(L===0)return this.set(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);let U=1/L;return e[0]=(a*D-c*C+l*P)*U,e[1]=(s*C-n*D-r*P)*U,e[2]=(x*E-g*M+p*S)*U,e[3]=(f*M-h*E-d*S)*U,e[4]=(c*A-o*D-l*w)*U,e[5]=(t*D-s*A+r*w)*U,e[6]=(g*_-m*E-p*b)*U,e[7]=(u*E-f*_+d*b)*U,e[8]=(o*C-a*A+l*y)*U,e[9]=(n*A-t*C-r*y)*U,e[10]=(m*M-x*_+p*v)*U,e[11]=(h*_-u*M-d*v)*U,e[12]=(a*w-o*P-c*y)*U,e[13]=(t*P-n*w+s*y)*U,e[14]=(x*b-m*S-g*v)*U,e[15]=(u*S-h*b+f*v)*U,this}scale(e){let t=this.elements,n=e.x,s=e.y,r=e.z;return t[0]*=n,t[4]*=s,t[8]*=r,t[1]*=n,t[5]*=s,t[9]*=r,t[2]*=n,t[6]*=s,t[10]*=r,t[3]*=n,t[7]*=s,t[11]*=r,this}getMaxScaleOnAxis(){let e=this.elements,t=e[0]*e[0]+e[1]*e[1]+e[2]*e[2],n=e[4]*e[4]+e[5]*e[5]+e[6]*e[6],s=e[8]*e[8]+e[9]*e[9]+e[10]*e[10];return Math.sqrt(Math.max(t,n,s))}makeTranslation(e,t,n){return e.isVector3?this.set(1,0,0,e.x,0,1,0,e.y,0,0,1,e.z,0,0,0,1):this.set(1,0,0,e,0,1,0,t,0,0,1,n,0,0,0,1),this}makeRotationX(e){let t=Math.cos(e),n=Math.sin(e);return this.set(1,0,0,0,0,t,-n,0,0,n,t,0,0,0,0,1),this}makeRotationY(e){let t=Math.cos(e),n=Math.sin(e);return this.set(t,0,n,0,0,1,0,0,-n,0,t,0,0,0,0,1),this}makeRotationZ(e){let t=Math.cos(e),n=Math.sin(e);return this.set(t,-n,0,0,n,t,0,0,0,0,1,0,0,0,0,1),this}makeRotationAxis(e,t){let n=Math.cos(t),s=Math.sin(t),r=1-n,o=e.x,a=e.y,c=e.z,l=r*o,u=r*a;return this.set(l*o+n,l*a-s*c,l*c+s*a,0,l*a+s*c,u*a+n,u*c-s*o,0,l*c-s*a,u*c+s*o,r*c*c+n,0,0,0,0,1),this}makeScale(e,t,n){return this.set(e,0,0,0,0,t,0,0,0,0,n,0,0,0,0,1),this}makeShear(e,t,n,s,r,o){return this.set(1,n,r,0,e,1,o,0,t,s,1,0,0,0,0,1),this}compose(e,t,n){let s=this.elements,r=t._x,o=t._y,a=t._z,c=t._w,l=r+r,u=o+o,h=a+a,f=r*l,d=r*u,m=r*h,x=o*u,g=o*h,p=a*h,v=c*l,b=c*u,_=c*h,S=n.x,M=n.y,E=n.z;return s[0]=(1-(x+p))*S,s[1]=(d+_)*S,s[2]=(m-b)*S,s[3]=0,s[4]=(d-_)*M,s[5]=(1-(f+p))*M,s[6]=(g+v)*M,s[7]=0,s[8]=(m+b)*E,s[9]=(g-v)*E,s[10]=(1-(f+x))*E,s[11]=0,s[12]=e.x,s[13]=e.y,s[14]=e.z,s[15]=1,this}decompose(e,t,n){let s=this.elements;e.x=s[12],e.y=s[13],e.z=s[14];let r=this.determinantAffine();if(r===0)return n.set(1,1,1),t.identity(),this;let o=fr.set(s[0],s[1],s[2]).length(),a=fr.set(s[4],s[5],s[6]).length(),c=fr.set(s[8],s[9],s[10]).length();r<0&&(o=-o),ei.copy(this);let l=1/o,u=1/a,h=1/c;return ei.elements[0]*=l,ei.elements[1]*=l,ei.elements[2]*=l,ei.elements[4]*=u,ei.elements[5]*=u,ei.elements[6]*=u,ei.elements[8]*=h,ei.elements[9]*=h,ei.elements[10]*=h,t.setFromRotationMatrix(ei),n.x=o,n.y=a,n.z=c,this}makePerspective(e,t,n,s,r,o,a=si,c=!1){let l=this.elements,u=2*r/(t-e),h=2*r/(n-s),f=(t+e)/(t-e),d=(n+s)/(n-s),m,x;if(c)m=r/(o-r),x=o*r/(o-r);else if(a===si)m=-(o+r)/(o-r),x=-2*o*r/(o-r);else if(a===Dr)m=-o/(o-r),x=-o*r/(o-r);else throw new Error("THREE.Matrix4.makePerspective(): Invalid coordinate system: "+a);return l[0]=u,l[4]=0,l[8]=f,l[12]=0,l[1]=0,l[5]=h,l[9]=d,l[13]=0,l[2]=0,l[6]=0,l[10]=m,l[14]=x,l[3]=0,l[7]=0,l[11]=-1,l[15]=0,this}makeOrthographic(e,t,n,s,r,o,a=si,c=!1){let l=this.elements,u=2/(t-e),h=2/(n-s),f=-(t+e)/(t-e),d=-(n+s)/(n-s),m,x;if(c)m=1/(o-r),x=o/(o-r);else if(a===si)m=-2/(o-r),x=-(o+r)/(o-r);else if(a===Dr)m=-1/(o-r),x=-r/(o-r);else throw new Error("THREE.Matrix4.makeOrthographic(): Invalid coordinate system: "+a);return l[0]=u,l[4]=0,l[8]=0,l[12]=f,l[1]=0,l[5]=h,l[9]=0,l[13]=d,l[2]=0,l[6]=0,l[10]=m,l[14]=x,l[3]=0,l[7]=0,l[11]=0,l[15]=1,this}equals(e){let t=this.elements,n=e.elements;for(let s=0;s<16;s++)if(t[s]!==n[s])return!1;return!0}fromArray(e,t=0){for(let n=0;n<16;n++)this.elements[n]=e[n+t];return this}toArray(e=[],t=0){let n=this.elements;return e[t]=n[0],e[t+1]=n[1],e[t+2]=n[2],e[t+3]=n[3],e[t+4]=n[4],e[t+5]=n[5],e[t+6]=n[6],e[t+7]=n[7],e[t+8]=n[8],e[t+9]=n[9],e[t+10]=n[10],e[t+11]=n[11],e[t+12]=n[12],e[t+13]=n[13],e[t+14]=n[14],e[t+15]=n[15],e}};Tl.prototype.isMatrix4=!0;var Ie=Tl,fr=new I,ei=new Ie,r_=new I(0,0,0),o_=new I(1,1,1),ns=new I,dc=new I,Fn=new I,Yp=new Ie,Zp=new pn,Oi=class i{constructor(e=0,t=0,n=0,s=i.DEFAULT_ORDER){this.isEuler=!0,this._x=e,this._y=t,this._z=n,this._order=s}get x(){return this._x}set x(e){this._x=e,this._onChangeCallback()}get y(){return this._y}set y(e){this._y=e,this._onChangeCallback()}get z(){return this._z}set z(e){this._z=e,this._onChangeCallback()}get order(){return this._order}set order(e){this._order=e,this._onChangeCallback()}set(e,t,n,s=this._order){return this._x=e,this._y=t,this._z=n,this._order=s,this._onChangeCallback(),this}clone(){return new this.constructor(this._x,this._y,this._z,this._order)}copy(e){return this._x=e._x,this._y=e._y,this._z=e._z,this._order=e._order,this._onChangeCallback(),this}setFromRotationMatrix(e,t=this._order,n=!0){let s=e.elements,r=s[0],o=s[4],a=s[8],c=s[1],l=s[5],u=s[9],h=s[2],f=s[6],d=s[10];switch(t){case"XYZ":this._y=Math.asin(qe(a,-1,1)),Math.abs(a)<.9999999?(this._x=Math.atan2(-u,d),this._z=Math.atan2(-o,r)):(this._x=Math.atan2(f,l),this._z=0);break;case"YXZ":this._x=Math.asin(-qe(u,-1,1)),Math.abs(u)<.9999999?(this._y=Math.atan2(a,d),this._z=Math.atan2(c,l)):(this._y=Math.atan2(-h,r),this._z=0);break;case"ZXY":this._x=Math.asin(qe(f,-1,1)),Math.abs(f)<.9999999?(this._y=Math.atan2(-h,d),this._z=Math.atan2(-o,l)):(this._y=0,this._z=Math.atan2(c,r));break;case"ZYX":this._y=Math.asin(-qe(h,-1,1)),Math.abs(h)<.9999999?(this._x=Math.atan2(f,d),this._z=Math.atan2(c,r)):(this._x=0,this._z=Math.atan2(-o,l));break;case"YZX":this._z=Math.asin(qe(c,-1,1)),Math.abs(c)<.9999999?(this._x=Math.atan2(-u,l),this._y=Math.atan2(-h,r)):(this._x=0,this._y=Math.atan2(a,d));break;case"XZY":this._z=Math.asin(-qe(o,-1,1)),Math.abs(o)<.9999999?(this._x=Math.atan2(f,l),this._y=Math.atan2(a,r)):(this._x=Math.atan2(-u,d),this._y=0);break;default:Fe("Euler: .setFromRotationMatrix() encountered an unknown order: "+t)}return this._order=t,n===!0&&this._onChangeCallback(),this}setFromQuaternion(e,t,n){return Yp.makeRotationFromQuaternion(e),this.setFromRotationMatrix(Yp,t,n)}setFromVector3(e,t=this._order){return this.set(e.x,e.y,e.z,t)}reorder(e){return Zp.setFromEuler(this),this.setFromQuaternion(Zp,e)}equals(e){return e._x===this._x&&e._y===this._y&&e._z===this._z&&e._order===this._order}fromArray(e){return this._x=e[0],this._y=e[1],this._z=e[2],e[3]!==void 0&&(this._order=e[3]),this._onChangeCallback(),this}toArray(e=[],t=0){return e[t]=this._x,e[t+1]=this._y,e[t+2]=this._z,e[t+3]=this._order,e}_onChange(e){return this._onChangeCallback=e,this}_onChangeCallback(){}*[Symbol.iterator](){yield this._x,yield this._y,yield this._z,yield this._order}};Oi.DEFAULT_ORDER="XYZ";var Br=class{constructor(){this.mask=1}set(e){this.mask=(1<<e|0)>>>0}enable(e){this.mask|=1<<e|0}enableAll(){this.mask=-1}toggle(e){this.mask^=1<<e|0}disable(e){this.mask&=~(1<<e|0)}disableAll(){this.mask=0}test(e){return(this.mask&e.mask)!==0}isEnabled(e){return(this.mask&(1<<e|0))!==0}},a_=0,Kp=new I,dr=new pn,Pi=new Ie,pc=new I,Io=new I,c_=new I,l_=new pn,Jp=new I(1,0,0),$p=new I(0,1,0),jp=new I(0,0,1),Qp={type:"added"},u_={type:"removed"},pr={type:"childadded",child:null},bh={type:"childremoved",child:null},Nt=class i extends ri{constructor(){super(),this.isObject3D=!0,Object.defineProperty(this,"id",{value:a_++}),this.uuid=Kn(),this.name="",this.type="Object3D",this.parent=null,this.children=[],this.up=i.DEFAULT_UP.clone();let e=new I,t=new Oi,n=new pn,s=new I(1,1,1);function r(){n.setFromEuler(t,!1)}function o(){t.setFromQuaternion(n,void 0,!1)}t._onChange(r),n._onChange(o),Object.defineProperties(this,{position:{configurable:!0,enumerable:!0,value:e},rotation:{configurable:!0,enumerable:!0,value:t},quaternion:{configurable:!0,enumerable:!0,value:n},scale:{configurable:!0,enumerable:!0,value:s},modelViewMatrix:{value:new Ie},normalMatrix:{value:new Ye}}),this.matrix=new Ie,this.matrixWorld=new Ie,this.matrixAutoUpdate=i.DEFAULT_MATRIX_AUTO_UPDATE,this.matrixWorldAutoUpdate=i.DEFAULT_MATRIX_WORLD_AUTO_UPDATE,this.matrixWorldNeedsUpdate=!1,this.layers=new Br,this.visible=!0,this.castShadow=!1,this.receiveShadow=!1,this.frustumCulled=!0,this.renderOrder=0,this.animations=[],this.customDepthMaterial=void 0,this.customDistanceMaterial=void 0,this.static=!1,this.userData={},this.pivot=null}onBeforeShadow(){}onAfterShadow(){}onBeforeRender(){}onAfterRender(){}applyMatrix4(e){this.matrixAutoUpdate&&this.updateMatrix(),this.matrix.premultiply(e),this.matrix.decompose(this.position,this.quaternion,this.scale)}applyQuaternion(e){return this.quaternion.premultiply(e),this}setRotationFromAxisAngle(e,t){this.quaternion.setFromAxisAngle(e,t)}setRotationFromEuler(e){this.quaternion.setFromEuler(e,!0)}setRotationFromMatrix(e){this.quaternion.setFromRotationMatrix(e)}setRotationFromQuaternion(e){this.quaternion.copy(e)}rotateOnAxis(e,t){return dr.setFromAxisAngle(e,t),this.quaternion.multiply(dr),this}rotateOnWorldAxis(e,t){return dr.setFromAxisAngle(e,t),this.quaternion.premultiply(dr),this}rotateX(e){return this.rotateOnAxis(Jp,e)}rotateY(e){return this.rotateOnAxis($p,e)}rotateZ(e){return this.rotateOnAxis(jp,e)}translateOnAxis(e,t){return Kp.copy(e).applyQuaternion(this.quaternion),this.position.add(Kp.multiplyScalar(t)),this}translateX(e){return this.translateOnAxis(Jp,e)}translateY(e){return this.translateOnAxis($p,e)}translateZ(e){return this.translateOnAxis(jp,e)}localToWorld(e){return this.updateWorldMatrix(!0,!1),e.applyMatrix4(this.matrixWorld)}worldToLocal(e){return this.updateWorldMatrix(!0,!1),e.applyMatrix4(Pi.copy(this.matrixWorld).invert())}lookAt(e,t,n){e.isVector3?pc.copy(e):pc.set(e,t,n);let s=this.parent;this.updateWorldMatrix(!0,!1),Io.setFromMatrixPosition(this.matrixWorld),this.isCamera||this.isLight?Pi.lookAt(Io,pc,this.up):Pi.lookAt(pc,Io,this.up),this.quaternion.setFromRotationMatrix(Pi),s&&(Pi.extractRotation(s.matrixWorld),dr.setFromRotationMatrix(Pi),this.quaternion.premultiply(dr.invert()))}add(e){if(arguments.length>1){for(let t=0;t<arguments.length;t++)this.add(arguments[t]);return this}return e===this?(We("Object3D.add: object can't be added as a child of itself.",e),this):(e&&e.isObject3D?(e.removeFromParent(),e.parent=this,this.children.push(e),e.dispatchEvent(Qp),pr.child=e,this.dispatchEvent(pr),pr.child=null):We("Object3D.add: object not an instance of THREE.Object3D.",e),this)}remove(e){if(arguments.length>1){for(let n=0;n<arguments.length;n++)this.remove(arguments[n]);return this}let t=this.children.indexOf(e);return t!==-1&&(e.parent=null,this.children.splice(t,1),e.dispatchEvent(u_),bh.child=e,this.dispatchEvent(bh),bh.child=null),this}removeFromParent(){let e=this.parent;return e!==null&&e.remove(this),this}clear(){return this.remove(...this.children)}attach(e){return this.updateWorldMatrix(!0,!1),Pi.copy(this.matrixWorld).invert(),e.parent!==null&&(e.parent.updateWorldMatrix(!0,!1),Pi.multiply(e.parent.matrixWorld)),e.applyMatrix4(Pi),e.removeFromParent(),e.parent=this,this.children.push(e),e.updateWorldMatrix(!1,!0),e.dispatchEvent(Qp),pr.child=e,this.dispatchEvent(pr),pr.child=null,this}getObjectById(e){return this.getObjectByProperty("id",e)}getObjectByName(e){return this.getObjectByProperty("name",e)}getObjectByProperty(e,t){if(this[e]===t)return this;for(let n=0,s=this.children.length;n<s;n++){let o=this.children[n].getObjectByProperty(e,t);if(o!==void 0)return o}}getObjectsByProperty(e,t,n=[]){this[e]===t&&n.push(this);let s=this.children;for(let r=0,o=s.length;r<o;r++)s[r].getObjectsByProperty(e,t,n);return n}getWorldPosition(e){return this.updateWorldMatrix(!0,!1),e.setFromMatrixPosition(this.matrixWorld)}getWorldQuaternion(e){return this.updateWorldMatrix(!0,!1),this.matrixWorld.decompose(Io,e,c_),e}getWorldScale(e){return this.updateWorldMatrix(!0,!1),this.matrixWorld.decompose(Io,l_,e),e}getWorldDirection(e){this.updateWorldMatrix(!0,!1);let t=this.matrixWorld.elements;return e.set(t[8],t[9],t[10]).normalize()}raycast(){}intersectsFrustum(){}traverse(e){e(this);let t=this.children;for(let n=0,s=t.length;n<s;n++)t[n].traverse(e)}traverseVisible(e){if(this.visible===!1)return;e(this);let t=this.children;for(let n=0,s=t.length;n<s;n++)t[n].traverseVisible(e)}traverseAncestors(e){let t=this.parent;t!==null&&(e(t),t.traverseAncestors(e))}updateMatrix(){this.matrix.compose(this.position,this.quaternion,this.scale);let e=this.pivot;if(e!==null){let t=e.x,n=e.y,s=e.z,r=this.matrix.elements;r[12]+=t-r[0]*t-r[4]*n-r[8]*s,r[13]+=n-r[1]*t-r[5]*n-r[9]*s,r[14]+=s-r[2]*t-r[6]*n-r[10]*s}this.matrixWorldNeedsUpdate=!0}updateMatrixWorld(e){this.matrixAutoUpdate&&this.updateMatrix(),(this.matrixWorldNeedsUpdate||e)&&(this.matrixWorldAutoUpdate===!0&&(this.parent===null?this.matrixWorld.copy(this.matrix):this.matrixWorld.multiplyMatrices(this.parent.matrixWorld,this.matrix)),this.matrixWorldNeedsUpdate=!1,e=!0);let t=this.children;for(let n=0,s=t.length;n<s;n++)t[n].updateMatrixWorld(e)}updateWorldMatrix(e,t,n=!1){let s=this.parent;if(e===!0&&s!==null&&s.updateWorldMatrix(!0,!1),this.matrixAutoUpdate&&this.updateMatrix(),(this.matrixWorldNeedsUpdate||n)&&(this.matrixWorldAutoUpdate===!0&&(this.parent===null?this.matrixWorld.copy(this.matrix):this.matrixWorld.multiplyMatrices(this.parent.matrixWorld,this.matrix)),this.matrixWorldNeedsUpdate=!1,n=!0),t===!0){let r=this.children;for(let o=0,a=r.length;o<a;o++)r[o].updateWorldMatrix(!1,!0,n)}}toJSON(e){let t=e===void 0||typeof e=="string",n={};t&&(e={geometries:{},materials:{},textures:{},images:{},shapes:{},skeletons:{},animations:{},nodes:{}},n.metadata={version:4.7,type:"Object",generator:"Object3D.toJSON"});let s={};s.uuid=this.uuid,s.type=this.type,s.name=this.name,s.castShadow=this.castShadow,s.receiveShadow=this.receiveShadow,s.visible=this.visible,s.frustumCulled=this.frustumCulled,s.renderOrder=this.renderOrder,s.static=this.static,s.matrixAutoUpdate=this.matrixAutoUpdate,Object.keys(this.userData).length>0&&(s.userData=this.userData),s.layers=this.layers.mask,s.matrix=this.matrix.toArray(),s.up=this.up.toArray(),this.pivot!==null&&(s.pivot=this.pivot.toArray()),this.morphTargetDictionary!==void 0&&(s.morphTargetDictionary=Object.assign({},this.morphTargetDictionary)),this.morphTargetInfluences!==void 0&&(s.morphTargetInfluences=this.morphTargetInfluences.slice()),this.isInstancedMesh&&(s.type="InstancedMesh",s.count=this.count,s.instanceMatrix=this.instanceMatrix.toJSON(),this.instanceColor!==null&&(s.instanceColor=this.instanceColor.toJSON())),this.isBatchedMesh&&(s.type="BatchedMesh",s.perObjectFrustumCulled=this.perObjectFrustumCulled,s.sortObjects=this.sortObjects,s.drawRanges=this._drawRanges,s.reservedRanges=this._reservedRanges,s.geometryInfo=this._geometryInfo.map(a=>({...a,boundingBox:a.boundingBox?a.boundingBox.toJSON():void 0,boundingSphere:a.boundingSphere?a.boundingSphere.toJSON():void 0})),s.instanceInfo=this._instanceInfo.map(a=>({...a})),s.availableInstanceIds=this._availableInstanceIds.slice(),s.availableGeometryIds=this._availableGeometryIds.slice(),s.nextIndexStart=this._nextIndexStart,s.nextVertexStart=this._nextVertexStart,s.geometryCount=this._geometryCount,s.maxInstanceCount=this._maxInstanceCount,s.maxVertexCount=this._maxVertexCount,s.maxIndexCount=this._maxIndexCount,s.geometryInitialized=this._geometryInitialized,s.matricesTexture=this._matricesTexture.toJSON(e),s.indirectTexture=this._indirectTexture.toJSON(e),this._colorsTexture!==null&&(s.colorsTexture=this._colorsTexture.toJSON(e)),this.boundingSphere!==null&&(s.boundingSphere=this.boundingSphere.toJSON()),this.boundingBox!==null&&(s.boundingBox=this.boundingBox.toJSON()));function r(a,c){return a[c.uuid]===void 0&&(a[c.uuid]=c.toJSON(e)),c.uuid}if(this.isScene)this.background&&(this.background.isColor?s.background=this.background.toJSON():this.background.isTexture&&(s.background=this.background.toJSON(e).uuid)),this.environment&&this.environment.isTexture&&this.environment.isRenderTargetTexture!==!0&&(s.environment=this.environment.toJSON(e).uuid);else if(this.isMesh||this.isLine||this.isPoints){s.geometry=r(e.geometries,this.geometry);let a=this.geometry.parameters;if(a!==void 0&&a.shapes!==void 0){let c=a.shapes;if(Array.isArray(c))for(let l=0,u=c.length;l<u;l++){let h=c[l];r(e.shapes,h)}else r(e.shapes,c)}}if(this.isSkinnedMesh&&(s.bindMode=this.bindMode,s.bindMatrix=this.bindMatrix.toArray(),this.skeleton!==void 0&&(r(e.skeletons,this.skeleton),s.skeleton=this.skeleton.uuid)),this.material!==void 0)if(Array.isArray(this.material)){let a=[];for(let c=0,l=this.material.length;c<l;c++)a.push(r(e.materials,this.material[c]));s.material=a}else s.material=r(e.materials,this.material);if(this.children.length>0){s.children=[];for(let a=0;a<this.children.length;a++)s.children.push(this.children[a].toJSON(e).object)}if(this.animations.length>0){s.animations=[];for(let a=0;a<this.animations.length;a++){let c=this.animations[a];s.animations.push(r(e.animations,c))}}if(t){let a=o(e.geometries),c=o(e.materials),l=o(e.textures),u=o(e.images),h=o(e.shapes),f=o(e.skeletons),d=o(e.animations),m=o(e.nodes);a.length>0&&(n.geometries=a),c.length>0&&(n.materials=c),l.length>0&&(n.textures=l),u.length>0&&(n.images=u),h.length>0&&(n.shapes=h),f.length>0&&(n.skeletons=f),d.length>0&&(n.animations=d),m.length>0&&(n.nodes=m)}return n.object=s,n;function o(a){let c=[];for(let l in a){let u=a[l];delete u.metadata,c.push(u)}return c}}clone(e){return new this.constructor().copy(this,e)}copy(e,t=!0){if(this.name=e.name,this.up.copy(e.up),this.position.copy(e.position),this.rotation.order=e.rotation.order,this.quaternion.copy(e.quaternion),this.scale.copy(e.scale),this.pivot=e.pivot!==null?e.pivot.clone():null,this.matrix.copy(e.matrix),this.matrixWorld.copy(e.matrixWorld),this.matrixAutoUpdate=e.matrixAutoUpdate,this.matrixWorldAutoUpdate=e.matrixWorldAutoUpdate,this.matrixWorldNeedsUpdate=e.matrixWorldNeedsUpdate,this.layers.mask=e.layers.mask,this.visible=e.visible,this.castShadow=e.castShadow,this.receiveShadow=e.receiveShadow,this.frustumCulled=e.frustumCulled,this.renderOrder=e.renderOrder,this.static=e.static,this.animations=e.animations.slice(),this.userData=JSON.parse(JSON.stringify(e.userData)),t===!0)for(let n=0;n<e.children.length;n++){let s=e.children[n];this.add(s.clone())}return this}dispose(){this.dispatchEvent({type:"dispose"})}};Nt.DEFAULT_UP=new I(0,1,0);Nt.DEFAULT_MATRIX_AUTO_UPDATE=!0;Nt.DEFAULT_MATRIX_WORLD_AUTO_UPDATE=!0;var Bt=class extends Nt{constructor(){super(),this.isGroup=!0,this.type="Group"}},h_={type:"move"},zr=class{constructor(){this._targetRay=null,this._grip=null,this._hand=null}getHandSpace(){return this._hand===null&&(this._hand=new Bt,this._hand.matrixAutoUpdate=!1,this._hand.visible=!1,this._hand.joints={},this._hand.inputState={pinching:!1}),this._hand}getTargetRaySpace(){return this._targetRay===null&&(this._targetRay=new Bt,this._targetRay.matrixAutoUpdate=!1,this._targetRay.visible=!1,this._targetRay.hasLinearVelocity=!1,this._targetRay.linearVelocity=new I,this._targetRay.hasAngularVelocity=!1,this._targetRay.angularVelocity=new I),this._targetRay}getGripSpace(){return this._grip===null&&(this._grip=new Bt,this._grip.matrixAutoUpdate=!1,this._grip.visible=!1,this._grip.hasLinearVelocity=!1,this._grip.linearVelocity=new I,this._grip.hasAngularVelocity=!1,this._grip.angularVelocity=new I,this._grip.eventsEnabled=!1),this._grip}dispatchEvent(e){return this._targetRay!==null&&this._targetRay.dispatchEvent(e),this._grip!==null&&this._grip.dispatchEvent(e),this._hand!==null&&this._hand.dispatchEvent(e),this}connect(e){if(e&&e.hand){let t=this._hand;if(t)for(let n of e.hand.values())this._getHandJoint(t,n)}return this.dispatchEvent({type:"connected",data:e}),this}disconnect(e){return this.dispatchEvent({type:"disconnected",data:e}),this._targetRay!==null&&(this._targetRay.visible=!1),this._grip!==null&&(this._grip.visible=!1),this._hand!==null&&(this._hand.visible=!1),this}update(e,t,n){let s=null,r=null,o=null,a=this._targetRay,c=this._grip,l=this._hand;if(e&&t.session.visibilityState!=="visible-blurred"){if(l&&e.hand){o=!0;for(let x of e.hand.values()){let g=t.getJointPose(x,n),p=this._getHandJoint(l,x);g!==null&&(p.matrix.fromArray(g.transform.matrix),p.matrix.decompose(p.position,p.rotation,p.scale),p.matrixWorldNeedsUpdate=!0,p.jointRadius=g.radius),p.visible=g!==null}let u=l.joints["index-finger-tip"],h=l.joints["thumb-tip"],f=u.position.distanceTo(h.position),d=.02,m=.005;l.inputState.pinching&&f>d+m?(l.inputState.pinching=!1,this.dispatchEvent({type:"pinchend",handedness:e.handedness,target:this})):!l.inputState.pinching&&f<=d-m&&(l.inputState.pinching=!0,this.dispatchEvent({type:"pinchstart",handedness:e.handedness,target:this}))}else c!==null&&e.gripSpace&&(r=t.getPose(e.gripSpace,n),r!==null&&(c.matrix.fromArray(r.transform.matrix),c.matrix.decompose(c.position,c.rotation,c.scale),c.matrixWorldNeedsUpdate=!0,r.linearVelocity?(c.hasLinearVelocity=!0,c.linearVelocity.copy(r.linearVelocity)):c.hasLinearVelocity=!1,r.angularVelocity?(c.hasAngularVelocity=!0,c.angularVelocity.copy(r.angularVelocity)):c.hasAngularVelocity=!1,c.eventsEnabled&&c.dispatchEvent({type:"gripUpdated",data:e,target:this})));a!==null&&(s=t.getPose(e.targetRaySpace,n),s===null&&r!==null&&(s=r),s!==null&&(a.matrix.fromArray(s.transform.matrix),a.matrix.decompose(a.position,a.rotation,a.scale),a.matrixWorldNeedsUpdate=!0,s.linearVelocity?(a.hasLinearVelocity=!0,a.linearVelocity.copy(s.linearVelocity)):a.hasLinearVelocity=!1,s.angularVelocity?(a.hasAngularVelocity=!0,a.angularVelocity.copy(s.angularVelocity)):a.hasAngularVelocity=!1,this.dispatchEvent(h_)))}return a!==null&&(a.visible=s!==null),c!==null&&(c.visible=r!==null),l!==null&&(l.visible=o!==null),this}_getHandJoint(e,t){if(e.joints[t.jointName]===void 0){let n=new Bt;n.matrixAutoUpdate=!1,n.visible=!1,e.joints[t.jointName]=n,e.add(n)}return e.joints[t.jointName]}},yg={aliceblue:15792383,antiquewhite:16444375,aqua:65535,aquamarine:8388564,azure:15794175,beige:16119260,bisque:16770244,black:0,blanchedalmond:16772045,blue:255,blueviolet:9055202,brown:10824234,burlywood:14596231,cadetblue:6266528,chartreuse:8388352,chocolate:13789470,coral:16744272,cornflowerblue:6591981,cornsilk:16775388,crimson:14423100,cyan:65535,darkblue:139,darkcyan:35723,darkgoldenrod:12092939,darkgray:11119017,darkgreen:25600,darkgrey:11119017,darkkhaki:12433259,darkmagenta:9109643,darkolivegreen:5597999,darkorange:16747520,darkorchid:10040012,darkred:9109504,darksalmon:15308410,darkseagreen:9419919,darkslateblue:4734347,darkslategray:3100495,darkslategrey:3100495,darkturquoise:52945,darkviolet:9699539,deeppink:16716947,deepskyblue:49151,dimgray:6908265,dimgrey:6908265,dodgerblue:2003199,firebrick:11674146,floralwhite:16775920,forestgreen:2263842,fuchsia:16711935,gainsboro:14474460,ghostwhite:16316671,gold:16766720,goldenrod:14329120,gray:8421504,green:32768,greenyellow:11403055,grey:8421504,honeydew:15794160,hotpink:16738740,indianred:13458524,indigo:4915330,ivory:16777200,khaki:15787660,lavender:15132410,lavenderblush:16773365,lawngreen:8190976,lemonchiffon:16775885,lightblue:11393254,lightcoral:15761536,lightcyan:14745599,lightgoldenrodyellow:16448210,lightgray:13882323,lightgreen:9498256,lightgrey:13882323,lightpink:16758465,lightsalmon:16752762,lightseagreen:2142890,lightskyblue:8900346,lightslategray:7833753,lightslategrey:7833753,lightsteelblue:11584734,lightyellow:16777184,lime:65280,limegreen:3329330,linen:16445670,magenta:16711935,maroon:8388608,mediumaquamarine:6737322,mediumblue:205,mediumorchid:12211667,mediumpurple:9662683,mediumseagreen:3978097,mediumslateblue:8087790,mediumspringgreen:64154,mediumturquoise:4772300,mediumvioletred:13047173,midnightblue:1644912,mintcream:16121850,mistyrose:16770273,moccasin:16770229,navajowhite:16768685,navy:128,oldlace:16643558,olive:8421376,olivedrab:7048739,orange:16753920,orangered:16729344,orchid:14315734,palegoldenrod:15657130,palegreen:10025880,paleturquoise:11529966,palevioletred:14381203,papayawhip:16773077,peachpuff:16767673,peru:13468991,pink:16761035,plum:14524637,powderblue:11591910,purple:8388736,rebeccapurple:6697881,red:16711680,rosybrown:12357519,royalblue:4286945,saddlebrown:9127187,salmon:16416882,sandybrown:16032864,seagreen:3050327,seashell:16774638,sienna:10506797,silver:12632256,skyblue:8900331,slateblue:6970061,slategray:7372944,slategrey:7372944,snow:16775930,springgreen:65407,steelblue:4620980,tan:13808780,teal:32896,thistle:14204888,tomato:16737095,turquoise:4251856,violet:15631086,wheat:16113331,white:16777215,whitesmoke:16119285,yellow:16776960,yellowgreen:10145074},is={h:0,s:0,l:0},mc={h:0,s:0,l:0};function Mh(i,e,t){return t<0&&(t+=1),t>1&&(t-=1),t<1/6?i+(e-i)*6*t:t<1/2?e:t<2/3?i+(e-i)*6*(2/3-t):i}var Ve=class{constructor(e,t,n){return this.isColor=!0,this.r=1,this.g=1,this.b=1,this.set(e,t,n)}set(e,t,n){if(t===void 0&&n===void 0){let s=e;s&&s.isColor?this.copy(s):typeof s=="number"?this.setHex(s):typeof s=="string"&&this.setStyle(s)}else this.setRGB(e,t,n);return this}setScalar(e){return this.r=e,this.g=e,this.b=e,this}setHex(e,t=Ft){return e=Math.floor(e),this.r=(e>>16&255)/255,this.g=(e>>8&255)/255,this.b=(e&255)/255,tt.colorSpaceToWorking(this,t),this}setRGB(e,t,n,s=tt.workingColorSpace){return this.r=e,this.g=t,this.b=n,tt.colorSpaceToWorking(this,s),this}setHSL(e,t,n,s=tt.workingColorSpace){if(e=Df(e,1),t=qe(t,0,1),n=qe(n,0,1),t===0)this.r=this.g=this.b=n;else{let r=n<=.5?n*(1+t):n+t-n*t,o=2*n-r;this.r=Mh(o,r,e+1/3),this.g=Mh(o,r,e),this.b=Mh(o,r,e-1/3)}return tt.colorSpaceToWorking(this,s),this}setStyle(e,t=Ft){function n(r){r!==void 0&&parseFloat(r)<1&&Fe("Color: Alpha component of "+e+" will be ignored.")}let s;if(s=/^(\w+)\(([^\)]*)\)/.exec(e)){let r,o=s[1],a=s[2];switch(o){case"rgb":case"rgba":if(r=/^\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(a))return n(r[4]),this.setRGB(Math.min(255,parseInt(r[1],10))/255,Math.min(255,parseInt(r[2],10))/255,Math.min(255,parseInt(r[3],10))/255,t);if(r=/^\s*(\d+)\%\s*,\s*(\d+)\%\s*,\s*(\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(a))return n(r[4]),this.setRGB(Math.min(100,parseInt(r[1],10))/100,Math.min(100,parseInt(r[2],10))/100,Math.min(100,parseInt(r[3],10))/100,t);break;case"hsl":case"hsla":if(r=/^\s*(\d*\.?\d+)\s*,\s*(\d*\.?\d+)\%\s*,\s*(\d*\.?\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(a))return n(r[4]),this.setHSL(parseFloat(r[1])/360,parseFloat(r[2])/100,parseFloat(r[3])/100,t);break;default:Fe("Color: Unknown color model "+e)}}else if(s=/^\#([A-Fa-f\d]+)$/.exec(e)){let r=s[1],o=r.length;if(o===3)return this.setRGB(parseInt(r.charAt(0),16)/15,parseInt(r.charAt(1),16)/15,parseInt(r.charAt(2),16)/15,t);if(o===6)return this.setHex(parseInt(r,16),t);Fe("Color: Invalid hex color "+e)}else if(e&&e.length>0)return this.setColorName(e,t);return this}setColorName(e,t=Ft){let n=yg[e.toLowerCase()];return n!==void 0?this.setHex(n,t):Fe("Color: Unknown color "+e),this}clone(){return new this.constructor(this.r,this.g,this.b)}copy(e){return this.r=e.r,this.g=e.g,this.b=e.b,this}copySRGBToLinear(e){return this.r=Fi(e.r),this.g=Fi(e.g),this.b=Fi(e.b),this}copyLinearToSRGB(e){return this.r=Ir(e.r),this.g=Ir(e.g),this.b=Ir(e.b),this}convertSRGBToLinear(){return this.copySRGBToLinear(this),this}convertLinearToSRGB(){return this.copyLinearToSRGB(this),this}getHex(e=Ft){return tt.workingToColorSpace(dn.copy(this),e),Math.round(qe(dn.r*255,0,255))*65536+Math.round(qe(dn.g*255,0,255))*256+Math.round(qe(dn.b*255,0,255))}getHexString(e=Ft){return("000000"+this.getHex(e).toString(16)).slice(-6)}getHSL(e,t=tt.workingColorSpace){tt.workingToColorSpace(dn.copy(this),t);let n=dn.r,s=dn.g,r=dn.b,o=Math.max(n,s,r),a=Math.min(n,s,r),c,l,u=(a+o)/2;if(a===o)c=0,l=0;else{let h=o-a;switch(l=u<=.5?h/(o+a):h/(2-o-a),o){case n:c=(s-r)/h+(s<r?6:0);break;case s:c=(r-n)/h+2;break;case r:c=(n-s)/h+4;break}c/=6}return e.h=c,e.s=l,e.l=u,e}getRGB(e,t=tt.workingColorSpace){return tt.workingToColorSpace(dn.copy(this),t),e.r=dn.r,e.g=dn.g,e.b=dn.b,e}getStyle(e=Ft){tt.workingToColorSpace(dn.copy(this),e);let t=dn.r,n=dn.g,s=dn.b;return e!==Ft?`color(${e} ${t.toFixed(3)} ${n.toFixed(3)} ${s.toFixed(3)})`:`rgb(${Math.round(t*255)},${Math.round(n*255)},${Math.round(s*255)})`}offsetHSL(e,t,n){return this.getHSL(is),this.setHSL(is.h+e,is.s+t,is.l+n)}add(e){return this.r+=e.r,this.g+=e.g,this.b+=e.b,this}addColors(e,t){return this.r=e.r+t.r,this.g=e.g+t.g,this.b=e.b+t.b,this}addScalar(e){return this.r+=e,this.g+=e,this.b+=e,this}sub(e){return this.r=Math.max(0,this.r-e.r),this.g=Math.max(0,this.g-e.g),this.b=Math.max(0,this.b-e.b),this}multiply(e){return this.r*=e.r,this.g*=e.g,this.b*=e.b,this}multiplyScalar(e){return this.r*=e,this.g*=e,this.b*=e,this}lerp(e,t){return this.r+=(e.r-this.r)*t,this.g+=(e.g-this.g)*t,this.b+=(e.b-this.b)*t,this}lerpColors(e,t,n){return this.r=e.r+(t.r-e.r)*n,this.g=e.g+(t.g-e.g)*n,this.b=e.b+(t.b-e.b)*n,this}lerpHSL(e,t){this.getHSL(is),e.getHSL(mc);let n=Wo(is.h,mc.h,t),s=Wo(is.s,mc.s,t),r=Wo(is.l,mc.l,t);return this.setHSL(n,s,r),this}setFromVector3(e){return this.r=e.x,this.g=e.y,this.b=e.z,this}applyMatrix3(e){let t=this.r,n=this.g,s=this.b,r=e.elements;return this.r=r[0]*t+r[3]*n+r[6]*s,this.g=r[1]*t+r[4]*n+r[7]*s,this.b=r[2]*t+r[5]*n+r[8]*s,this}equals(e){return e.r===this.r&&e.g===this.g&&e.b===this.b}fromArray(e,t=0){return this.r=e[t],this.g=e[t+1],this.b=e[t+2],this}toArray(e=[],t=0){return e[t]=this.r,e[t+1]=this.g,e[t+2]=this.b,e}fromBufferAttribute(e,t){return this.r=e.getX(t),this.g=e.getY(t),this.b=e.getZ(t),this}toJSON(){return this.getHex()}*[Symbol.iterator](){yield this.r,yield this.g,yield this.b}},dn=new Ve;Ve.NAMES=yg;var Jo=class i{constructor(e,t=1,n=1e3){this.isFog=!0,this.name="",this.color=new Ve(e),this.near=t,this.far=n}clone(){return new i(this.color,this.near,this.far)}toJSON(){return{type:"Fog",name:this.name,color:this.color.getHex(),near:this.near,far:this.far}}},Bs=class extends Nt{constructor(){super(),this.isScene=!0,this.type="Scene",this.background=null,this.environment=null,this.fog=null,this.backgroundBlurriness=0,this.backgroundIntensity=1,this.backgroundRotation=new Oi,this.environmentIntensity=1,this.environmentRotation=new Oi,this.overrideMaterial=null,typeof __THREE_DEVTOOLS__<"u"&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe",{detail:this}))}copy(e,t){return super.copy(e,t),e.background!==null&&(this.background=e.background.clone()),e.environment!==null&&(this.environment=e.environment.clone()),e.fog!==null&&(this.fog=e.fog.clone()),this.backgroundBlurriness=e.backgroundBlurriness,this.backgroundIntensity=e.backgroundIntensity,this.backgroundRotation.copy(e.backgroundRotation),this.environmentIntensity=e.environmentIntensity,this.environmentRotation.copy(e.environmentRotation),e.overrideMaterial!==null&&(this.overrideMaterial=e.overrideMaterial.clone()),this.matrixAutoUpdate=e.matrixAutoUpdate,this}toJSON(e){let t=super.toJSON(e);return this.fog!==null&&(t.object.fog=this.fog.toJSON()),t.object.backgroundBlurriness=this.backgroundBlurriness,t.object.backgroundIntensity=this.backgroundIntensity,t.object.backgroundRotation=this.backgroundRotation.toArray(),t.object.environmentIntensity=this.environmentIntensity,t.object.environmentRotation=this.environmentRotation.toArray(),t}},ti=new I,Ii=new I,Th=new I,Li=new I,mr=new I,gr=new I,em=new I,wh=new I,Eh=new I,Ah=new I,Rh=new ut,Ch=new ut,Ph=new ut,cn=class i{constructor(e=new I,t=new I,n=new I){this.a=e,this.b=t,this.c=n}static getNormal(e,t,n,s){s.subVectors(n,t),ti.subVectors(e,t),s.cross(ti);let r=s.lengthSq();return r>0?s.multiplyScalar(1/Math.sqrt(r)):s.set(0,0,0)}static getBarycoord(e,t,n,s,r){ti.subVectors(s,t),Ii.subVectors(n,t),Th.subVectors(e,t);let o=ti.dot(ti),a=ti.dot(Ii),c=ti.dot(Th),l=Ii.dot(Ii),u=Ii.dot(Th),h=o*l-a*a;if(h===0)return r.set(0,0,0),null;let f=1/h,d=(l*c-a*u)*f,m=(o*u-a*c)*f;return r.set(1-d-m,m,d)}static containsPoint(e,t,n,s){return this.getBarycoord(e,t,n,s,Li)===null?!1:Li.x>=0&&Li.y>=0&&Li.x+Li.y<=1}static getInterpolation(e,t,n,s,r,o,a,c){return this.getBarycoord(e,t,n,s,Li)===null?(c.x=0,c.y=0,"z"in c&&(c.z=0),"w"in c&&(c.w=0),null):(c.setScalar(0),c.addScaledVector(r,Li.x),c.addScaledVector(o,Li.y),c.addScaledVector(a,Li.z),c)}static getInterpolatedAttribute(e,t,n,s,r,o){return Rh.setScalar(0),Ch.setScalar(0),Ph.setScalar(0),Rh.fromBufferAttribute(e,t),Ch.fromBufferAttribute(e,n),Ph.fromBufferAttribute(e,s),o.setScalar(0),o.addScaledVector(Rh,r.x),o.addScaledVector(Ch,r.y),o.addScaledVector(Ph,r.z),o}static isFrontFacing(e,t,n,s){return ti.subVectors(n,t),Ii.subVectors(e,t),ti.cross(Ii).dot(s)<0}set(e,t,n){return this.a.copy(e),this.b.copy(t),this.c.copy(n),this}setFromPointsAndIndices(e,t,n,s){return this.a.copy(e[t]),this.b.copy(e[n]),this.c.copy(e[s]),this}setFromAttributeAndIndices(e,t,n,s){return this.a.fromBufferAttribute(e,t),this.b.fromBufferAttribute(e,n),this.c.fromBufferAttribute(e,s),this}clone(){return new this.constructor().copy(this)}copy(e){return this.a.copy(e.a),this.b.copy(e.b),this.c.copy(e.c),this}getArea(){return ti.subVectors(this.c,this.b),Ii.subVectors(this.a,this.b),ti.cross(Ii).length()*.5}getMidpoint(e){return e.addVectors(this.a,this.b).add(this.c).multiplyScalar(1/3)}getNormal(e){return i.getNormal(this.a,this.b,this.c,e)}getPlane(e){return e.setFromCoplanarPoints(this.a,this.b,this.c)}getBarycoord(e,t){return i.getBarycoord(e,this.a,this.b,this.c,t)}getInterpolation(e,t,n,s,r){return i.getInterpolation(e,this.a,this.b,this.c,t,n,s,r)}containsPoint(e){return i.containsPoint(e,this.a,this.b,this.c)}isFrontFacing(e){return i.isFrontFacing(this.a,this.b,this.c,e)}intersectsBox(e){return e.intersectsTriangle(this)}closestPointToPoint(e,t){let n=this.a,s=this.b,r=this.c,o,a;mr.subVectors(s,n),gr.subVectors(r,n),wh.subVectors(e,n);let c=mr.dot(wh),l=gr.dot(wh);if(c<=0&&l<=0)return t.copy(n);Eh.subVectors(e,s);let u=mr.dot(Eh),h=gr.dot(Eh);if(u>=0&&h<=u)return t.copy(s);let f=c*h-u*l;if(f<=0&&c>=0&&u<=0)return o=c/(c-u),t.copy(n).addScaledVector(mr,o);Ah.subVectors(e,r);let d=mr.dot(Ah),m=gr.dot(Ah);if(m>=0&&d<=m)return t.copy(r);let x=d*l-c*m;if(x<=0&&l>=0&&m<=0)return a=l/(l-m),t.copy(n).addScaledVector(gr,a);let g=u*m-d*h;if(g<=0&&h-u>=0&&d-m>=0)return em.subVectors(r,s),a=(h-u)/(h-u+(d-m)),t.copy(s).addScaledVector(em,a);let p=1/(g+x+f);return o=x*p,a=f*p,t.copy(n).addScaledVector(mr,o).addScaledVector(gr,a)}equals(e){return e.a.equals(this.a)&&e.b.equals(this.b)&&e.c.equals(this.c)}},Ke=class{constructor(e=new I(1/0,1/0,1/0),t=new I(-1/0,-1/0,-1/0)){this.isBox3=!0,this.min=e,this.max=t}set(e,t){return this.min.copy(e),this.max.copy(t),this}setFromArray(e){this.makeEmpty();for(let t=0,n=e.length;t<n;t+=3)this.expandByPoint(ni.fromArray(e,t));return this}setFromBufferAttribute(e){this.makeEmpty();for(let t=0,n=e.count;t<n;t++)this.expandByPoint(ni.fromBufferAttribute(e,t));return this}setFromPoints(e){this.makeEmpty();for(let t=0,n=e.length;t<n;t++)this.expandByPoint(e[t]);return this}setFromCenterAndSize(e,t){let n=ni.copy(t).multiplyScalar(.5);return this.min.copy(e).sub(n),this.max.copy(e).add(n),this}setFromObject(e,t=!1){return this.makeEmpty(),this.expandByObject(e,t)}clone(){return new this.constructor().copy(this)}copy(e){return this.min.copy(e.min),this.max.copy(e.max),this}makeEmpty(){return this.min.x=this.min.y=this.min.z=1/0,this.max.x=this.max.y=this.max.z=-1/0,this}isEmpty(){return this.max.x<this.min.x||this.max.y<this.min.y||this.max.z<this.min.z}getCenter(e){return this.isEmpty()?e.set(0,0,0):e.addVectors(this.min,this.max).multiplyScalar(.5)}getSize(e){return this.isEmpty()?e.set(0,0,0):e.subVectors(this.max,this.min)}expandByPoint(e){return this.min.min(e),this.max.max(e),this}expandByVector(e){return this.min.sub(e),this.max.add(e),this}expandByScalar(e){return this.min.addScalar(-e),this.max.addScalar(e),this}expandByObject(e,t=!1){e.updateWorldMatrix(!1,!1);let n=e.geometry;if(n!==void 0){let r=n.getAttribute("position");if(t===!0&&r!==void 0&&e.isInstancedMesh!==!0)for(let o=0,a=r.count;o<a;o++)e.isMesh===!0?e.getVertexPosition(o,ni):ni.fromBufferAttribute(r,o),ni.applyMatrix4(e.matrixWorld),this.expandByPoint(ni);else e.boundingBox!==void 0?(e.boundingBox===null&&e.computeBoundingBox(),gc.copy(e.boundingBox)):(n.boundingBox===null&&n.computeBoundingBox(),gc.copy(n.boundingBox)),gc.applyMatrix4(e.matrixWorld),this.union(gc)}let s=e.children;for(let r=0,o=s.length;r<o;r++)this.expandByObject(s[r],t);return this}containsPoint(e){return e.x>=this.min.x&&e.x<=this.max.x&&e.y>=this.min.y&&e.y<=this.max.y&&e.z>=this.min.z&&e.z<=this.max.z}containsBox(e){return this.min.x<=e.min.x&&e.max.x<=this.max.x&&this.min.y<=e.min.y&&e.max.y<=this.max.y&&this.min.z<=e.min.z&&e.max.z<=this.max.z}getParameter(e,t){return t.set((e.x-this.min.x)/(this.max.x-this.min.x),(e.y-this.min.y)/(this.max.y-this.min.y),(e.z-this.min.z)/(this.max.z-this.min.z))}intersectsBox(e){return e.max.x>=this.min.x&&e.min.x<=this.max.x&&e.max.y>=this.min.y&&e.min.y<=this.max.y&&e.max.z>=this.min.z&&e.min.z<=this.max.z}intersectsSphere(e){return this.clampPoint(e.center,ni),ni.distanceToSquared(e.center)<=e.radius*e.radius}intersectsPlane(e){let t,n;return e.normal.x>0?(t=e.normal.x*this.min.x,n=e.normal.x*this.max.x):(t=e.normal.x*this.max.x,n=e.normal.x*this.min.x),e.normal.y>0?(t+=e.normal.y*this.min.y,n+=e.normal.y*this.max.y):(t+=e.normal.y*this.max.y,n+=e.normal.y*this.min.y),e.normal.z>0?(t+=e.normal.z*this.min.z,n+=e.normal.z*this.max.z):(t+=e.normal.z*this.max.z,n+=e.normal.z*this.min.z),t<=-e.constant&&n>=-e.constant}intersectsTriangle(e){if(this.isEmpty())return!1;this.getCenter(Lo),xc.subVectors(this.max,Lo),xr.subVectors(e.a,Lo),_r.subVectors(e.b,Lo),yr.subVectors(e.c,Lo),ss.subVectors(_r,xr),rs.subVectors(yr,_r),Cs.subVectors(xr,yr);let t=[0,-ss.z,ss.y,0,-rs.z,rs.y,0,-Cs.z,Cs.y,ss.z,0,-ss.x,rs.z,0,-rs.x,Cs.z,0,-Cs.x,-ss.y,ss.x,0,-rs.y,rs.x,0,-Cs.y,Cs.x,0];return!Ih(t,xr,_r,yr,xc)||(t=[1,0,0,0,1,0,0,0,1],!Ih(t,xr,_r,yr,xc))?!1:(_c.crossVectors(ss,rs),t=[_c.x,_c.y,_c.z],Ih(t,xr,_r,yr,xc))}clampPoint(e,t){return t.copy(e).clamp(this.min,this.max)}distanceToPoint(e){return this.clampPoint(e,ni).distanceTo(e)}getBoundingSphere(e){return this.isEmpty()?e.makeEmpty():(this.getCenter(e.center),e.radius=this.getSize(ni).length()*.5),e}intersect(e){return this.min.max(e.min),this.max.min(e.max),this.isEmpty()&&this.makeEmpty(),this}union(e){return this.min.min(e.min),this.max.max(e.max),this}applyMatrix4(e){return this.isEmpty()?this:(Ni[0].set(this.min.x,this.min.y,this.min.z).applyMatrix4(e),Ni[1].set(this.min.x,this.min.y,this.max.z).applyMatrix4(e),Ni[2].set(this.min.x,this.max.y,this.min.z).applyMatrix4(e),Ni[3].set(this.min.x,this.max.y,this.max.z).applyMatrix4(e),Ni[4].set(this.max.x,this.min.y,this.min.z).applyMatrix4(e),Ni[5].set(this.max.x,this.min.y,this.max.z).applyMatrix4(e),Ni[6].set(this.max.x,this.max.y,this.min.z).applyMatrix4(e),Ni[7].set(this.max.x,this.max.y,this.max.z).applyMatrix4(e),this.setFromPoints(Ni),this)}translate(e){return this.min.add(e),this.max.add(e),this}equals(e){return e.min.equals(this.min)&&e.max.equals(this.max)}toJSON(){return{min:this.min.toArray(),max:this.max.toArray()}}fromJSON(e){return this.min.fromArray(e.min),this.max.fromArray(e.max),this}},Ni=[new I,new I,new I,new I,new I,new I,new I,new I],ni=new I,gc=new Ke,xr=new I,_r=new I,yr=new I,ss=new I,rs=new I,Cs=new I,Lo=new I,xc=new I,_c=new I,Ps=new I;function Ih(i,e,t,n,s){for(let r=0,o=i.length-3;r<=o;r+=3){Ps.fromArray(i,r);let a=s.x*Math.abs(Ps.x)+s.y*Math.abs(Ps.y)+s.z*Math.abs(Ps.z),c=e.dot(Ps),l=t.dot(Ps),u=n.dot(Ps);if(Math.max(-Math.max(c,l,u),Math.min(c,l,u))>a)return!1}return!0}var qt=new I,yc=new ce,f_=0,Tt=class extends ri{constructor(e,t,n=!1){if(super(),Array.isArray(e))throw new TypeError("THREE.BufferAttribute: array should be a Typed Array.");this.isBufferAttribute=!0,Object.defineProperty(this,"id",{value:f_++}),this.name="",this.array=e,this.itemSize=t,this.count=e!==void 0?e.length/t:0,this.normalized=n,this.usage=Lf,this.updateRanges=[],this.gpuType=Vn,this.version=0}onUploadCallback(){}set needsUpdate(e){e===!0&&this.version++}setUsage(e){return this.usage=e,this}addUpdateRange(e,t){this.updateRanges.push({start:e,count:t})}clearUpdateRanges(){this.updateRanges.length=0}copy(e){return this.name=e.name,this.array=new e.array.constructor(e.array),this.itemSize=e.itemSize,this.count=e.count,this.normalized=e.normalized,this.usage=e.usage,this.gpuType=e.gpuType,this}copyAt(e,t,n){e*=this.itemSize,n*=t.itemSize;for(let s=0,r=this.itemSize;s<r;s++)this.array[e+s]=t.array[n+s];return this}copyArray(e){return this.array.set(e),this}applyMatrix3(e){if(this.itemSize===2)for(let t=0,n=this.count;t<n;t++)yc.fromBufferAttribute(this,t),yc.applyMatrix3(e),this.setXY(t,yc.x,yc.y);else if(this.itemSize===3)for(let t=0,n=this.count;t<n;t++)qt.fromBufferAttribute(this,t),qt.applyMatrix3(e),this.setXYZ(t,qt.x,qt.y,qt.z);return this}applyMatrix4(e){for(let t=0,n=this.count;t<n;t++)qt.fromBufferAttribute(this,t),qt.applyMatrix4(e),this.setXYZ(t,qt.x,qt.y,qt.z);return this}applyNormalMatrix(e){for(let t=0,n=this.count;t<n;t++)qt.fromBufferAttribute(this,t),qt.applyNormalMatrix(e),this.setXYZ(t,qt.x,qt.y,qt.z);return this}transformDirection(e){for(let t=0,n=this.count;t<n;t++)qt.fromBufferAttribute(this,t),qt.transformDirection(e),this.setXYZ(t,qt.x,qt.y,qt.z);return this}set(e,t=0){return this.array.set(e,t),this}getComponent(e,t){let n=this.array[e*this.itemSize+t];return this.normalized&&(n=ii(n,this.array)),n}setComponent(e,t,n){return this.normalized&&(n=St(n,this.array)),this.array[e*this.itemSize+t]=n,this}getX(e){let t=this.array[e*this.itemSize];return this.normalized&&(t=ii(t,this.array)),t}setX(e,t){return this.normalized&&(t=St(t,this.array)),this.array[e*this.itemSize]=t,this}getY(e){let t=this.array[e*this.itemSize+1];return this.normalized&&(t=ii(t,this.array)),t}setY(e,t){return this.normalized&&(t=St(t,this.array)),this.array[e*this.itemSize+1]=t,this}getZ(e){let t=this.array[e*this.itemSize+2];return this.normalized&&(t=ii(t,this.array)),t}setZ(e,t){return this.normalized&&(t=St(t,this.array)),this.array[e*this.itemSize+2]=t,this}getW(e){let t=this.array[e*this.itemSize+3];return this.normalized&&(t=ii(t,this.array)),t}setW(e,t){return this.normalized&&(t=St(t,this.array)),this.array[e*this.itemSize+3]=t,this}setXY(e,t,n){return e*=this.itemSize,this.normalized&&(t=St(t,this.array),n=St(n,this.array)),this.array[e+0]=t,this.array[e+1]=n,this}setXYZ(e,t,n,s){return e*=this.itemSize,this.normalized&&(t=St(t,this.array),n=St(n,this.array),s=St(s,this.array)),this.array[e+0]=t,this.array[e+1]=n,this.array[e+2]=s,this}setXYZW(e,t,n,s,r){return e*=this.itemSize,this.normalized&&(t=St(t,this.array),n=St(n,this.array),s=St(s,this.array),r=St(r,this.array)),this.array[e+0]=t,this.array[e+1]=n,this.array[e+2]=s,this.array[e+3]=r,this}onUpload(e){return this.onUploadCallback=e,this}clone(){return new this.constructor(this.array,this.itemSize).copy(this)}toJSON(){let e={itemSize:this.itemSize,type:this.array.constructor.name,array:Array.from(this.array),normalized:this.normalized};return e.name=this.name,e.usage=this.usage,e.gpuType=this.gpuType,e}dispose(){this.dispatchEvent({type:"dispose"})}};var $o=class extends Tt{constructor(e,t,n){super(new Uint16Array(e),t,n)}};var jo=class extends Tt{constructor(e,t,n){super(new Uint32Array(e),t,n)}};var lt=class extends Tt{constructor(e,t,n){super(new Float32Array(e),t,n)}},d_=new Ke,No=new I,Lh=new I,Cn=class{constructor(e=new I,t=-1){this.isSphere=!0,this.center=e,this.radius=t}set(e,t){return this.center.copy(e),this.radius=t,this}setFromPoints(e,t){let n=this.center;t!==void 0?n.copy(t):d_.setFromPoints(e).getCenter(n);let s=0;for(let r=0,o=e.length;r<o;r++)s=Math.max(s,n.distanceToSquared(e[r]));return this.radius=Math.sqrt(s),this}copy(e){return this.center.copy(e.center),this.radius=e.radius,this}isEmpty(){return this.radius<0}makeEmpty(){return this.center.set(0,0,0),this.radius=-1,this}containsPoint(e){return e.distanceToSquared(this.center)<=this.radius*this.radius}distanceToPoint(e){return e.distanceTo(this.center)-this.radius}intersectsSphere(e){let t=this.radius+e.radius;return e.center.distanceToSquared(this.center)<=t*t}intersectsBox(e){return e.intersectsSphere(this)}intersectsPlane(e){return Math.abs(e.distanceToPoint(this.center))<=this.radius}clampPoint(e,t){let n=this.center.distanceToSquared(e);return t.copy(e),n>this.radius*this.radius&&(t.sub(this.center).normalize(),t.multiplyScalar(this.radius).add(this.center)),t}getBoundingBox(e){return this.isEmpty()?(e.makeEmpty(),e):(e.set(this.center,this.center),e.expandByScalar(this.radius),e)}applyMatrix4(e){return this.center.applyMatrix4(e),this.radius=this.radius*e.getMaxScaleOnAxis(),this}translate(e){return this.center.add(e),this}expandByPoint(e){if(this.isEmpty())return this.center.copy(e),this.radius=0,this;No.subVectors(e,this.center);let t=No.lengthSq();if(t>this.radius*this.radius){let n=Math.sqrt(t),s=(n-this.radius)*.5;this.center.addScaledVector(No,s/n),this.radius+=s}return this}union(e){return e.isEmpty()?this:this.isEmpty()?(this.copy(e),this):(this.center.equals(e.center)===!0?this.radius=Math.max(this.radius,e.radius):(Lh.subVectors(e.center,this.center).setLength(e.radius),this.expandByPoint(No.copy(e.center).add(Lh)),this.expandByPoint(No.copy(e.center).sub(Lh))),this)}equals(e){return e.center.equals(this.center)&&e.radius===this.radius}clone(){return new this.constructor().copy(this)}toJSON(){return{radius:this.radius,center:this.center.toArray()}}fromJSON(e){return this.radius=e.radius,this.center.fromArray(e.center),this}},p_=0,Yn=new Ie,Nh=new Nt,vr=new I,On=new Ke,Do=new Ke,rn=new I,ht=class i extends ri{constructor(){super(),this.isBufferGeometry=!0,Object.defineProperty(this,"id",{value:p_++}),this.uuid=Kn(),this.name="",this.type="BufferGeometry",this.index=null,this.indirect=null,this.indirectOffset=0,this.attributes={},this.morphAttributes={},this.morphTargetsRelative=!1,this.groups=[],this.boundingBox=null,this.boundingSphere=null,this.drawRange={start:0,count:1/0},this.userData={},this._transformed=!1}getIndex(){return this.index}setIndex(e){return Array.isArray(e)?this.index=new(Bx(e)?jo:$o)(e,1):this.index=e,this}setIndirect(e,t=0){return this.indirect=e,this.indirectOffset=t,this}getIndirect(){return this.indirect}getAttribute(e){return this.attributes[e]}setAttribute(e,t){return this.attributes[e]=t,this}deleteAttribute(e){return delete this.attributes[e],this}hasAttribute(e){return this.attributes[e]!==void 0}addGroup(e,t,n=0){this.groups.push({start:e,count:t,materialIndex:n})}clearGroups(){this.groups=[]}setDrawRange(e,t){this.drawRange.start=e,this.drawRange.count=t}applyMatrix4(e){let t=this.attributes.position;t!==void 0&&(t.applyMatrix4(e),t.needsUpdate=!0);let n=this.attributes.normal;if(n!==void 0){let r=new Ye().getNormalMatrix(e);n.applyNormalMatrix(r),n.needsUpdate=!0}let s=this.attributes.tangent;return s!==void 0&&(s.transformDirection(e),s.needsUpdate=!0),this.boundingBox!==null&&this.computeBoundingBox(),this.boundingSphere!==null&&this.computeBoundingSphere(),this._transformed=!0,this}applyQuaternion(e){return Yn.makeRotationFromQuaternion(e),this.applyMatrix4(Yn),this}rotateX(e){return Yn.makeRotationX(e),this.applyMatrix4(Yn),this}rotateY(e){return Yn.makeRotationY(e),this.applyMatrix4(Yn),this}rotateZ(e){return Yn.makeRotationZ(e),this.applyMatrix4(Yn),this}translate(e,t,n){return Yn.makeTranslation(e,t,n),this.applyMatrix4(Yn),this}scale(e,t,n){return Yn.makeScale(e,t,n),this.applyMatrix4(Yn),this}lookAt(e){return Nh.lookAt(e),Nh.updateMatrix(),this.applyMatrix4(Nh.matrix),this}center(){return this.computeBoundingBox(),this.boundingBox.getCenter(vr).negate(),this.translate(vr.x,vr.y,vr.z),this}setFromPoints(e){let t=this.getAttribute("position");if(t===void 0){let n=[];for(let s=0,r=e.length;s<r;s++){let o=e[s];n.push(o.x,o.y,o.z||0)}this.setAttribute("position",new lt(n,3))}else{let n=Math.min(e.length,t.count);for(let s=0;s<n;s++){let r=e[s];t.setXYZ(s,r.x,r.y,r.z||0)}e.length>t.count&&Fe("BufferGeometry: Buffer size too small for points data. Use .dispose() and create a new geometry."),t.needsUpdate=!0}return this}computeBoundingBox(){this.boundingBox===null&&(this.boundingBox=new Ke);let e=this.attributes.position,t=this.morphAttributes.position;if(e&&e.isGLBufferAttribute){We("BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.",this),this.boundingBox.set(new I(-1/0,-1/0,-1/0),new I(1/0,1/0,1/0));return}if(e!==void 0){if(this.boundingBox.setFromBufferAttribute(e),t)for(let n=0,s=t.length;n<s;n++){let r=t[n];On.setFromBufferAttribute(r),this.morphTargetsRelative?(rn.addVectors(this.boundingBox.min,On.min),this.boundingBox.expandByPoint(rn),rn.addVectors(this.boundingBox.max,On.max),this.boundingBox.expandByPoint(rn)):(this.boundingBox.expandByPoint(On.min),this.boundingBox.expandByPoint(On.max))}}else this.boundingBox.makeEmpty();(isNaN(this.boundingBox.min.x)||isNaN(this.boundingBox.min.y)||isNaN(this.boundingBox.min.z))&&We('BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.',this)}computeBoundingSphere(){this.boundingSphere===null&&(this.boundingSphere=new Cn);let e=this.attributes.position,t=this.morphAttributes.position;if(e&&e.isGLBufferAttribute){We("BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.",this),this.boundingSphere.set(new I,1/0);return}if(e){let n=this.boundingSphere.center;if(On.setFromBufferAttribute(e),t)for(let r=0,o=t.length;r<o;r++){let a=t[r];Do.setFromBufferAttribute(a),this.morphTargetsRelative?(rn.addVectors(On.min,Do.min),On.expandByPoint(rn),rn.addVectors(On.max,Do.max),On.expandByPoint(rn)):(On.expandByPoint(Do.min),On.expandByPoint(Do.max))}On.getCenter(n);let s=0;for(let r=0,o=e.count;r<o;r++)rn.fromBufferAttribute(e,r),s=Math.max(s,n.distanceToSquared(rn));if(t)for(let r=0,o=t.length;r<o;r++){let a=t[r],c=this.morphTargetsRelative;for(let l=0,u=a.count;l<u;l++)rn.fromBufferAttribute(a,l),c&&(vr.fromBufferAttribute(e,l),rn.add(vr)),s=Math.max(s,n.distanceToSquared(rn))}this.boundingSphere.radius=Math.sqrt(s),isNaN(this.boundingSphere.radius)&&We('BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.',this)}}computeTangents(){let e=this.index,t=this.attributes;if(e===null||t.position===void 0||t.normal===void 0||t.uv===void 0){We("BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)");return}let n=t.position,s=t.normal,r=t.uv,o=this.getAttribute("tangent");(o===void 0||o.count!==n.count)&&(o=new Tt(new Float32Array(4*n.count),4),this.setAttribute("tangent",o));let a=[],c=[];for(let y=0;y<n.count;y++)a[y]=new I,c[y]=new I;let l=new I,u=new I,h=new I,f=new ce,d=new ce,m=new ce,x=new I,g=new I;function p(y,w,A){l.fromBufferAttribute(n,y),u.fromBufferAttribute(n,w),h.fromBufferAttribute(n,A),f.fromBufferAttribute(r,y),d.fromBufferAttribute(r,w),m.fromBufferAttribute(r,A),u.sub(l),h.sub(l),d.sub(f),m.sub(f);let P=1/(d.x*m.y-m.x*d.y);isFinite(P)&&(x.copy(u).multiplyScalar(m.y).addScaledVector(h,-d.y).multiplyScalar(P),g.copy(h).multiplyScalar(d.x).addScaledVector(u,-m.x).multiplyScalar(P),a[y].add(x),a[w].add(x),a[A].add(x),c[y].add(g),c[w].add(g),c[A].add(g))}let v=this.groups;v.length===0&&(v=[{start:0,count:e.count}]);for(let y=0,w=v.length;y<w;++y){let A=v[y],P=A.start,C=A.count;for(let D=P,L=P+C;D<L;D+=3)p(e.getX(D+0),e.getX(D+1),e.getX(D+2))}let b=new I,_=new I,S=new I,M=new I;function E(y){S.fromBufferAttribute(s,y),M.copy(S);let w=a[y];b.copy(w),b.sub(S.multiplyScalar(S.dot(w))).normalize(),_.crossVectors(M,w);let P=_.dot(c[y])<0?-1:1;o.setXYZW(y,b.x,b.y,b.z,P)}for(let y=0,w=v.length;y<w;++y){let A=v[y],P=A.start,C=A.count;for(let D=P,L=P+C;D<L;D+=3)E(e.getX(D+0)),E(e.getX(D+1)),E(e.getX(D+2))}this._transformed=!0}computeVertexNormals(){let e=this.index,t=this.getAttribute("position");if(t!==void 0){let n=this.getAttribute("normal");if(n===void 0||n.count!==t.count)n=new Tt(new Float32Array(t.count*3),3),this.setAttribute("normal",n);else for(let f=0,d=n.count;f<d;f++)n.setXYZ(f,0,0,0);let s=new I,r=new I,o=new I,a=new I,c=new I,l=new I,u=new I,h=new I;if(e)for(let f=0,d=e.count;f<d;f+=3){let m=e.getX(f+0),x=e.getX(f+1),g=e.getX(f+2);s.fromBufferAttribute(t,m),r.fromBufferAttribute(t,x),o.fromBufferAttribute(t,g),u.subVectors(o,r),h.subVectors(s,r),u.cross(h),a.fromBufferAttribute(n,m),c.fromBufferAttribute(n,x),l.fromBufferAttribute(n,g),a.add(u),c.add(u),l.add(u),n.setXYZ(m,a.x,a.y,a.z),n.setXYZ(x,c.x,c.y,c.z),n.setXYZ(g,l.x,l.y,l.z)}else for(let f=0,d=t.count;f<d;f+=3)s.fromBufferAttribute(t,f+0),r.fromBufferAttribute(t,f+1),o.fromBufferAttribute(t,f+2),u.subVectors(o,r),h.subVectors(s,r),u.cross(h),n.setXYZ(f+0,u.x,u.y,u.z),n.setXYZ(f+1,u.x,u.y,u.z),n.setXYZ(f+2,u.x,u.y,u.z);this.normalizeNormals(),n.needsUpdate=!0}}normalizeNormals(){let e=this.attributes.normal;for(let t=0,n=e.count;t<n;t++)rn.fromBufferAttribute(e,t),rn.normalize(),e.setXYZ(t,rn.x,rn.y,rn.z)}toNonIndexed(){function e(a,c){let l=a.array,u=a.itemSize,h=a.normalized,f=new l.constructor(c.length*u),d=0,m=0;for(let x=0,g=c.length;x<g;x++){a.isInterleavedBufferAttribute?d=c[x]*a.data.stride+a.offset:d=c[x]*u;for(let p=0;p<u;p++)f[m++]=l[d++]}return new Tt(f,u,h)}if(this.index===null)return Fe("BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed."),this;let t=new i,n=this.index.array,s=this.attributes;for(let a in s){let c=s[a],l=e(c,n);t.setAttribute(a,l)}let r=this.morphAttributes;for(let a in r){let c=[],l=r[a];for(let u=0,h=l.length;u<h;u++){let f=l[u],d=e(f,n);c.push(d)}t.morphAttributes[a]=c}t.morphTargetsRelative=this.morphTargetsRelative;let o=this.groups;for(let a=0,c=o.length;a<c;a++){let l=o[a];t.addGroup(l.start,l.count,l.materialIndex)}return t}toJSON(){let e={metadata:{version:4.7,type:"BufferGeometry",generator:"BufferGeometry.toJSON"}};if(e.uuid=this.uuid,e.type=this.parameters!==void 0&&this._transformed===!0?"BufferGeometry":this.type,e.name=this.name,Object.keys(this.userData).length>0&&(e.userData=this.userData),this.parameters!==void 0&&this._transformed!==!0){let c=this.parameters;for(let l in c)c[l]!==void 0&&(e[l]=c[l]);return e}e.data={attributes:{}};let t=this.index;t!==null&&(e.data.index={type:t.array.constructor.name,array:Array.prototype.slice.call(t.array)});let n=this.attributes;for(let c in n){let l=n[c];e.data.attributes[c]=l.toJSON(e.data)}let s={},r=!1;for(let c in this.morphAttributes){let l=this.morphAttributes[c],u=[];for(let h=0,f=l.length;h<f;h++){let d=l[h];u.push(d.toJSON(e.data))}u.length>0&&(s[c]=u,r=!0)}r&&(e.data.morphAttributes=s,e.data.morphTargetsRelative=this.morphTargetsRelative);let o=this.groups;o.length>0&&(e.data.groups=JSON.parse(JSON.stringify(o)));let a=this.boundingSphere;return a!==null&&(e.data.boundingSphere=a.toJSON()),e}clone(){return new this.constructor().copy(this)}copy(e){this.index=null,this.attributes={},this.morphAttributes={},this.groups=[],this.boundingBox=null,this.boundingSphere=null;let t={};this.name=e.name;let n=e.index;n!==null&&this.setIndex(n.clone());let s=e.attributes;for(let l in s){let u=s[l];this.setAttribute(l,u.clone(t))}let r=e.morphAttributes;for(let l in r){let u=[],h=r[l];for(let f=0,d=h.length;f<d;f++)u.push(h[f].clone(t));this.morphAttributes[l]=u}this.morphTargetsRelative=e.morphTargetsRelative;let o=e.groups;for(let l=0,u=o.length;l<u;l++){let h=o[l];this.addGroup(h.start,h.count,h.materialIndex)}let a=e.boundingBox;a!==null&&(this.boundingBox=a.clone());let c=e.boundingSphere;return c!==null&&(this.boundingSphere=c.clone()),this.drawRange.start=e.drawRange.start,this.drawRange.count=e.drawRange.count,this.userData=e.userData,this._transformed=e._transformed,this}dispose(){this.dispatchEvent({type:"dispose"})}},zs=class{constructor(e,t){this.isInterleavedBuffer=!0,this.array=e,this.stride=t,this.count=e!==void 0?e.length/t:0,this.usage=Lf,this.updateRanges=[],this.version=0,this.uuid=Kn()}onUploadCallback(){}set needsUpdate(e){e===!0&&this.version++}setUsage(e){return this.usage=e,this}addUpdateRange(e,t){this.updateRanges.push({start:e,count:t})}clearUpdateRanges(){this.updateRanges.length=0}copy(e){return this.array=new e.array.constructor(e.array),this.count=e.count,this.stride=e.stride,this.usage=e.usage,this}copyAt(e,t,n){e*=this.stride,n*=t.stride;for(let s=0,r=this.stride;s<r;s++)this.array[e+s]=t.array[n+s];return this}set(e,t=0){return this.array.set(e,t),this}clone(e){e.arrayBuffers===void 0&&(e.arrayBuffers={}),this.array.buffer._uuid===void 0&&(this.array.buffer._uuid=Kn()),e.arrayBuffers[this.array.buffer._uuid]===void 0&&(e.arrayBuffers[this.array.buffer._uuid]=this.array.slice(0).buffer);let t=new this.array.constructor(e.arrayBuffers[this.array.buffer._uuid]),n=new this.constructor(t,this.stride);return n.setUsage(this.usage),n}onUpload(e){return this.onUploadCallback=e,this}toJSON(e){e.arrayBuffers===void 0&&(e.arrayBuffers={}),this.array.buffer._uuid===void 0&&(this.array.buffer._uuid=Kn()),e.arrayBuffers[this.array.buffer._uuid]===void 0&&(e.arrayBuffers[this.array.buffer._uuid]=Array.from(new Uint32Array(this.array.buffer)));let t={uuid:this.uuid,buffer:this.array.buffer._uuid,type:this.array.constructor.name,stride:this.stride};return t.usage=this.usage,t}},Sn=new I,ls=class i{constructor(e,t,n,s=!1){this.isInterleavedBufferAttribute=!0,this.name="",this.data=e,this.itemSize=t,this.offset=n,this.normalized=s}get count(){return this.data.count}get array(){return this.data.array}set needsUpdate(e){this.data.needsUpdate=e}applyMatrix4(e){for(let t=0,n=this.data.count;t<n;t++)Sn.fromBufferAttribute(this,t),Sn.applyMatrix4(e),this.setXYZ(t,Sn.x,Sn.y,Sn.z);return this}applyNormalMatrix(e){for(let t=0,n=this.count;t<n;t++)Sn.fromBufferAttribute(this,t),Sn.applyNormalMatrix(e),this.setXYZ(t,Sn.x,Sn.y,Sn.z);return this}transformDirection(e){for(let t=0,n=this.count;t<n;t++)Sn.fromBufferAttribute(this,t),Sn.transformDirection(e),this.setXYZ(t,Sn.x,Sn.y,Sn.z);return this}getComponent(e,t){let n=this.array[e*this.data.stride+this.offset+t];return this.normalized&&(n=ii(n,this.array)),n}setComponent(e,t,n){return this.normalized&&(n=St(n,this.array)),this.data.array[e*this.data.stride+this.offset+t]=n,this}setX(e,t){return this.normalized&&(t=St(t,this.array)),this.data.array[e*this.data.stride+this.offset]=t,this}setY(e,t){return this.normalized&&(t=St(t,this.array)),this.data.array[e*this.data.stride+this.offset+1]=t,this}setZ(e,t){return this.normalized&&(t=St(t,this.array)),this.data.array[e*this.data.stride+this.offset+2]=t,this}setW(e,t){return this.normalized&&(t=St(t,this.array)),this.data.array[e*this.data.stride+this.offset+3]=t,this}getX(e){let t=this.data.array[e*this.data.stride+this.offset];return this.normalized&&(t=ii(t,this.array)),t}getY(e){let t=this.data.array[e*this.data.stride+this.offset+1];return this.normalized&&(t=ii(t,this.array)),t}getZ(e){let t=this.data.array[e*this.data.stride+this.offset+2];return this.normalized&&(t=ii(t,this.array)),t}getW(e){let t=this.data.array[e*this.data.stride+this.offset+3];return this.normalized&&(t=ii(t,this.array)),t}setXY(e,t,n){return e=e*this.data.stride+this.offset,this.normalized&&(t=St(t,this.array),n=St(n,this.array)),this.data.array[e+0]=t,this.data.array[e+1]=n,this}setXYZ(e,t,n,s){return e=e*this.data.stride+this.offset,this.normalized&&(t=St(t,this.array),n=St(n,this.array),s=St(s,this.array)),this.data.array[e+0]=t,this.data.array[e+1]=n,this.data.array[e+2]=s,this}setXYZW(e,t,n,s,r){return e=e*this.data.stride+this.offset,this.normalized&&(t=St(t,this.array),n=St(n,this.array),s=St(s,this.array),r=St(r,this.array)),this.data.array[e+0]=t,this.data.array[e+1]=n,this.data.array[e+2]=s,this.data.array[e+3]=r,this}clone(e){if(e===void 0){Zo("InterleavedBufferAttribute.clone(): Cloning an interleaved buffer attribute will de-interleave buffer data.");let t=[];for(let n=0;n<this.count;n++){let s=n*this.data.stride+this.offset;for(let r=0;r<this.itemSize;r++)t.push(this.data.array[s+r])}return new Tt(new this.array.constructor(t),this.itemSize,this.normalized)}else return e.interleavedBuffers===void 0&&(e.interleavedBuffers={}),e.interleavedBuffers[this.data.uuid]===void 0&&(e.interleavedBuffers[this.data.uuid]=this.data.clone(e)),new i(e.interleavedBuffers[this.data.uuid],this.itemSize,this.offset,this.normalized)}toJSON(e){if(e===void 0){Zo("InterleavedBufferAttribute.toJSON(): Serializing an interleaved buffer attribute will de-interleave buffer data.");let t=[];for(let n=0;n<this.count;n++){let s=n*this.data.stride+this.offset;for(let r=0;r<this.itemSize;r++)t.push(this.data.array[s+r])}return{itemSize:this.itemSize,type:this.array.constructor.name,array:t,normalized:this.normalized}}else return e.interleavedBuffers===void 0&&(e.interleavedBuffers={}),e.interleavedBuffers[this.data.uuid]===void 0&&(e.interleavedBuffers[this.data.uuid]=this.data.toJSON(e)),{isInterleavedBufferAttribute:!0,itemSize:this.itemSize,data:this.data.uuid,offset:this.offset,normalized:this.normalized}}},Dh=new I,m_=new I,g_=new Ye,an=class{constructor(e=new I(1,0,0),t=0){this.isPlane=!0,this.normal=e,this.constant=t}set(e,t){return this.normal.copy(e),this.constant=t,this}setComponents(e,t,n,s){return this.normal.set(e,t,n),this.constant=s,this}setFromNormalAndCoplanarPoint(e,t){return this.normal.copy(e),this.constant=-t.dot(this.normal),this}setFromCoplanarPoints(e,t,n){let s=Dh.subVectors(n,t).cross(m_.subVectors(e,t)).normalize();return this.setFromNormalAndCoplanarPoint(s,e),this}copy(e){return this.normal.copy(e.normal),this.constant=e.constant,this}normalize(){let e=1/this.normal.length();return this.normal.multiplyScalar(e),this.constant*=e,this}negate(){return this.constant*=-1,this.normal.negate(),this}distanceToPoint(e){return this.normal.dot(e)+this.constant}distanceToSphere(e){return this.distanceToPoint(e.center)-e.radius}projectPoint(e,t){return t.copy(e).addScaledVector(this.normal,-this.distanceToPoint(e))}intersectLine(e,t,n=!0){let s=e.delta(Dh),r=this.normal.dot(s);if(r===0)return this.distanceToPoint(e.start)===0?t.copy(e.start):null;let o=-(e.start.dot(this.normal)+this.constant)/r;return n===!0&&(o<0||o>1)?null:t.copy(e.start).addScaledVector(s,o)}intersectsLine(e){let t=this.distanceToPoint(e.start),n=this.distanceToPoint(e.end);return t<0&&n>0||n<0&&t>0}intersectsBox(e){return e.intersectsPlane(this)}intersectsSphere(e){return e.intersectsPlane(this)}coplanarPoint(e){return e.copy(this.normal).multiplyScalar(-this.constant)}applyMatrix4(e,t){let n=t||g_.getNormalMatrix(e),s=this.coplanarPoint(Dh).applyMatrix4(e),r=this.normal.applyMatrix3(n).normalize();return this.constant=-s.dot(r),this}translate(e){return this.constant-=e.dot(this.normal),this}equals(e){return e.normal.equals(this.normal)&&e.constant===this.constant}clone(){return new this.constructor().copy(this)}toJSON(){return{normal:this.normal.toArray(),constant:this.constant}}fromJSON(e){return this.normal.fromArray(e.normal),this.constant=e.constant,this}},x_=0,Mn=class extends ri{constructor(){super(),this.isMaterial=!0,Object.defineProperty(this,"id",{value:x_++}),this.uuid=Kn(),this.name="",this.type="Material",this.blending=jr,this.side=kn,this.vertexColors=!1,this.opacity=1,this.transparent=!1,this.alphaHash=!1,this.blendSrc=mf,this.blendDst=gf,this.blendEquation=qs,this.blendSrcAlpha=null,this.blendDstAlpha=null,this.blendEquationAlpha=null,this.blendColor=new Ve(0,0,0),this.blendAlpha=0,this.depthFunc=Lr,this.depthTest=!0,this.depthWrite=!0,this.stencilWriteMask=255,this.stencilFunc=cg,this.stencilRef=0,this.stencilFuncMask=255,this.stencilFail=Xc,this.stencilZFail=Xc,this.stencilZPass=Xc,this.stencilWrite=!1,this.clippingPlanes=null,this.clipIntersection=!1,this.clipShadows=!1,this.shadowSide=null,this.colorWrite=!0,this.precision=null,this.polygonOffset=!1,this.polygonOffsetFactor=0,this.polygonOffsetUnits=0,this.dithering=!1,this.alphaToCoverage=!1,this.premultipliedAlpha=!1,this.forceSinglePass=!1,this.allowOverride=!0,this.visible=!0,this.toneMapped=!0,this.userData={},this.version=0,this._alphaTest=0}get alphaTest(){return this._alphaTest}set alphaTest(e){this._alphaTest>0!=e>0&&this.version++,this._alphaTest=e}onBeforeRender(){}onBeforeCompile(){}customProgramCacheKey(){return this.onBeforeCompile.toString()}setValues(e){if(e!==void 0)for(let t in e){let n=e[t];if(n===void 0){Fe(`Material: parameter '${t}' has value of undefined.`);continue}let s=this[t];if(s===void 0){Fe(`Material: '${t}' is not a property of THREE.${this.type}.`);continue}s&&s.isColor?s.set(n):s&&s.isVector2&&n&&n.isVector2||s&&s.isEuler&&n&&n.isEuler||s&&s.isVector3&&n&&n.isVector3?s.copy(n):this[t]=n}}toJSON(e){let t=e===void 0||typeof e=="string";t&&(e={textures:{},images:{}});let n={metadata:{version:4.7,type:"Material",generator:"Material.toJSON"}};n.uuid=this.uuid,n.type=this.type,n.blending=this.blending,n.side=this.side,n.shadowSide=this.shadowSide,n.vertexColors=this.vertexColors,n.opacity=this.opacity,n.transparent=this.transparent,n.blendSrc=this.blendSrc,n.blendDst=this.blendDst,n.blendEquation=this.blendEquation,n.blendSrcAlpha=this.blendSrcAlpha,n.blendDstAlpha=this.blendDstAlpha,n.blendEquationAlpha=this.blendEquationAlpha,n.blendColor=this.blendColor.getHex(),n.blendAlpha=this.blendAlpha,n.depthFunc=this.depthFunc,n.depthTest=this.depthTest,n.depthWrite=this.depthWrite,n.colorWrite=this.colorWrite,n.clipIntersection=this.clipIntersection,n.clipShadows=this.clipShadows,n.stencilWriteMask=this.stencilWriteMask,n.stencilFunc=this.stencilFunc,n.stencilRef=this.stencilRef,n.stencilFuncMask=this.stencilFuncMask,n.stencilFail=this.stencilFail,n.stencilZFail=this.stencilZFail,n.stencilZPass=this.stencilZPass,n.stencilWrite=this.stencilWrite,n.polygonOffset=this.polygonOffset,n.polygonOffsetFactor=this.polygonOffsetFactor,n.polygonOffsetUnits=this.polygonOffsetUnits,n.dithering=this.dithering,n.alphaTest=this.alphaTest,n.alphaHash=this.alphaHash,n.alphaToCoverage=this.alphaToCoverage,n.premultipliedAlpha=this.premultipliedAlpha,n.forceSinglePass=this.forceSinglePass,n.allowOverride=this.allowOverride,n.visible=this.visible,n.toneMapped=this.toneMapped,n.name=this.name,this.color&&this.color.isColor&&(n.color=this.color.getHex()),this.roughness!==void 0&&(n.roughness=this.roughness),this.metalness!==void 0&&(n.metalness=this.metalness),this.sheen!==void 0&&(n.sheen=this.sheen),this.sheenColor&&this.sheenColor.isColor&&(n.sheenColor=this.sheenColor.getHex()),this.sheenRoughness!==void 0&&(n.sheenRoughness=this.sheenRoughness),this.emissive&&this.emissive.isColor&&(n.emissive=this.emissive.getHex()),this.emissiveIntensity!==void 0&&(n.emissiveIntensity=this.emissiveIntensity),this.specular&&this.specular.isColor&&(n.specular=this.specular.getHex()),this.specularIntensity!==void 0&&(n.specularIntensity=this.specularIntensity),this.specularColor&&this.specularColor.isColor&&(n.specularColor=this.specularColor.getHex()),this.shininess!==void 0&&(n.shininess=this.shininess),this.clearcoat!==void 0&&(n.clearcoat=this.clearcoat),this.clearcoatRoughness!==void 0&&(n.clearcoatRoughness=this.clearcoatRoughness),this.clearcoatMap&&this.clearcoatMap.isTexture&&(n.clearcoatMap=this.clearcoatMap.toJSON(e).uuid),this.clearcoatRoughnessMap&&this.clearcoatRoughnessMap.isTexture&&(n.clearcoatRoughnessMap=this.clearcoatRoughnessMap.toJSON(e).uuid),this.clearcoatNormalMap&&this.clearcoatNormalMap.isTexture&&(n.clearcoatNormalMap=this.clearcoatNormalMap.toJSON(e).uuid,n.clearcoatNormalScale=this.clearcoatNormalScale.toArray()),this.sheenColorMap&&this.sheenColorMap.isTexture&&(n.sheenColorMap=this.sheenColorMap.toJSON(e).uuid),this.sheenRoughnessMap&&this.sheenRoughnessMap.isTexture&&(n.sheenRoughnessMap=this.sheenRoughnessMap.toJSON(e).uuid),this.dispersion!==void 0&&(n.dispersion=this.dispersion),this.retroreflectivity!==void 0&&(n.retroreflectivity=this.retroreflectivity),this.iridescence!==void 0&&(n.iridescence=this.iridescence),this.iridescenceIOR!==void 0&&(n.iridescenceIOR=this.iridescenceIOR),this.iridescenceThicknessRange!==void 0&&(n.iridescenceThicknessRange=this.iridescenceThicknessRange),this.iridescenceMap&&this.iridescenceMap.isTexture&&(n.iridescenceMap=this.iridescenceMap.toJSON(e).uuid),this.iridescenceThicknessMap&&this.iridescenceThicknessMap.isTexture&&(n.iridescenceThicknessMap=this.iridescenceThicknessMap.toJSON(e).uuid),this.anisotropy!==void 0&&(n.anisotropy=this.anisotropy),this.anisotropyRotation!==void 0&&(n.anisotropyRotation=this.anisotropyRotation),this.anisotropyMap&&this.anisotropyMap.isTexture&&(n.anisotropyMap=this.anisotropyMap.toJSON(e).uuid),this.map&&this.map.isTexture&&(n.map=this.map.toJSON(e).uuid),this.matcap&&this.matcap.isTexture&&(n.matcap=this.matcap.toJSON(e).uuid),this.alphaMap&&this.alphaMap.isTexture&&(n.alphaMap=this.alphaMap.toJSON(e).uuid),this.lightMap&&this.lightMap.isTexture&&(n.lightMap=this.lightMap.toJSON(e).uuid,n.lightMapIntensity=this.lightMapIntensity),this.aoMap&&this.aoMap.isTexture&&(n.aoMap=this.aoMap.toJSON(e).uuid,n.aoMapIntensity=this.aoMapIntensity),this.bumpMap&&this.bumpMap.isTexture&&(n.bumpMap=this.bumpMap.toJSON(e).uuid,n.bumpScale=this.bumpScale),this.normalMap&&this.normalMap.isTexture&&(n.normalMap=this.normalMap.toJSON(e).uuid,n.normalMapType=this.normalMapType,n.normalScale=this.normalScale.toArray()),this.displacementMap&&this.displacementMap.isTexture&&(n.displacementMap=this.displacementMap.toJSON(e).uuid,n.displacementScale=this.displacementScale,n.displacementBias=this.displacementBias),this.roughnessMap&&this.roughnessMap.isTexture&&(n.roughnessMap=this.roughnessMap.toJSON(e).uuid),this.metalnessMap&&this.metalnessMap.isTexture&&(n.metalnessMap=this.metalnessMap.toJSON(e).uuid),this.emissiveMap&&this.emissiveMap.isTexture&&(n.emissiveMap=this.emissiveMap.toJSON(e).uuid),this.specularMap&&this.specularMap.isTexture&&(n.specularMap=this.specularMap.toJSON(e).uuid),this.specularIntensityMap&&this.specularIntensityMap.isTexture&&(n.specularIntensityMap=this.specularIntensityMap.toJSON(e).uuid),this.specularColorMap&&this.specularColorMap.isTexture&&(n.specularColorMap=this.specularColorMap.toJSON(e).uuid),this.envMap&&this.envMap.isTexture&&(n.envMap=this.envMap.toJSON(e).uuid,this.combine!==void 0&&(n.combine=this.combine)),this.envMapRotation!==void 0&&(n.envMapRotation=this.envMapRotation.toArray()),this.envMapIntensity!==void 0&&(n.envMapIntensity=this.envMapIntensity),this.reflectivity!==void 0&&(n.reflectivity=this.reflectivity),this.refractionRatio!==void 0&&(n.refractionRatio=this.refractionRatio),this.gradientMap&&this.gradientMap.isTexture&&(n.gradientMap=this.gradientMap.toJSON(e).uuid),this.transmission!==void 0&&(n.transmission=this.transmission),this.transmissionMap&&this.transmissionMap.isTexture&&(n.transmissionMap=this.transmissionMap.toJSON(e).uuid),this.thickness!==void 0&&(n.thickness=this.thickness),this.thicknessMap&&this.thicknessMap.isTexture&&(n.thicknessMap=this.thicknessMap.toJSON(e).uuid),this.attenuationDistance!==void 0&&(n.attenuationDistance=this.attenuationDistance),this.attenuationColor!==void 0&&(n.attenuationColor=this.attenuationColor.getHex()),this.size!==void 0&&(n.size=this.size),this.sizeAttenuation!==void 0&&(n.sizeAttenuation=this.sizeAttenuation),Array.isArray(this.clippingPlanes)&&this.clippingPlanes.length>0&&(n.clippingPlanes=this.clippingPlanes.map(r=>r.toJSON())),this.rotation!==void 0&&(n.rotation=this.rotation),this.depthPacking!==void 0&&(n.depthPacking=this.depthPacking),this.linewidth!==void 0&&(n.linewidth=this.linewidth),this.linecap!==void 0&&(n.linecap=this.linecap),this.linejoin!==void 0&&(n.linejoin=this.linejoin),this.dashSize!==void 0&&(n.dashSize=this.dashSize),this.gapSize!==void 0&&(n.gapSize=this.gapSize),this.scale!==void 0&&(n.scale=this.scale),this.wireframe!==void 0&&(n.wireframe=this.wireframe),this.wireframeLinewidth!==void 0&&(n.wireframeLinewidth=this.wireframeLinewidth),this.wireframeLinecap!==void 0&&(n.wireframeLinecap=this.wireframeLinecap),this.wireframeLinejoin!==void 0&&(n.wireframeLinejoin=this.wireframeLinejoin),this.flatShading!==void 0&&(n.flatShading=this.flatShading),this.fog!==void 0&&(n.fog=this.fog),Object.keys(this.userData).length>0&&(n.userData=this.userData);function s(r){let o=[];for(let a in r){let c=r[a];delete c.metadata,o.push(c)}return o}if(t){let r=s(e.textures),o=s(e.images);r.length>0&&(n.textures=r),o.length>0&&(n.images=o)}return n}fromJSON(e,t){if(e.uuid!==void 0&&(this.uuid=e.uuid),e.name!==void 0&&(this.name=e.name),e.color!==void 0&&this.color!==void 0&&this.color.setHex(e.color),e.roughness!==void 0&&(this.roughness=e.roughness),e.metalness!==void 0&&(this.metalness=e.metalness),e.sheen!==void 0&&(this.sheen=e.sheen),e.sheenColor!==void 0&&(this.sheenColor=new Ve().setHex(e.sheenColor)),e.sheenRoughness!==void 0&&(this.sheenRoughness=e.sheenRoughness),e.emissive!==void 0&&this.emissive!==void 0&&this.emissive.setHex(e.emissive),e.specular!==void 0&&this.specular!==void 0&&this.specular.setHex(e.specular),e.specularIntensity!==void 0&&(this.specularIntensity=e.specularIntensity),e.specularColor!==void 0&&this.specularColor!==void 0&&this.specularColor.setHex(e.specularColor),e.shininess!==void 0&&(this.shininess=e.shininess),e.clearcoat!==void 0&&(this.clearcoat=e.clearcoat),e.clearcoatRoughness!==void 0&&(this.clearcoatRoughness=e.clearcoatRoughness),e.dispersion!==void 0&&(this.dispersion=e.dispersion),e.retroreflectivity!==void 0&&(this.retroreflectivity=e.retroreflectivity),e.iridescence!==void 0&&(this.iridescence=e.iridescence),e.iridescenceIOR!==void 0&&(this.iridescenceIOR=e.iridescenceIOR),e.iridescenceThicknessRange!==void 0&&(this.iridescenceThicknessRange=e.iridescenceThicknessRange),e.transmission!==void 0&&(this.transmission=e.transmission),e.thickness!==void 0&&(this.thickness=e.thickness),e.attenuationDistance!==void 0&&(this.attenuationDistance=e.attenuationDistance),e.attenuationColor!==void 0&&this.attenuationColor!==void 0&&this.attenuationColor.setHex(e.attenuationColor),e.anisotropy!==void 0&&(this.anisotropy=e.anisotropy),e.anisotropyRotation!==void 0&&(this.anisotropyRotation=e.anisotropyRotation),e.fog!==void 0&&(this.fog=e.fog),e.flatShading!==void 0&&(this.flatShading=e.flatShading),e.blending!==void 0&&(this.blending=e.blending),e.combine!==void 0&&(this.combine=e.combine),e.side!==void 0&&(this.side=e.side),e.shadowSide!==void 0&&(this.shadowSide=e.shadowSide),e.opacity!==void 0&&(this.opacity=e.opacity),e.transparent!==void 0&&(this.transparent=e.transparent),e.alphaTest!==void 0&&(this.alphaTest=e.alphaTest),e.alphaHash!==void 0&&(this.alphaHash=e.alphaHash),e.depthFunc!==void 0&&(this.depthFunc=e.depthFunc),e.depthTest!==void 0&&(this.depthTest=e.depthTest),e.depthWrite!==void 0&&(this.depthWrite=e.depthWrite),e.colorWrite!==void 0&&(this.colorWrite=e.colorWrite),e.clippingPlanes!==void 0&&(this.clippingPlanes=e.clippingPlanes.map(n=>new an().fromJSON(n))),e.clipIntersection!==void 0&&(this.clipIntersection=e.clipIntersection),e.clipShadows!==void 0&&(this.clipShadows=e.clipShadows),e.depthPacking!==void 0&&(this.depthPacking=e.depthPacking),e.blendSrc!==void 0&&(this.blendSrc=e.blendSrc),e.blendDst!==void 0&&(this.blendDst=e.blendDst),e.blendEquation!==void 0&&(this.blendEquation=e.blendEquation),e.blendSrcAlpha!==void 0&&(this.blendSrcAlpha=e.blendSrcAlpha),e.blendDstAlpha!==void 0&&(this.blendDstAlpha=e.blendDstAlpha),e.blendEquationAlpha!==void 0&&(this.blendEquationAlpha=e.blendEquationAlpha),e.blendColor!==void 0&&this.blendColor!==void 0&&this.blendColor.setHex(e.blendColor),e.blendAlpha!==void 0&&(this.blendAlpha=e.blendAlpha),e.stencilWriteMask!==void 0&&(this.stencilWriteMask=e.stencilWriteMask),e.stencilFunc!==void 0&&(this.stencilFunc=e.stencilFunc),e.stencilRef!==void 0&&(this.stencilRef=e.stencilRef),e.stencilFuncMask!==void 0&&(this.stencilFuncMask=e.stencilFuncMask),e.stencilFail!==void 0&&(this.stencilFail=e.stencilFail),e.stencilZFail!==void 0&&(this.stencilZFail=e.stencilZFail),e.stencilZPass!==void 0&&(this.stencilZPass=e.stencilZPass),e.stencilWrite!==void 0&&(this.stencilWrite=e.stencilWrite),e.wireframe!==void 0&&(this.wireframe=e.wireframe),e.wireframeLinewidth!==void 0&&(this.wireframeLinewidth=e.wireframeLinewidth),e.wireframeLinecap!==void 0&&(this.wireframeLinecap=e.wireframeLinecap),e.wireframeLinejoin!==void 0&&(this.wireframeLinejoin=e.wireframeLinejoin),e.rotation!==void 0&&(this.rotation=e.rotation),e.linewidth!==void 0&&(this.linewidth=e.linewidth),e.linecap!==void 0&&(this.linecap=e.linecap),e.linejoin!==void 0&&(this.linejoin=e.linejoin),e.dashSize!==void 0&&(this.dashSize=e.dashSize),e.gapSize!==void 0&&(this.gapSize=e.gapSize),e.scale!==void 0&&(this.scale=e.scale),e.polygonOffset!==void 0&&(this.polygonOffset=e.polygonOffset),e.polygonOffsetFactor!==void 0&&(this.polygonOffsetFactor=e.polygonOffsetFactor),e.polygonOffsetUnits!==void 0&&(this.polygonOffsetUnits=e.polygonOffsetUnits),e.dithering!==void 0&&(this.dithering=e.dithering),e.alphaToCoverage!==void 0&&(this.alphaToCoverage=e.alphaToCoverage),e.premultipliedAlpha!==void 0&&(this.premultipliedAlpha=e.premultipliedAlpha),e.forceSinglePass!==void 0&&(this.forceSinglePass=e.forceSinglePass),e.allowOverride!==void 0&&(this.allowOverride=e.allowOverride),e.visible!==void 0&&(this.visible=e.visible),e.toneMapped!==void 0&&(this.toneMapped=e.toneMapped),e.userData!==void 0&&(this.userData=e.userData),e.vertexColors!==void 0&&(typeof e.vertexColors=="number"?this.vertexColors=e.vertexColors>0:this.vertexColors=e.vertexColors),e.size!==void 0&&(this.size=e.size),e.sizeAttenuation!==void 0&&(this.sizeAttenuation=e.sizeAttenuation),e.map!==void 0&&(this.map=t[e.map]||null),e.matcap!==void 0&&(this.matcap=t[e.matcap]||null),e.alphaMap!==void 0&&(this.alphaMap=t[e.alphaMap]||null),e.bumpMap!==void 0&&(this.bumpMap=t[e.bumpMap]||null),e.bumpScale!==void 0&&(this.bumpScale=e.bumpScale),e.normalMap!==void 0&&(this.normalMap=t[e.normalMap]||null),e.normalMapType!==void 0&&(this.normalMapType=e.normalMapType),e.normalScale!==void 0){let n=e.normalScale;Array.isArray(n)===!1&&(n=[n,n]),this.normalScale=new ce().fromArray(n)}return e.displacementMap!==void 0&&(this.displacementMap=t[e.displacementMap]||null),e.displacementScale!==void 0&&(this.displacementScale=e.displacementScale),e.displacementBias!==void 0&&(this.displacementBias=e.displacementBias),e.roughnessMap!==void 0&&(this.roughnessMap=t[e.roughnessMap]||null),e.metalnessMap!==void 0&&(this.metalnessMap=t[e.metalnessMap]||null),e.emissiveMap!==void 0&&(this.emissiveMap=t[e.emissiveMap]||null),e.emissiveIntensity!==void 0&&(this.emissiveIntensity=e.emissiveIntensity),e.specularMap!==void 0&&(this.specularMap=t[e.specularMap]||null),e.specularIntensityMap!==void 0&&(this.specularIntensityMap=t[e.specularIntensityMap]||null),e.specularColorMap!==void 0&&(this.specularColorMap=t[e.specularColorMap]||null),e.envMap!==void 0&&(this.envMap=t[e.envMap]||null),e.envMapRotation!==void 0&&this.envMapRotation.fromArray(e.envMapRotation),e.envMapIntensity!==void 0&&(this.envMapIntensity=e.envMapIntensity),e.reflectivity!==void 0&&(this.reflectivity=e.reflectivity),e.refractionRatio!==void 0&&(this.refractionRatio=e.refractionRatio),e.lightMap!==void 0&&(this.lightMap=t[e.lightMap]||null),e.lightMapIntensity!==void 0&&(this.lightMapIntensity=e.lightMapIntensity),e.aoMap!==void 0&&(this.aoMap=t[e.aoMap]||null),e.aoMapIntensity!==void 0&&(this.aoMapIntensity=e.aoMapIntensity),e.gradientMap!==void 0&&(this.gradientMap=t[e.gradientMap]||null),e.clearcoatMap!==void 0&&(this.clearcoatMap=t[e.clearcoatMap]||null),e.clearcoatRoughnessMap!==void 0&&(this.clearcoatRoughnessMap=t[e.clearcoatRoughnessMap]||null),e.clearcoatNormalMap!==void 0&&(this.clearcoatNormalMap=t[e.clearcoatNormalMap]||null),e.clearcoatNormalScale!==void 0&&(this.clearcoatNormalScale=new ce().fromArray(e.clearcoatNormalScale)),e.iridescenceMap!==void 0&&(this.iridescenceMap=t[e.iridescenceMap]||null),e.iridescenceThicknessMap!==void 0&&(this.iridescenceThicknessMap=t[e.iridescenceThicknessMap]||null),e.transmissionMap!==void 0&&(this.transmissionMap=t[e.transmissionMap]||null),e.thicknessMap!==void 0&&(this.thicknessMap=t[e.thicknessMap]||null),e.anisotropyMap!==void 0&&(this.anisotropyMap=t[e.anisotropyMap]||null),e.sheenColorMap!==void 0&&(this.sheenColorMap=t[e.sheenColorMap]||null),e.sheenRoughnessMap!==void 0&&(this.sheenRoughnessMap=t[e.sheenRoughnessMap]||null),this}clone(){return new this.constructor().copy(this)}copy(e){this.name=e.name,this.blending=e.blending,this.side=e.side,this.vertexColors=e.vertexColors,this.opacity=e.opacity,this.transparent=e.transparent,this.blendSrc=e.blendSrc,this.blendDst=e.blendDst,this.blendEquation=e.blendEquation,this.blendSrcAlpha=e.blendSrcAlpha,this.blendDstAlpha=e.blendDstAlpha,this.blendEquationAlpha=e.blendEquationAlpha,this.blendColor.copy(e.blendColor),this.blendAlpha=e.blendAlpha,this.depthFunc=e.depthFunc,this.depthTest=e.depthTest,this.depthWrite=e.depthWrite,this.stencilWriteMask=e.stencilWriteMask,this.stencilFunc=e.stencilFunc,this.stencilRef=e.stencilRef,this.stencilFuncMask=e.stencilFuncMask,this.stencilFail=e.stencilFail,this.stencilZFail=e.stencilZFail,this.stencilZPass=e.stencilZPass,this.stencilWrite=e.stencilWrite;let t=e.clippingPlanes,n=null;if(t!==null){let s=t.length;n=new Array(s);for(let r=0;r!==s;++r)n[r]=t[r].clone()}return this.clippingPlanes=n,this.clipIntersection=e.clipIntersection,this.clipShadows=e.clipShadows,this.shadowSide=e.shadowSide,this.colorWrite=e.colorWrite,this.precision=e.precision,this.polygonOffset=e.polygonOffset,this.polygonOffsetFactor=e.polygonOffsetFactor,this.polygonOffsetUnits=e.polygonOffsetUnits,this.dithering=e.dithering,this.alphaTest=e.alphaTest,this.alphaHash=e.alphaHash,this.alphaToCoverage=e.alphaToCoverage,this.premultipliedAlpha=e.premultipliedAlpha,this.forceSinglePass=e.forceSinglePass,this.allowOverride=e.allowOverride,this.visible=e.visible,this.toneMapped=e.toneMapped,this.userData=JSON.parse(JSON.stringify(e.userData)),this}dispose(){this.dispatchEvent({type:"dispose"})}set needsUpdate(e){e===!0&&this.version++}},kr=class extends Mn{constructor(e){super(),this.isSpriteMaterial=!0,this.type="SpriteMaterial",this.color=new Ve(16777215),this.map=null,this.alphaMap=null,this.rotation=0,this.sizeAttenuation=!0,this.transparent=!0,this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.color.copy(e.color),this.map=e.map,this.alphaMap=e.alphaMap,this.rotation=e.rotation,this.sizeAttenuation=e.sizeAttenuation,this.fog=e.fog,this}},Sr,Uo=new I,br=new I,Mr=new I,Tr=new ce,Fo=new ce,vg=new Ie,vc=new I,Oo=new I,Sc=new I,tm=new ce,Uh=new ce,nm=new ce,Qo=class extends Nt{constructor(e=new kr){if(super(),this.isSprite=!0,this.type="Sprite",Sr===void 0){Sr=new ht;let t=new Float32Array([-.5,-.5,0,0,0,.5,-.5,0,1,0,.5,.5,0,1,1,-.5,.5,0,0,1]),n=new zs(t,5);Sr.setIndex([0,1,2,0,2,3]),Sr.setAttribute("position",new ls(n,3,0,!1)),Sr.setAttribute("uv",new ls(n,2,3,!1))}this.geometry=Sr,this.material=e,this.center=new ce(.5,.5),this.count=1}intersectsFrustum(e){return e.intersectsSprite(this)}raycast(e,t){e.camera===null&&We('Sprite: "Raycaster.camera" needs to be set in order to raycast against sprites.'),br.setFromMatrixScale(this.matrixWorld),vg.copy(e.camera.matrixWorld),this.modelViewMatrix.multiplyMatrices(e.camera.matrixWorldInverse,this.matrixWorld),Mr.setFromMatrixPosition(this.modelViewMatrix),e.camera.isPerspectiveCamera&&this.material.sizeAttenuation===!1&&br.multiplyScalar(-Mr.z);let n=this.material.rotation,s,r;n!==0&&(r=Math.cos(n),s=Math.sin(n));let o=this.center;bc(vc.set(-.5,-.5,0),Mr,o,br,s,r),bc(Oo.set(.5,-.5,0),Mr,o,br,s,r),bc(Sc.set(.5,.5,0),Mr,o,br,s,r),tm.set(0,0),Uh.set(1,0),nm.set(1,1);let a=e.ray.intersectTriangle(vc,Oo,Sc,!1,Uo);if(a===null&&(bc(Oo.set(-.5,.5,0),Mr,o,br,s,r),Uh.set(0,1),a=e.ray.intersectTriangle(vc,Sc,Oo,!1,Uo),a===null))return;let c=e.ray.origin.distanceTo(Uo);c<e.near||c>e.far||t.push({distance:c,point:Uo.clone(),uv:cn.getInterpolation(Uo,vc,Oo,Sc,tm,Uh,nm,new ce),face:null,object:this})}copy(e,t){return super.copy(e,t),e.center!==void 0&&this.center.copy(e.center),this.material=e.material,this}};function bc(i,e,t,n,s,r){Tr.subVectors(i,t).addScalar(.5).multiply(n),s!==void 0?(Fo.x=r*Tr.x-s*Tr.y,Fo.y=s*Tr.x+r*Tr.y):Fo.copy(Tr),i.copy(e),i.x+=Fo.x,i.y+=Fo.y,i.applyMatrix4(vg)}var Di=new I,Fh=new I,Mc=new I,Tc=new I,Pn=class{constructor(e=new I,t=new I(0,0,-1)){this.origin=e,this.direction=t}set(e,t){return this.origin.copy(e),this.direction.copy(t),this}copy(e){return this.origin.copy(e.origin),this.direction.copy(e.direction),this}at(e,t){return t.copy(this.origin).addScaledVector(this.direction,e)}lookAt(e){return this.direction.copy(e).sub(this.origin).normalize(),this}recast(e){return this.origin.copy(this.at(e,Di)),this}closestPointToPoint(e,t){t.subVectors(e,this.origin);let n=t.dot(this.direction);return n<0?t.copy(this.origin):t.copy(this.origin).addScaledVector(this.direction,n)}distanceToPoint(e){return Math.sqrt(this.distanceSqToPoint(e))}distanceSqToPoint(e){let t=Di.subVectors(e,this.origin).dot(this.direction);return t<0?this.origin.distanceToSquared(e):(Di.copy(this.origin).addScaledVector(this.direction,t),Di.distanceToSquared(e))}distanceSqToSegment(e,t,n,s){Fh.copy(e).add(t).multiplyScalar(.5),Mc.copy(t).sub(e).normalize(),Tc.copy(this.origin).sub(Fh);let r=e.distanceTo(t)*.5,o=-this.direction.dot(Mc),a=Tc.dot(this.direction),c=-Tc.dot(Mc),l=Tc.lengthSq(),u=Math.abs(1-o*o),h,f,d,m;if(u>0)if(h=o*c-a,f=o*a-c,m=r*u,h>=0)if(f>=-m)if(f<=m){let x=1/u;h*=x,f*=x,d=h*(h+o*f+2*a)+f*(o*h+f+2*c)+l}else f=r,h=Math.max(0,-(o*f+a)),d=-h*h+f*(f+2*c)+l;else f=-r,h=Math.max(0,-(o*f+a)),d=-h*h+f*(f+2*c)+l;else f<=-m?(h=Math.max(0,-(-o*r+a)),f=h>0?-r:Math.min(Math.max(-r,-c),r),d=-h*h+f*(f+2*c)+l):f<=m?(h=0,f=Math.min(Math.max(-r,-c),r),d=f*(f+2*c)+l):(h=Math.max(0,-(o*r+a)),f=h>0?r:Math.min(Math.max(-r,-c),r),d=-h*h+f*(f+2*c)+l);else f=o>0?-r:r,h=Math.max(0,-(o*f+a)),d=-h*h+f*(f+2*c)+l;return n&&n.copy(this.origin).addScaledVector(this.direction,h),s&&s.copy(Fh).addScaledVector(Mc,f),d}intersectSphere(e,t){if(e.radius<0)return null;Di.subVectors(e.center,this.origin);let n=Di.dot(this.direction),s=Di.dot(Di)-n*n,r=e.radius*e.radius;if(s>r)return null;let o=Math.sqrt(r-s),a=n-o,c=n+o;return c<0?null:a<0?this.at(c,t):this.at(a,t)}intersectsSphere(e){return e.radius<0?!1:this.distanceSqToPoint(e.center)<=e.radius*e.radius}distanceToPlane(e){let t=e.normal.dot(this.direction);if(t===0)return e.distanceToPoint(this.origin)===0?0:null;let n=-(this.origin.dot(e.normal)+e.constant)/t;return n>=0?n:null}intersectPlane(e,t){let n=this.distanceToPlane(e);return n===null?null:this.at(n,t)}intersectsPlane(e){let t=e.distanceToPoint(this.origin);return t===0||e.normal.dot(this.direction)*t<0}intersectBox(e,t){let n,s,r,o,a,c,l=1/this.direction.x,u=1/this.direction.y,h=1/this.direction.z,f=this.origin;return l>=0?(n=(e.min.x-f.x)*l,s=(e.max.x-f.x)*l):(n=(e.max.x-f.x)*l,s=(e.min.x-f.x)*l),u>=0?(r=(e.min.y-f.y)*u,o=(e.max.y-f.y)*u):(r=(e.max.y-f.y)*u,o=(e.min.y-f.y)*u),n>o||r>s||((r>n||isNaN(n))&&(n=r),(o<s||isNaN(s))&&(s=o),h>=0?(a=(e.min.z-f.z)*h,c=(e.max.z-f.z)*h):(a=(e.max.z-f.z)*h,c=(e.min.z-f.z)*h),n>c||a>s)||((a>n||n!==n)&&(n=a),(c<s||s!==s)&&(s=c),s<0)?null:this.at(n>=0?n:s,t)}intersectsBox(e){return this.intersectBox(e,Di)!==null}intersectTriangle(e,t,n,s,r){let o=this.origin,a=this.direction,c=a.x,l=a.y,u=a.z,h=e.x-o.x,f=e.y-o.y,d=e.z-o.z,m=t.x-o.x,x=t.y-o.y,g=t.z-o.z,p=n.x-o.x,v=n.y-o.y,b=n.z-o.z,_=Math.abs(c),S=Math.abs(l),M=Math.abs(u),E,y,w,A,P,C,D,L,U,G,Z,oe;if(_>=S&&_>=M?(w=c,C=h,U=m,oe=p,c>=0?(E=l,y=u,A=f,P=d,D=x,L=g,G=v,Z=b):(E=u,y=l,A=d,P=f,D=g,L=x,G=b,Z=v)):S>=M?(w=l,C=f,U=x,oe=v,l>=0?(E=u,y=c,A=d,P=h,D=g,L=m,G=b,Z=p):(E=c,y=u,A=h,P=d,D=m,L=g,G=p,Z=b)):(w=u,C=d,U=g,oe=b,u>=0?(E=c,y=l,A=h,P=f,D=m,L=x,G=p,Z=v):(E=l,y=c,A=f,P=h,D=x,L=m,G=v,Z=p)),w===0)return null;let K=E/w,te=y/w,se=1/w,Re=A-K*C,Te=P-te*C,nt=D-K*U,He=L-te*U,$e=G-K*oe,$=Z-te*oe,z=$e*He-$*nt,j=Re*$-Te*$e,me=nt*Te-He*Re;if(s){if(z<0||j<0||me<0)return null}else if((z<0||j<0||me<0)&&(z>0||j>0||me>0))return null;let fe=z+j+me;if(fe===0)return null;let de=se*(z*C+j*U+me*oe);return(fe>0?de<0:de>0)?null:this.at(de/fe,r)}applyMatrix4(e){return this.origin.applyMatrix4(e),this.direction.transformDirection(e),this}equals(e){return e.origin.equals(this.origin)&&e.direction.equals(this.direction)}clone(){return new this.constructor().copy(this)}},Bn=class extends Mn{constructor(e){super(),this.isMeshBasicMaterial=!0,this.type="MeshBasicMaterial",this.color=new Ve(16777215),this.map=null,this.lightMap=null,this.lightMapIntensity=1,this.aoMap=null,this.aoMapIntensity=1,this.specularMap=null,this.alphaMap=null,this.envMap=null,this.envMapRotation=new Oi,this.combine=xf,this.reflectivity=1,this.refractionRatio=.98,this.wireframe=!1,this.wireframeLinewidth=1,this.wireframeLinecap="round",this.wireframeLinejoin="round",this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.color.copy(e.color),this.map=e.map,this.lightMap=e.lightMap,this.lightMapIntensity=e.lightMapIntensity,this.aoMap=e.aoMap,this.aoMapIntensity=e.aoMapIntensity,this.specularMap=e.specularMap,this.alphaMap=e.alphaMap,this.envMap=e.envMap,this.envMapRotation.copy(e.envMapRotation),this.combine=e.combine,this.reflectivity=e.reflectivity,this.refractionRatio=e.refractionRatio,this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this.wireframeLinecap=e.wireframeLinecap,this.wireframeLinejoin=e.wireframeLinejoin,this.fog=e.fog,this}},im=new Ie,Is=new Pn,wc=new Cn,sm=new I,Ec=new I,Ac=new I,Rc=new I,Oh=new I,Cc=new I,rm=new I,Pc=new I,it=class extends Nt{constructor(e=new ht,t=new Bn){super(),this.isMesh=!0,this.type="Mesh",this.geometry=e,this.material=t,this.morphTargetDictionary=void 0,this.morphTargetInfluences=void 0,this.count=1,this.updateMorphTargets()}copy(e,t){return super.copy(e,t),e.morphTargetInfluences!==void 0&&(this.morphTargetInfluences=e.morphTargetInfluences.slice()),e.morphTargetDictionary!==void 0&&(this.morphTargetDictionary=Object.assign({},e.morphTargetDictionary)),this.material=Array.isArray(e.material)?e.material.slice():e.material,this.geometry=e.geometry,this}updateMorphTargets(){let t=this.geometry.morphAttributes,n=Object.keys(t);if(n.length>0){let s=t[n[0]];if(s!==void 0){this.morphTargetInfluences=[],this.morphTargetDictionary={};for(let r=0,o=s.length;r<o;r++){let a=s[r].name||String(r);this.morphTargetInfluences.push(0),this.morphTargetDictionary[a]=r}}}}getVertexPosition(e,t){let n=this.geometry,s=n.attributes.position,r=n.morphAttributes.position,o=n.morphTargetsRelative;t.fromBufferAttribute(s,e);let a=this.morphTargetInfluences;if(r&&a){Cc.set(0,0,0);for(let c=0,l=r.length;c<l;c++){let u=a[c],h=r[c];u!==0&&(Oh.fromBufferAttribute(h,e),o?Cc.addScaledVector(Oh,u):Cc.addScaledVector(Oh.sub(t),u))}t.add(Cc)}return t}intersectsFrustum(e){return e.intersectsObject(this)}raycast(e,t){let n=this.geometry,s=this.material,r=this.matrixWorld;s!==void 0&&(n.boundingSphere===null&&n.computeBoundingSphere(),wc.copy(n.boundingSphere),wc.applyMatrix4(r),Is.copy(e.ray).recast(e.near),!(wc.containsPoint(Is.origin)===!1&&(Is.intersectSphere(wc,sm)===null||Is.origin.distanceToSquared(sm)>(e.far-e.near)**2))&&(im.copy(r).invert(),Is.copy(e.ray).applyMatrix4(im),!(n.boundingBox!==null&&Is.intersectsBox(n.boundingBox)===!1)&&this._computeIntersections(e,t,Is)))}_computeIntersections(e,t,n){let s,r=this.geometry,o=this.material,a=r.index,c=r.attributes.position,l=r.attributes.uv,u=r.attributes.uv1,h=r.attributes.normal,f=r.groups,d=r.drawRange;if(a!==null)if(Array.isArray(o))for(let m=0,x=f.length;m<x;m++){let g=f[m],p=o[g.materialIndex],v=Math.max(g.start,d.start),b=Math.min(a.count,Math.min(g.start+g.count,d.start+d.count));for(let _=v,S=b;_<S;_+=3){let M=a.getX(_),E=a.getX(_+1),y=a.getX(_+2);s=Ic(this,p,e,n,l,u,h,M,E,y),s&&(s.faceIndex=Math.floor(_/3),s.face.materialIndex=g.materialIndex,t.push(s))}}else{let m=Math.max(0,d.start),x=Math.min(a.count,d.start+d.count);for(let g=m,p=x;g<p;g+=3){let v=a.getX(g),b=a.getX(g+1),_=a.getX(g+2);s=Ic(this,o,e,n,l,u,h,v,b,_),s&&(s.faceIndex=Math.floor(g/3),t.push(s))}}else if(c!==void 0)if(Array.isArray(o))for(let m=0,x=f.length;m<x;m++){let g=f[m],p=o[g.materialIndex],v=Math.max(g.start,d.start),b=Math.min(c.count,Math.min(g.start+g.count,d.start+d.count));for(let _=v,S=b;_<S;_+=3){let M=_,E=_+1,y=_+2;s=Ic(this,p,e,n,l,u,h,M,E,y),s&&(s.faceIndex=Math.floor(_/3),s.face.materialIndex=g.materialIndex,t.push(s))}}else{let m=Math.max(0,d.start),x=Math.min(c.count,d.start+d.count);for(let g=m,p=x;g<p;g+=3){let v=g,b=g+1,_=g+2;s=Ic(this,o,e,n,l,u,h,v,b,_),s&&(s.faceIndex=Math.floor(g/3),t.push(s))}}}};function __(i,e,t,n,s,r,o,a){let c;if(e.side===jt?c=n.intersectTriangle(o,r,s,!0,a):c=n.intersectTriangle(s,r,o,e.side===kn,a),c===null)return null;Pc.copy(a),Pc.applyMatrix4(i.matrixWorld);let l=t.ray.origin.distanceTo(Pc);return l<t.near||l>t.far?null:{distance:l,point:Pc.clone(),object:i}}function Ic(i,e,t,n,s,r,o,a,c,l){i.getVertexPosition(a,Ec),i.getVertexPosition(c,Ac),i.getVertexPosition(l,Rc);let u=__(i,e,t,n,Ec,Ac,Rc,rm);if(u){let h=new I;cn.getBarycoord(rm,Ec,Ac,Rc,h),s&&(u.uv=cn.getInterpolatedAttribute(s,a,c,l,h,new ce)),r&&(u.uv1=cn.getInterpolatedAttribute(r,a,c,l,h,new ce)),o&&(u.normal=cn.getInterpolatedAttribute(o,a,c,l,h,new I),u.normal.dot(n.direction)>0&&u.normal.multiplyScalar(-1));let f={a,b:c,c:l,normal:new I,materialIndex:0};cn.getNormal(Ec,Ac,Rc,f.normal),u.face=f,u.barycoord=h}return u}var Bo=new ut,om=new ut,am=new ut,y_=new ut,cm=new Ie,Lc=new I,Bh=new Cn,lm=new Ie,zh=new Pn,ea=class extends it{constructor(e,t){super(e,t),this.isSkinnedMesh=!0,this.type="SkinnedMesh",this.bindMode=Yh,this.bindMatrix=new Ie,this.bindMatrixInverse=new Ie,this.boundingBox=null,this.boundingSphere=null}computeBoundingBox(){let e=this.geometry;this.boundingBox===null&&(this.boundingBox=new Ke),this.boundingBox.makeEmpty();let t=e.getAttribute("position");for(let n=0;n<t.count;n++)this.getVertexPosition(n,Lc),this.boundingBox.expandByPoint(Lc)}computeBoundingSphere(){let e=this.geometry;this.boundingSphere===null&&(this.boundingSphere=new Cn),this.boundingSphere.makeEmpty();let t=e.getAttribute("position");for(let n=0;n<t.count;n++)this.getVertexPosition(n,Lc),this.boundingSphere.expandByPoint(Lc)}copy(e,t){return super.copy(e,t),this.bindMode=e.bindMode,this.bindMatrix.copy(e.bindMatrix),this.bindMatrixInverse.copy(e.bindMatrixInverse),this.skeleton=e.skeleton,e.boundingBox!==null&&(this.boundingBox=e.boundingBox.clone()),e.boundingSphere!==null&&(this.boundingSphere=e.boundingSphere.clone()),this}raycast(e,t){let n=this.material,s=this.matrixWorld;n!==void 0&&(this.boundingSphere===null&&this.computeBoundingSphere(),Bh.copy(this.boundingSphere),Bh.applyMatrix4(s),e.ray.intersectsSphere(Bh)!==!1&&(lm.copy(s).invert(),zh.copy(e.ray).applyMatrix4(lm),!(this.boundingBox!==null&&zh.intersectsBox(this.boundingBox)===!1)&&this._computeIntersections(e,t,zh)))}getVertexPosition(e,t){return super.getVertexPosition(e,t),this.applyBoneTransform(e,t),t}bind(e,t){this.skeleton=e,t===void 0&&(this.updateMatrixWorld(!0),this.skeleton.calculateInverses(),t=this.matrixWorld),this.bindMatrix.copy(t),this.bindMatrixInverse.copy(t).invert()}pose(){this.skeleton.pose()}normalizeSkinWeights(){let e=new ut,t=this.geometry.attributes.skinWeight;for(let n=0,s=t.count;n<s;n++){e.fromBufferAttribute(t,n);let r=1/e.manhattanLength();r!==1/0?e.multiplyScalar(r):e.set(1,0,0,0),t.setXYZW(n,e.x,e.y,e.z,e.w)}}updateMatrixWorld(e){super.updateMatrixWorld(e),this.bindMode===Yh?this.bindMatrixInverse.copy(this.matrixWorld).invert():this.bindMode===sg?this.bindMatrixInverse.copy(this.bindMatrix).invert():Fe("SkinnedMesh: Unrecognized bindMode: "+this.bindMode)}applyBoneTransform(e,t){let n=this.skeleton,s=this.geometry;om.fromBufferAttribute(s.attributes.skinIndex,e),am.fromBufferAttribute(s.attributes.skinWeight,e),t.isVector4?(Bo.copy(t),t.set(0,0,0,0)):(Bo.set(...t,1),t.set(0,0,0)),Bo.applyMatrix4(this.bindMatrix);for(let r=0;r<4;r++){let o=am.getComponent(r);if(o!==0){let a=om.getComponent(r);cm.multiplyMatrices(n.bones[a].matrixWorld,n.boneInverses[a]),t.addScaledVector(y_.copy(Bo).applyMatrix4(cm),o)}}return t.isVector4&&(t.w=Bo.w),t.applyMatrix4(this.bindMatrixInverse)}},Vr=class extends Nt{constructor(){super(),this.isBone=!0,this.type="Bone"}},Hr=class extends Jt{constructor(e=null,t=1,n=1,s,r,o,a,c,l=Ht,u=Ht,h,f){super(null,o,a,c,l,u,s,r,h,f),this.isDataTexture=!0,this.image={data:e,width:t,height:n},this.generateMipmaps=!1,this.flipY=!1,this.unpackAlignment=1}},um=new Ie,v_=new Ie,ta=class i{constructor(e=[],t=[]){this.uuid=Kn(),this.bones=e.slice(0),this.boneInverses=t,this.boneMatrices=null,this.boneTexture=null,this.init()}init(){let e=this.bones,t=this.boneInverses;if(this.boneMatrices=new Float32Array(e.length*16),t.length===0)this.calculateInverses();else if(e.length!==t.length){Fe("Skeleton: Number of inverse bone matrices does not match amount of bones."),this.boneInverses=[];for(let n=0,s=this.bones.length;n<s;n++)this.boneInverses.push(new Ie)}}calculateInverses(){this.boneInverses.length=0;for(let e=0,t=this.bones.length;e<t;e++){let n=new Ie;this.bones[e]&&n.copy(this.bones[e].matrixWorld).invert(),this.boneInverses.push(n)}}pose(){for(let e=0,t=this.bones.length;e<t;e++){let n=this.bones[e];n&&n.matrixWorld.copy(this.boneInverses[e]).invert()}for(let e=0,t=this.bones.length;e<t;e++){let n=this.bones[e];n&&(n.parent&&n.parent.isBone?(n.matrix.copy(n.parent.matrixWorld).invert(),n.matrix.multiply(n.matrixWorld)):n.matrix.copy(n.matrixWorld),n.matrix.decompose(n.position,n.quaternion,n.scale))}}update(){let e=this.bones,t=this.boneInverses,n=this.boneMatrices,s=this.boneTexture;for(let r=0,o=e.length;r<o;r++){let a=e[r]?e[r].matrixWorld:v_;um.multiplyMatrices(a,t[r]),um.toArray(n,r*16)}s!==null&&(s.needsUpdate=!0)}clone(){return new i(this.bones,this.boneInverses)}computeBoneTexture(){let e=Math.sqrt(this.bones.length*4);e=Math.ceil(e/4)*4,e=Math.max(e,4);let t=new Float32Array(e*e*4);t.set(this.boneMatrices);let n=new Hr(t,e,e,Hn,Vn);return n.needsUpdate=!0,this.boneMatrices=t,this.boneTexture=n,this}getBoneByName(e){for(let t=0,n=this.bones.length;t<n;t++){let s=this.bones[t];if(s.name===e)return s}}dispose(){this.boneTexture!==null&&(this.boneTexture.dispose(),this.boneTexture=null)}fromJSON(e,t){this.uuid=e.uuid;for(let n=0,s=e.bones.length;n<s;n++){let r=e.bones[n],o=t[r];o===void 0&&(Fe("Skeleton: No bone found with UUID:",r),o=new Vr),this.bones.push(o),this.boneInverses.push(new Ie().fromArray(e.boneInverses[n]))}return this.init(),this}toJSON(){let e={metadata:{version:4.7,type:"Skeleton",generator:"Skeleton.toJSON"},bones:[],boneInverses:[]};e.uuid=this.uuid;let t=this.bones,n=this.boneInverses;for(let s=0,r=t.length;s<r;s++){let o=t[s];e.bones.push(o.uuid);let a=n[s];e.boneInverses.push(a.toArray())}return e}},Bi=class extends Tt{constructor(e,t,n,s=1){super(e,t,n),this.isInstancedBufferAttribute=!0,this.meshPerAttribute=s}copy(e){return super.copy(e),this.meshPerAttribute=e.meshPerAttribute,this}toJSON(){let e=super.toJSON();return e.meshPerAttribute=this.meshPerAttribute,e.isInstancedBufferAttribute=!0,e}},wr=new Ie,hm=new Ie,Nc=[],fm=new Ke,S_=new Ie,zo=new it,ko=new Cn,na=class extends it{constructor(e,t,n){super(e,t),this.isInstancedMesh=!0,this.instanceMatrix=new Bi(new Float32Array(n*16),16),this.instanceColor=null,this.morphTexture=null,this.count=n,this.boundingBox=null,this.boundingSphere=null;for(let s=0;s<n;s++)this.setMatrixAt(s,S_)}computeBoundingBox(){let e=this.geometry,t=this.count;this.boundingBox===null&&(this.boundingBox=new Ke),e.boundingBox===null&&e.computeBoundingBox(),this.boundingBox.makeEmpty();for(let n=0;n<t;n++)this.getMatrixAt(n,wr),fm.copy(e.boundingBox).applyMatrix4(wr),this.boundingBox.union(fm)}computeBoundingSphere(){let e=this.geometry,t=this.count;this.boundingSphere===null&&(this.boundingSphere=new Cn),e.boundingSphere===null&&e.computeBoundingSphere(),this.boundingSphere.makeEmpty();for(let n=0;n<t;n++)this.getMatrixAt(n,wr),ko.copy(e.boundingSphere).applyMatrix4(wr),this.boundingSphere.union(ko)}copy(e,t){return super.copy(e,t),this.instanceMatrix.copy(e.instanceMatrix),e.morphTexture!==null&&(this.morphTexture=e.morphTexture.clone()),e.instanceColor!==null&&(this.instanceColor=e.instanceColor.clone()),this.count=e.count,e.boundingBox!==null&&(this.boundingBox=e.boundingBox.clone()),e.boundingSphere!==null&&(this.boundingSphere=e.boundingSphere.clone()),this}getColorAt(e,t){return this.instanceColor===null?t.setRGB(1,1,1):t.fromArray(this.instanceColor.array,e*3)}getMatrixAt(e,t){return t.fromArray(this.instanceMatrix.array,e*16)}getMorphAt(e,t){let n=t.morphTargetInfluences,s=this.morphTexture.source.data.data,r=n.length+1,o=e*r+1;for(let a=0;a<n.length;a++)n[a]=s[o+a]}raycast(e,t){let n=this.matrixWorld,s=this.count;if(zo.geometry=this.geometry,zo.material=this.material,zo.material!==void 0&&(this.boundingSphere===null&&this.computeBoundingSphere(),ko.copy(this.boundingSphere),ko.applyMatrix4(n),e.ray.intersectsSphere(ko)!==!1))for(let r=0;r<s;r++){this.getMatrixAt(r,wr),hm.multiplyMatrices(n,wr),zo.matrixWorld=hm,zo.raycast(e,Nc);for(let o=0,a=Nc.length;o<a;o++){let c=Nc[o];c.instanceId=r,c.object=this,t.push(c)}Nc.length=0}}setColorAt(e,t){return this.instanceColor===null&&(this.instanceColor=new Bi(new Float32Array(this.instanceMatrix.count*3).fill(1),3)),t.toArray(this.instanceColor.array,e*3),this}setMatrixAt(e,t){return t.toArray(this.instanceMatrix.array,e*16),this}setMorphAt(e,t){let n=t.morphTargetInfluences,s=n.length+1;this.morphTexture===null&&(this.morphTexture=new Hr(new Float32Array(s*this.count),s,this.count,Ll,Vn));let r=this.morphTexture.source.data.data,o=0;for(let l=0;l<n.length;l++)o+=n[l];let a=this.geometry.morphTargetsRelative?1:1-o,c=s*e;return r[c]=a,r.set(n,c+1),this}updateMorphTargets(){}dispose(){super.dispose(),this.morphTexture!==null&&(this.morphTexture.dispose(),this.morphTexture=null)}},Ls=new Cn,b_=new ce(.5,.5),Dc=new I,Gr=class{constructor(e=new an,t=new an,n=new an,s=new an,r=new an,o=new an){this.planes=[e,t,n,s,r,o]}set(e,t,n,s,r,o){let a=this.planes;return a[0].copy(e),a[1].copy(t),a[2].copy(n),a[3].copy(s),a[4].copy(r),a[5].copy(o),this}copy(e){let t=this.planes;for(let n=0;n<6;n++)t[n].copy(e.planes[n]);return this}setFromProjectionMatrix(e,t=si,n=!1){let s=this.planes,r=e.elements,o=r[0],a=r[1],c=r[2],l=r[3],u=r[4],h=r[5],f=r[6],d=r[7],m=r[8],x=r[9],g=r[10],p=r[11],v=r[12],b=r[13],_=r[14],S=r[15];if(s[0].setComponents(l-o,d-u,p-m,S-v).normalize(),s[1].setComponents(l+o,d+u,p+m,S+v).normalize(),s[2].setComponents(l+a,d+h,p+x,S+b).normalize(),s[3].setComponents(l-a,d-h,p-x,S-b).normalize(),n)s[4].setComponents(c,f,g,_).normalize(),s[5].setComponents(l-c,d-f,p-g,S-_).normalize();else if(s[4].setComponents(l-c,d-f,p-g,S-_).normalize(),t===si)s[5].setComponents(l+c,d+f,p+g,S+_).normalize();else if(t===Dr)s[5].setComponents(c,f,g,_).normalize();else throw new Error("THREE.Frustum.setFromProjectionMatrix(): Invalid coordinate system: "+t);return this}intersectsObject(e){if(e.boundingSphere!==void 0)e.boundingSphere===null&&e.computeBoundingSphere(),Ls.copy(e.boundingSphere).applyMatrix4(e.matrixWorld);else{let t=e.geometry;t.boundingSphere===null&&t.computeBoundingSphere(),Ls.copy(t.boundingSphere).applyMatrix4(e.matrixWorld)}return this.intersectsSphere(Ls)}intersectsSprite(e){Ls.center.set(0,0,0);let t=b_.distanceTo(e.center);return Ls.radius=.7071067811865476+t,Ls.applyMatrix4(e.matrixWorld),this.intersectsSphere(Ls)}intersectsSphere(e){let t=this.planes,n=e.center,s=-e.radius;for(let r=0;r<6;r++)if(t[r].distanceToPoint(n)<s)return!1;return!0}intersectsBox(e){let t=this.planes;for(let n=0;n<6;n++){let s=t[n];if(Dc.x=s.normal.x>0?e.max.x:e.min.x,Dc.y=s.normal.y>0?e.max.y:e.min.y,Dc.z=s.normal.z>0?e.max.z:e.min.z,s.distanceToPoint(Dc)<0)return!1}return!0}containsPoint(e){let t=this.planes;for(let n=0;n<6;n++)if(t[n].distanceToPoint(e)<0)return!1;return!0}clone(){return new this.constructor().copy(this)}};var us=class extends Mn{constructor(e){super(),this.isLineBasicMaterial=!0,this.type="LineBasicMaterial",this.color=new Ve(16777215),this.map=null,this.linewidth=1,this.linecap="round",this.linejoin="round",this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.color.copy(e.color),this.map=e.map,this.linewidth=e.linewidth,this.linecap=e.linecap,this.linejoin=e.linejoin,this.fog=e.fog,this}},il=new I,sl=new I,dm=new Ie,Vo=new Pn,Uc=new Cn,kh=new I,pm=new I,zi=class extends Nt{constructor(e=new ht,t=new us){super(),this.isLine=!0,this.type="Line",this.geometry=e,this.material=t,this.morphTargetDictionary=void 0,this.morphTargetInfluences=void 0,this.updateMorphTargets()}copy(e,t){return super.copy(e,t),this.material=Array.isArray(e.material)?e.material.slice():e.material,this.geometry=e.geometry,this}computeLineDistances(){let e=this.geometry;if(e.index===null){let t=e.attributes.position,n=[0];for(let s=1,r=t.count;s<r;s++)il.fromBufferAttribute(t,s-1),sl.fromBufferAttribute(t,s),n[s]=n[s-1],n[s]+=il.distanceTo(sl);e.setAttribute("lineDistance",new lt(n,1))}else Fe("Line.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.");return this}intersectsFrustum(e){return e.intersectsObject(this)}raycast(e,t){let n=this.geometry,s=this.matrixWorld,r=e.params.Line.threshold,o=n.drawRange;if(n.boundingSphere===null&&n.computeBoundingSphere(),Uc.copy(n.boundingSphere),Uc.applyMatrix4(s),Uc.radius+=r,e.ray.intersectsSphere(Uc)===!1)return;dm.copy(s).invert(),Vo.copy(e.ray).applyMatrix4(dm);let a=r/((this.scale.x+this.scale.y+this.scale.z)/3),c=a*a,l=this.isLineSegments?2:1,u=n.index,f=n.attributes.position;if(u!==null){let d=Math.max(0,o.start),m=Math.min(u.count,o.start+o.count);for(let x=d,g=m-1;x<g;x+=l){let p=u.getX(x),v=u.getX(x+1),b=Fc(this,e,Vo,c,p,v,x);b&&t.push(b)}if(this.isLineLoop){let x=u.getX(m-1),g=u.getX(d),p=Fc(this,e,Vo,c,x,g,m-1);p&&t.push(p)}}else{let d=Math.max(0,o.start),m=Math.min(f.count,o.start+o.count);for(let x=d,g=m-1;x<g;x+=l){let p=Fc(this,e,Vo,c,x,x+1,x);p&&t.push(p)}if(this.isLineLoop){let x=Fc(this,e,Vo,c,m-1,d,m-1);x&&t.push(x)}}}updateMorphTargets(){let t=this.geometry.morphAttributes,n=Object.keys(t);if(n.length>0){let s=t[n[0]];if(s!==void 0){this.morphTargetInfluences=[],this.morphTargetDictionary={};for(let r=0,o=s.length;r<o;r++){let a=s[r].name||String(r);this.morphTargetInfluences.push(0),this.morphTargetDictionary[a]=r}}}}};function Fc(i,e,t,n,s,r,o){let a=i.geometry.attributes.position;if(il.fromBufferAttribute(a,s),sl.fromBufferAttribute(a,r),t.distanceSqToSegment(il,sl,kh,pm)>n)return;kh.applyMatrix4(i.matrixWorld);let l=e.ray.origin.distanceTo(kh);if(!(l<e.near||l>e.far))return{distance:l,point:pm.clone().applyMatrix4(i.matrixWorld),index:o,face:null,faceIndex:null,barycoord:null,object:i}}var mm=new I,gm=new I,ia=class extends zi{constructor(e,t){super(e,t),this.isLineSegments=!0,this.type="LineSegments"}computeLineDistances(){let e=this.geometry;if(e.index===null){let t=e.attributes.position,n=[];for(let s=0,r=t.count;s<r;s+=2)mm.fromBufferAttribute(t,s),gm.fromBufferAttribute(t,s+1),n[s]=s===0?0:n[s-1],n[s+1]=n[s]+mm.distanceTo(gm);e.setAttribute("lineDistance",new lt(n,1))}else Fe("LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.");return this}},sa=class extends zi{constructor(e,t){super(e,t),this.isLineLoop=!0,this.type="LineLoop"}},Wr=class extends Mn{constructor(e){super(),this.isPointsMaterial=!0,this.type="PointsMaterial",this.color=new Ve(16777215),this.map=null,this.alphaMap=null,this.size=1,this.sizeAttenuation=!0,this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.color.copy(e.color),this.map=e.map,this.alphaMap=e.alphaMap,this.size=e.size,this.sizeAttenuation=e.sizeAttenuation,this.fog=e.fog,this}},xm=new Ie,jh=new Pn,Oc=new Cn,Bc=new I,ra=class extends Nt{constructor(e=new ht,t=new Wr){super(),this.isPoints=!0,this.type="Points",this.geometry=e,this.material=t,this.morphTargetDictionary=void 0,this.morphTargetInfluences=void 0,this.updateMorphTargets()}copy(e,t){return super.copy(e,t),this.material=Array.isArray(e.material)?e.material.slice():e.material,this.geometry=e.geometry,this}intersectsFrustum(e){return e.intersectsObject(this)}raycast(e,t){let n=this.geometry,s=this.matrixWorld,r=e.params.Points.threshold,o=n.drawRange;if(n.boundingSphere===null&&n.computeBoundingSphere(),Oc.copy(n.boundingSphere),Oc.applyMatrix4(s),Oc.radius+=r,e.ray.intersectsSphere(Oc)===!1)return;xm.copy(s).invert(),jh.copy(e.ray).applyMatrix4(xm);let a=r/((this.scale.x+this.scale.y+this.scale.z)/3),c=a*a,l=n.index,h=n.attributes.position;if(l!==null){let f=Math.max(0,o.start),d=Math.min(l.count,o.start+o.count);for(let m=f,x=d;m<x;m++){let g=l.getX(m);Bc.fromBufferAttribute(h,g),_m(Bc,g,c,s,e,t,this)}}else{let f=Math.max(0,o.start),d=Math.min(h.count,o.start+o.count);for(let m=f,x=d;m<x;m++)Bc.fromBufferAttribute(h,m),_m(Bc,m,c,s,e,t,this)}}updateMorphTargets(){let t=this.geometry.morphAttributes,n=Object.keys(t);if(n.length>0){let s=t[n[0]];if(s!==void 0){this.morphTargetInfluences=[],this.morphTargetDictionary={};for(let r=0,o=s.length;r<o;r++){let a=s[r].name||String(r);this.morphTargetInfluences.push(0),this.morphTargetDictionary[a]=r}}}}};function _m(i,e,t,n,s,r,o){let a=jh.distanceSqToPoint(i);if(a<t){let c=new I;jh.closestPointToPoint(i,c),c.applyMatrix4(n);let l=s.ray.origin.distanceTo(c);if(l<s.near||l>s.far)return;r.push({distance:l,distanceToRay:Math.sqrt(a),point:c,index:e,face:null,faceIndex:null,barycoord:null,object:o})}}var oa=class extends Jt{constructor(e=[],t=xs,n,s,r,o,a,c,l,u){super(e,t,n,s,r,o,a,c,l,u),this.isCubeTexture=!0,this.flipY=!1}get images(){return this.image}set images(e){this.image=e}},aa=class extends Jt{constructor(e,t,n,s,r,o,a,c,l){super(e,t,n,s,r,o,a,c,l),this.isCanvasTexture=!0,this.needsUpdate=!0}};var hs=class extends Jt{constructor(e,t,n=ci,s,r,o,a=Ht,c=Ht,l,u=_i,h=1){if(u!==_i&&u!==_s)throw new Error("THREE.DepthTexture: format must be either THREE.DepthFormat or THREE.DepthStencilFormat");let f={width:e,height:t,depth:h};super(f,s,r,o,a,c,u,n,l),this.isDepthTexture=!0,this.flipY=!1,this.generateMipmaps=!1,this.compareFunction=null}copy(e){return super.copy(e),this.source=new Or(Object.assign({},e.image)),this.compareFunction=e.compareFunction,this}toJSON(e){let t=super.toJSON(e);return t.compareFunction=this.compareFunction,t}},rl=class extends hs{constructor(e,t=ci,n=xs,s,r,o=Ht,a=Ht,c,l=_i){let u={width:e,height:e,depth:1},h=[u,u,u,u,u,u];super(e,e,t,n,s,r,o,a,c,l),this.image=h,this.isCubeDepthTexture=!0,this.isCubeTexture=!0}get images(){return this.image}set images(e){this.image=e}},ca=class extends Jt{constructor(e=null){super(),this.sourceTexture=e,this.isExternalTexture=!0}copy(e){return super.copy(e),this.sourceTexture=e.sourceTexture,this}},In=class i extends ht{constructor(e=1,t=1,n=1,s=1,r=1,o=1){super(),this.type="BoxGeometry",this.parameters={width:e,height:t,depth:n,widthSegments:s,heightSegments:r,depthSegments:o};let a=this;s=Math.floor(s),r=Math.floor(r),o=Math.floor(o);let c=[],l=[],u=[],h=[],f=0,d=0;m("z","y","x",-1,-1,n,t,e,o,r,0),m("z","y","x",1,-1,n,t,-e,o,r,1),m("x","z","y",1,1,e,n,t,s,o,2),m("x","z","y",1,-1,e,n,-t,s,o,3),m("x","y","z",1,-1,e,t,n,s,r,4),m("x","y","z",-1,-1,e,t,-n,s,r,5),this.setIndex(c),this.setAttribute("position",new lt(l,3)),this.setAttribute("normal",new lt(u,3)),this.setAttribute("uv",new lt(h,2));function m(x,g,p,v,b,_,S,M,E,y,w){let A=_/E,P=S/y,C=_/2,D=S/2,L=M/2,U=E+1,G=y+1,Z=0,oe=0,K=new I;for(let te=0;te<G;te++){let se=te*P-D;for(let Re=0;Re<U;Re++){let Te=Re*A-C;K[x]=Te*v,K[g]=se*b,K[p]=L,l.push(K.x,K.y,K.z),K[x]=0,K[g]=0,K[p]=M>0?1:-1,u.push(K.x,K.y,K.z),h.push(Re/E),h.push(1-te/y),Z+=1}}for(let te=0;te<y;te++)for(let se=0;se<E;se++){let Re=f+se+U*te,Te=f+se+U*(te+1),nt=f+(se+1)+U*(te+1),He=f+(se+1)+U*te;c.push(Re,Te,He),c.push(Te,nt,He),oe+=6}a.addGroup(d,oe,w),d+=oe,f+=Z}}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.width,e.height,e.depth,e.widthSegments,e.heightSegments,e.depthSegments)}};var fs=class i extends ht{constructor(e=1,t=1,n=1,s=32,r=1,o=!1,a=0,c=Math.PI*2){super(),this.type="CylinderGeometry",this.parameters={radiusTop:e,radiusBottom:t,height:n,radialSegments:s,heightSegments:r,openEnded:o,thetaStart:a,thetaLength:c};let l=this;s=Math.floor(s),r=Math.floor(r);let u=[],h=[],f=[],d=[],m=0,x=[],g=n/2,p=0;v(),o===!1&&(e>0&&b(!0),t>0&&b(!1)),this.setIndex(u),this.setAttribute("position",new lt(h,3)),this.setAttribute("normal",new lt(f,3)),this.setAttribute("uv",new lt(d,2));function v(){let _=new I,S=new I,M=0,E=(t-e)/n;for(let y=0;y<=r;y++){let w=[],A=y/r,P=A*(t-e)+e;for(let C=0;C<=s;C++){let D=C/s,L=D*c+a,U=Math.sin(L),G=Math.cos(L);S.x=P*U,S.y=-A*n+g,S.z=P*G,h.push(S.x,S.y,S.z),_.set(U,E,G).normalize(),f.push(_.x,_.y,_.z),d.push(D,1-A),w.push(m++)}x.push(w)}for(let y=0;y<s;y++)for(let w=0;w<r;w++){let A=x[w][y],P=x[w+1][y],C=x[w+1][y+1],D=x[w][y+1];(e>0||w!==0)&&(u.push(A,P,D),M+=3),(t>0||w!==r-1)&&(u.push(P,C,D),M+=3)}l.addGroup(p,M,0),p+=M}function b(_){let S=m,M=new ce,E=new I,y=0,w=_===!0?e:t,A=_===!0?1:-1;for(let C=1;C<=s;C++)h.push(0,g*A,0),f.push(0,A,0),d.push(.5,.5),m++;let P=m;for(let C=0;C<=s;C++){let L=C/s*c+a,U=Math.cos(L),G=Math.sin(L);E.x=w*G,E.y=g*A,E.z=w*U,h.push(E.x,E.y,E.z),f.push(0,A,0),M.x=U*.5+.5,M.y=G*.5*A+.5,d.push(M.x,M.y),m++}for(let C=0;C<s;C++){let D=S+C,L=P+C;_===!0?u.push(L,L+1,D):u.push(L+1,L,D),y+=3}l.addGroup(p,y,_===!0?1:2),p+=y}}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.radiusTop,e.radiusBottom,e.height,e.radialSegments,e.heightSegments,e.openEnded,e.thetaStart,e.thetaLength)}},ks=class i extends fs{constructor(e=1,t=1,n=32,s=1,r=!1,o=0,a=Math.PI*2){super(0,e,t,n,s,r,o,a),this.type="ConeGeometry",this.parameters={radius:e,height:t,radialSegments:n,heightSegments:s,openEnded:r,thetaStart:o,thetaLength:a}}static fromJSON(e){return new i(e.radius,e.height,e.radialSegments,e.heightSegments,e.openEnded,e.thetaStart,e.thetaLength)}};var zn=class{constructor(){this.type="Curve",this.arcLengthDivisions=200,this.needsUpdate=!1,this.cacheArcLengths=null}getPoint(){Fe("Curve: .getPoint() not implemented.")}getPointAt(e,t){let n=this.getUtoTmapping(e);return this.getPoint(n,t)}getPoints(e=5){let t=[];for(let n=0;n<=e;n++)t.push(this.getPoint(n/e));return t}getSpacedPoints(e=5){let t=[];for(let n=0;n<=e;n++)t.push(this.getPointAt(n/e));return t}getLength(){let e=this.getLengths();return e[e.length-1]}getLengths(e=this.arcLengthDivisions){if(this.cacheArcLengths&&this.cacheArcLengths.length===e+1&&!this.needsUpdate)return this.cacheArcLengths;this.needsUpdate=!1;let t=[],n,s=this.getPoint(0),r=0;t.push(0);for(let o=1;o<=e;o++)n=this.getPoint(o/e),r+=n.distanceTo(s),t.push(r),s=n;return this.cacheArcLengths=t,t}updateArcLengths(){this.needsUpdate=!0,this.getLengths()}getUtoTmapping(e,t=null){let n=this.getLengths(),s=0,r=n.length,o;t?o=t:o=e*n[r-1];let a=0,c=r-1,l;for(;a<=c;)if(s=Math.floor(a+(c-a)/2),l=n[s]-o,l<0)a=s+1;else if(l>0)c=s-1;else{c=s;break}if(s=c,n[s]===o)return s/(r-1);let u=n[s],f=n[s+1]-u,d=(o-u)/f;return(s+d)/(r-1)}getTangent(e,t){let s=e-1e-4,r=e+1e-4;s<0&&(s=0),r>1&&(r=1);let o=this.getPoint(s),a=this.getPoint(r),c=t||(o.isVector2?new ce:new I);return c.copy(a).sub(o).normalize(),c}getTangentAt(e,t){let n=this.getUtoTmapping(e);return this.getTangent(n,t)}computeFrenetFrames(e,t=!1){let n=new I,s=[],r=[],o=[],a=new I,c=new Ie;for(let d=0;d<=e;d++){let m=d/e;s[d]=this.getTangentAt(m,new I)}r[0]=new I,o[0]=new I;let l=Number.MAX_VALUE,u=Math.abs(s[0].x),h=Math.abs(s[0].y),f=Math.abs(s[0].z);u<=l&&(l=u,n.set(1,0,0)),h<=l&&(l=h,n.set(0,1,0)),f<=l&&n.set(0,0,1),a.crossVectors(s[0],n).normalize(),r[0].crossVectors(s[0],a),o[0].crossVectors(s[0],r[0]);for(let d=1;d<=e;d++){if(r[d]=r[d-1].clone(),o[d]=o[d-1].clone(),a.crossVectors(s[d-1],s[d]),a.length()>Number.EPSILON){a.normalize();let m=Math.acos(qe(s[d-1].dot(s[d]),-1,1));r[d].applyMatrix4(c.makeRotationAxis(a,m))}o[d].crossVectors(s[d],r[d])}if(t===!0){let d=Math.acos(qe(r[0].dot(r[e]),-1,1));d/=e,s[0].dot(a.crossVectors(r[0],r[e]))>0&&(d=-d);for(let m=1;m<=e;m++)r[m].applyMatrix4(c.makeRotationAxis(s[m],d*m)),o[m].crossVectors(s[m],r[m])}return{tangents:s,normals:r,binormals:o}}clone(){return new this.constructor().copy(this)}copy(e){return this.arcLengthDivisions=e.arcLengthDivisions,this}toJSON(){let e={metadata:{version:4.7,type:"Curve",generator:"Curve.toJSON"}};return e.arcLengthDivisions=this.arcLengthDivisions,e.type=this.type,e}fromJSON(e){return this.arcLengthDivisions=e.arcLengthDivisions,this}},Xr=class extends zn{constructor(e=0,t=0,n=1,s=1,r=0,o=Math.PI*2,a=!1,c=0){super(),this.isEllipseCurve=!0,this.type="EllipseCurve",this.aX=e,this.aY=t,this.xRadius=n,this.yRadius=s,this.aStartAngle=r,this.aEndAngle=o,this.aClockwise=a,this.aRotation=c}getPoint(e,t=new ce){let n=t,s=Math.PI*2,r=this.aEndAngle-this.aStartAngle,o=Math.abs(r)<Number.EPSILON;for(;r<0;)r+=s;for(;r>s;)r-=s;r<Number.EPSILON&&(o?r=0:r=s),this.aClockwise===!0&&!o&&(r===s?r=-s:r=r-s);let a=this.aStartAngle+e*r,c=this.aX+this.xRadius*Math.cos(a),l=this.aY+this.yRadius*Math.sin(a);if(this.aRotation!==0){let u=Math.cos(this.aRotation),h=Math.sin(this.aRotation),f=c-this.aX,d=l-this.aY;c=f*u-d*h+this.aX,l=f*h+d*u+this.aY}return n.set(c,l)}copy(e){return super.copy(e),this.aX=e.aX,this.aY=e.aY,this.xRadius=e.xRadius,this.yRadius=e.yRadius,this.aStartAngle=e.aStartAngle,this.aEndAngle=e.aEndAngle,this.aClockwise=e.aClockwise,this.aRotation=e.aRotation,this}toJSON(){let e=super.toJSON();return e.aX=this.aX,e.aY=this.aY,e.xRadius=this.xRadius,e.yRadius=this.yRadius,e.aStartAngle=this.aStartAngle,e.aEndAngle=this.aEndAngle,e.aClockwise=this.aClockwise,e.aRotation=this.aRotation,e}fromJSON(e){return super.fromJSON(e),this.aX=e.aX,this.aY=e.aY,this.xRadius=e.xRadius,this.yRadius=e.yRadius,this.aStartAngle=e.aStartAngle,this.aEndAngle=e.aEndAngle,this.aClockwise=e.aClockwise,this.aRotation=e.aRotation,this}},ol=class extends Xr{constructor(e,t,n,s,r,o){super(e,t,n,n,s,r,o),this.isArcCurve=!0,this.type="ArcCurve"}};function Uf(){let i=0,e=0,t=0,n=0;function s(r,o,a,c){i=r,e=a,t=-3*r+3*o-2*a-c,n=2*r-2*o+a+c}return{initCatmullRom:function(r,o,a,c,l){s(o,a,l*(a-r),l*(c-o))},initNonuniformCatmullRom:function(r,o,a,c,l,u,h){let f=(o-r)/l-(a-r)/(l+u)+(a-o)/u,d=(a-o)/u-(c-o)/(u+h)+(c-a)/h;f*=u,d*=u,s(o,a,f,d)},calc:function(r){let o=r*r,a=o*r;return i+e*r+t*o+n*a}}}var ym=new I,vm=new I,Vh=new Uf,Hh=new Uf,Gh=new Uf,al=class extends zn{constructor(e=[],t=!1,n="centripetal",s=.5){super(),this.isCatmullRomCurve3=!0,this.type="CatmullRomCurve3",this.points=e,this.closed=t,this.curveType=n,this.tension=s}getPoint(e,t=new I){let n=t,s=this.points,r=s.length,o=(r-(this.closed?0:1))*e,a=Math.floor(o),c=o-a;this.closed?a+=a>0?0:(Math.floor(Math.abs(a)/r)+1)*r:c===0&&a===r-1&&(a=r-2,c=1);let l,u;this.closed||a>0?l=s[(a-1)%r]:(vm.subVectors(s[0],s[1]).add(s[0]),l=vm);let h=s[a%r],f=s[(a+1)%r];if(this.closed||a+2<r?u=s[(a+2)%r]:(ym.subVectors(s[r-1],s[r-2]).add(s[r-1]),u=ym),this.curveType==="centripetal"||this.curveType==="chordal"){let d=this.curveType==="chordal"?.5:.25,m=Math.pow(l.distanceToSquared(h),d),x=Math.pow(h.distanceToSquared(f),d),g=Math.pow(f.distanceToSquared(u),d);x<1e-4&&(x=1),m<1e-4&&(m=x),g<1e-4&&(g=x),Vh.initNonuniformCatmullRom(l.x,h.x,f.x,u.x,m,x,g),Hh.initNonuniformCatmullRom(l.y,h.y,f.y,u.y,m,x,g),Gh.initNonuniformCatmullRom(l.z,h.z,f.z,u.z,m,x,g)}else this.curveType==="catmullrom"&&(Vh.initCatmullRom(l.x,h.x,f.x,u.x,this.tension),Hh.initCatmullRom(l.y,h.y,f.y,u.y,this.tension),Gh.initCatmullRom(l.z,h.z,f.z,u.z,this.tension));return n.set(Vh.calc(c),Hh.calc(c),Gh.calc(c)),n}copy(e){super.copy(e),this.points=[];for(let t=0,n=e.points.length;t<n;t++){let s=e.points[t];this.points.push(s.clone())}return this.closed=e.closed,this.curveType=e.curveType,this.tension=e.tension,this}toJSON(){let e=super.toJSON();e.points=[];for(let t=0,n=this.points.length;t<n;t++){let s=this.points[t];e.points.push(s.toArray())}return e.closed=this.closed,e.curveType=this.curveType,e.tension=this.tension,e}fromJSON(e){super.fromJSON(e),this.points=[];for(let t=0,n=e.points.length;t<n;t++){let s=e.points[t];this.points.push(new I().fromArray(s))}return this.closed=e.closed,this.curveType=e.curveType,this.tension=e.tension,this}};function Sm(i,e,t,n,s){let r=(n-e)*.5,o=(s-t)*.5,a=i*i,c=i*a;return(2*t-2*n+r+o)*c+(-3*t+3*n-2*r-o)*a+r*i+t}function M_(i,e){let t=1-i;return t*t*e}function T_(i,e){return 2*(1-i)*i*e}function w_(i,e){return i*i*e}function Xo(i,e,t,n){return M_(i,e)+T_(i,t)+w_(i,n)}function E_(i,e){let t=1-i;return t*t*t*e}function A_(i,e){let t=1-i;return 3*t*t*i*e}function R_(i,e){return 3*(1-i)*i*i*e}function C_(i,e){return i*i*i*e}function qo(i,e,t,n,s){return E_(i,e)+A_(i,t)+R_(i,n)+C_(i,s)}var la=class extends zn{constructor(e=new ce,t=new ce,n=new ce,s=new ce){super(),this.isCubicBezierCurve=!0,this.type="CubicBezierCurve",this.v0=e,this.v1=t,this.v2=n,this.v3=s}getPoint(e,t=new ce){let n=t,s=this.v0,r=this.v1,o=this.v2,a=this.v3;return n.set(qo(e,s.x,r.x,o.x,a.x),qo(e,s.y,r.y,o.y,a.y)),n}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this.v3.copy(e.v3),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e.v3=this.v3.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this.v3.fromArray(e.v3),this}},cl=class extends zn{constructor(e=new I,t=new I,n=new I,s=new I){super(),this.isCubicBezierCurve3=!0,this.type="CubicBezierCurve3",this.v0=e,this.v1=t,this.v2=n,this.v3=s}getPoint(e,t=new I){let n=t,s=this.v0,r=this.v1,o=this.v2,a=this.v3;return n.set(qo(e,s.x,r.x,o.x,a.x),qo(e,s.y,r.y,o.y,a.y),qo(e,s.z,r.z,o.z,a.z)),n}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this.v3.copy(e.v3),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e.v3=this.v3.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this.v3.fromArray(e.v3),this}},ua=class extends zn{constructor(e=new ce,t=new ce){super(),this.isLineCurve=!0,this.type="LineCurve",this.v1=e,this.v2=t}getPoint(e,t=new ce){let n=t;return e===1?n.copy(this.v2):(n.copy(this.v2).sub(this.v1),n.multiplyScalar(e).add(this.v1)),n}getPointAt(e,t){return this.getPoint(e,t)}getTangent(e,t=new ce){return t.subVectors(this.v2,this.v1).normalize()}getTangentAt(e,t){return this.getTangent(e,t)}copy(e){return super.copy(e),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},ll=class extends zn{constructor(e=new I,t=new I){super(),this.isLineCurve3=!0,this.type="LineCurve3",this.v1=e,this.v2=t}getPoint(e,t=new I){let n=t;return e===1?n.copy(this.v2):(n.copy(this.v2).sub(this.v1),n.multiplyScalar(e).add(this.v1)),n}getPointAt(e,t){return this.getPoint(e,t)}getTangent(e,t=new I){return t.subVectors(this.v2,this.v1).normalize()}getTangentAt(e,t){return this.getTangent(e,t)}copy(e){return super.copy(e),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},ha=class extends zn{constructor(e=new ce,t=new ce,n=new ce){super(),this.isQuadraticBezierCurve=!0,this.type="QuadraticBezierCurve",this.v0=e,this.v1=t,this.v2=n}getPoint(e,t=new ce){let n=t,s=this.v0,r=this.v1,o=this.v2;return n.set(Xo(e,s.x,r.x,o.x),Xo(e,s.y,r.y,o.y)),n}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},ul=class extends zn{constructor(e=new I,t=new I,n=new I){super(),this.isQuadraticBezierCurve3=!0,this.type="QuadraticBezierCurve3",this.v0=e,this.v1=t,this.v2=n}getPoint(e,t=new I){let n=t,s=this.v0,r=this.v1,o=this.v2;return n.set(Xo(e,s.x,r.x,o.x),Xo(e,s.y,r.y,o.y),Xo(e,s.z,r.z,o.z)),n}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},fa=class extends zn{constructor(e=[]){super(),this.isSplineCurve=!0,this.type="SplineCurve",this.points=e}getPoint(e,t=new ce){let n=t,s=this.points,r=(s.length-1)*e,o=Math.floor(r),a=r-o,c=s[o===0?o:o-1],l=s[o],u=s[o>s.length-2?s.length-1:o+1],h=s[o>s.length-3?s.length-1:o+2];return n.set(Sm(a,c.x,l.x,u.x,h.x),Sm(a,c.y,l.y,u.y,h.y)),n}copy(e){super.copy(e),this.points=[];for(let t=0,n=e.points.length;t<n;t++){let s=e.points[t];this.points.push(s.clone())}return this}toJSON(){let e=super.toJSON();e.points=[];for(let t=0,n=this.points.length;t<n;t++){let s=this.points[t];e.points.push(s.toArray())}return e}fromJSON(e){super.fromJSON(e),this.points=[];for(let t=0,n=e.points.length;t<n;t++){let s=e.points[t];this.points.push(new ce().fromArray(s))}return this}},Qh=Object.freeze({__proto__:null,ArcCurve:ol,CatmullRomCurve3:al,CubicBezierCurve:la,CubicBezierCurve3:cl,EllipseCurve:Xr,LineCurve:ua,LineCurve3:ll,QuadraticBezierCurve:ha,QuadraticBezierCurve3:ul,SplineCurve:fa}),hl=class extends zn{constructor(){super(),this.type="CurvePath",this.curves=[],this.autoClose=!1}add(e){this.curves.push(e)}closePath(){let e=this.curves[0].getPoint(0),t=this.curves[this.curves.length-1].getPoint(1);if(!e.equals(t)){let n=e.isVector2===!0?"LineCurve":"LineCurve3";this.curves.push(new Qh[n](t,e))}return this}getPoint(e,t){let n=e*this.getLength(),s=this.getCurveLengths(),r=0;for(;r<s.length;){if(s[r]>=n){let o=s[r]-n,a=this.curves[r],c=a.getLength(),l=c===0?0:1-o/c;return a.getPointAt(l,t)}r++}return null}getLength(){let e=this.getCurveLengths();return e[e.length-1]}updateArcLengths(){this.needsUpdate=!0,this.cacheLengths=null,this.getCurveLengths()}getCurveLengths(){if(this.cacheLengths&&this.cacheLengths.length===this.curves.length)return this.cacheLengths;let e=[],t=0;for(let n=0,s=this.curves.length;n<s;n++)t+=this.curves[n].getLength(),e.push(t);return this.cacheLengths=e,e}getSpacedPoints(e=40){let t=[];for(let n=0;n<=e;n++)t.push(this.getPoint(n/e));return this.autoClose&&t.push(t[0]),t}getPoints(e=12){let t=[],n;for(let s=0,r=this.curves;s<r.length;s++){let o=r[s],a=o.isEllipseCurve?e*2:o.isLineCurve||o.isLineCurve3?1:o.isSplineCurve?e*o.points.length:e,c=o.getPoints(a);for(let l=0;l<c.length;l++){let u=c[l];n&&n.equals(u)||(t.push(u),n=u)}}return this.autoClose&&t.length>1&&!t[t.length-1].equals(t[0])&&t.push(t[0]),t}copy(e){super.copy(e),this.curves=[];for(let t=0,n=e.curves.length;t<n;t++){let s=e.curves[t];this.curves.push(s.clone())}return this.autoClose=e.autoClose,this}toJSON(){let e=super.toJSON();e.autoClose=this.autoClose,e.curves=[];for(let t=0,n=this.curves.length;t<n;t++){let s=this.curves[t];e.curves.push(s.toJSON())}return e}fromJSON(e){super.fromJSON(e),this.autoClose=e.autoClose,this.curves=[];for(let t=0,n=e.curves.length;t<n;t++){let s=e.curves[t];this.curves.push(new Qh[s.type]().fromJSON(s))}return this}},da=class extends hl{constructor(e){super(),this.type="Path",this.currentPoint=new ce,e&&this.setFromPoints(e)}setFromPoints(e){this.moveTo(e[0].x,e[0].y);for(let t=1,n=e.length;t<n;t++)this.lineTo(e[t].x,e[t].y);return this}moveTo(e,t){return this.currentPoint.set(e,t),this}lineTo(e,t){let n=new ua(this.currentPoint.clone(),new ce(e,t));return this.curves.push(n),this.currentPoint.set(e,t),this}quadraticCurveTo(e,t,n,s){let r=new ha(this.currentPoint.clone(),new ce(e,t),new ce(n,s));return this.curves.push(r),this.currentPoint.set(n,s),this}bezierCurveTo(e,t,n,s,r,o){let a=new la(this.currentPoint.clone(),new ce(e,t),new ce(n,s),new ce(r,o));return this.curves.push(a),this.currentPoint.set(r,o),this}splineThru(e){let t=[this.currentPoint.clone()].concat(e),n=new fa(t);return this.curves.push(n),this.currentPoint.copy(e[e.length-1]),this}arc(e,t,n,s,r,o){let a=this.currentPoint.x,c=this.currentPoint.y;return this.absarc(e+a,t+c,n,s,r,o),this}absarc(e,t,n,s,r,o){return this.absellipse(e,t,n,n,s,r,o),this}ellipse(e,t,n,s,r,o,a,c){let l=this.currentPoint.x,u=this.currentPoint.y;return this.absellipse(e+l,t+u,n,s,r,o,a,c),this}absellipse(e,t,n,s,r,o,a,c){let l=new Xr(e,t,n,s,r,o,a,c);if(this.curves.length>0){let h=l.getPoint(0);h.equals(this.currentPoint)||this.lineTo(h.x,h.y)}this.curves.push(l);let u=l.getPoint(1);return this.currentPoint.copy(u),this}copy(e){return super.copy(e),this.currentPoint.copy(e.currentPoint),this}toJSON(){let e=super.toJSON();return e.currentPoint=this.currentPoint.toArray(),e}fromJSON(e){return super.fromJSON(e),this.currentPoint.fromArray(e.currentPoint),this}},qr=class extends da{constructor(e){super(e),this.uuid=Kn(),this.type="Shape",this.holes=[]}getPointsHoles(e){let t=[];for(let n=0,s=this.holes.length;n<s;n++)t[n]=this.holes[n].getPoints(e);return t}extractPoints(e){return{shape:this.getPoints(e),holes:this.getPointsHoles(e)}}copy(e){super.copy(e),this.holes=[];for(let t=0,n=e.holes.length;t<n;t++){let s=e.holes[t];this.holes.push(s.clone())}return this}toJSON(){let e=super.toJSON();e.uuid=this.uuid,e.holes=[];for(let t=0,n=this.holes.length;t<n;t++){let s=this.holes[t];e.holes.push(s.toJSON())}return e}fromJSON(e){super.fromJSON(e),this.uuid=e.uuid,this.holes=[];for(let t=0,n=e.holes.length;t<n;t++){let s=e.holes[t];this.holes.push(new da().fromJSON(s))}return this}};function P_(i,e,t=2){let n=e&&e.length,s=n?e[0]*t:i.length,r=Sg(i,0,s,t,!0),o=[];if(!r||r.next===r.prev)return o;let a,c,l;if(n&&(r=U_(i,e,r,t)),i.length>80*t){a=i[0],c=i[1];let u=a,h=c;for(let f=t;f<s;f+=t){let d=i[f],m=i[f+1];d<a&&(a=d),m<c&&(c=m),d>u&&(u=d),m>h&&(h=m)}l=Math.max(u-a,h-c),l=l!==0?32767/l:0}return pa(r,o,t,a,c,l,0),o}function Sg(i,e,t,n,s){let r;if(s===q_(i,e,t,n)>0)for(let o=e;o<t;o+=n)r=bm(o/n|0,i[o],i[o+1],r);else for(let o=t-n;o>=e;o-=n)r=bm(o/n|0,i[o],i[o+1],r);return r&&Yr(r,r.next)&&(ga(r),r=r.next),r}function Vs(i,e){if(!i)return i;e||(e=i);let t=i,n;do if(n=!1,!t.steiner&&(Yr(t,t.next)||Ot(t.prev,t,t.next)===0)){if(ga(t),t=e=t.prev,t===t.next)break;n=!0}else t=t.next;while(n||t!==e);return e}function pa(i,e,t,n,s,r,o){if(!i)return;!o&&r&&k_(i,n,s,r);let a=i;for(;i.prev!==i.next;){let c=i.prev,l=i.next;if(r?L_(i,n,s,r):I_(i)){e.push(c.i,i.i,l.i),ga(i),i=l.next,a=l.next;continue}if(i=l,i===a){o?o===1?(i=N_(Vs(i),e),pa(i,e,t,n,s,r,2)):o===2&&D_(i,e,t,n,s,r):pa(Vs(i),e,t,n,s,r,1);break}}}function I_(i){let e=i.prev,t=i,n=i.next;if(Ot(e,t,n)>=0)return!1;let s=e.x,r=t.x,o=n.x,a=e.y,c=t.y,l=n.y,u=Math.min(s,r,o),h=Math.min(a,c,l),f=Math.max(s,r,o),d=Math.max(a,c,l),m=n.next;for(;m!==e;){if(m.x>=u&&m.x<=f&&m.y>=h&&m.y<=d&&Ho(s,a,r,c,o,l,m.x,m.y)&&Ot(m.prev,m,m.next)>=0)return!1;m=m.next}return!0}function L_(i,e,t,n){let s=i.prev,r=i,o=i.next;if(Ot(s,r,o)>=0)return!1;let a=s.x,c=r.x,l=o.x,u=s.y,h=r.y,f=o.y,d=Math.min(a,c,l),m=Math.min(u,h,f),x=Math.max(a,c,l),g=Math.max(u,h,f),p=ef(d,m,e,t,n),v=ef(x,g,e,t,n),b=i.prevZ,_=i.nextZ;for(;b&&b.z>=p&&_&&_.z<=v;){if(b.x>=d&&b.x<=x&&b.y>=m&&b.y<=g&&b!==s&&b!==o&&Ho(a,u,c,h,l,f,b.x,b.y)&&Ot(b.prev,b,b.next)>=0||(b=b.prevZ,_.x>=d&&_.x<=x&&_.y>=m&&_.y<=g&&_!==s&&_!==o&&Ho(a,u,c,h,l,f,_.x,_.y)&&Ot(_.prev,_,_.next)>=0))return!1;_=_.nextZ}for(;b&&b.z>=p;){if(b.x>=d&&b.x<=x&&b.y>=m&&b.y<=g&&b!==s&&b!==o&&Ho(a,u,c,h,l,f,b.x,b.y)&&Ot(b.prev,b,b.next)>=0)return!1;b=b.prevZ}for(;_&&_.z<=v;){if(_.x>=d&&_.x<=x&&_.y>=m&&_.y<=g&&_!==s&&_!==o&&Ho(a,u,c,h,l,f,_.x,_.y)&&Ot(_.prev,_,_.next)>=0)return!1;_=_.nextZ}return!0}function N_(i,e){let t=i;do{let n=t.prev,s=t.next.next;!Yr(n,s)&&Mg(n,t,t.next,s)&&ma(n,s)&&ma(s,n)&&(e.push(n.i,t.i,s.i),ga(t),ga(t.next),t=i=s),t=t.next}while(t!==i);return Vs(t)}function D_(i,e,t,n,s,r){let o=i;do{let a=o.next.next;for(;a!==o.prev;){if(o.i!==a.i&&G_(o,a)){let c=Tg(o,a);o=Vs(o,o.next),c=Vs(c,c.next),pa(o,e,t,n,s,r,0),pa(c,e,t,n,s,r,0);return}a=a.next}o=o.next}while(o!==i)}function U_(i,e,t,n){let s=[];for(let r=0,o=e.length;r<o;r++){let a=e[r]*n,c=r<o-1?e[r+1]*n:i.length,l=Sg(i,a,c,n,!1);l===l.next&&(l.steiner=!0),s.push(H_(l))}s.sort(F_);for(let r=0;r<s.length;r++)t=O_(s[r],t);return t}function F_(i,e){let t=i.x-e.x;if(t===0&&(t=i.y-e.y,t===0)){let n=(i.next.y-i.y)/(i.next.x-i.x),s=(e.next.y-e.y)/(e.next.x-e.x);t=n-s}return t}function O_(i,e){let t=B_(i,e);if(!t)return e;let n=Tg(t,i);return Vs(n,n.next),Vs(t,t.next)}function B_(i,e){let t=e,n=i.x,s=i.y,r=-1/0,o;if(Yr(i,t))return t;do{if(Yr(i,t.next))return t.next;if(s<=t.y&&s>=t.next.y&&t.next.y!==t.y){let h=t.x+(s-t.y)*(t.next.x-t.x)/(t.next.y-t.y);if(h<=n&&h>r&&(r=h,o=t.x<t.next.x?t:t.next,h===n))return o}t=t.next}while(t!==e);if(!o)return null;let a=o,c=o.x,l=o.y,u=1/0;t=o;do{if(n>=t.x&&t.x>=c&&n!==t.x&&bg(s<l?n:r,s,c,l,s<l?r:n,s,t.x,t.y)){let h=Math.abs(s-t.y)/(n-t.x);ma(t,i)&&(h<u||h===u&&(t.x>o.x||t.x===o.x&&z_(o,t)))&&(o=t,u=h)}t=t.next}while(t!==a);return o}function z_(i,e){return Ot(i.prev,i,e.prev)<0&&Ot(e.next,i,i.next)<0}function k_(i,e,t,n){let s=i;do s.z===0&&(s.z=ef(s.x,s.y,e,t,n)),s.prevZ=s.prev,s.nextZ=s.next,s=s.next;while(s!==i);s.prevZ.nextZ=null,s.prevZ=null,V_(s)}function V_(i){let e,t=1;do{let n=i,s;i=null;let r=null;for(e=0;n;){e++;let o=n,a=0;for(let l=0;l<t&&(a++,o=o.nextZ,!!o);l++);let c=t;for(;a>0||c>0&&o;)a!==0&&(c===0||!o||n.z<=o.z)?(s=n,n=n.nextZ,a--):(s=o,o=o.nextZ,c--),r?r.nextZ=s:i=s,s.prevZ=r,r=s;n=o}r.nextZ=null,t*=2}while(e>1);return i}function ef(i,e,t,n,s){return i=(i-t)*s|0,e=(e-n)*s|0,i=(i|i<<8)&16711935,i=(i|i<<4)&252645135,i=(i|i<<2)&858993459,i=(i|i<<1)&1431655765,e=(e|e<<8)&16711935,e=(e|e<<4)&252645135,e=(e|e<<2)&858993459,e=(e|e<<1)&1431655765,i|e<<1}function H_(i){let e=i,t=i;do(e.x<t.x||e.x===t.x&&e.y<t.y)&&(t=e),e=e.next;while(e!==i);return t}function bg(i,e,t,n,s,r,o,a){return(s-o)*(e-a)>=(i-o)*(r-a)&&(i-o)*(n-a)>=(t-o)*(e-a)&&(t-o)*(r-a)>=(s-o)*(n-a)}function Ho(i,e,t,n,s,r,o,a){return!(i===o&&e===a)&&bg(i,e,t,n,s,r,o,a)}function G_(i,e){return i.next.i!==e.i&&i.prev.i!==e.i&&!W_(i,e)&&(ma(i,e)&&ma(e,i)&&X_(i,e)&&(Ot(i.prev,i,e.prev)||Ot(i,e.prev,e))||Yr(i,e)&&Ot(i.prev,i,i.next)>0&&Ot(e.prev,e,e.next)>0)}function Ot(i,e,t){return(e.y-i.y)*(t.x-e.x)-(e.x-i.x)*(t.y-e.y)}function Yr(i,e){return i.x===e.x&&i.y===e.y}function Mg(i,e,t,n){let s=kc(Ot(i,e,t)),r=kc(Ot(i,e,n)),o=kc(Ot(t,n,i)),a=kc(Ot(t,n,e));return!!(s!==r&&o!==a||s===0&&zc(i,t,e)||r===0&&zc(i,n,e)||o===0&&zc(t,i,n)||a===0&&zc(t,e,n))}function zc(i,e,t){return e.x<=Math.max(i.x,t.x)&&e.x>=Math.min(i.x,t.x)&&e.y<=Math.max(i.y,t.y)&&e.y>=Math.min(i.y,t.y)}function kc(i){return i>0?1:i<0?-1:0}function W_(i,e){let t=i;do{if(t.i!==i.i&&t.next.i!==i.i&&t.i!==e.i&&t.next.i!==e.i&&Mg(t,t.next,i,e))return!0;t=t.next}while(t!==i);return!1}function ma(i,e){return Ot(i.prev,i,i.next)<0?Ot(i,e,i.next)>=0&&Ot(i,i.prev,e)>=0:Ot(i,e,i.prev)<0||Ot(i,i.next,e)<0}function X_(i,e){let t=i,n=!1,s=(i.x+e.x)/2,r=(i.y+e.y)/2;do t.y>r!=t.next.y>r&&t.next.y!==t.y&&s<(t.next.x-t.x)*(r-t.y)/(t.next.y-t.y)+t.x&&(n=!n),t=t.next;while(t!==i);return n}function Tg(i,e){let t=tf(i.i,i.x,i.y),n=tf(e.i,e.x,e.y),s=i.next,r=e.prev;return i.next=e,e.prev=i,t.next=s,s.prev=t,n.next=t,t.prev=n,r.next=n,n.prev=r,n}function bm(i,e,t,n){let s=tf(i,e,t);return n?(s.next=n.next,s.prev=n,n.next.prev=s,n.next=s):(s.prev=s,s.next=s),s}function ga(i){i.next.prev=i.prev,i.prev.next=i.next,i.prevZ&&(i.prevZ.nextZ=i.nextZ),i.nextZ&&(i.nextZ.prevZ=i.prevZ)}function tf(i,e,t){return{i,x:e,y:t,prev:null,next:null,z:0,prevZ:null,nextZ:null,steiner:!1}}function q_(i,e,t,n){let s=0;for(let r=e,o=t-n;r<t;r+=n)s+=(i[o]-i[r])*(i[r+1]+i[o+1]),o=r;return s}var nf=class{static triangulate(e,t,n=2){return P_(e,t,n)}},Ns=class i{static area(e){let t=e.length,n=0;for(let s=t-1,r=0;r<t;s=r++)n+=e[s].x*e[r].y-e[r].x*e[s].y;return n*.5}static isClockWise(e){return i.area(e)<0}static triangulateShape(e,t){let n=[],s=[],r=[];Mm(e),Tm(n,e);let o=e.length;t.forEach(Mm);for(let c=0;c<t.length;c++)s.push(o),o+=t[c].length,Tm(n,t[c]);let a=nf.triangulate(n,s);for(let c=0;c<a.length;c+=3)r.push(a.slice(c,c+3));return r}};function Mm(i){let e=i.length;e>2&&i[e-1].equals(i[0])&&i.pop()}function Tm(i,e){for(let t=0;t<e.length;t++)i.push(e[t].x),i.push(e[t].y)}var xa=class i extends ht{constructor(e=new qr([new ce(.5,.5),new ce(-.5,.5),new ce(-.5,-.5),new ce(.5,-.5)]),t={}){super(),this.type="ExtrudeGeometry",this.parameters={shapes:e,options:t},e=Array.isArray(e)?e:[e];let n=this,s=[],r=[];for(let a=0,c=e.length;a<c;a++){let l=e[a];o(l)}this.setAttribute("position",new lt(s,3)),this.setAttribute("uv",new lt(r,2)),this.computeVertexNormals();function o(a){let c=[],l=t.curveSegments!==void 0?t.curveSegments:12,u=t.steps!==void 0?t.steps:1,h=t.depth!==void 0?t.depth:1,f=t.bevelEnabled!==void 0?t.bevelEnabled:!0,d=t.bevelThickness!==void 0?t.bevelThickness:.2,m=t.bevelSize!==void 0?t.bevelSize:d-.1,x=t.bevelOffset!==void 0?t.bevelOffset:0,g=t.bevelSegments!==void 0?t.bevelSegments:3,p=t.extrudePath,v=t.UVGenerator!==void 0?t.UVGenerator:Y_,b,_=!1,S,M,E,y;if(p){b=p.getSpacedPoints(u),_=!0,f=!1;let ne=p.isCatmullRomCurve3?p.closed:!1;S=p.computeFrenetFrames(u,ne),M=new I,E=new I,y=new I}f||(g=0,d=0,m=0,x=0);let w=a.extractPoints(l),A=w.shape,P=w.holes;if(!Ns.isClockWise(A)){A=A.reverse();for(let ne=0,F=P.length;ne<F;ne++){let V=P[ne];Ns.isClockWise(V)&&(P[ne]=V.reverse())}}function D(ne){let V=10000000000000001e-36,q=ne[0];for(let ie=1;ie<=ne.length;ie++){let le=ie%ne.length,ge=ne[le],he=ge.x-q.x,ze=ge.y-q.y,O=he*he+ze*ze,gt=Math.max(Math.abs(ge.x),Math.abs(ge.y),Math.abs(q.x),Math.abs(q.y)),rt=V*gt*gt;if(O<=rt){ne.splice(le,1),ie--;continue}q=ge}}D(A),P.forEach(D);let L=P.length,U=A;for(let ne=0;ne<L;ne++){let F=P[ne];A=A.concat(F)}function G(ne,F,V){return F||We("ExtrudeGeometry: vec does not exist"),ne.clone().addScaledVector(F,V)}let Z=A.length;function oe(ne,F,V){let q,ie,le,ge=ne.x-F.x,he=ne.y-F.y,ze=V.x-ne.x,O=V.y-ne.y,gt=ge*ge+he*he,rt=ge*O-he*ze;if(Math.abs(rt)>Number.EPSILON){let N=Math.sqrt(gt),T=Math.sqrt(ze*ze+O*O),H=F.x-he/N,Y=F.y+ge/N,Q=V.x-O/T,pe=V.y+ze/T,xe=((Q-H)*O-(pe-Y)*ze)/(ge*O-he*ze);q=H+ge*xe-ne.x,ie=Y+he*xe-ne.y;let ee=q*q+ie*ie;if(ee<=2)return new ce(q,ie);le=Math.sqrt(ee/2)}else{let N=!1;ge>Number.EPSILON?ze>Number.EPSILON&&(N=!0):ge<-Number.EPSILON?ze<-Number.EPSILON&&(N=!0):Math.sign(he)===Math.sign(O)&&(N=!0),N?(q=-he,ie=ge,le=Math.sqrt(gt)):(q=ge,ie=he,le=Math.sqrt(gt/2))}return new ce(q/le,ie/le)}let K=[];for(let ne=0,F=U.length,V=F-1,q=ne+1;ne<F;ne++,V++,q++)V===F&&(V=0),q===F&&(q=0),K[ne]=oe(U[ne],U[V],U[q]);let te=[],se,Re=K.concat();for(let ne=0,F=L;ne<F;ne++){let V=P[ne];se=[];for(let q=0,ie=V.length,le=ie-1,ge=q+1;q<ie;q++,le++,ge++)le===ie&&(le=0),ge===ie&&(ge=0),se[q]=oe(V[q],V[le],V[ge]);te.push(se),Re=Re.concat(se)}let Te;if(g===0)Te=Ns.triangulateShape(U,P);else{let ne=[],F=[];for(let V=0;V<g;V++){let q=V/g,ie=d*Math.cos(q*Math.PI/2),le=m*Math.sin(q*Math.PI/2)+x;for(let ge=0,he=U.length;ge<he;ge++){let ze=G(U[ge],K[ge],le);j(ze.x,ze.y,-ie),q===0&&ne.push(ze)}for(let ge=0,he=L;ge<he;ge++){let ze=P[ge];se=te[ge];let O=[];for(let gt=0,rt=ze.length;gt<rt;gt++){let N=G(ze[gt],se[gt],le);j(N.x,N.y,-ie),q===0&&O.push(N)}q===0&&F.push(O)}}Te=Ns.triangulateShape(ne,F)}let nt=Te.length,He=m+x;for(let ne=0;ne<Z;ne++){let F=f?G(A[ne],Re[ne],He):A[ne];_?(E.copy(S.normals[0]).multiplyScalar(F.x),M.copy(S.binormals[0]).multiplyScalar(F.y),y.copy(b[0]).add(E).add(M),j(y.x,y.y,y.z)):j(F.x,F.y,0)}for(let ne=1;ne<=u;ne++)for(let F=0;F<Z;F++){let V=f?G(A[F],Re[F],He):A[F];_?(E.copy(S.normals[ne]).multiplyScalar(V.x),M.copy(S.binormals[ne]).multiplyScalar(V.y),y.copy(b[ne]).add(E).add(M),j(y.x,y.y,y.z)):j(V.x,V.y,h/u*ne)}for(let ne=g-1;ne>=0;ne--){let F=ne/g,V=d*Math.cos(F*Math.PI/2),q=m*Math.sin(F*Math.PI/2)+x;for(let ie=0,le=U.length;ie<le;ie++){let ge=G(U[ie],K[ie],q);j(ge.x,ge.y,h+V)}for(let ie=0,le=P.length;ie<le;ie++){let ge=P[ie];se=te[ie];for(let he=0,ze=ge.length;he<ze;he++){let O=G(ge[he],se[he],q);_?j(O.x,O.y+b[u-1].y,b[u-1].x+V):j(O.x,O.y,h+V)}}}$e(),$();function $e(){let ne=s.length/3;if(f){let F=0,V=Z*F;for(let q=0;q<nt;q++){let ie=Te[q];me(ie[2]+V,ie[1]+V,ie[0]+V)}F=u+g*2,V=Z*F;for(let q=0;q<nt;q++){let ie=Te[q];me(ie[0]+V,ie[1]+V,ie[2]+V)}}else{for(let F=0;F<nt;F++){let V=Te[F];me(V[2],V[1],V[0])}for(let F=0;F<nt;F++){let V=Te[F];me(V[0]+Z*u,V[1]+Z*u,V[2]+Z*u)}}n.addGroup(ne,s.length/3-ne,0)}function $(){let ne=s.length/3,F=0;z(U,F),F+=U.length;for(let V=0,q=P.length;V<q;V++){let ie=P[V];z(ie,F),F+=ie.length}n.addGroup(ne,s.length/3-ne,1)}function z(ne,F){let V=ne.length;for(;--V>=0;){let q=V,ie=V-1;ie<0&&(ie=ne.length-1);for(let le=0,ge=u+g*2;le<ge;le++){let he=Z*le,ze=Z*(le+1),O=F+q+he,gt=F+ie+he,rt=F+ie+ze,N=F+q+ze;fe(O,gt,rt,N)}}}function j(ne,F,V){c.push(ne),c.push(F),c.push(V)}function me(ne,F,V){de(ne),de(F),de(V);let q=s.length/3,ie=v.generateTopUV(n,s,q-3,q-2,q-1);et(ie[0]),et(ie[1]),et(ie[2])}function fe(ne,F,V,q){de(ne),de(F),de(q),de(F),de(V),de(q);let ie=s.length/3,le=v.generateSideWallUV(n,s,ie-6,ie-3,ie-2,ie-1);et(le[0]),et(le[1]),et(le[3]),et(le[1]),et(le[2]),et(le[3])}function de(ne){s.push(c[ne*3+0]),s.push(c[ne*3+1]),s.push(c[ne*3+2])}function et(ne){r.push(ne.x),r.push(ne.y)}}}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}toJSON(){let e=super.toJSON(),t=this.parameters.shapes,n=this.parameters.options;return Z_(t,n,e)}static fromJSON(e,t){let n=[];for(let r=0,o=e.shapes.length;r<o;r++){let a=t[e.shapes[r]];n.push(a)}let s=e.options.extrudePath;return s!==void 0&&(e.options.extrudePath=new Qh[s.type]().fromJSON(s)),new i(n,e.options)}},Y_={generateTopUV:function(i,e,t,n,s){let r=e[t*3],o=e[t*3+1],a=e[n*3],c=e[n*3+1],l=e[s*3],u=e[s*3+1];return[new ce(r,o),new ce(a,c),new ce(l,u)]},generateSideWallUV:function(i,e,t,n,s,r){let o=e[t*3],a=e[t*3+1],c=e[t*3+2],l=e[n*3],u=e[n*3+1],h=e[n*3+2],f=e[s*3],d=e[s*3+1],m=e[s*3+2],x=e[r*3],g=e[r*3+1],p=e[r*3+2];return Math.abs(a-u)<Math.abs(o-l)?[new ce(o,1-c),new ce(l,1-h),new ce(f,1-m),new ce(x,1-p)]:[new ce(a,1-c),new ce(u,1-h),new ce(d,1-m),new ce(g,1-p)]}};function Z_(i,e,t){if(t.shapes=[],Array.isArray(i))for(let n=0,s=i.length;n<s;n++){let r=i[n];t.shapes.push(r.uuid)}else t.shapes.push(i.uuid);return t.options=Object.assign({},e),e.extrudePath!==void 0&&(t.options.extrudePath=e.extrudePath.toJSON()),t}var _a=class i extends ht{constructor(e=1,t=1,n=1,s=1){super(),this.type="PlaneGeometry",this.parameters={width:e,height:t,widthSegments:n,heightSegments:s};let r=e/2,o=t/2,a=Math.floor(n),c=Math.floor(s),l=a+1,u=c+1,h=e/a,f=t/c,d=[],m=[],x=[],g=[];for(let p=0;p<u;p++){let v=p*f-o;for(let b=0;b<l;b++){let _=b*h-r;m.push(_,-v,0),x.push(0,0,1),g.push(b/a),g.push(1-p/c)}}for(let p=0;p<c;p++)for(let v=0;v<a;v++){let b=v+l*p,_=v+l*(p+1),S=v+1+l*(p+1),M=v+1+l*p;d.push(b,_,M),d.push(_,S,M)}this.setIndex(d),this.setAttribute("position",new lt(m,3)),this.setAttribute("normal",new lt(x,3)),this.setAttribute("uv",new lt(g,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.width,e.height,e.widthSegments,e.heightSegments)}};var ya=class i extends ht{constructor(e=1,t=32,n=16,s=0,r=Math.PI*2,o=0,a=Math.PI){super(),this.type="SphereGeometry",this.parameters={radius:e,widthSegments:t,heightSegments:n,phiStart:s,phiLength:r,thetaStart:o,thetaLength:a},t=Math.max(3,Math.floor(t)),n=Math.max(2,Math.floor(n));let c=Math.min(o+a,Math.PI),l=0,u=[],h=new I,f=new I,d=[],m=[],x=[],g=[];for(let p=0;p<=n;p++){let v=[],b=p/n,_=o+b*a,S=e*Math.cos(_),M=Math.sqrt(e*e-S*S),E=0;p===0&&o===0?E=.5/t:p===n&&c===Math.PI&&(E=-.5/t);for(let y=0;y<=t;y++){let w=y/t,A=s+w*r;h.x=-M*Math.cos(A),h.y=S,h.z=M*Math.sin(A),m.push(h.x,h.y,h.z),f.copy(h).normalize(),x.push(f.x,f.y,f.z),g.push(w+E,1-b),v.push(l++)}u.push(v)}for(let p=0;p<n;p++)for(let v=0;v<t;v++){let b=u[p][v+1],_=u[p][v],S=u[p+1][v],M=u[p+1][v+1];(p!==0||o>0)&&d.push(b,_,M),(p!==n-1||c<Math.PI)&&d.push(_,S,M)}this.setIndex(d),this.setAttribute("position",new lt(m,3)),this.setAttribute("normal",new lt(x,3)),this.setAttribute("uv",new lt(g,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.radius,e.widthSegments,e.heightSegments,e.phiStart,e.phiLength,e.thetaStart,e.thetaLength)}};var va=class i extends ht{constructor(e=1,t=.4,n=12,s=48,r=Math.PI*2,o=0,a=Math.PI*2){super(),this.type="TorusGeometry",this.parameters={radius:e,tube:t,radialSegments:n,tubularSegments:s,arc:r,thetaStart:o,thetaLength:a},n=Math.floor(n),s=Math.floor(s);let c=[],l=[],u=[],h=[],f=new I,d=new I,m=new I;for(let x=0;x<=n;x++){let g=o+x/n*a;for(let p=0;p<=s;p++){let v=p/s*r;d.x=(e+t*Math.cos(g))*Math.cos(v),d.y=(e+t*Math.cos(g))*Math.sin(v),d.z=t*Math.sin(g),l.push(d.x,d.y,d.z),f.x=e*Math.cos(v),f.y=e*Math.sin(v),m.subVectors(d,f).normalize(),u.push(m.x,m.y,m.z),h.push(p/s),h.push(x/n)}}for(let x=1;x<=n;x++)for(let g=1;g<=s;g++){let p=(s+1)*x+g-1,v=(s+1)*(x-1)+g-1,b=(s+1)*(x-1)+g,_=(s+1)*x+g;c.push(p,v,_),c.push(v,b,_)}this.setIndex(c),this.setAttribute("position",new lt(l,3)),this.setAttribute("normal",new lt(u,3)),this.setAttribute("uv",new lt(h,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.radius,e.tube,e.radialSegments,e.tubularSegments,e.arc,e.thetaStart,e.thetaLength)}};function Ks(i){let e={};for(let t in i){e[t]={};for(let n in i[t]){let s=i[t][n];if(wm(s))s.isRenderTargetTexture?(Fe("UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms()."),e[t][n]=null):e[t][n]=s.clone();else if(Array.isArray(s))if(wm(s[0])){let r=[];for(let o=0,a=s.length;o<a;o++)r[o]=s[o].clone();e[t][n]=r}else e[t][n]=s.slice();else e[t][n]=s}}return e}function mn(i){let e={};for(let t=0;t<i.length;t++){let n=Ks(i[t]);for(let s in n)e[s]=n[s]}return e}function wm(i){return i&&(i.isColor||i.isMatrix3||i.isMatrix4||i.isVector2||i.isVector3||i.isVector4||i.isTexture||i.isQuaternion)}function K_(i){let e=[];for(let t=0;t<i.length;t++)e.push(i[t].clone());return e}function Ff(i){let e=i.getRenderTarget();return e===null?i.outputColorSpace:e.isXRRenderTarget===!0?e.texture.colorSpace:tt.workingColorSpace}var mu={clone:Ks,merge:mn},J_=`void main() {
	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}`,$_=`void main() {
	gl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );
}`,ln=class extends Mn{constructor(e){super(),this.isShaderMaterial=!0,this.type="ShaderMaterial",this.defines={},this.uniforms={},this.uniformsGroups=[],this.vertexShader=J_,this.fragmentShader=$_,this.linewidth=1,this.wireframe=!1,this.wireframeLinewidth=1,this.fog=!1,this.lights=!1,this.clipping=!1,this.forceSinglePass=!0,this.extensions={clipCullDistance:!1,multiDraw:!1},this.defaultAttributeValues={color:[1,1,1],uv:[0,0],uv1:[0,0]},this.index0AttributeName=void 0,this.uniformsNeedUpdate=!1,this.glslVersion=null,e!==void 0&&this.setValues(e)}copy(e){return super.copy(e),this.fragmentShader=e.fragmentShader,this.vertexShader=e.vertexShader,this.uniforms=Ks(e.uniforms),this.uniformsGroups=K_(e.uniformsGroups),this.defines=Object.assign({},e.defines),this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this.fog=e.fog,this.lights=e.lights,this.clipping=e.clipping,this.extensions=Object.assign({},e.extensions),this.glslVersion=e.glslVersion,this.defaultAttributeValues=Object.assign({},e.defaultAttributeValues),this.index0AttributeName=e.index0AttributeName,this.uniformsNeedUpdate=e.uniformsNeedUpdate,this}toJSON(e){let t=super.toJSON(e);t.glslVersion=this.glslVersion,t.uniforms={};for(let s in this.uniforms){let o=this.uniforms[s].value;o&&o.isTexture?t.uniforms[s]={type:"t",value:o.toJSON(e).uuid}:o&&o.isColor?t.uniforms[s]={type:"c",value:o.getHex()}:o&&o.isVector2?t.uniforms[s]={type:"v2",value:o.toArray()}:o&&o.isVector3?t.uniforms[s]={type:"v3",value:o.toArray()}:o&&o.isVector4?t.uniforms[s]={type:"v4",value:o.toArray()}:o&&o.isMatrix3?t.uniforms[s]={type:"m3",value:o.toArray()}:o&&o.isMatrix4?t.uniforms[s]={type:"m4",value:o.toArray()}:t.uniforms[s]={value:o}}Object.keys(this.defines).length>0&&(t.defines=this.defines),t.vertexShader=this.vertexShader,t.fragmentShader=this.fragmentShader,t.lights=this.lights,t.clipping=this.clipping;let n={};for(let s in this.extensions)this.extensions[s]===!0&&(n[s]=!0);return Object.keys(n).length>0&&(t.extensions=n),t}fromJSON(e,t){if(super.fromJSON(e,t),e.uniforms!==void 0)for(let n in e.uniforms){let s=e.uniforms[n];switch(this.uniforms[n]={},s.type){case"t":this.uniforms[n].value=t[s.value]||null;break;case"c":this.uniforms[n].value=new Ve().setHex(s.value);break;case"v2":this.uniforms[n].value=new ce().fromArray(s.value);break;case"v3":this.uniforms[n].value=new I().fromArray(s.value);break;case"v4":this.uniforms[n].value=new ut().fromArray(s.value);break;case"m3":this.uniforms[n].value=new Ye().fromArray(s.value);break;case"m4":this.uniforms[n].value=new Ie().fromArray(s.value);break;default:this.uniforms[n].value=s.value}}if(e.defines!==void 0&&(this.defines=e.defines),e.vertexShader!==void 0&&(this.vertexShader=e.vertexShader),e.fragmentShader!==void 0&&(this.fragmentShader=e.fragmentShader),e.glslVersion!==void 0&&(this.glslVersion=e.glslVersion),e.extensions!==void 0)for(let n in e.extensions)this.extensions[n]=e.extensions[n];return e.lights!==void 0&&(this.lights=e.lights),e.clipping!==void 0&&(this.clipping=e.clipping),this}},fl=class extends ln{constructor(e){super(e),this.isRawShaderMaterial=!0,this.type="RawShaderMaterial"}},$t=class extends Mn{constructor(e){super(),this.isMeshStandardMaterial=!0,this.type="MeshStandardMaterial",this.defines={STANDARD:""},this.color=new Ve(16777215),this.roughness=1,this.metalness=0,this.map=null,this.lightMap=null,this.lightMapIntensity=1,this.aoMap=null,this.aoMapIntensity=1,this.emissive=new Ve(0),this.emissiveIntensity=1,this.emissiveMap=null,this.bumpMap=null,this.bumpScale=1,this.normalMap=null,this.normalMapType=fu,this.normalScale=new ce(1,1),this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.roughnessMap=null,this.metalnessMap=null,this.alphaMap=null,this.envMap=null,this.envMapRotation=new Oi,this.envMapIntensity=1,this.wireframe=!1,this.wireframeLinewidth=1,this.wireframeLinecap="round",this.wireframeLinejoin="round",this.flatShading=!1,this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.defines={STANDARD:""},this.color.copy(e.color),this.roughness=e.roughness,this.metalness=e.metalness,this.map=e.map,this.lightMap=e.lightMap,this.lightMapIntensity=e.lightMapIntensity,this.aoMap=e.aoMap,this.aoMapIntensity=e.aoMapIntensity,this.emissive.copy(e.emissive),this.emissiveMap=e.emissiveMap,this.emissiveIntensity=e.emissiveIntensity,this.bumpMap=e.bumpMap,this.bumpScale=e.bumpScale,this.normalMap=e.normalMap,this.normalMapType=e.normalMapType,this.normalScale.copy(e.normalScale),this.displacementMap=e.displacementMap,this.displacementScale=e.displacementScale,this.displacementBias=e.displacementBias,this.roughnessMap=e.roughnessMap,this.metalnessMap=e.metalnessMap,this.alphaMap=e.alphaMap,this.envMap=e.envMap,this.envMapRotation.copy(e.envMapRotation),this.envMapIntensity=e.envMapIntensity,this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this.wireframeLinecap=e.wireframeLinecap,this.wireframeLinejoin=e.wireframeLinejoin,this.flatShading=e.flatShading,this.fog=e.fog,this}},Ln=class extends $t{constructor(e){super(),this.isMeshPhysicalMaterial=!0,this.defines={STANDARD:"",PHYSICAL:""},this.type="MeshPhysicalMaterial",this.anisotropyRotation=0,this.anisotropyMap=null,this.clearcoatMap=null,this.clearcoatRoughness=0,this.clearcoatRoughnessMap=null,this.clearcoatNormalScale=new ce(1,1),this.clearcoatNormalMap=null,this.ior=1.5,Object.defineProperty(this,"reflectivity",{get:function(){return qe(2.5*(this.ior-1)/(this.ior+1),0,1)},set:function(t){this.ior=(1+.4*t)/(1-.4*t)}}),this.iridescenceMap=null,this.iridescenceIOR=1.3,this.iridescenceThicknessRange=[100,400],this.iridescenceThicknessMap=null,this.sheenColor=new Ve(0),this.sheenColorMap=null,this.sheenRoughness=1,this.sheenRoughnessMap=null,this.transmissionMap=null,this.thickness=0,this.thicknessMap=null,this.attenuationDistance=1/0,this.attenuationColor=new Ve(1,1,1),this.specularIntensity=1,this.specularIntensityMap=null,this.specularColor=new Ve(1,1,1),this.specularColorMap=null,this._anisotropy=0,this._clearcoat=0,this._dispersion=0,this._iridescence=0,this._retroreflectivity=0,this._sheen=0,this._transmission=0,this.setValues(e)}get anisotropy(){return this._anisotropy}set anisotropy(e){this._anisotropy>0!=e>0&&this.version++,this._anisotropy=e}get clearcoat(){return this._clearcoat}set clearcoat(e){this._clearcoat>0!=e>0&&this.version++,this._clearcoat=e}get iridescence(){return this._iridescence}set iridescence(e){this._iridescence>0!=e>0&&this.version++,this._iridescence=e}get dispersion(){return this._dispersion}set dispersion(e){this._dispersion>0!=e>0&&this.version++,this._dispersion=e}get retroreflectivity(){return this._retroreflectivity}set retroreflectivity(e){this._retroreflectivity>0!=e>0&&this.version++,this._retroreflectivity=e}get sheen(){return this._sheen}set sheen(e){this._sheen>0!=e>0&&this.version++,this._sheen=e}get transmission(){return this._transmission}set transmission(e){this._transmission>0!=e>0&&this.version++,this._transmission=e}copy(e){return super.copy(e),this.defines={STANDARD:"",PHYSICAL:""},this.anisotropy=e.anisotropy,this.anisotropyRotation=e.anisotropyRotation,this.anisotropyMap=e.anisotropyMap,this.clearcoat=e.clearcoat,this.clearcoatMap=e.clearcoatMap,this.clearcoatRoughness=e.clearcoatRoughness,this.clearcoatRoughnessMap=e.clearcoatRoughnessMap,this.clearcoatNormalMap=e.clearcoatNormalMap,this.clearcoatNormalScale.copy(e.clearcoatNormalScale),this.dispersion=e.dispersion,this.ior=e.ior,this.iridescence=e.iridescence,this.iridescenceMap=e.iridescenceMap,this.iridescenceIOR=e.iridescenceIOR,this.iridescenceThicknessRange=[...e.iridescenceThicknessRange],this.iridescenceThicknessMap=e.iridescenceThicknessMap,this.retroreflectivity=e.retroreflectivity,this.sheen=e.sheen,this.sheenColor.copy(e.sheenColor),this.sheenColorMap=e.sheenColorMap,this.sheenRoughness=e.sheenRoughness,this.sheenRoughnessMap=e.sheenRoughnessMap,this.transmission=e.transmission,this.transmissionMap=e.transmissionMap,this.thickness=e.thickness,this.thicknessMap=e.thicknessMap,this.attenuationDistance=e.attenuationDistance,this.attenuationColor.copy(e.attenuationColor),this.specularIntensity=e.specularIntensity,this.specularIntensityMap=e.specularIntensityMap,this.specularColor.copy(e.specularColor),this.specularColorMap=e.specularColorMap,this}};var dl=class extends Mn{constructor(e){super(),this.isMeshDepthMaterial=!0,this.type="MeshDepthMaterial",this.depthPacking=og,this.map=null,this.alphaMap=null,this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.wireframe=!1,this.wireframeLinewidth=1,this.setValues(e)}copy(e){return super.copy(e),this.depthPacking=e.depthPacking,this.map=e.map,this.alphaMap=e.alphaMap,this.displacementMap=e.displacementMap,this.displacementScale=e.displacementScale,this.displacementBias=e.displacementBias,this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this}},pl=class extends Mn{constructor(e){super(),this.isMeshDistanceMaterial=!0,this.type="MeshDistanceMaterial",this.map=null,this.alphaMap=null,this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.setValues(e)}copy(e){return super.copy(e),this.map=e.map,this.alphaMap=e.alphaMap,this.displacementMap=e.displacementMap,this.displacementScale=e.displacementScale,this.displacementBias=e.displacementBias,this}};function as(i,e){return!i||i.constructor===e?i:typeof e.BYTES_PER_ELEMENT=="number"?new e(i):Array.prototype.slice.call(i)}function qc(i){return i!==void 0&&i.inTangents!==void 0&&i.outTangents!==void 0}function j_(i){function e(s,r){return i[s]-i[r]}let t=i.length,n=new Array(t);for(let s=0;s!==t;++s)n[s]=s;return n.sort(e),n}function Em(i,e,t){let n=i.length,s=new i.constructor(n);for(let r=0,o=0;o!==n;++r){let a=t[r]*e;for(let c=0;c!==e;++c)s[o++]=i[a+c]}return s}function Q_(i,e,t,n){let s=1,r=i[0];for(;r!==void 0&&r[n]===void 0;)r=i[s++];if(r===void 0)return;let o=r[n];if(o!==void 0)if(Array.isArray(o))do o=r[n],o!==void 0&&(e.push(r.time),t.push(...o)),r=i[s++];while(r!==void 0);else if(o.toArray!==void 0)do o=r[n],o!==void 0&&(e.push(r.time),o.toArray(t,t.length)),r=i[s++];while(r!==void 0);else do o=r[n],o!==void 0&&(e.push(r.time),t.push(o)),r=i[s++];while(r!==void 0)}var yi=class{constructor(e,t,n,s){this.parameterPositions=e,this._cachedIndex=0,this.resultBuffer=s!==void 0?s:new t.constructor(n),this.sampleValues=t,this.valueSize=n,this.settings=null,this.DefaultSettings_={}}evaluate(e){let t=this.parameterPositions,n=this._cachedIndex,s=t[n],r=t[n-1];n:{e:{let o;t:{i:if(!(e<s)){for(let a=n+2;;){if(s===void 0){if(e<r)break i;return n=t.length,this._cachedIndex=n,this.copySampleValue_(n-1)}if(n===a)break;if(r=s,s=t[++n],e<s)break e}o=t.length;break t}if(!(e>=r)){let a=t[1];e<a&&(n=2,r=a);for(let c=n-2;;){if(r===void 0)return this._cachedIndex=0,this.copySampleValue_(0);if(n===c)break;if(s=r,r=t[--n-1],e>=r)break e}o=n,n=0;break t}break n}for(;n<o;){let a=n+o>>>1;e<t[a]?o=a:n=a+1}if(s=t[n],r=t[n-1],r===void 0)return this._cachedIndex=0,this.copySampleValue_(0);if(s===void 0)return n=t.length,this._cachedIndex=n,this.copySampleValue_(n-1)}this._cachedIndex=n,this.intervalChanged_(n,r,s)}return this.interpolate_(n,r,e,s)}getSettings_(){return this.settings||this.DefaultSettings_}copySampleValue_(e){let t=this.resultBuffer,n=this.sampleValues,s=this.valueSize,r=e*s;for(let o=0;o!==s;++o)t[o]=n[r+o];return t}interpolate_(){throw new Error("THREE.Interpolant: Call to abstract method.")}intervalChanged_(){}},ml=class extends yi{constructor(e,t,n,s){super(e,t,n,s),this._weightPrev=-0,this._offsetPrev=-0,this._weightNext=-0,this._offsetNext=-0,this.DefaultSettings_={endingStart:Kh,endingEnd:Kh}}intervalChanged_(e,t,n){let s=this.parameterPositions,r=e-2,o=e+1,a=s[r],c=s[o];if(a===void 0)switch(this.getSettings_().endingStart){case Jh:r=e,a=2*t-n;break;case $h:r=s.length-2,a=t+s[r]-s[r+1];break;default:r=e,a=n}if(c===void 0)switch(this.getSettings_().endingEnd){case Jh:o=e,c=2*n-t;break;case $h:o=1,c=n+s[1]-s[0];break;default:o=e-1,c=t}let l=(n-t)*.5,u=this.valueSize;this._weightPrev=l/(t-a),this._weightNext=l/(c-n),this._offsetPrev=r*u,this._offsetNext=o*u}interpolate_(e,t,n,s){let r=this.resultBuffer,o=this.sampleValues,a=this.valueSize,c=e*a,l=c-a,u=this._offsetPrev,h=this._offsetNext,f=this._weightPrev,d=this._weightNext,m=(n-t)/(s-t),x=m*m,g=x*m,p=-f*g+2*f*x-f*m,v=(1+f)*g+(-1.5-2*f)*x+(-.5+f)*m+1,b=(-1-d)*g+(1.5+d)*x+.5*m,_=d*g-d*x;for(let S=0;S!==a;++S)r[S]=p*o[u+S]+v*o[l+S]+b*o[c+S]+_*o[h+S];return r}},gl=class extends yi{constructor(e,t,n,s){super(e,t,n,s)}interpolate_(e,t,n,s){let r=this.resultBuffer,o=this.sampleValues,a=this.valueSize,c=e*a,l=c-a,u=(n-t)/(s-t),h=1-u;for(let f=0;f!==a;++f)r[f]=o[l+f]*h+o[c+f]*u;return r}},xl=class extends yi{constructor(e,t,n,s){super(e,t,n,s)}interpolate_(e){return this.copySampleValue_(e-1)}},_l=class extends yi{interpolate_(e,t,n,s){let r=this.resultBuffer,o=this.sampleValues,a=this.valueSize,c=e*a,l=c-a,u=this.inTangents,h=this.outTangents;if(!u||!h){let m=(n-t)/(s-t),x=1-m;for(let g=0;g!==a;++g)r[g]=o[l+g]*x+o[c+g]*m;return r}let f=a*2,d=e-1;for(let m=0;m!==a;++m){let x=o[l+m],g=o[c+m],p=d*f+m*2,v=h[p],b=h[p+1],_=e*f+m*2,S=u[_],M=u[_+1],E=ty(n,t,v,S,s);r[m]=wg(E,x,b,M,g)}return r}};function wg(i,e,t,n,s){let r=1-i;return r*r*r*e+3*r*r*i*t+3*r*i*i*n+i*i*i*s}function ey(i,e,t,n,s){let r=1-i;return 3*r*r*(t-e)+6*r*i*(n-t)+3*i*i*(s-n)}function ty(i,e,t,n,s){let r=(i-e)/(s-e);for(let o=0;o<8;o++){let a=wg(r,e,t,n,s)-i;if(Math.abs(a)<1e-10)break;let c=ey(r,e,t,n,s);if(Math.abs(c)<1e-10)break;r=Math.max(0,Math.min(1,r-a/c))}return r}var Nn=class{constructor(e,t,n,s){if(e===void 0)throw new Error("THREE.KeyframeTrack: track name is undefined");if(t===void 0||t.length===0)throw new Error("THREE.KeyframeTrack: no keyframes in track named "+e);this.name=e,this.times=as(t,this.TimeBufferType),this.values=as(n,this.ValueBufferType),this.setInterpolation(s||this.DefaultInterpolation)}static toJSON(e){let t=e.constructor,n;if(t.toJSON!==this.toJSON)n=t.toJSON(e);else{n={name:e.name,times:as(e.times,Array),values:as(e.values,Array)};let s=e.getInterpolation();s!==e.DefaultInterpolation&&(n.interpolation=s),qc(e.settings)&&(n.settings={inTangents:as(e.settings.inTangents,Array),outTangents:as(e.settings.outTangents,Array)})}return n.type=e.ValueTypeName,n}InterpolantFactoryMethodDiscrete(e){return new xl(this.times,this.values,this.getValueSize(),e)}InterpolantFactoryMethodLinear(e){return new gl(this.times,this.values,this.getValueSize(),e)}InterpolantFactoryMethodSmooth(e){return new ml(this.times,this.values,this.getValueSize(),e)}InterpolantFactoryMethodBezier(e){let t=new _l(this.times,this.values,this.getValueSize(),e);return this.settings&&(t.inTangents=this.settings.inTangents,t.outTangents=this.settings.outTangents),t}setInterpolation(e){let t;switch(e){case Us:t=this.InterpolantFactoryMethodDiscrete;break;case Fs:t=this.InterpolantFactoryMethodLinear;break;case Wc:t=this.InterpolantFactoryMethodSmooth;break;case Zh:t=this.InterpolantFactoryMethodBezier;break}if(t===void 0){let n="unsupported interpolation for "+this.ValueTypeName+" keyframe track named "+this.name;if(this.createInterpolant===void 0)if(e!==this.DefaultInterpolation)this.setInterpolation(this.DefaultInterpolation);else throw new Error(n);return Fe("KeyframeTrack:",n),this}return this.createInterpolant=t,this}getInterpolation(){switch(this.createInterpolant){case this.InterpolantFactoryMethodDiscrete:return Us;case this.InterpolantFactoryMethodLinear:return Fs;case this.InterpolantFactoryMethodSmooth:return Wc;case this.InterpolantFactoryMethodBezier:return Zh}}getValueSize(){return this.values.length/this.times.length}shift(e){if(e!==0){let t=this.times;for(let n=0,s=t.length;n!==s;++n)t[n]+=e}return this}scale(e){if(e!==1){let t=this.times;for(let n=0,s=t.length;n!==s;++n)t[n]*=e;qc(this.settings)&&(Am(this.settings.inTangents,e),Am(this.settings.outTangents,e))}return this}trim(e,t){let n=this.times,s=n.length,r=0,o=s-1;for(;r!==s&&n[r]<e;)++r;for(;o!==-1&&n[o]>t;)--o;if(++o,r!==0||o!==s){r>=o&&(o=Math.max(o,1),r=o-1);let a=this.getValueSize();this.times=n.slice(r,o),this.values=this.values.slice(r*a,o*a)}return this}validate(){let e=!0,t=this.getValueSize();t-Math.floor(t)!==0&&(We("KeyframeTrack: Invalid value size in track.",this),e=!1);let n=this.times,s=this.values,r=n.length;r===0&&(We("KeyframeTrack: Track is empty.",this),e=!1);let o=null;for(let a=0;a!==r;a++){let c=n[a];if(typeof c=="number"&&isNaN(c)){We("KeyframeTrack: Time is not a valid number.",this,a,c),e=!1;break}if(o!==null&&o>c){We("KeyframeTrack: Out of order keys.",this,a,c,o),e=!1;break}o=c}if(s!==void 0&&zx(s))for(let a=0,c=s.length;a!==c;++a){let l=s[a];if(isNaN(l)){We("KeyframeTrack: Value is not a valid number.",this,a,l),e=!1;break}}return e}optimize(){let e=this.times.slice(),t=this.values.slice(),n=this.getValueSize(),s=this.getInterpolation()===Wc,r=e.length-1,o=1;for(let a=1;a<r;++a){let c=!1,l=e[a],u=e[a+1];if(l!==u&&(a!==1||l!==e[0]))if(s)c=!0;else{let h=a*n,f=h-n,d=h+n;for(let m=0;m!==n;++m){let x=t[h+m];if(x!==t[f+m]||x!==t[d+m]){c=!0;break}}}if(c){if(a!==o){e[o]=e[a];let h=a*n,f=o*n;for(let d=0;d!==n;++d)t[f+d]=t[h+d]}++o}}if(r>0){e[o]=e[r];for(let a=r*n,c=o*n,l=0;l!==n;++l)t[c+l]=t[a+l];++o}return o!==e.length?(this.times=e.slice(0,o),this.values=t.slice(0,o*n)):(this.times=e,this.values=t),this}clone(){let e=this.times.slice(),t=this.values.slice(),n=this.constructor,s=new n(this.name,e,t);return s.createInterpolant=this.createInterpolant,qc(this.settings)&&(s.settings={inTangents:this.settings.inTangents.slice(),outTangents:this.settings.outTangents.slice()}),s}};function Am(i,e){for(let t=0,n=i.length;t!==n;t+=2)i[t]*=e}Nn.prototype.ValueTypeName="";Nn.prototype.TimeBufferType=Float32Array;Nn.prototype.ValueBufferType=Float32Array;Nn.prototype.DefaultInterpolation=Fs;var ki=class extends Nn{constructor(e,t,n){super(e,t,n)}};ki.prototype.ValueTypeName="bool";ki.prototype.ValueBufferType=Array;ki.prototype.DefaultInterpolation=Us;ki.prototype.InterpolantFactoryMethodLinear=void 0;ki.prototype.InterpolantFactoryMethodSmooth=void 0;var Sa=class extends Nn{constructor(e,t,n,s){super(e,t,n,s)}};Sa.prototype.ValueTypeName="color";var Vi=class extends Nn{constructor(e,t,n,s){super(e,t,n,s)}};Vi.prototype.ValueTypeName="number";var yl=class extends yi{constructor(e,t,n,s){super(e,t,n,s)}interpolate_(e,t,n,s){let r=this.resultBuffer,o=this.sampleValues,a=this.valueSize,c=(n-t)/(s-t),l=e*a;for(let u=l+a;l!==u;l+=4)pn.slerpFlat(r,0,o,l-a,o,l,c);return r}},Hi=class extends Nn{constructor(e,t,n,s){super(e,t,n,s)}InterpolantFactoryMethodLinear(e){return new yl(this.times,this.values,this.getValueSize(),e)}};Hi.prototype.ValueTypeName="quaternion";Hi.prototype.InterpolantFactoryMethodSmooth=void 0;var Gi=class extends Nn{constructor(e,t,n){super(e,t,n)}};Gi.prototype.ValueTypeName="string";Gi.prototype.ValueBufferType=Array;Gi.prototype.DefaultInterpolation=Us;Gi.prototype.InterpolantFactoryMethodLinear=void 0;Gi.prototype.InterpolantFactoryMethodSmooth=void 0;var ds=class extends Nn{constructor(e,t,n,s){super(e,t,n,s)}};ds.prototype.ValueTypeName="vector";var ba=class{constructor(e="",t=-1,n=[],s=rg){this.name=e,this.tracks=n,this.duration=t,this.blendMode=s,this.uuid=Kn(),this.userData={},this.duration<0&&this.resetDuration()}static parse(e){let t=[],n=e.tracks,s=1/(e.fps||1);for(let o=0,a=n.length;o!==a;++o)t.push(iy(n[o]).scale(s));let r=new this(e.name,e.duration,t,e.blendMode);return r.uuid=e.uuid,r.userData=JSON.parse(e.userData||"{}"),r}static toJSON(e){let t=[],n=e.tracks,s={name:e.name,duration:e.duration,tracks:t,uuid:e.uuid,blendMode:e.blendMode,userData:JSON.stringify(e.userData)};for(let r=0,o=n.length;r!==o;++r)t.push(Nn.toJSON(n[r]));return s}static CreateFromMorphTargetSequence(e,t,n,s){let r=t.length,o=[];for(let a=0;a<r;a++){let c=[],l=[];c.push((a+r-1)%r,a,(a+1)%r),l.push(0,1,0);let u=j_(c);c=Em(c,1,u),l=Em(l,1,u),!s&&c[0]===0&&(c.push(r),l.push(l[0])),o.push(new Vi(".morphTargetInfluences["+t[a].name+"]",c,l).scale(1/n))}return new this(e,-1,o)}static findByName(e,t){let n=e;if(!Array.isArray(e)){let s=e;n=s.geometry&&s.geometry.animations||s.animations}for(let s=0;s<n.length;s++)if(n[s].name===t)return n[s];return null}static CreateClipsFromMorphTargetSequences(e,t,n){let s={},r=/^([\w-]*?)([\d]+)$/;for(let a=0,c=e.length;a<c;a++){let l=e[a],u=l.name.match(r);if(u&&u.length>1){let h=u[1],f=s[h];f||(s[h]=f=[]),f.push(l)}}let o=[];for(let a in s)o.push(this.CreateFromMorphTargetSequence(a,s[a],t,n));return o}resetDuration(){let e=this.tracks,t=0;for(let n=0,s=e.length;n!==s;++n){let r=this.tracks[n];t=Math.max(t,r.times[r.times.length-1])}return this.duration=t,this}trim(){for(let e=0;e<this.tracks.length;e++)this.tracks[e].trim(0,this.duration);return this}validate(){let e=!0;for(let t=0;t<this.tracks.length;t++)e=e&&this.tracks[t].validate();return e}optimize(){for(let e=0;e<this.tracks.length;e++)this.tracks[e].optimize();return this}clone(){let e=[];for(let n=0;n<this.tracks.length;n++)e.push(this.tracks[n].clone());let t=new this.constructor(this.name,this.duration,e,this.blendMode);return t.userData=JSON.parse(JSON.stringify(this.userData)),t}toJSON(){return this.constructor.toJSON(this)}};function ny(i){switch(i.toLowerCase()){case"scalar":case"double":case"float":case"number":case"integer":return Vi;case"vector":case"vector2":case"vector3":case"vector4":return ds;case"color":return Sa;case"quaternion":return Hi;case"bool":case"boolean":return ki;case"string":return Gi}throw new Error("THREE.KeyframeTrack: Unsupported typeName: "+i)}function iy(i){if(i.type===void 0)throw new Error("THREE.KeyframeTrack: track type undefined, can not parse");let e=ny(i.type);if(i.times===void 0){let n=[],s=[];Q_(i.keys,n,s,"value"),i.times=n,i.values=s}let t;return e.parse!==void 0?t=e.parse(i):t=new e(i.name,i.times,i.values,i.interpolation),qc(i.settings)&&(t.settings={inTangents:as(i.settings.inTangents,Float32Array),outTangents:as(i.settings.outTangents,Float32Array)}),t}var xi={enabled:!1,files:{},add:function(i,e){this.enabled!==!1&&(Rm(i)||(this.files[i]=e))},get:function(i){if(this.enabled!==!1&&!Rm(i))return this.files[i]},remove:function(i){delete this.files[i]},clear:function(){this.files={}}};function Rm(i){try{let e=i.slice(i.indexOf(":")+1);return new URL(e).protocol==="blob:"}catch{return!1}}var vl=class{constructor(e,t,n){let s=this,r=!1,o=0,a=0,c,l=[];this.onStart=void 0,this.onLoad=e,this.onProgress=t,this.onError=n,this._abortController=null,this.itemStart=function(u){a++,r===!1&&s.onStart!==void 0&&s.onStart(u,o,a),r=!0},this.itemEnd=function(u){o++,s.onProgress!==void 0&&s.onProgress(u,o,a),o===a&&(r=!1,s.onLoad!==void 0&&s.onLoad())},this.itemError=function(u){s.onError!==void 0&&s.onError(u)},this.resolveURL=function(u){return u=u.normalize("NFC"),c?c(u):u},this.setURLModifier=function(u){return c=u,this},this.addHandler=function(u,h){return l.push(u,h),this},this.removeHandler=function(u){let h=l.indexOf(u);return h!==-1&&l.splice(h,2),this},this.getHandler=function(u){for(let h=0,f=l.length;h<f;h+=2){let d=l[h],m=l[h+1];if(d.global&&(d.lastIndex=0),d.test(u))return m}return null},this.abort=function(){return this.abortController.abort(),this._abortController=null,this}}get abortController(){return this._abortController||(this._abortController=new AbortController),this._abortController}},Eg=new vl,vi=class{constructor(e){this.manager=e!==void 0?e:Eg,this.crossOrigin="anonymous",this.withCredentials=!1,this.path="",this.resourcePath="",this.requestHeader={},typeof __THREE_DEVTOOLS__<"u"&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe",{detail:this}))}load(){}loadAsync(e,t){let n=this;return new Promise(function(s,r){n.load(e,s,t,r)})}parse(){}setCrossOrigin(e){return this.crossOrigin=e,this}setWithCredentials(e){return this.withCredentials=e,this}setPath(e){return this.path=e,this}setResourcePath(e){return this.resourcePath=e,this}setRequestHeader(e){return this.requestHeader=e,this}abort(){return this}};vi.DEFAULT_MATERIAL_NAME="__DEFAULT";var Ui={},sf=class extends Error{constructor(e,t){super(e),this.response=t}},Zr=class extends vi{constructor(e){super(e),this.mimeType="",this.responseType="",this._abortController=new AbortController}load(e,t,n,s){e===void 0&&(e=""),this.path!==void 0&&(e=this.path+e),e=this.manager.resolveURL(e);let r=xi.get(`file:${e}`);if(r!==void 0){this.manager.itemStart(e),setTimeout(()=>{t&&t(r),this.manager.itemEnd(e)},0);return}if(Ui[e]!==void 0){Ui[e].push({onLoad:t,onProgress:n,onError:s});return}Ui[e]=[],Ui[e].push({onLoad:t,onProgress:n,onError:s});let o=new Request(e,{headers:new Headers(this.requestHeader),credentials:this.withCredentials?"include":"same-origin",signal:typeof AbortSignal.any=="function"?AbortSignal.any([this._abortController.signal,this.manager.abortController.signal]):this._abortController.signal}),a=this.mimeType,c=this.responseType;fetch(o).then(l=>{if(l.status===200||l.status===0){if(l.status===0&&Fe("FileLoader: HTTP Status 0 received."),typeof ReadableStream>"u"||l.body===void 0||l.body.getReader===void 0)return l;let u=Ui[e],h=l.body.getReader(),f=l.headers.get("X-File-Size")||l.headers.get("Content-Length"),d=f?parseInt(f):0,m=d!==0,x=0,g=new ReadableStream({start(p){v();function v(){h.read().then(({done:b,value:_})=>{if(b)p.close();else{x+=_.byteLength;let S=new ProgressEvent("progress",{lengthComputable:m,loaded:x,total:d});for(let M=0,E=u.length;M<E;M++){let y=u[M];y.onProgress&&y.onProgress(S)}p.enqueue(_),v()}},b=>{p.error(b)})}}});return new Response(g)}else throw new sf(`fetch for "${l.url}" responded with ${l.status}: ${l.statusText}`,l)}).then(l=>{switch(c){case"arraybuffer":return l.arrayBuffer();case"blob":return l.blob();case"document":return l.text().then(u=>new DOMParser().parseFromString(u,a));case"json":return l.json();default:if(a==="")return l.text();{let h=/charset="?([^;"\s]*)"?/i.exec(a),f=h&&h[1]?h[1].toLowerCase():void 0,d=new TextDecoder(f);return l.arrayBuffer().then(m=>d.decode(m))}}}).then(l=>{xi.add(`file:${e}`,l);let u=Ui[e];delete Ui[e];for(let h=0,f=u.length;h<f;h++){let d=u[h];d.onLoad&&d.onLoad(l)}}).catch(l=>{let u=Ui[e];if(u===void 0)throw this.manager.itemError(e),l;delete Ui[e];for(let h=0,f=u.length;h<f;h++){let d=u[h];d.onError&&d.onError(l)}this.manager.itemError(e)}).finally(()=>{this.manager.itemEnd(e)}),this.manager.itemStart(e)}setResponseType(e){return this.responseType=e,this}setMimeType(e){return this.mimeType=e,this}abort(){return this._abortController.abort(),this._abortController=new AbortController,this}};var Er=new WeakMap,Sl=class extends vi{constructor(e){super(e)}load(e,t,n,s){this.path!==void 0&&(e=this.path+e),e=this.manager.resolveURL(e);let r=this,o=xi.get(`image:${e}`);if(o!==void 0){if(o.complete===!0)r.manager.itemStart(e),setTimeout(function(){t&&t(o),r.manager.itemEnd(e)},0);else{let h=Er.get(o);h===void 0&&(h=[],Er.set(o,h)),h.push({onLoad:t,onError:s})}return o}let a=Ur("img");function c(){u(),t&&t(this);let h=Er.get(this)||[];for(let f=0;f<h.length;f++){let d=h[f];d.onLoad&&d.onLoad(this)}Er.delete(this),r.manager.itemEnd(e)}function l(h){u(),s&&s(h),xi.remove(`image:${e}`);let f=Er.get(this)||[];for(let d=0;d<f.length;d++){let m=f[d];m.onError&&m.onError(h)}Er.delete(this),r.manager.itemError(e),r.manager.itemEnd(e)}function u(){a.removeEventListener("load",c,!1),a.removeEventListener("error",l,!1)}return a.addEventListener("load",c,!1),a.addEventListener("error",l,!1),e.slice(0,5)!=="data:"&&this.crossOrigin!==void 0&&(a.crossOrigin=this.crossOrigin),xi.add(`image:${e}`,a),r.manager.itemStart(e),a.src=e,a}};var Hs=class extends vi{constructor(e){super(e)}load(e,t,n,s){let r=new Jt,o=new Sl(this.manager);return o.setCrossOrigin(this.crossOrigin),o.setPath(this.path),o.load(e,function(a){r.image=a,r.needsUpdate=!0,t!==void 0&&t(r)},n,s),r}},Gs=class extends Nt{constructor(e,t=1){super(),this.isLight=!0,this.type="Light",this.color=new Ve(e),this.intensity=t}copy(e,t){return super.copy(e,t),this.color.copy(e.color),this.intensity=e.intensity,this}toJSON(e){let t=super.toJSON(e);return t.object.color=this.color.getHex(),t.object.intensity=this.intensity,t}},Ma=class extends Gs{constructor(e,t,n){super(e,n),this.isHemisphereLight=!0,this.type="HemisphereLight",this.position.copy(Nt.DEFAULT_UP),this.updateMatrix(),this.groundColor=new Ve(t)}copy(e,t){return super.copy(e,t),this.groundColor.copy(e.groundColor),this}toJSON(e){let t=super.toJSON(e);return t.object.groundColor=this.groundColor.getHex(),t}},Wh=new Ie,Cm=new I,Pm=new I,Kr=class{constructor(e){this.camera=e,this.intensity=1,this.bias=0,this.biasNode=null,this.normalBias=0,this.radius=1,this.blurSamples=8,this.mapSize=new ce(512,512),this.mapType=Dn,this.map=null,this.mapPass=null,this.matrix=new Ie,this.autoUpdate=!0,this.needsUpdate=!1,this._frustum=new Gr,this._frameExtents=new ce(1,1),this._viewportCount=1,this._viewports=[new ut(0,0,1,1)]}getViewportCount(){return this._viewportCount}getCamera(){return this.camera}getFrustum(){return this._frustum}updateMatrices(e){let t=this.camera;Cm.setFromMatrixPosition(e.matrixWorld),t.position.copy(Cm),Pm.setFromMatrixPosition(e.target.matrixWorld),t.lookAt(Pm),t.updateMatrixWorld(),this._updateMatrix(t,this.matrix,this._frustum)}_updateMatrix(e,t,n,s){Wh.multiplyMatrices(e.projectionMatrix,e.matrixWorldInverse),n.setFromProjectionMatrix(Wh,e.coordinateSystem,e.reversedDepth);let r=this._frameExtents,o=s?s.z/r.x:1,a=s?s.w/r.y:1,c=s?s.x/r.x:0,l=s?s.y/r.y:0;e.coordinateSystem===Dr||e.reversedDepth?t.set(.5*o,0,0,.5*o+c,0,.5*a,0,.5*a+l,0,0,1,0,0,0,0,1):t.set(.5*o,0,0,.5*o+c,0,.5*a,0,.5*a+l,0,0,.5,.5,0,0,0,1),t.multiply(Wh)}getViewport(e){return this._viewports[e]}getFrameExtents(){return this._frameExtents}dispose(){this.map&&this.map.dispose(),this.mapPass&&this.mapPass.dispose()}copy(e){return this.camera=e.camera.clone(),this.intensity=e.intensity,this.bias=e.bias,this.radius=e.radius,this.autoUpdate=e.autoUpdate,this.needsUpdate=e.needsUpdate,this.normalBias=e.normalBias,this.blurSamples=e.blurSamples,this.mapSize.copy(e.mapSize),this.biasNode=e.biasNode,this}clone(){return new this.constructor().copy(this)}toJSON(){let e={};return e.intensity=this.intensity,e.bias=this.bias,e.normalBias=this.normalBias,e.radius=this.radius,e.blurSamples=this.blurSamples,e.mapSize=this.mapSize.toArray(),e.camera=this.camera.toJSON(!1).object,delete e.camera.matrix,e}},Vc=new I,Hc=new pn,gi=new I,Ta=class extends Nt{constructor(){super(),this.isCamera=!0,this.type="Camera",this.matrixWorldInverse=new Ie,this.projectionMatrix=new Ie,this.projectionMatrixInverse=new Ie,this.coordinateSystem=si,this._reversedDepth=!1}get reversedDepth(){return this._reversedDepth}copy(e,t){return super.copy(e,t),this.matrixWorldInverse.copy(e.matrixWorldInverse),this.projectionMatrix.copy(e.projectionMatrix),this.projectionMatrixInverse.copy(e.projectionMatrixInverse),this.coordinateSystem=e.coordinateSystem,this}getWorldDirection(e){return super.getWorldDirection(e).negate()}updateMatrixWorld(e){super.updateMatrixWorld(e),this.matrixWorld.decompose(Vc,Hc,gi),gi.x===1&&gi.y===1&&gi.z===1?this.matrixWorldInverse.copy(this.matrixWorld).invert():this.matrixWorldInverse.compose(Vc,Hc,gi.set(1,1,1)).invert()}updateWorldMatrix(e,t,n=!1){super.updateWorldMatrix(e,t,n),this.matrixWorld.decompose(Vc,Hc,gi),gi.x===1&&gi.y===1&&gi.z===1?this.matrixWorldInverse.copy(this.matrixWorld).invert():this.matrixWorldInverse.compose(Vc,Hc,gi.set(1,1,1)).invert()}clone(){return new this.constructor().copy(this)}},os=new I,Im=new ce,Lm=new ce,Yt=class extends Ta{constructor(e=50,t=1,n=.1,s=2e3){super(),this.isPerspectiveCamera=!0,this.type="PerspectiveCamera",this.fov=e,this.zoom=1,this.near=n,this.far=s,this.focus=10,this.aspect=t,this.view=null,this.filmGauge=35,this.filmOffset=0,this.updateProjectionMatrix()}copy(e,t){return super.copy(e,t),this.fov=e.fov,this.zoom=e.zoom,this.near=e.near,this.far=e.far,this.focus=e.focus,this.aspect=e.aspect,this.view=e.view===null?null:Object.assign({},e.view),this.filmGauge=e.filmGauge,this.filmOffset=e.filmOffset,this}setFocalLength(e){let t=.5*this.getFilmHeight()/e;this.fov=Os*2*Math.atan(t),this.updateProjectionMatrix()}getFocalLength(){let e=Math.tan(Go*.5*this.fov);return .5*this.getFilmHeight()/e}getEffectiveFOV(){return Os*2*Math.atan(Math.tan(Go*.5*this.fov)/this.zoom)}getFilmWidth(){return this.filmGauge*Math.min(this.aspect,1)}getFilmHeight(){return this.filmGauge/Math.max(this.aspect,1)}getViewBounds(e,t,n){os.set(-1,-1,.5).applyMatrix4(this.projectionMatrixInverse),t.set(os.x,os.y).multiplyScalar(-e/os.z),os.set(1,1,.5).applyMatrix4(this.projectionMatrixInverse),n.set(os.x,os.y).multiplyScalar(-e/os.z)}getViewSize(e,t){return this.getViewBounds(e,Im,Lm),t.subVectors(Lm,Im)}setViewOffset(e,t,n,s,r,o){this.aspect=e/t,this.view===null&&(this.view={enabled:!0,fullWidth:1,fullHeight:1,offsetX:0,offsetY:0,width:1,height:1}),this.view.enabled=!0,this.view.fullWidth=e,this.view.fullHeight=t,this.view.offsetX=n,this.view.offsetY=s,this.view.width=r,this.view.height=o,this.updateProjectionMatrix()}clearViewOffset(){this.view!==null&&(this.view.enabled=!1),this.updateProjectionMatrix()}updateProjectionMatrix(){let e=this.near,t=e*Math.tan(Go*.5*this.fov)/this.zoom,n=2*t,s=this.aspect*n,r=-.5*s,o=this.view;if(this.view!==null&&this.view.enabled){let c=o.fullWidth,l=o.fullHeight;r+=o.offsetX*s/c,t-=o.offsetY*n/l,s*=o.width/c,n*=o.height/l}let a=this.filmOffset;a!==0&&(r+=e*a/this.getFilmWidth()),this.projectionMatrix.makePerspective(r,r+s,t,t-n,e,this.far,this.coordinateSystem,this.reversedDepth),this.projectionMatrixInverse.copy(this.projectionMatrix).invert()}toJSON(e){let t=super.toJSON(e);return t.object.fov=this.fov,t.object.zoom=this.zoom,t.object.near=this.near,t.object.far=this.far,t.object.focus=this.focus,t.object.aspect=this.aspect,this.view!==null&&(t.object.view=Object.assign({},this.view)),t.object.filmGauge=this.filmGauge,t.object.filmOffset=this.filmOffset,t}},rf=class extends Kr{constructor(){super(new Yt(50,1,.5,500)),this.isSpotLightShadow=!0,this.focus=1,this.aspect=1}updateMatrices(e){let t=this.camera,n=Os*2*e.angle*this.focus,s=this.mapSize.width/this.mapSize.height*this.aspect,r=e.distance||t.far;(n!==t.fov||s!==t.aspect||r!==t.far)&&(t.fov=n,t.aspect=s,t.far=r,t.updateProjectionMatrix()),super.updateMatrices(e)}copy(e){return super.copy(e),this.focus=e.focus,this.aspect=e.aspect,this}toJSON(){let e=super.toJSON();return e.focus=this.focus,e.aspect=this.aspect,e}},wa=class extends Gs{constructor(e,t,n=0,s=Math.PI/3,r=0,o=2){super(e,t),this.isSpotLight=!0,this.type="SpotLight",this.position.copy(Nt.DEFAULT_UP),this.updateMatrix(),this.target=new Nt,this.distance=n,this.angle=s,this.penumbra=r,this.decay=o,this.map=null,this.shadow=new rf}get power(){return this.intensity*Math.PI}set power(e){this.intensity=e/Math.PI}dispose(){super.dispose(),this.shadow.dispose()}copy(e,t){return super.copy(e,t),this.distance=e.distance,this.angle=e.angle,this.penumbra=e.penumbra,this.decay=e.decay,this.target=e.target.clone(),this.map=e.map,this.shadow=e.shadow.clone(),this}toJSON(e){let t=super.toJSON(e);return t.object.distance=this.distance,t.object.angle=this.angle,t.object.decay=this.decay,t.object.penumbra=this.penumbra,t.object.target=this.target.uuid,this.map&&this.map.isTexture&&(t.object.map=this.map.toJSON(e).uuid),t.object.shadow=this.shadow.toJSON(),t}},of=class extends Kr{constructor(){super(new Yt(90,1,.5,500)),this.isPointLightShadow=!0}},Ea=class extends Gs{constructor(e,t,n=0,s=2){super(e,t),this.isPointLight=!0,this.type="PointLight",this.distance=n,this.decay=s,this.shadow=new of}get power(){return this.intensity*4*Math.PI}set power(e){this.intensity=e/(4*Math.PI)}dispose(){super.dispose(),this.shadow.dispose()}copy(e,t){return super.copy(e,t),this.distance=e.distance,this.decay=e.decay,this.shadow=e.shadow.clone(),this}toJSON(e){let t=super.toJSON(e);return t.object.distance=this.distance,t.object.decay=this.decay,t.object.shadow=this.shadow.toJSON(),t}},ps=class extends Ta{constructor(e=-1,t=1,n=1,s=-1,r=.1,o=2e3){super(),this.isOrthographicCamera=!0,this.type="OrthographicCamera",this.zoom=1,this.view=null,this.left=e,this.right=t,this.top=n,this.bottom=s,this.near=r,this.far=o,this.updateProjectionMatrix()}copy(e,t){return super.copy(e,t),this.left=e.left,this.right=e.right,this.top=e.top,this.bottom=e.bottom,this.near=e.near,this.far=e.far,this.zoom=e.zoom,this.view=e.view===null?null:Object.assign({},e.view),this}setViewOffset(e,t,n,s,r,o){this.view===null&&(this.view={enabled:!0,fullWidth:1,fullHeight:1,offsetX:0,offsetY:0,width:1,height:1}),this.view.enabled=!0,this.view.fullWidth=e,this.view.fullHeight=t,this.view.offsetX=n,this.view.offsetY=s,this.view.width=r,this.view.height=o,this.updateProjectionMatrix()}clearViewOffset(){this.view!==null&&(this.view.enabled=!1),this.updateProjectionMatrix()}updateProjectionMatrix(){let e=(this.right-this.left)/(2*this.zoom),t=(this.top-this.bottom)/(2*this.zoom),n=(this.right+this.left)/2,s=(this.top+this.bottom)/2,r=n-e,o=n+e,a=s+t,c=s-t;if(this.view!==null&&this.view.enabled){let l=(this.right-this.left)/this.view.fullWidth/this.zoom,u=(this.top-this.bottom)/this.view.fullHeight/this.zoom;r+=l*this.view.offsetX,o=r+l*this.view.width,a-=u*this.view.offsetY,c=a-u*this.view.height}this.projectionMatrix.makeOrthographic(r,o,a,c,this.near,this.far,this.coordinateSystem,this.reversedDepth),this.projectionMatrixInverse.copy(this.projectionMatrix).invert()}toJSON(e){let t=super.toJSON(e);return t.object.zoom=this.zoom,t.object.left=this.left,t.object.right=this.right,t.object.top=this.top,t.object.bottom=this.bottom,t.object.near=this.near,t.object.far=this.far,this.view!==null&&(t.object.view=Object.assign({},this.view)),t}},af=class extends Kr{constructor(){super(new ps(-5,5,5,-5,.5,500)),this.isDirectionalLightShadow=!0}},Ws=class extends Gs{constructor(e,t){super(e,t),this.isDirectionalLight=!0,this.type="DirectionalLight",this.position.copy(Nt.DEFAULT_UP),this.updateMatrix(),this.target=new Nt,this.shadow=new af}dispose(){super.dispose(),this.shadow.dispose()}copy(e){return super.copy(e),this.target=e.target.clone(),this.shadow=e.shadow.clone(),this}toJSON(e){let t=super.toJSON(e);return t.object.shadow=this.shadow.toJSON(),t.object.target=this.target.uuid,t}};var Wi=class{static extractUrlBase(e){let t=e.lastIndexOf("/");return t===-1?"./":e.slice(0,t+1)}static resolveURL(e,t){return typeof e!="string"||e===""?"":(/^https?:\/\//i.test(t)&&/^\//.test(e)&&(t=t.replace(/(^https?:\/\/[^\/]+).*/i,"$1")),/^(https?:)?\/\//i.test(e)||/^data:.*,.*$/i.test(e)||/^blob:.*$/i.test(e)?e:t+e)}};var Xh=new WeakMap,Aa=class extends vi{constructor(e){super(e),this.isImageBitmapLoader=!0,typeof createImageBitmap>"u"&&Fe("ImageBitmapLoader: createImageBitmap() not supported."),typeof fetch>"u"&&Fe("ImageBitmapLoader: fetch() not supported."),this.options={premultiplyAlpha:"none"},this._abortController=new AbortController}setOptions(e){return this.options=e,this}load(e,t,n,s){e===void 0&&(e=""),this.path!==void 0&&(e=this.path+e),e=this.manager.resolveURL(e);let r=this,o=xi.get(`image-bitmap:${e}`);if(o!==void 0){if(r.manager.itemStart(e),o.then){o.then(l=>{Xh.has(o)===!0?(s&&s(Xh.get(o)),r.manager.itemError(e),r.manager.itemEnd(e)):(t&&t(l),r.manager.itemEnd(e))});return}setTimeout(function(){t&&t(o),r.manager.itemEnd(e)},0);return}let a={};a.credentials=this.crossOrigin==="anonymous"?"same-origin":"include",a.headers=this.requestHeader,a.signal=typeof AbortSignal.any=="function"?AbortSignal.any([this._abortController.signal,this.manager.abortController.signal]):this._abortController.signal;let c=fetch(e,a).then(function(l){return l.blob()}).then(function(l){return createImageBitmap(l,Object.assign({},r.options,{colorSpaceConversion:"none"}))}).then(function(l){return xi.add(`image-bitmap:${e}`,l),t&&t(l),r.manager.itemEnd(e),l}).catch(function(l){s&&s(l),Xh.set(c,l),xi.remove(`image-bitmap:${e}`),r.manager.itemError(e),r.manager.itemEnd(e)});xi.add(`image-bitmap:${e}`,c),r.manager.itemStart(e)}abort(){return this._abortController.abort(),this._abortController=new AbortController,this}};var Ar=-90,Rr=1,bl=class extends Nt{constructor(e,t,n){super(),this.type="CubeCamera",this.renderTarget=n,this.coordinateSystem=null,this.activeMipmapLevel=0;let s=new Yt(Ar,Rr,e,t);s.layers=this.layers,this.add(s);let r=new Yt(Ar,Rr,e,t);r.layers=this.layers,this.add(r);let o=new Yt(Ar,Rr,e,t);o.layers=this.layers,this.add(o);let a=new Yt(Ar,Rr,e,t);a.layers=this.layers,this.add(a);let c=new Yt(Ar,Rr,e,t);c.layers=this.layers,this.add(c);let l=new Yt(Ar,Rr,e,t);l.layers=this.layers,this.add(l)}updateCoordinateSystem(){let e=this.coordinateSystem,t=this.children.concat(),[n,s,r,o,a,c]=t;for(let l of t)this.remove(l);if(e===si)n.up.set(0,1,0),n.lookAt(1,0,0),s.up.set(0,1,0),s.lookAt(-1,0,0),r.up.set(0,0,-1),r.lookAt(0,1,0),o.up.set(0,0,1),o.lookAt(0,-1,0),a.up.set(0,1,0),a.lookAt(0,0,1),c.up.set(0,1,0),c.lookAt(0,0,-1);else if(e===Dr)n.up.set(0,-1,0),n.lookAt(-1,0,0),s.up.set(0,-1,0),s.lookAt(1,0,0),r.up.set(0,0,1),r.lookAt(0,1,0),o.up.set(0,0,-1),o.lookAt(0,-1,0),a.up.set(0,-1,0),a.lookAt(0,0,1),c.up.set(0,-1,0),c.lookAt(0,0,-1);else throw new Error("THREE.CubeCamera.updateCoordinateSystem(): Invalid coordinate system: "+e);for(let l of t)this.add(l),l.updateMatrixWorld()}update(e,t){this.parent===null&&this.updateMatrixWorld();let{renderTarget:n,activeMipmapLevel:s}=this;this.coordinateSystem!==e.coordinateSystem&&(this.coordinateSystem=e.coordinateSystem,this.updateCoordinateSystem());let[r,o,a,c,l,u]=this.children,h=e.getRenderTarget(),f=e.getActiveCubeFace(),d=e.getActiveMipmapLevel(),m=e.xr.enabled;e.xr.enabled=!1;let x=n.texture.generateMipmaps;n.texture.generateMipmaps=!1;let g=!1;e.isWebGLRenderer===!0?g=e.state.buffers.depth.getReversed():g=e.reversedDepthBuffer,e.setRenderTarget(n,0,s),g&&e.autoClear===!1&&e.clearDepth(),e.render(t,r),e.setRenderTarget(n,1,s),g&&e.autoClear===!1&&e.clearDepth(),e.render(t,o),e.setRenderTarget(n,2,s),g&&e.autoClear===!1&&e.clearDepth(),e.render(t,a),e.setRenderTarget(n,3,s),g&&e.autoClear===!1&&e.clearDepth(),e.render(t,c),e.setRenderTarget(n,4,s),g&&e.autoClear===!1&&e.clearDepth(),e.render(t,l),n.texture.generateMipmaps=x,e.setRenderTarget(n,5,s),g&&e.autoClear===!1&&e.clearDepth(),e.render(t,u),e.setRenderTarget(h,f,d),e.xr.enabled=m,n.texture.needsPMREMUpdate=!0}},Ml=class extends Yt{constructor(e=[]){super(),this.isArrayCamera=!0,this.isMultiViewCamera=!1,this.cameras=e}};var Of="\\[\\]\\.:\\/",sy=new RegExp("["+Of+"]","g"),Bf="[^"+Of+"]",ry="[^"+Of.replace("\\.","")+"]",oy=/((?:WC+[\/:])*)/.source.replace("WC",Bf),ay=/(WCOD+)?/.source.replace("WCOD",ry),cy=/(?:\.(WC+)(?:\[(.+)\])?)?/.source.replace("WC",Bf),ly=/\.(WC+)(?:\[(.+)\])?/.source.replace("WC",Bf),uy=new RegExp("^"+oy+ay+cy+ly+"$"),hy=["material","materials","bones","map"],cf=class{constructor(e,t,n){let s=n||At.parseTrackName(t);this._targetGroup=e,this._bindings=e.subscribe_(t,s)}getValue(e,t){this.bind();let n=this._targetGroup.nCachedObjects_,s=this._bindings[n];s!==void 0&&s.getValue(e,t)}setValue(e,t){let n=this._bindings;for(let s=this._targetGroup.nCachedObjects_,r=n.length;s!==r;++s)n[s].setValue(e,t)}bind(){let e=this._bindings;for(let t=this._targetGroup.nCachedObjects_,n=e.length;t!==n;++t)e[t].bind()}unbind(){let e=this._bindings;for(let t=this._targetGroup.nCachedObjects_,n=e.length;t!==n;++t)e[t].unbind()}},At=class i{constructor(e,t,n){this.path=t,this.parsedPath=n||i.parseTrackName(t),this.node=i.findNode(e,this.parsedPath.nodeName),this.rootNode=e,this.getValue=this._getValue_unbound,this.setValue=this._setValue_unbound}static create(e,t,n){return e&&e.isAnimationObjectGroup?new i.Composite(e,t,n):new i(e,t,n)}static sanitizeNodeName(e){return e.replace(/\s/g,"_").replace(sy,"")}static parseTrackName(e){let t=uy.exec(e);if(t===null)throw new Error("THREE.PropertyBinding: Cannot parse trackName: "+e);let n={nodeName:t[2],objectName:t[3],objectIndex:t[4],propertyName:t[5],propertyIndex:t[6]},s=n.nodeName&&n.nodeName.lastIndexOf(".");if(s!==void 0&&s!==-1){let r=n.nodeName.substring(s+1);hy.indexOf(r)!==-1&&(n.nodeName=n.nodeName.substring(0,s),n.objectName=r)}if(n.propertyName===null||n.propertyName.length===0)throw new Error("THREE.PropertyBinding: can not parse propertyName from trackName: "+e);return n}static findNode(e,t){if(t===void 0||t===""||t==="."||t===-1||t===e.name||t===e.uuid)return e;if(e.skeleton){let n=e.skeleton.getBoneByName(t);if(n!==void 0)return n}if(e.children){let n=function(r){for(let o=0;o<r.length;o++){let a=r[o];if(a.name===t||a.uuid===t)return a;let c=n(a.children);if(c)return c}return null},s=n(e.children);if(s)return s}return null}_getValue_unavailable(){}_setValue_unavailable(){}_getValue_direct(e,t){e[t]=this.targetObject[this.propertyName]}_getValue_array(e,t){let n=this.resolvedProperty;for(let s=0,r=n.length;s!==r;++s)e[t++]=n[s]}_getValue_arrayElement(e,t){e[t]=this.resolvedProperty[this.propertyIndex]}_getValue_toArray(e,t){this.resolvedProperty.toArray(e,t)}_setValue_direct(e,t){this.targetObject[this.propertyName]=e[t]}_setValue_direct_setNeedsUpdate(e,t){this.targetObject[this.propertyName]=e[t],this.targetObject.needsUpdate=!0}_setValue_direct_setMatrixWorldNeedsUpdate(e,t){this.targetObject[this.propertyName]=e[t],this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_array(e,t){let n=this.resolvedProperty;for(let s=0,r=n.length;s!==r;++s)n[s]=e[t++]}_setValue_array_setNeedsUpdate(e,t){let n=this.resolvedProperty;for(let s=0,r=n.length;s!==r;++s)n[s]=e[t++];this.targetObject.needsUpdate=!0}_setValue_array_setMatrixWorldNeedsUpdate(e,t){let n=this.resolvedProperty;for(let s=0,r=n.length;s!==r;++s)n[s]=e[t++];this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_arrayElement(e,t){this.resolvedProperty[this.propertyIndex]=e[t]}_setValue_arrayElement_setNeedsUpdate(e,t){this.resolvedProperty[this.propertyIndex]=e[t],this.targetObject.needsUpdate=!0}_setValue_arrayElement_setMatrixWorldNeedsUpdate(e,t){this.resolvedProperty[this.propertyIndex]=e[t],this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_fromArray(e,t){this.resolvedProperty.fromArray(e,t)}_setValue_fromArray_setNeedsUpdate(e,t){this.resolvedProperty.fromArray(e,t),this.targetObject.needsUpdate=!0}_setValue_fromArray_setMatrixWorldNeedsUpdate(e,t){this.resolvedProperty.fromArray(e,t),this.targetObject.matrixWorldNeedsUpdate=!0}_getValue_unbound(e,t){this.bind(),this.getValue(e,t)}_setValue_unbound(e,t){this.bind(),this.setValue(e,t)}bind(){let e=this.node,t=this.parsedPath,n=t.objectName,s=t.propertyName,r=t.propertyIndex;if(e||(e=i.findNode(this.rootNode,t.nodeName),this.node=e),this.getValue=this._getValue_unavailable,this.setValue=this._setValue_unavailable,!e){Fe("PropertyBinding: No target node found for track: "+this.path+".");return}if(n){let l=t.objectIndex;switch(n){case"materials":if(!e.material){We("PropertyBinding: Can not bind to material as node does not have a material.",this);return}if(!e.material.materials){We("PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.",this);return}e=e.material.materials;break;case"bones":if(!e.skeleton){We("PropertyBinding: Can not bind to bones as node does not have a skeleton.",this);return}e=e.skeleton.bones;for(let u=0;u<e.length;u++)if(e[u].name===l){l=u;break}break;case"map":if("map"in e){e=e.map;break}if(!e.material){We("PropertyBinding: Can not bind to material as node does not have a material.",this);return}if(!e.material.map){We("PropertyBinding: Can not bind to material.map as node.material does not have a map.",this);return}e=e.material.map;break;default:if(e[n]===void 0){We("PropertyBinding: Can not bind to objectName of node undefined.",this);return}e=e[n]}if(l!==void 0){if(e[l]===void 0){We("PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.",this,e);return}e=e[l]}}let o=e[s];if(o===void 0){let l=t.nodeName;We("PropertyBinding: Trying to update property for track: "+l+"."+s+" but it wasn't found.",e);return}let a=this.Versioning.None;this.targetObject=e,e.isMaterial===!0?a=this.Versioning.NeedsUpdate:e.isObject3D===!0&&(a=this.Versioning.MatrixWorldNeedsUpdate);let c=this.BindingType.Direct;if(r!==void 0){if(s==="morphTargetInfluences"){if(!e.geometry){We("PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.",this);return}if(!e.geometry.morphAttributes){We("PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.",this);return}e.morphTargetDictionary[r]!==void 0&&(r=e.morphTargetDictionary[r])}c=this.BindingType.ArrayElement,this.resolvedProperty=o,this.propertyIndex=r}else o.fromArray!==void 0&&o.toArray!==void 0?(c=this.BindingType.HasFromToArray,this.resolvedProperty=o):Array.isArray(o)?(c=this.BindingType.EntireArray,this.resolvedProperty=o):this.propertyName=s;this.getValue=this.GetterByBindingType[c],this.setValue=this.SetterByBindingTypeAndVersioning[c][a]}unbind(){this.node=null,this.getValue=this._getValue_unbound,this.setValue=this._setValue_unbound}};At.Composite=cf;At.prototype.BindingType={Direct:0,EntireArray:1,ArrayElement:2,HasFromToArray:3};At.prototype.Versioning={None:0,NeedsUpdate:1,MatrixWorldNeedsUpdate:2};At.prototype.GetterByBindingType=[At.prototype._getValue_direct,At.prototype._getValue_array,At.prototype._getValue_arrayElement,At.prototype._getValue_toArray];At.prototype.SetterByBindingTypeAndVersioning=[[At.prototype._setValue_direct,At.prototype._setValue_direct_setNeedsUpdate,At.prototype._setValue_direct_setMatrixWorldNeedsUpdate],[At.prototype._setValue_array,At.prototype._setValue_array_setNeedsUpdate,At.prototype._setValue_array_setMatrixWorldNeedsUpdate],[At.prototype._setValue_arrayElement,At.prototype._setValue_arrayElement_setNeedsUpdate,At.prototype._setValue_arrayElement_setMatrixWorldNeedsUpdate],[At.prototype._setValue_fromArray,At.prototype._setValue_fromArray_setNeedsUpdate,At.prototype._setValue_fromArray_setMatrixWorldNeedsUpdate]];var vw=new Float32Array(1);var Nm=new Ie,Xs=class{constructor(e,t,n=0,s=1/0){this.ray=new Pn(e,t),this.near=n,this.far=s,this.camera=null,this.layers=new Br,this.params={Mesh:{},Line:{threshold:1},LOD:{},Points:{threshold:1},Sprite:{}}}set(e,t){this.ray.set(e,t)}setFromCamera(e,t){t.isPerspectiveCamera?(this.ray.origin.setFromMatrixPosition(t.matrixWorld),this.ray.direction.set(e.x,e.y,.5).unproject(t).sub(this.ray.origin).normalize(),this.camera=t):t.isOrthographicCamera?(this.ray.origin.set(e.x,e.y,t.projectionMatrix.elements[14]).unproject(t),this.ray.direction.set(0,0,-1).transformDirection(t.matrixWorld),this.camera=t):We("Raycaster: Unsupported camera type: "+t.type)}setFromXRController(e){return Nm.identity().extractRotation(e.matrixWorld),this.ray.origin.setFromMatrixPosition(e.matrixWorld),this.ray.direction.set(0,0,-1).applyMatrix4(Nm),this}intersectObject(e,t=!0,n=[]){return lf(e,this,n,t),n.sort(Dm),n}intersectObjects(e,t=!0,n=[]){for(let s=0,r=e.length;s<r;s++)lf(e[s],this,n,t);return n.sort(Dm),n}};function Dm(i,e){return i.distance-e.distance}function lf(i,e,t,n){let s=!0;if(i.layers.test(e.layers)&&i.raycast(e,t)===!1&&(s=!1),s===!0&&n===!0){let r=i.children;for(let o=0,a=r.length;o<a;o++)lf(r[o],e,t,!0)}}var Jr=class{constructor(e=1,t=0,n=0){this.radius=e,this.phi=t,this.theta=n}set(e,t,n){return this.radius=e,this.phi=t,this.theta=n,this}copy(e){return this.radius=e.radius,this.phi=e.phi,this.theta=e.theta,this}makeSafe(){return this.phi=qe(this.phi,1e-6,Math.PI-1e-6),this}setFromVector3(e){return this.setFromCartesianCoords(e.x,e.y,e.z)}setFromCartesianCoords(e,t,n){return this.radius=Math.sqrt(e*e+t*t+n*n),this.radius===0?(this.theta=0,this.phi=0):(this.theta=Math.atan2(e,n),this.phi=Math.acos(qe(t/this.radius,-1,1))),this}clone(){return new this.constructor().copy(this)}};var Wf=class Wf{constructor(e,t,n,s){this.elements=[1,0,0,1],e!==void 0&&this.set(e,t,n,s)}identity(){return this.set(1,0,0,1),this}fromArray(e,t=0){for(let n=0;n<4;n++)this.elements[n]=e[n+t];return this}set(e,t,n,s){let r=this.elements;return r[0]=e,r[2]=t,r[1]=n,r[3]=s,this}};Wf.prototype.isMatrix2=!0;var uf=Wf;var Um=new I,Gc=new I,Cr=new I,Pr=new I,qh=new I,fy=new I,dy=new I,Tn=class{constructor(e=new I,t=new I){this.start=e,this.end=t}set(e,t){return this.start.copy(e),this.end.copy(t),this}copy(e){return this.start.copy(e.start),this.end.copy(e.end),this}getCenter(e){return e.addVectors(this.start,this.end).multiplyScalar(.5)}delta(e){return e.subVectors(this.end,this.start)}distanceSq(){return this.start.distanceToSquared(this.end)}distance(){return this.start.distanceTo(this.end)}at(e,t){return this.delta(t).multiplyScalar(e).add(this.start)}closestPointToPointParameter(e,t){Um.subVectors(e,this.start),Gc.subVectors(this.end,this.start);let n=Gc.dot(Gc);if(n===0)return 0;let r=Gc.dot(Um)/n;return t&&(r=qe(r,0,1)),r}closestPointToPoint(e,t,n){let s=this.closestPointToPointParameter(e,t);return this.delta(n).multiplyScalar(s).add(this.start)}distanceSqToLine3(e,t=fy,n=dy){let s=10000000000000001e-32,r,o,a=this.start,c=e.start,l=this.end,u=e.end;Cr.subVectors(l,a),Pr.subVectors(u,c),qh.subVectors(a,c);let h=Cr.dot(Cr),f=Pr.dot(Pr),d=Pr.dot(qh);if(h<=s&&f<=s)return t.copy(a),n.copy(c),t.sub(n),t.dot(t);if(h<=s)r=0,o=d/f,o=qe(o,0,1);else{let m=Cr.dot(qh);if(f<=s)o=0,r=qe(-m/h,0,1);else{let x=Cr.dot(Pr),g=h*f-x*x;g!==0?r=qe((x*d-m*f)/g,0,1):r=0,o=(x*r+d)/f,o<0?(o=0,r=qe(-m/h,0,1)):o>1&&(o=1,r=qe((x-m)/h,0,1))}}return t.copy(a).addScaledVector(Cr,r),n.copy(c).addScaledVector(Pr,o),t.distanceToSquared(n)}applyMatrix4(e){return this.start.applyMatrix4(e),this.end.applyMatrix4(e),this}equals(e){return e.start.equals(this.start)&&e.end.equals(this.end)}clone(){return new this.constructor().copy(this)}};var Ra=class extends ri{constructor(e,t=null){super(),this.object=e,this.domElement=t,this.enabled=!0,this.state=-1,this.keys={},this.mouseButtons={LEFT:null,MIDDLE:null,RIGHT:null},this.touches={ONE:null,TWO:null}}connect(e){this.domElement!==null&&this.disconnect(),this.domElement=e}disconnect(){}dispose(){}update(){}};function zf(i,e,t,n){let s=py(n);switch(t){case Cf:return i*e;case Ll:return i*e/s.components*s.byteLength;case Nl:return i*e/s.components*s.byteLength;case ys:return i*e*2/s.components*s.byteLength;case Dl:return i*e*2/s.components*s.byteLength;case Pf:return i*e*3/s.components*s.byteLength;case Hn:return i*e*4/s.components*s.byteLength;case Ul:return i*e*4/s.components*s.byteLength;case La:case Na:return Math.floor((i+3)/4)*Math.floor((e+3)/4)*8;case Da:case Ua:return Math.floor((i+3)/4)*Math.floor((e+3)/4)*16;case Ol:case zl:return Math.max(i,16)*Math.max(e,8)/4;case Fl:case Bl:return Math.max(i,8)*Math.max(e,8)/2;case kl:case Vl:case Gl:case Wl:return Math.floor((i+3)/4)*Math.floor((e+3)/4)*8;case Hl:case Fa:case Xl:return Math.floor((i+3)/4)*Math.floor((e+3)/4)*16;case ql:return Math.floor((i+3)/4)*Math.floor((e+3)/4)*16;case Yl:return Math.floor((i+4)/5)*Math.floor((e+3)/4)*16;case Zl:return Math.floor((i+4)/5)*Math.floor((e+4)/5)*16;case Kl:return Math.floor((i+5)/6)*Math.floor((e+4)/5)*16;case Jl:return Math.floor((i+5)/6)*Math.floor((e+5)/6)*16;case $l:return Math.floor((i+7)/8)*Math.floor((e+4)/5)*16;case jl:return Math.floor((i+7)/8)*Math.floor((e+5)/6)*16;case Ql:return Math.floor((i+7)/8)*Math.floor((e+7)/8)*16;case eu:return Math.floor((i+9)/10)*Math.floor((e+4)/5)*16;case tu:return Math.floor((i+9)/10)*Math.floor((e+5)/6)*16;case nu:return Math.floor((i+9)/10)*Math.floor((e+7)/8)*16;case iu:return Math.floor((i+9)/10)*Math.floor((e+9)/10)*16;case su:return Math.floor((i+11)/12)*Math.floor((e+9)/10)*16;case ru:return Math.floor((i+11)/12)*Math.floor((e+11)/12)*16;case ou:case au:case cu:return Math.ceil(i/4)*Math.ceil(e/4)*16;case lu:case uu:return Math.ceil(i/4)*Math.ceil(e/4)*8;case Oa:case hu:return Math.ceil(i/4)*Math.ceil(e/4)*16}throw new Error(`Unable to determine texture byte length for ${t} format.`)}function py(i){switch(i){case Dn:case wf:return{byteLength:1,components:1};case eo:case Ef:case li:return{byteLength:2,components:1};case Pl:case Il:return{byteLength:2,components:4};case ci:case Cl:case Vn:return{byteLength:4,components:1};case Af:case Rf:return{byteLength:4,components:3}}throw new Error(`THREE.TextureUtils: Unknown texture type ${i}.`)}typeof __THREE_DEVTOOLS__<"u"&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("register",{detail:{revision:"186"}}));typeof window<"u"&&(window.__THREE__?Fe("WARNING: Multiple instances of Three.js being imported."):window.__THREE__="186");function Zg(){let i=null,e=!1,t=null,n=null;function s(r,o){n=i.requestAnimationFrame(s),t(r,o)}return{start:function(){e!==!0&&t!==null&&i!==null&&(n=i.requestAnimationFrame(s),e=!0)},stop:function(){i!==null&&i.cancelAnimationFrame(n),e=!1},setAnimationLoop:function(r){t=r},setContext:function(r){i=r}}}function my(i){let e=new WeakMap;function t(a,c){let l=a.array,u=a.usage,h=l.byteLength,f=i.createBuffer();i.bindBuffer(c,f),i.bufferData(c,l,u),a.onUploadCallback();let d;if(l instanceof Float32Array)d=i.FLOAT;else if(typeof Float16Array<"u"&&l instanceof Float16Array)d=i.HALF_FLOAT;else if(l instanceof Uint16Array)a.isFloat16BufferAttribute?d=i.HALF_FLOAT:d=i.UNSIGNED_SHORT;else if(l instanceof Int16Array)d=i.SHORT;else if(l instanceof Uint32Array)d=i.UNSIGNED_INT;else if(l instanceof Int32Array)d=i.INT;else if(l instanceof Int8Array)d=i.BYTE;else if(l instanceof Uint8Array)d=i.UNSIGNED_BYTE;else if(l instanceof Uint8ClampedArray)d=i.UNSIGNED_BYTE;else throw new Error("THREE.WebGLAttributes: Unsupported buffer data format: "+l);return{buffer:f,type:d,bytesPerElement:l.BYTES_PER_ELEMENT,version:a.version,size:h}}function n(a,c,l){let u=c.array,h=c.updateRanges;if(i.bindBuffer(l,a),h.length===0)i.bufferSubData(l,0,u);else{h.sort((d,m)=>d.start-m.start);let f=0;for(let d=1;d<h.length;d++){let m=h[f],x=h[d];x.start<=m.start+m.count+1?m.count=Math.max(m.count,x.start+x.count-m.start):(++f,h[f]=x)}h.length=f+1;for(let d=0,m=h.length;d<m;d++){let x=h[d];i.bufferSubData(l,x.start*u.BYTES_PER_ELEMENT,u,x.start,x.count)}c.clearUpdateRanges()}c.onUploadCallback()}function s(a){return a.isInterleavedBufferAttribute&&(a=a.data),e.get(a)}function r(a){a.isInterleavedBufferAttribute&&(a=a.data);let c=e.get(a);c&&(i.deleteBuffer(c.buffer),e.delete(a))}function o(a,c){if(a.isInterleavedBufferAttribute&&(a=a.data),a.isGLBufferAttribute){let u=e.get(a);(!u||u.version<a.version)&&e.set(a,{buffer:a.buffer,type:a.type,bytesPerElement:a.elementSize,version:a.version});return}let l=e.get(a);if(l===void 0)e.set(a,t(a,c));else if(l.version<a.version){if(l.size!==a.array.byteLength)throw new Error("THREE.WebGLAttributes: The size of the buffer attribute's array buffer does not match the original size. Resizing buffer attributes is not supported.");n(l.buffer,a,c),l.version=a.version}}return{get:s,remove:r,update:o}}var gy=`#ifdef USE_ALPHAHASH
	if ( diffuseColor.a < getAlphaHashThreshold( vPosition ) ) discard;
#endif`,xy=`#ifdef USE_ALPHAHASH
	const float ALPHA_HASH_SCALE = 0.05;
	float hash2D( vec2 value ) {
		return fract( 1.0e4 * sin( 17.0 * value.x + 0.1 * value.y ) * ( 0.1 + abs( sin( 13.0 * value.y + value.x ) ) ) );
	}
	float hash3D( vec3 value ) {
		return hash2D( vec2( hash2D( value.xy ), value.z ) );
	}
	float getAlphaHashThreshold( vec3 position ) {
		float maxDeriv = max(
			length( dFdx( position.xyz ) ),
			length( dFdy( position.xyz ) )
		);
		float pixScale = 1.0 / ( ALPHA_HASH_SCALE * maxDeriv );
		vec2 pixScales = vec2(
			exp2( floor( log2( pixScale ) ) ),
			exp2( ceil( log2( pixScale ) ) )
		);
		vec2 alpha = vec2(
			hash3D( floor( pixScales.x * position.xyz ) ),
			hash3D( floor( pixScales.y * position.xyz ) )
		);
		float lerpFactor = fract( log2( pixScale ) );
		float x = ( 1.0 - lerpFactor ) * alpha.x + lerpFactor * alpha.y;
		float a = min( lerpFactor, 1.0 - lerpFactor );
		vec3 cases = vec3(
			x * x / ( 2.0 * a * ( 1.0 - a ) ),
			( x - 0.5 * a ) / ( 1.0 - a ),
			1.0 - ( ( 1.0 - x ) * ( 1.0 - x ) / ( 2.0 * a * ( 1.0 - a ) ) )
		);
		float threshold = ( x < ( 1.0 - a ) )
			? ( ( x < a ) ? cases.x : cases.y )
			: cases.z;
		return clamp( threshold , 1.0e-6, 1.0 );
	}
#endif`,_y=`#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, vAlphaMapUv ).g;
#endif`,yy=`#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`,vy=`#ifdef USE_ALPHATEST
	#ifdef ALPHA_TO_COVERAGE
	diffuseColor.a = smoothstep( alphaTest, alphaTest + fwidth( diffuseColor.a ), diffuseColor.a );
	if ( diffuseColor.a == 0.0 ) discard;
	#else
	if ( diffuseColor.a < alphaTest ) discard;
	#endif
#endif`,Sy=`#ifdef USE_ALPHATEST
	uniform float alphaTest;
#endif`,by=`#ifdef USE_AOMAP
	float ambientOcclusion = ( texture2D( aoMap, vAoMapUv ).r - 1.0 ) * aoMapIntensity + 1.0;
	reflectedLight.indirectDiffuse *= ambientOcclusion;
	#if defined( USE_CLEARCOAT ) 
		clearcoatSpecularIndirect *= ambientOcclusion;
	#endif
	#if defined( USE_SHEEN ) 
		sheenSpecularIndirect *= ambientOcclusion;
	#endif
	#if defined( USE_ENVMAP ) && defined( STANDARD )
		float dotNV = saturate( dot( geometryNormal, geometryViewDir ) );
		reflectedLight.indirectSpecular *= computeSpecularOcclusion( dotNV, ambientOcclusion, material.roughness );
	#endif
#endif`,My=`#ifdef USE_AOMAP
	uniform sampler2D aoMap;
	uniform float aoMapIntensity;
#endif`,Ty=`#ifdef USE_BATCHING
	#if ! defined( GL_ANGLE_multi_draw )
	#define gl_DrawID _gl_DrawID
	uniform int _gl_DrawID;
	#endif
	uniform highp sampler2D batchingTexture;
	uniform highp usampler2D batchingIdTexture;
	mat4 getBatchingMatrix( const in float i ) {
		int size = textureSize( batchingTexture, 0 ).x;
		int j = int( i ) * 4;
		int x = j % size;
		int y = j / size;
		vec4 v1 = texelFetch( batchingTexture, ivec2( x, y ), 0 );
		vec4 v2 = texelFetch( batchingTexture, ivec2( x + 1, y ), 0 );
		vec4 v3 = texelFetch( batchingTexture, ivec2( x + 2, y ), 0 );
		vec4 v4 = texelFetch( batchingTexture, ivec2( x + 3, y ), 0 );
		return mat4( v1, v2, v3, v4 );
	}
	float getIndirectIndex( const in int i ) {
		int size = textureSize( batchingIdTexture, 0 ).x;
		int x = i % size;
		int y = i / size;
		return float( texelFetch( batchingIdTexture, ivec2( x, y ), 0 ).r );
	}
#endif
#ifdef USE_BATCHING_COLOR
	uniform sampler2D batchingColorTexture;
	vec4 getBatchingColor( const in float i ) {
		int size = textureSize( batchingColorTexture, 0 ).x;
		int j = int( i );
		int x = j % size;
		int y = j / size;
		return texelFetch( batchingColorTexture, ivec2( x, y ), 0 );
	}
#endif`,wy=`#ifdef USE_BATCHING
	mat4 batchingMatrix = getBatchingMatrix( getIndirectIndex( gl_DrawID ) );
#endif`,Ey=`vec3 transformed = vec3( position );
#ifdef USE_ALPHAHASH
	vPosition = vec3( position );
#endif`,Ay=`vec3 objectNormal = vec3( normal );
#ifdef USE_TANGENT
	vec3 objectTangent = vec3( tangent.xyz );
#endif`,Ry=`float G_BlinnPhong_Implicit( ) {
	return 0.25;
}
float D_BlinnPhong( const in float shininess, const in float dotNH ) {
	return RECIPROCAL_PI * ( shininess * 0.5 + 1.0 ) * pow( dotNH, shininess );
}
vec3 BRDF_BlinnPhong( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in vec3 specularColor, const in float shininess ) {
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNH = saturate( dot( normal, halfDir ) );
	float dotVH = saturate( dot( viewDir, halfDir ) );
	vec3 F = F_Schlick( specularColor, 1.0, dotVH );
	float G = G_BlinnPhong_Implicit( );
	float D = D_BlinnPhong( shininess, dotNH );
	return F * ( G * D );
} // validated`,Cy=`#ifdef USE_IRIDESCENCE
	const mat3 XYZ_TO_REC709 = mat3(
		 3.2404542, -0.9692660,  0.0556434,
		-1.5371385,  1.8760108, -0.2040259,
		-0.4985314,  0.0415560,  1.0572252
	);
	vec3 Fresnel0ToIor( vec3 fresnel0 ) {
		vec3 sqrtF0 = sqrt( fresnel0 );
		return ( vec3( 1.0 ) + sqrtF0 ) / ( vec3( 1.0 ) - sqrtF0 );
	}
	vec3 IorToFresnel0( vec3 transmittedIor, float incidentIor ) {
		return pow2( ( transmittedIor - vec3( incidentIor ) ) / ( transmittedIor + vec3( incidentIor ) ) );
	}
	float IorToFresnel0( float transmittedIor, float incidentIor ) {
		return pow2( ( transmittedIor - incidentIor ) / ( transmittedIor + incidentIor ));
	}
	vec3 evalSensitivity( float OPD, vec3 shift ) {
		float phase = 2.0 * PI * OPD * 1.0e-9;
		vec3 val = vec3( 5.4856e-13, 4.4201e-13, 5.2481e-13 );
		vec3 pos = vec3( 1.6810e+06, 1.7953e+06, 2.2084e+06 );
		vec3 var = vec3( 4.3278e+09, 9.3046e+09, 6.6121e+09 );
		vec3 xyz = val * sqrt( 2.0 * PI * var ) * cos( pos * phase + shift ) * exp( - pow2( phase ) * var );
		xyz.x += 9.7470e-14 * sqrt( 2.0 * PI * 4.5282e+09 ) * cos( 2.2399e+06 * phase + shift[ 0 ] ) * exp( - 4.5282e+09 * pow2( phase ) );
		xyz /= 1.0685e-7;
		vec3 rgb = XYZ_TO_REC709 * xyz;
		return rgb;
	}
	vec3 evalIridescence( float outsideIOR, float eta2, float cosTheta1, float thinFilmThickness, vec3 baseF0 ) {
		vec3 I;
		float iridescenceIOR = mix( outsideIOR, eta2, smoothstep( 0.0, 0.03, thinFilmThickness ) );
		float sinTheta2Sq = pow2( outsideIOR / iridescenceIOR ) * ( 1.0 - pow2( cosTheta1 ) );
		float cosTheta2Sq = 1.0 - sinTheta2Sq;
		if ( cosTheta2Sq < 0.0 ) {
			return vec3( 1.0 );
		}
		float cosTheta2 = sqrt( cosTheta2Sq );
		float R0 = IorToFresnel0( iridescenceIOR, outsideIOR );
		float R12 = F_Schlick( R0, 1.0, cosTheta1 );
		float T121 = 1.0 - R12;
		float phi12 = 0.0;
		if ( iridescenceIOR < outsideIOR ) phi12 = PI;
		float phi21 = PI - phi12;
		vec3 baseIOR = Fresnel0ToIor( clamp( baseF0, 0.0, 0.9999 ) );		vec3 R1 = IorToFresnel0( baseIOR, iridescenceIOR );
		vec3 R23 = F_Schlick( R1, 1.0, cosTheta2 );
		vec3 phi23 = vec3( 0.0 );
		if ( baseIOR[ 0 ] < iridescenceIOR ) phi23[ 0 ] = PI;
		if ( baseIOR[ 1 ] < iridescenceIOR ) phi23[ 1 ] = PI;
		if ( baseIOR[ 2 ] < iridescenceIOR ) phi23[ 2 ] = PI;
		float OPD = 2.0 * iridescenceIOR * thinFilmThickness * cosTheta2;
		vec3 phi = vec3( phi21 ) + phi23;
		vec3 R123 = clamp( R12 * R23, 1e-5, 0.9999 );
		vec3 r123 = sqrt( R123 );
		vec3 Rs = pow2( T121 ) * R23 / ( vec3( 1.0 ) - R123 );
		vec3 C0 = R12 + Rs;
		I = C0;
		vec3 Cm = Rs - T121;
		for ( int m = 1; m <= 2; ++ m ) {
			Cm *= r123;
			vec3 Sm = 2.0 * evalSensitivity( float( m ) * OPD, float( m ) * phi );
			I += Cm * Sm;
		}
		return max( I, vec3( 0.0 ) );
	}
#endif`,Py=`#ifdef USE_BUMPMAP
	uniform sampler2D bumpMap;
	uniform float bumpScale;
	vec2 dHdxy_fwd() {
		vec2 dSTdx = dFdx( vBumpMapUv );
		vec2 dSTdy = dFdy( vBumpMapUv );
		float Hll = bumpScale * texture2D( bumpMap, vBumpMapUv ).x;
		float dBx = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdx ).x - Hll;
		float dBy = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdy ).x - Hll;
		return vec2( dBx, dBy );
	}
	vec3 perturbNormalArb( vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection ) {
		vec3 vSigmaX = normalize( dFdx( surf_pos.xyz ) );
		vec3 vSigmaY = normalize( dFdy( surf_pos.xyz ) );
		vec3 vN = surf_norm;
		vec3 R1 = cross( vSigmaY, vN );
		vec3 R2 = cross( vN, vSigmaX );
		float fDet = dot( vSigmaX, R1 ) * faceDirection;
		vec3 vGrad = sign( fDet ) * ( dHdxy.x * R1 + dHdxy.y * R2 );
		return normalize( abs( fDet ) * surf_norm - vGrad );
	}
#endif`,Iy=`#if NUM_CLIPPING_PLANES > 0
	vec4 plane;
	#ifdef ALPHA_TO_COVERAGE
		float distanceToPlane, distanceGradient;
		float clipOpacity = 1.0;
		#pragma unroll_loop_start
		for ( int i = 0; i < UNION_CLIPPING_PLANES; i ++ ) {
			plane = clippingPlanes[ i ];
			distanceToPlane = - dot( vClipPosition, plane.xyz ) + plane.w;
			distanceGradient = fwidth( distanceToPlane ) / 2.0;
			clipOpacity *= smoothstep( - distanceGradient, distanceGradient, distanceToPlane );
			if ( clipOpacity == 0.0 ) discard;
		}
		#pragma unroll_loop_end
		#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES
			float unionClipOpacity = 1.0;
			#pragma unroll_loop_start
			for ( int i = UNION_CLIPPING_PLANES; i < NUM_CLIPPING_PLANES; i ++ ) {
				plane = clippingPlanes[ i ];
				distanceToPlane = - dot( vClipPosition, plane.xyz ) + plane.w;
				distanceGradient = fwidth( distanceToPlane ) / 2.0;
				unionClipOpacity *= 1.0 - smoothstep( - distanceGradient, distanceGradient, distanceToPlane );
			}
			#pragma unroll_loop_end
			clipOpacity *= 1.0 - unionClipOpacity;
		#endif
		diffuseColor.a *= clipOpacity;
		if ( diffuseColor.a == 0.0 ) discard;
	#else
		#pragma unroll_loop_start
		for ( int i = 0; i < UNION_CLIPPING_PLANES; i ++ ) {
			plane = clippingPlanes[ i ];
			if ( dot( vClipPosition, plane.xyz ) > plane.w ) discard;
		}
		#pragma unroll_loop_end
		#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES
			bool clipped = true;
			#pragma unroll_loop_start
			for ( int i = UNION_CLIPPING_PLANES; i < NUM_CLIPPING_PLANES; i ++ ) {
				plane = clippingPlanes[ i ];
				clipped = ( dot( vClipPosition, plane.xyz ) > plane.w ) && clipped;
			}
			#pragma unroll_loop_end
			if ( clipped ) discard;
		#endif
	#endif
#endif`,Ly=`#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
	uniform vec4 clippingPlanes[ NUM_CLIPPING_PLANES ];
#endif`,Ny=`#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
#endif`,Dy=`#if NUM_CLIPPING_PLANES > 0
	vClipPosition = - mvPosition.xyz;
#endif`,Uy=`#if defined( USE_COLOR ) || defined( USE_COLOR_ALPHA )
	diffuseColor *= vColor;
#endif`,Fy=`#if defined( USE_COLOR ) || defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#endif`,Oy=`#if defined( USE_COLOR ) || defined( USE_COLOR_ALPHA ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )
	varying vec4 vColor;
#endif`,By=`#if defined( USE_COLOR ) || defined( USE_COLOR_ALPHA ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )
	vColor = vec4( 1.0 );
#endif
#ifdef USE_COLOR_ALPHA
	vColor *= color;
#elif defined( USE_COLOR )
	vColor.rgb *= color;
#endif
#ifdef USE_INSTANCING_COLOR
	vColor.rgb *= instanceColor.rgb;
#endif
#ifdef USE_BATCHING_COLOR
	vColor *= getBatchingColor( getIndirectIndex( gl_DrawID ) );
#endif`,zy=`#define PI 3.141592653589793
#define PI2 6.283185307179586
#define PI_HALF 1.5707963267948966
#define RECIPROCAL_PI 0.3183098861837907
#define RECIPROCAL_PI2 0.15915494309189535
#define EPSILON 1e-6
#ifndef saturate
#define saturate( a ) clamp( a, 0.0, 1.0 )
#endif
#define whiteComplement( a ) ( 1.0 - saturate( a ) )
float pow2( const in float x ) { return x*x; }
vec3 pow2( const in vec3 x ) { return x*x; }
float pow3( const in float x ) { return x*x*x; }
float pow4( const in float x ) { float x2 = x*x; return x2*x2; }
float max3( const in vec3 v ) { return max( max( v.x, v.y ), v.z ); }
float average( const in vec3 v ) { return dot( v, vec3( 0.3333333 ) ); }
highp float rand( const in vec2 uv ) {
	const highp float a = 12.9898, b = 78.233, c = 43758.5453;
	highp float dt = dot( uv.xy, vec2( a,b ) ), sn = mod( dt, PI );
	return fract( sin( sn ) * c );
}
#ifdef HIGH_PRECISION
	float precisionSafeLength( vec3 v ) { return length( v ); }
#else
	float precisionSafeLength( vec3 v ) {
		float maxComponent = max3( abs( v ) );
		return length( v / maxComponent ) * maxComponent;
	}
#endif
struct IncidentLight {
	vec3 color;
	vec3 direction;
	bool visible;
};
struct ReflectedLight {
	vec3 directDiffuse;
	vec3 directSpecular;
	vec3 indirectDiffuse;
	vec3 indirectSpecular;
};
#ifdef USE_ALPHAHASH
	varying vec3 vPosition;
#endif
vec3 transformDirection( in vec3 dir, in mat4 matrix ) {
	return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );
}
#define inverseTransformDirection transformDirectionByInverseViewMatrix
vec3 transformNormalByInverseViewMatrix( in vec3 normal, in mat4 viewMatrix ) {
	return normalize( ( vec4( normal, 0.0 ) * viewMatrix ).xyz );
}
vec3 transformDirectionByInverseViewMatrix( in vec3 dir, in mat4 viewMatrix ) {
	return normalize( ( vec4( dir, 0.0 ) * viewMatrix ).xyz );
}
bool isPerspectiveMatrix( mat4 m ) {
	return m[ 2 ][ 3 ] == - 1.0;
}
vec2 equirectUv( in vec3 dir ) {
	float u = atan( dir.z, dir.x ) * RECIPROCAL_PI2 + 0.5;
	float v = asin( clamp( dir.y, - 1.0, 1.0 ) ) * RECIPROCAL_PI + 0.5;
	return vec2( u, v );
}
vec3 BRDF_Lambert( const in vec3 diffuseColor ) {
	return RECIPROCAL_PI * diffuseColor;
}
vec3 F_Schlick( const in vec3 f0, const in float f90, const in float dotVH ) {
	float fresnel = exp2( ( - 5.55473 * dotVH - 6.98316 ) * dotVH );
	return f0 * ( 1.0 - fresnel ) + ( f90 * fresnel );
}
float F_Schlick( const in float f0, const in float f90, const in float dotVH ) {
	float fresnel = exp2( ( - 5.55473 * dotVH - 6.98316 ) * dotVH );
	return f0 * ( 1.0 - fresnel ) + ( f90 * fresnel );
} // validated`,ky=`#ifdef ENVMAP_TYPE_CUBE_UV
	#define cubeUV_minMipLevel 4.0
	#define cubeUV_minTileSize 16.0
	float getFace( vec3 direction ) {
		vec3 absDirection = abs( direction );
		float face = - 1.0;
		if ( absDirection.x > absDirection.z ) {
			if ( absDirection.x > absDirection.y )
				face = direction.x > 0.0 ? 0.0 : 3.0;
			else
				face = direction.y > 0.0 ? 1.0 : 4.0;
		} else {
			if ( absDirection.z > absDirection.y )
				face = direction.z > 0.0 ? 2.0 : 5.0;
			else
				face = direction.y > 0.0 ? 1.0 : 4.0;
		}
		return face;
	}
	vec2 getUV( vec3 direction, float face ) {
		vec2 uv;
		if ( face == 0.0 ) {
			uv = vec2( direction.z, direction.y ) / abs( direction.x );
		} else if ( face == 1.0 ) {
			uv = vec2( - direction.x, - direction.z ) / abs( direction.y );
		} else if ( face == 2.0 ) {
			uv = vec2( - direction.x, direction.y ) / abs( direction.z );
		} else if ( face == 3.0 ) {
			uv = vec2( - direction.z, direction.y ) / abs( direction.x );
		} else if ( face == 4.0 ) {
			uv = vec2( - direction.x, direction.z ) / abs( direction.y );
		} else {
			uv = vec2( direction.x, direction.y ) / abs( direction.z );
		}
		return 0.5 * ( uv + 1.0 );
	}
	vec3 bilinearCubeUV( sampler2D envMap, vec3 direction, float mipInt ) {
		float face = getFace( direction );
		float filterInt = max( cubeUV_minMipLevel - mipInt, 0.0 );
		mipInt = max( mipInt, cubeUV_minMipLevel );
		float faceSize = exp2( mipInt );
		highp vec2 uv = getUV( direction, face ) * ( faceSize - 2.0 ) + 1.0;
		if ( face > 2.0 ) {
			uv.y += faceSize;
			face -= 3.0;
		}
		uv.x += face * faceSize;
		uv.x += filterInt * 3.0 * cubeUV_minTileSize;
		uv.y += 4.0 * ( exp2( CUBEUV_MAX_MIP ) - faceSize );
		uv.x *= CUBEUV_TEXEL_WIDTH;
		uv.y *= CUBEUV_TEXEL_HEIGHT;
		#ifdef texture2DGradEXT
			return texture2DGradEXT( envMap, uv, vec2( 0.0 ), vec2( 0.0 ) ).rgb;
		#else
			return texture2D( envMap, uv ).rgb;
		#endif
	}
	#define cubeUV_r0 1.0
	#define cubeUV_m0 - 2.0
	#define cubeUV_r1 0.8
	#define cubeUV_m1 - 1.0
	#define cubeUV_r4 0.4
	#define cubeUV_m4 2.0
	#define cubeUV_r5 0.305
	#define cubeUV_m5 3.0
	#define cubeUV_r6 0.21
	#define cubeUV_m6 4.0
	float roughnessToMip( float roughness ) {
		float mip = 0.0;
		if ( roughness >= cubeUV_r1 ) {
			mip = ( cubeUV_r0 - roughness ) * ( cubeUV_m1 - cubeUV_m0 ) / ( cubeUV_r0 - cubeUV_r1 ) + cubeUV_m0;
		} else if ( roughness >= cubeUV_r4 ) {
			mip = ( cubeUV_r1 - roughness ) * ( cubeUV_m4 - cubeUV_m1 ) / ( cubeUV_r1 - cubeUV_r4 ) + cubeUV_m1;
		} else if ( roughness >= cubeUV_r5 ) {
			mip = ( cubeUV_r4 - roughness ) * ( cubeUV_m5 - cubeUV_m4 ) / ( cubeUV_r4 - cubeUV_r5 ) + cubeUV_m4;
		} else if ( roughness >= cubeUV_r6 ) {
			mip = ( cubeUV_r5 - roughness ) * ( cubeUV_m6 - cubeUV_m5 ) / ( cubeUV_r5 - cubeUV_r6 ) + cubeUV_m5;
		} else {
			mip = - 2.0 * log2( 1.16 * roughness );		}
		return mip;
	}
	vec4 textureCubeUV( sampler2D envMap, vec3 sampleDir, float roughness ) {
		float mip = clamp( roughnessToMip( roughness ), cubeUV_m0, CUBEUV_MAX_MIP );
		float mipF = fract( mip );
		float mipInt = floor( mip );
		vec3 color0 = bilinearCubeUV( envMap, sampleDir, mipInt );
		if ( mipF == 0.0 ) {
			return vec4( color0, 1.0 );
		} else {
			vec3 color1 = bilinearCubeUV( envMap, sampleDir, mipInt + 1.0 );
			return vec4( mix( color0, color1, mipF ), 1.0 );
		}
	}
#endif`,Vy=`vec3 transformedNormal = objectNormal;
#ifdef USE_TANGENT
	vec3 transformedTangent = objectTangent;
#endif
#ifdef USE_BATCHING
	mat3 bm = mat3( batchingMatrix );
	transformedNormal /= vec3( dot( bm[ 0 ], bm[ 0 ] ), dot( bm[ 1 ], bm[ 1 ] ), dot( bm[ 2 ], bm[ 2 ] ) );
	transformedNormal = bm * transformedNormal;
	#ifdef USE_TANGENT
		transformedTangent = bm * transformedTangent;
	#endif
#endif
#ifdef USE_INSTANCING
	mat3 im = mat3( instanceMatrix );
	transformedNormal /= vec3( dot( im[ 0 ], im[ 0 ] ), dot( im[ 1 ], im[ 1 ] ), dot( im[ 2 ], im[ 2 ] ) );
	transformedNormal = im * transformedNormal;
	#ifdef USE_TANGENT
		transformedTangent = im * transformedTangent;
	#endif
#endif
transformedNormal = normalMatrix * transformedNormal;
#ifdef FLIP_SIDED
	transformedNormal = - transformedNormal;
#endif
#ifdef USE_TANGENT
	transformedTangent = ( modelViewMatrix * vec4( transformedTangent, 0.0 ) ).xyz;
#endif`,Hy=`#ifdef USE_DISPLACEMENTMAP
	uniform sampler2D displacementMap;
	uniform float displacementScale;
	uniform float displacementBias;
#endif`,Gy=`#ifdef USE_DISPLACEMENTMAP
	transformed += normalize( objectNormal ) * ( texture2D( displacementMap, vDisplacementMapUv ).x * displacementScale + displacementBias );
#endif`,Wy=`#ifdef USE_EMISSIVEMAP
	vec4 emissiveColor = texture2D( emissiveMap, vEmissiveMapUv );
	#ifdef DECODE_VIDEO_TEXTURE_EMISSIVE
		emissiveColor = sRGBTransferEOTF( emissiveColor );
	#endif
	totalEmissiveRadiance *= emissiveColor.rgb;
#endif`,Xy=`#ifdef USE_EMISSIVEMAP
	uniform sampler2D emissiveMap;
#endif`,qy="gl_FragColor = linearToOutputTexel( gl_FragColor );",Yy=`vec4 LinearTransferOETF( in vec4 value ) {
	return value;
}
vec4 sRGBTransferEOTF( in vec4 value ) {
	return vec4( mix( pow( value.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), value.rgb * 0.0773993808, vec3( lessThanEqual( value.rgb, vec3( 0.04045 ) ) ) ), value.a );
}
vec4 sRGBTransferOETF( in vec4 value ) {
	return vec4( mix( pow( value.rgb, vec3( 0.41666 ) ) * 1.055 - vec3( 0.055 ), value.rgb * 12.92, vec3( lessThanEqual( value.rgb, vec3( 0.0031308 ) ) ) ), value.a );
}`,Zy=`#ifdef USE_ENVMAP
	#ifdef ENV_WORLDPOS
		vec3 cameraToFrag;
		if ( isOrthographic ) {
			cameraToFrag = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );
		} else {
			cameraToFrag = normalize( vWorldPosition - cameraPosition );
		}
		vec3 worldNormal = transformNormalByInverseViewMatrix( normal, viewMatrix );
		#ifdef ENVMAP_MODE_REFLECTION
			vec3 reflectVec = reflect( cameraToFrag, worldNormal );
		#else
			vec3 reflectVec = refract( cameraToFrag, worldNormal, refractionRatio );
		#endif
	#else
		vec3 reflectVec = vReflect;
	#endif
	#ifdef ENVMAP_TYPE_CUBE
		vec4 envColor = textureCube( envMap, envMapRotation * reflectVec );
		#ifdef ENVMAP_BLENDING_MULTIPLY
			outgoingLight = mix( outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity );
		#elif defined( ENVMAP_BLENDING_MIX )
			outgoingLight = mix( outgoingLight, envColor.xyz, specularStrength * reflectivity );
		#elif defined( ENVMAP_BLENDING_ADD )
			outgoingLight += envColor.xyz * specularStrength * reflectivity;
		#endif
	#endif
#endif`,Ky=`#ifdef USE_ENVMAP
	uniform float envMapIntensity;
	uniform mat3 envMapRotation;
	#ifdef ENVMAP_TYPE_CUBE
		uniform samplerCube envMap;
	#else
		uniform sampler2D envMap;
	#endif
#endif`,Jy=`#ifdef USE_ENVMAP
	uniform float reflectivity;
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		varying vec3 vWorldPosition;
		uniform float refractionRatio;
	#else
		varying vec3 vReflect;
	#endif
#endif`,$y=`#ifdef USE_ENVMAP
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		
		varying vec3 vWorldPosition;
	#else
		varying vec3 vReflect;
		uniform float refractionRatio;
	#endif
#endif`,jy=`#ifdef USE_ENVMAP
	#ifdef ENV_WORLDPOS
		vWorldPosition = worldPosition.xyz;
	#else
		vec3 cameraToVertex;
		if ( isOrthographic ) {
			cameraToVertex = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );
		} else {
			cameraToVertex = normalize( worldPosition.xyz - cameraPosition );
		}
		vec3 worldNormal = transformNormalByInverseViewMatrix( transformedNormal, viewMatrix );
		#ifdef ENVMAP_MODE_REFLECTION
			vReflect = reflect( cameraToVertex, worldNormal );
		#else
			vReflect = refract( cameraToVertex, worldNormal, refractionRatio );
		#endif
	#endif
#endif`,Qy=`#ifdef USE_FOG
	vFogDepth = - mvPosition.z;
#endif`,ev=`#ifdef USE_FOG
	varying float vFogDepth;
#endif`,tv=`#ifdef USE_FOG
	#ifdef FOG_EXP2
		float fogFactor = 1.0 - exp( - fogDensity * fogDensity * vFogDepth * vFogDepth );
	#else
		float fogFactor = smoothstep( fogNear, fogFar, vFogDepth );
	#endif
	gl_FragColor.rgb = mix( gl_FragColor.rgb, fogColor, fogFactor );
#endif`,nv=`#ifdef USE_FOG
	uniform vec3 fogColor;
	varying float vFogDepth;
	#ifdef FOG_EXP2
		uniform float fogDensity;
	#else
		uniform float fogNear;
		uniform float fogFar;
	#endif
#endif`,iv=`#ifdef USE_GRADIENTMAP
	uniform sampler2D gradientMap;
#endif
vec3 getGradientIrradiance( vec3 normal, vec3 lightDirection ) {
	float dotNL = dot( normal, lightDirection );
	vec2 coord = vec2( dotNL * 0.5 + 0.5, 0.0 );
	#ifdef USE_GRADIENTMAP
		return vec3( texture2D( gradientMap, coord ).r );
	#else
		vec2 fw = fwidth( coord ) * 0.5;
		return mix( vec3( 0.7 ), vec3( 1.0 ), smoothstep( 0.7 - fw.x, 0.7 + fw.x, coord.x ) );
	#endif
}`,sv=`#ifdef USE_LIGHTMAP
	uniform sampler2D lightMap;
	uniform float lightMapIntensity;
#endif`,rv=`LambertMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularStrength = specularStrength;`,ov=`varying vec3 vViewPosition;
struct LambertMaterial {
	vec3 diffuseColor;
	float specularStrength;
};
void RE_Direct_Lambert( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Lambert( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_Lambert
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Lambert`,av=`uniform bool receiveShadow;
uniform vec3 ambientLightColor;
#if defined( USE_LIGHT_PROBES )
	uniform vec3 lightProbe[ 9 ];
#endif
vec3 shGetIrradianceAt( in vec3 normal, in vec3 shCoefficients[ 9 ] ) {
	float x = normal.x, y = normal.y, z = normal.z;
	vec3 result = shCoefficients[ 0 ] * 0.886227;
	result += shCoefficients[ 1 ] * 2.0 * 0.511664 * y;
	result += shCoefficients[ 2 ] * 2.0 * 0.511664 * z;
	result += shCoefficients[ 3 ] * 2.0 * 0.511664 * x;
	result += shCoefficients[ 4 ] * 2.0 * 0.429043 * x * y;
	result += shCoefficients[ 5 ] * 2.0 * 0.429043 * y * z;
	result += shCoefficients[ 6 ] * ( 0.743125 * z * z - 0.247708 );
	result += shCoefficients[ 7 ] * 2.0 * 0.429043 * x * z;
	result += shCoefficients[ 8 ] * 0.429043 * ( x * x - y * y );
	return result;
}
vec3 getLightProbeIrradiance( const in vec3 lightProbe[ 9 ], const in vec3 normal ) {
	vec3 worldNormal = transformNormalByInverseViewMatrix( normal, viewMatrix );
	vec3 irradiance = shGetIrradianceAt( worldNormal, lightProbe );
	return irradiance;
}
vec3 getAmbientLightIrradiance( const in vec3 ambientLightColor ) {
	vec3 irradiance = ambientLightColor;
	return irradiance;
}
float getDistanceAttenuation( const in float lightDistance, const in float cutoffDistance, const in float decayExponent ) {
	float distanceFalloff = 1.0 / max( pow( lightDistance, decayExponent ), 0.01 );
	if ( cutoffDistance > 0.0 ) {
		distanceFalloff *= pow2( saturate( 1.0 - pow4( lightDistance / cutoffDistance ) ) );
	}
	return distanceFalloff;
}
float getSpotAttenuation( const in float coneCosine, const in float penumbraCosine, const in float angleCosine ) {
	return smoothstep( coneCosine, penumbraCosine, angleCosine );
}
#if NUM_SUN_LIGHTS > 0
	struct SunLight {
		vec3 direction;
		vec3 color;
	};
	uniform SunLight sunLights[ NUM_SUN_LIGHTS ];
	void getSunLightInfo( const in SunLight sunLight, out IncidentLight light ) {
		light.color = sunLight.color;
		light.direction = sunLight.direction;
		light.visible = true;
	}
#endif
#if NUM_DIR_LIGHTS > 0
	struct DirectionalLight {
		vec3 direction;
		vec3 color;
	};
	uniform DirectionalLight directionalLights[ NUM_DIR_LIGHTS ];
	void getDirectionalLightInfo( const in DirectionalLight directionalLight, out IncidentLight light ) {
		light.color = directionalLight.color;
		light.direction = directionalLight.direction;
		light.visible = true;
	}
#endif
#if NUM_POINT_LIGHTS > 0
	struct PointLight {
		vec3 position;
		vec3 color;
		float distance;
		float decay;
	};
	uniform PointLight pointLights[ NUM_POINT_LIGHTS ];
	void getPointLightInfo( const in PointLight pointLight, const in vec3 geometryPosition, out IncidentLight light ) {
		vec3 lVector = pointLight.position - geometryPosition;
		light.direction = normalize( lVector );
		float lightDistance = length( lVector );
		light.color = pointLight.color;
		light.color *= getDistanceAttenuation( lightDistance, pointLight.distance, pointLight.decay );
		light.visible = ( light.color != vec3( 0.0 ) );
	}
#endif
#if NUM_SPOT_LIGHTS > 0
	struct SpotLight {
		vec3 position;
		vec3 direction;
		vec3 color;
		float distance;
		float decay;
		float coneCos;
		float penumbraCos;
	};
	uniform SpotLight spotLights[ NUM_SPOT_LIGHTS ];
	void getSpotLightInfo( const in SpotLight spotLight, const in vec3 geometryPosition, out IncidentLight light ) {
		vec3 lVector = spotLight.position - geometryPosition;
		light.direction = normalize( lVector );
		float angleCos = dot( light.direction, spotLight.direction );
		float spotAttenuation = getSpotAttenuation( spotLight.coneCos, spotLight.penumbraCos, angleCos );
		if ( spotAttenuation > 0.0 ) {
			float lightDistance = length( lVector );
			light.color = spotLight.color * spotAttenuation;
			light.color *= getDistanceAttenuation( lightDistance, spotLight.distance, spotLight.decay );
			light.visible = ( light.color != vec3( 0.0 ) );
		} else {
			light.color = vec3( 0.0 );
			light.visible = false;
		}
	}
#endif
#if NUM_RECT_AREA_LIGHTS > 0
	struct RectAreaLight {
		vec3 color;
		vec3 position;
		vec3 halfWidth;
		vec3 halfHeight;
	};
	uniform sampler2D ltc_1;	uniform sampler2D ltc_2;
	uniform RectAreaLight rectAreaLights[ NUM_RECT_AREA_LIGHTS ];
#endif
#if NUM_HEMI_LIGHTS > 0
	struct HemisphereLight {
		vec3 direction;
		vec3 skyColor;
		vec3 groundColor;
	};
	uniform HemisphereLight hemisphereLights[ NUM_HEMI_LIGHTS ];
	vec3 getHemisphereLightIrradiance( const in HemisphereLight hemiLight, const in vec3 normal ) {
		float dotNL = dot( normal, hemiLight.direction );
		float hemiDiffuseWeight = 0.5 * dotNL + 0.5;
		vec3 irradiance = mix( hemiLight.groundColor, hemiLight.skyColor, hemiDiffuseWeight );
		return irradiance;
	}
#endif
#include <lightprobes_pars_fragment>`,cv=`#ifdef USE_ENVMAP
	vec3 getIBLIrradiance( const in vec3 normal ) {
		#ifdef ENVMAP_TYPE_CUBE_UV
			vec3 worldNormal = transformNormalByInverseViewMatrix( normal, viewMatrix );
			vec4 envMapColor = textureCubeUV( envMap, envMapRotation * worldNormal, 1.0 );
			return PI * envMapColor.rgb * envMapIntensity;
		#else
			return vec3( 0.0 );
		#endif
	}
	vec3 getIBLRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness ) {
		#ifdef ENVMAP_TYPE_CUBE_UV
			vec3 reflectVec = reflect( - viewDir, normal );
			reflectVec = normalize( mix( reflectVec, normal, pow4( roughness ) ) );
			reflectVec = transformDirectionByInverseViewMatrix( reflectVec, viewMatrix );
			vec4 envMapColor = textureCubeUV( envMap, envMapRotation * reflectVec, roughness );
			return envMapColor.rgb * envMapIntensity;
		#else
			return vec3( 0.0 );
		#endif
	}
	#ifdef USE_RETROREFLECTION
		vec3 getIBLRetroRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness ) {
			#ifdef ENVMAP_TYPE_CUBE_UV
				vec3 retroVec = normalize( mix( viewDir, normal, pow4( roughness ) ) );
				retroVec = transformDirectionByInverseViewMatrix( retroVec, viewMatrix );
				vec4 envMapColor = textureCubeUV( envMap, envMapRotation * retroVec, roughness );
				return envMapColor.rgb * envMapIntensity;
			#else
				return vec3( 0.0 );
			#endif
		}
	#endif
	#ifdef USE_ANISOTROPY
		vec3 getIBLAnisotropyRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness, const in vec3 bitangent, const in float anisotropy ) {
			#ifdef ENVMAP_TYPE_CUBE_UV
				vec3 bentNormal = cross( bitangent, viewDir );
				bentNormal = normalize( cross( bentNormal, bitangent ) );
				bentNormal = normalize( mix( bentNormal, normal, pow2( pow2( 1.0 - anisotropy * ( 1.0 - roughness ) ) ) ) );
				return getIBLRadiance( viewDir, bentNormal, roughness );
			#else
				return vec3( 0.0 );
			#endif
		}
		#ifdef USE_RETROREFLECTION
			vec3 getIBLAnisotropyRetroRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness, const in vec3 bitangent, const in float anisotropy ) {
				#ifdef ENVMAP_TYPE_CUBE_UV
					vec3 bentNormal = cross( bitangent, viewDir );
					bentNormal = normalize( cross( bentNormal, bitangent ) );
					bentNormal = normalize( mix( bentNormal, normal, pow2( pow2( 1.0 - anisotropy * ( 1.0 - roughness ) ) ) ) );
					return getIBLRetroRadiance( viewDir, bentNormal, roughness );
				#else
					return vec3( 0.0 );
				#endif
			}
		#endif
	#endif
#endif`,lv=`ToonMaterial material;
material.diffuseColor = diffuseColor.rgb;`,uv=`varying vec3 vViewPosition;
struct ToonMaterial {
	vec3 diffuseColor;
};
void RE_Direct_Toon( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {
	vec3 irradiance = getGradientIrradiance( geometryNormal, directLight.direction ) * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Toon( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_Toon
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Toon`,hv=`BlinnPhongMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularColor = specular;
material.specularShininess = shininess;
material.specularStrength = specularStrength;`,fv=`varying vec3 vViewPosition;
struct BlinnPhongMaterial {
	vec3 diffuseColor;
	vec3 specularColor;
	float specularShininess;
	float specularStrength;
};
void RE_Direct_BlinnPhong( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
	reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong( directLight.direction, geometryViewDir, geometryNormal, material.specularColor, material.specularShininess ) * material.specularStrength;
}
void RE_IndirectDiffuse_BlinnPhong( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_BlinnPhong
#define RE_IndirectDiffuse		RE_IndirectDiffuse_BlinnPhong`,dv=`PhysicalMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.diffuseContribution = diffuseColor.rgb * ( 1.0 - metalnessFactor );
material.metalness = metalnessFactor;
vec3 dxy = max( abs( dFdx( nonPerturbedNormal ) ), abs( dFdy( nonPerturbedNormal ) ) );
float geometryRoughness = max( max( dxy.x, dxy.y ), dxy.z );
material.roughness = max( roughnessFactor, 0.0525 );material.roughness += geometryRoughness;
material.roughness = min( material.roughness, 1.0 );
#ifdef IOR
	material.ior = ior;
	#ifdef USE_SPECULAR
		float specularIntensityFactor = specularIntensity;
		vec3 specularColorFactor = specularColor;
		#ifdef USE_SPECULAR_COLORMAP
			specularColorFactor *= texture2D( specularColorMap, vSpecularColorMapUv ).rgb;
		#endif
		#ifdef USE_SPECULAR_INTENSITYMAP
			specularIntensityFactor *= texture2D( specularIntensityMap, vSpecularIntensityMapUv ).a;
		#endif
		material.specularF90 = mix( specularIntensityFactor, 1.0, metalnessFactor );
	#else
		float specularIntensityFactor = 1.0;
		vec3 specularColorFactor = vec3( 1.0 );
		material.specularF90 = 1.0;
	#endif
	material.specularColor = min( pow2( ( material.ior - 1.0 ) / ( material.ior + 1.0 ) ) * specularColorFactor, vec3( 1.0 ) ) * specularIntensityFactor;
	material.specularColorBlended = mix( material.specularColor, diffuseColor.rgb, metalnessFactor );
#else
	material.specularColor = vec3( 0.04 );
	material.specularColorBlended = mix( material.specularColor, diffuseColor.rgb, metalnessFactor );
	material.specularF90 = 1.0;
#endif
#ifdef USE_CLEARCOAT
	material.clearcoat = clearcoat;
	material.clearcoatRoughness = clearcoatRoughness;
	material.clearcoatF0 = vec3( 0.04 );
	material.clearcoatF90 = 1.0;
	#ifdef USE_CLEARCOATMAP
		material.clearcoat *= texture2D( clearcoatMap, vClearcoatMapUv ).x;
	#endif
	#ifdef USE_CLEARCOAT_ROUGHNESSMAP
		material.clearcoatRoughness *= texture2D( clearcoatRoughnessMap, vClearcoatRoughnessMapUv ).y;
	#endif
	material.clearcoat = saturate( material.clearcoat );	material.clearcoatRoughness = max( material.clearcoatRoughness, 0.0525 );
	material.clearcoatRoughness += geometryRoughness;
	material.clearcoatRoughness = min( material.clearcoatRoughness, 1.0 );
#endif
#ifdef USE_DISPERSION
	material.dispersion = dispersion;
#endif
#ifdef USE_RETROREFLECTION
	material.retroreflectivity = retroreflectivity;
#endif
#ifdef USE_IRIDESCENCE
	material.iridescence = iridescence;
	material.iridescenceIOR = iridescenceIOR;
	#ifdef USE_IRIDESCENCEMAP
		material.iridescence *= texture2D( iridescenceMap, vIridescenceMapUv ).r;
	#endif
	#ifdef USE_IRIDESCENCE_THICKNESSMAP
		material.iridescenceThickness = (iridescenceThicknessMaximum - iridescenceThicknessMinimum) * texture2D( iridescenceThicknessMap, vIridescenceThicknessMapUv ).g + iridescenceThicknessMinimum;
	#else
		material.iridescenceThickness = iridescenceThicknessMaximum;
	#endif
#endif
#ifdef USE_SHEEN
	material.sheenColor = sheenColor;
	#ifdef USE_SHEEN_COLORMAP
		material.sheenColor *= texture2D( sheenColorMap, vSheenColorMapUv ).rgb;
	#endif
	material.sheenRoughness = clamp( sheenRoughness, 0.0001, 1.0 );
	#ifdef USE_SHEEN_ROUGHNESSMAP
		material.sheenRoughness *= texture2D( sheenRoughnessMap, vSheenRoughnessMapUv ).a;
	#endif
#endif
#ifdef USE_ANISOTROPY
	#ifdef USE_ANISOTROPYMAP
		mat2 anisotropyMat = mat2( anisotropyVector.x, anisotropyVector.y, - anisotropyVector.y, anisotropyVector.x );
		vec3 anisotropyPolar = texture2D( anisotropyMap, vAnisotropyMapUv ).rgb;
		vec2 anisotropyV = anisotropyMat * normalize( 2.0 * anisotropyPolar.rg - vec2( 1.0 ) ) * anisotropyPolar.b;
	#else
		vec2 anisotropyV = anisotropyVector;
	#endif
	material.anisotropy = length( anisotropyV );
	if( material.anisotropy == 0.0 ) {
		anisotropyV = vec2( 1.0, 0.0 );
	} else {
		anisotropyV /= material.anisotropy;
		material.anisotropy = saturate( material.anisotropy );
	}
	material.alphaT = mix( pow2( material.roughness ), 1.0, pow2( material.anisotropy ) );
	material.anisotropyT = tbn[ 0 ] * anisotropyV.x + tbn[ 1 ] * anisotropyV.y;
	material.anisotropyB = tbn[ 1 ] * anisotropyV.x - tbn[ 0 ] * anisotropyV.y;
#endif`,pv=`uniform sampler2D dfgLUT;
struct PhysicalMaterial {
	vec3 diffuseColor;
	vec3 diffuseContribution;
	vec3 specularColor;
	vec3 specularColorBlended;
	float roughness;
	float metalness;
	float specularF90;
	float dispersion;
	vec2 dfg;
	vec3 multiScatteringCompensation;
	#ifdef USE_RETROREFLECTION
		float retroreflectivity;
	#endif
	#ifdef USE_CLEARCOAT
		float clearcoat;
		float clearcoatRoughness;
		vec3 clearcoatF0;
		float clearcoatF90;
	#endif
	#ifdef USE_IRIDESCENCE
		float iridescence;
		float iridescenceIOR;
		float iridescenceThickness;
		vec3 iridescenceFresnel;
		vec3 iridescenceF0Dielectric;
		vec3 iridescenceF0Metallic;
	#endif
	#ifdef USE_SHEEN
		vec3 sheenColor;
		float sheenRoughness;
	#endif
	#ifdef IOR
		float ior;
	#endif
	#ifdef USE_TRANSMISSION
		float transmission;
		float transmissionAlpha;
		float thickness;
		float attenuationDistance;
		vec3 attenuationColor;
	#endif
	#ifdef USE_ANISOTROPY
		float anisotropy;
		float alphaT;
		vec3 anisotropyT;
		vec3 anisotropyB;
	#endif
};
vec3 clearcoatSpecularDirect = vec3( 0.0 );
vec3 clearcoatSpecularIndirect = vec3( 0.0 );
vec3 sheenSpecularDirect = vec3( 0.0 );
vec3 sheenSpecularIndirect = vec3(0.0 );
vec3 Schlick_to_F0( const in vec3 f, const in float f90, const in float dotVH ) {
    float x = clamp( 1.0 - dotVH, 0.0, 1.0 );
    float x2 = x * x;
    float x5 = clamp( x * x2 * x2, 0.0, 0.9999 );
    return ( f - vec3( f90 ) * x5 ) / ( 1.0 - x5 );
}
float V_GGX_SmithCorrelated( const in float alpha, const in float dotNL, const in float dotNV ) {
	float a2 = pow2( alpha );
	float gv = dotNL * sqrt( a2 + ( 1.0 - a2 ) * pow2( dotNV ) );
	float gl = dotNV * sqrt( a2 + ( 1.0 - a2 ) * pow2( dotNL ) );
	return 0.5 / max( gv + gl, EPSILON );
}
float D_GGX( const in float alpha, const in float dotNH ) {
	float a2 = pow2( alpha );
	float denom = pow2( dotNH ) * ( a2 - 1.0 ) + 1.0;
	return RECIPROCAL_PI * a2 / pow2( denom );
}
#ifdef USE_ANISOTROPY
	float V_GGX_SmithCorrelated_Anisotropic( const in float alphaT, const in float alphaB, const in float dotTV, const in float dotBV, const in float dotTL, const in float dotBL, const in float dotNV, const in float dotNL ) {
		float gv = dotNL * length( vec3( alphaT * dotTV, alphaB * dotBV, dotNV ) );
		float gl = dotNV * length( vec3( alphaT * dotTL, alphaB * dotBL, dotNL ) );
		return 0.5 / max( gv + gl, EPSILON );
	}
	float D_GGX_Anisotropic( const in float alphaT, const in float alphaB, const in float dotNH, const in float dotTH, const in float dotBH ) {
		float a2 = alphaT * alphaB;
		highp vec3 v = vec3( alphaB * dotTH, alphaT * dotBH, a2 * dotNH );
		highp float v2 = dot( v, v );
		float w2 = a2 / v2;
		return RECIPROCAL_PI * a2 * pow2 ( w2 );
	}
#endif
#ifdef USE_CLEARCOAT
	vec3 BRDF_GGX_Clearcoat( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material) {
		vec3 f0 = material.clearcoatF0;
		float f90 = material.clearcoatF90;
		float roughness = material.clearcoatRoughness;
		float alpha = pow2( roughness );
		vec3 halfDir = normalize( lightDir + viewDir );
		float dotNL = saturate( dot( normal, lightDir ) );
		float dotNV = saturate( dot( normal, viewDir ) );
		float dotNH = saturate( dot( normal, halfDir ) );
		float dotVH = saturate( dot( viewDir, halfDir ) );
		vec3 F = F_Schlick( f0, f90, dotVH );
		float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );
		float D = D_GGX( alpha, dotNH );
		return F * ( V * D );
	}
#endif
vec3 BRDF_GGX( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material ) {
	vec3 f0 = material.specularColorBlended;
	float f90 = material.specularF90;
	float roughness = material.roughness;
	float alpha = pow2( roughness );
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNL = saturate( dot( normal, lightDir ) );
	float dotNV = saturate( dot( normal, viewDir ) );
	float dotNH = saturate( dot( normal, halfDir ) );
	float dotVH = saturate( dot( viewDir, halfDir ) );
	vec3 F = F_Schlick( f0, f90, dotVH );
	#ifdef USE_IRIDESCENCE
		F = mix( F, material.iridescenceFresnel, material.iridescence );
	#endif
	#ifdef USE_ANISOTROPY
		float dotTL = dot( material.anisotropyT, lightDir );
		float dotTV = dot( material.anisotropyT, viewDir );
		float dotTH = dot( material.anisotropyT, halfDir );
		float dotBL = dot( material.anisotropyB, lightDir );
		float dotBV = dot( material.anisotropyB, viewDir );
		float dotBH = dot( material.anisotropyB, halfDir );
		float V = V_GGX_SmithCorrelated_Anisotropic( material.alphaT, alpha, dotTV, dotBV, dotTL, dotBL, dotNV, dotNL );
		float D = D_GGX_Anisotropic( material.alphaT, alpha, dotNH, dotTH, dotBH );
	#else
		float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );
		float D = D_GGX( alpha, dotNH );
	#endif
	return F * ( V * D );
}
vec2 LTC_Uv( const in vec3 N, const in vec3 V, const in float roughness ) {
	const float LUT_SIZE = 64.0;
	const float LUT_SCALE = ( LUT_SIZE - 1.0 ) / LUT_SIZE;
	const float LUT_BIAS = 0.5 / LUT_SIZE;
	float dotNV = saturate( dot( N, V ) );
	vec2 uv = vec2( roughness, sqrt( 1.0 - dotNV ) );
	uv = uv * LUT_SCALE + LUT_BIAS;
	return uv;
}
float LTC_ClippedSphereFormFactor( const in vec3 f ) {
	float l = length( f );
	return max( ( l * l + f.z ) / ( l + 1.0 ), 0.0 );
}
vec3 LTC_EdgeVectorFormFactor( const in vec3 v1, const in vec3 v2 ) {
	float x = dot( v1, v2 );
	float y = abs( x );
	float a = 0.8543985 + ( 0.4965155 + 0.0145206 * y ) * y;
	float b = 3.4175940 + ( 4.1616724 + y ) * y;
	float v = a / b;
	float theta_sintheta = ( x > 0.0 ) ? v : 0.5 * inversesqrt( max( 1.0 - x * x, 1e-7 ) ) - v;
	return cross( v1, v2 ) * theta_sintheta;
}
vec3 LTC_Evaluate( const in vec3 N, const in vec3 V, const in vec3 P, const in mat3 mInv, const in vec3 rectCoords[ 4 ] ) {
	vec3 v1 = rectCoords[ 1 ] - rectCoords[ 0 ];
	vec3 v2 = rectCoords[ 3 ] - rectCoords[ 0 ];
	vec3 lightNormal = cross( v1, v2 );
	if( dot( lightNormal, P - rectCoords[ 0 ] ) < 0.0 ) return vec3( 0.0 );
	vec3 T1, T2;
	T1 = normalize( V - N * dot( V, N ) );
	T2 = - cross( N, T1 );
	mat3 mat = mInv * transpose( mat3( T1, T2, N ) );
	vec3 coords[ 4 ];
	coords[ 0 ] = mat * ( rectCoords[ 0 ] - P );
	coords[ 1 ] = mat * ( rectCoords[ 1 ] - P );
	coords[ 2 ] = mat * ( rectCoords[ 2 ] - P );
	coords[ 3 ] = mat * ( rectCoords[ 3 ] - P );
	coords[ 0 ] = normalize( coords[ 0 ] );
	coords[ 1 ] = normalize( coords[ 1 ] );
	coords[ 2 ] = normalize( coords[ 2 ] );
	coords[ 3 ] = normalize( coords[ 3 ] );
	vec3 vectorFormFactor = vec3( 0.0 );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 0 ], coords[ 1 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 1 ], coords[ 2 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 2 ], coords[ 3 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 3 ], coords[ 0 ] );
	float result = LTC_ClippedSphereFormFactor( vectorFormFactor );
	return vec3( result );
}
#if defined( USE_SHEEN )
float D_Charlie( float roughness, float dotNH ) {
	float alpha = pow2( roughness );
	float invAlpha = 1.0 / alpha;
	float cos2h = dotNH * dotNH;
	float sin2h = max( 1.0 - cos2h, 0.0078125 );
	return ( 2.0 + invAlpha ) * pow( sin2h, invAlpha * 0.5 ) / ( 2.0 * PI );
}
float V_Neubelt( float dotNV, float dotNL ) {
	return saturate( 1.0 / ( 4.0 * ( dotNL + dotNV - dotNL * dotNV ) ) );
}
vec3 BRDF_Sheen( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, vec3 sheenColor, const in float sheenRoughness ) {
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNL = saturate( dot( normal, lightDir ) );
	float dotNV = saturate( dot( normal, viewDir ) );
	float dotNH = saturate( dot( normal, halfDir ) );
	float D = D_Charlie( sheenRoughness, dotNH );
	float V = V_Neubelt( dotNV, dotNL );
	return sheenColor * ( D * V );
}
#endif
float IBLSheenBRDF( const in vec3 normal, const in vec3 viewDir, const in float roughness ) {
	float dotNV = saturate( dot( normal, viewDir ) );
	float r2 = roughness * roughness;
	float rInv = 1.0 / ( roughness + 0.1 );
	float a = -1.9362 + 1.0678 * roughness + 0.4573 * r2 - 0.8469 * rInv;
	float b = -0.6014 + 0.5538 * roughness - 0.4670 * r2 - 0.1255 * rInv;
	float DG = exp( a * dotNV + b );
	return saturate( DG );
}
vec3 EnvironmentBRDF( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness ) {
	float dotNV = saturate( dot( normal, viewDir ) );
	vec2 fab = texture2D( dfgLUT, vec2( roughness, dotNV ) ).rg;
	return specularColor * fab.x + specularF90 * fab.y;
}
#ifdef USE_IRIDESCENCE
void computeMultiscatteringIridescence( const in vec2 fab, const in vec3 specularColor, const in float specularF90, const in float iridescence, const in vec3 iridescenceF0, inout vec3 singleScatter, inout vec3 multiScatter ) {
#else
void computeMultiscattering( const in vec2 fab, const in vec3 specularColor, const in float specularF90, inout vec3 singleScatter, inout vec3 multiScatter ) {
#endif
	#ifdef USE_IRIDESCENCE
		vec3 Fr = mix( specularColor, iridescenceF0, iridescence );
	#else
		vec3 Fr = specularColor;
	#endif
	vec3 FssEss = Fr * fab.x + specularF90 * fab.y;
	float Ess = fab.x + fab.y;
	float Ems = 1.0 - Ess;
	vec3 Favg = Fr + ( 1.0 - Fr ) * 0.047619;	vec3 Fms = FssEss * Favg / ( 1.0 - Ems * Favg );
	singleScatter += FssEss;
	multiScatter += Fms * Ems;
}
#if NUM_RECT_AREA_LIGHTS > 0
	void RE_Direct_RectArea_Physical( const in RectAreaLight rectAreaLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
		vec3 normal = geometryNormal;
		vec3 viewDir = geometryViewDir;
		vec3 position = geometryPosition;
		vec3 lightPos = rectAreaLight.position;
		vec3 halfWidth = rectAreaLight.halfWidth;
		vec3 halfHeight = rectAreaLight.halfHeight;
		vec3 lightColor = rectAreaLight.color;
		float roughness = material.roughness;
		vec3 rectCoords[ 4 ];
		rectCoords[ 0 ] = lightPos + halfWidth - halfHeight;		rectCoords[ 1 ] = lightPos - halfWidth - halfHeight;
		rectCoords[ 2 ] = lightPos - halfWidth + halfHeight;
		rectCoords[ 3 ] = lightPos + halfWidth + halfHeight;
		vec2 uv = LTC_Uv( normal, viewDir, roughness );
		vec4 t1 = texture2D( ltc_1, uv );
		vec4 t2 = texture2D( ltc_2, uv );
		mat3 mInv = mat3(
			vec3( t1.x, 0, t1.y ),
			vec3(    0, 1,    0 ),
			vec3( t1.z, 0, t1.w )
		);
		vec3 fresnel = ( material.specularColorBlended * t2.x + ( material.specularF90 - material.specularColorBlended ) * t2.y );
		reflectedLight.directSpecular += lightColor * fresnel * LTC_Evaluate( normal, viewDir, position, mInv, rectCoords );
		reflectedLight.directDiffuse += lightColor * material.diffuseContribution * LTC_Evaluate( normal, viewDir, position, mat3( 1.0 ), rectCoords );
		#ifdef USE_CLEARCOAT
			vec3 Ncc = geometryClearcoatNormal;
			vec2 uvClearcoat = LTC_Uv( Ncc, viewDir, material.clearcoatRoughness );
			vec4 t1Clearcoat = texture2D( ltc_1, uvClearcoat );
			vec4 t2Clearcoat = texture2D( ltc_2, uvClearcoat );
			mat3 mInvClearcoat = mat3(
				vec3( t1Clearcoat.x, 0, t1Clearcoat.y ),
				vec3(             0, 1,             0 ),
				vec3( t1Clearcoat.z, 0, t1Clearcoat.w )
			);
			vec3 fresnelClearcoat = material.clearcoatF0 * t2Clearcoat.x + ( material.clearcoatF90 - material.clearcoatF0 ) * t2Clearcoat.y;
			clearcoatSpecularDirect += lightColor * fresnelClearcoat * LTC_Evaluate( Ncc, viewDir, position, mInvClearcoat, rectCoords );
		#endif
	}
#endif
void RE_Direct_Physical( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	#ifdef USE_CLEARCOAT
		float dotNLcc = saturate( dot( geometryClearcoatNormal, directLight.direction ) );
		vec3 ccIrradiance = dotNLcc * directLight.color;
		clearcoatSpecularDirect += ccIrradiance * BRDF_GGX_Clearcoat( directLight.direction, geometryViewDir, geometryClearcoatNormal, material );
	#endif
	#ifdef USE_SHEEN
 
 		sheenSpecularDirect += irradiance * BRDF_Sheen( directLight.direction, geometryViewDir, geometryNormal, material.sheenColor, material.sheenRoughness );
 
 		float sheenAlbedoV = IBLSheenBRDF( geometryNormal, geometryViewDir, material.sheenRoughness );
 		float sheenAlbedoL = IBLSheenBRDF( geometryNormal, directLight.direction, material.sheenRoughness );
 
 		float sheenEnergyComp = 1.0 - max3( material.sheenColor ) * max( sheenAlbedoV, sheenAlbedoL );
 
 		irradiance *= sheenEnergyComp;
 
 	#endif
	vec3 specularBRDF = BRDF_GGX( directLight.direction, geometryViewDir, geometryNormal, material );
	#ifdef USE_RETROREFLECTION
		vec3 retroViewDir = reflect( - geometryViewDir, geometryNormal );
		vec3 retroSpecularBRDF = BRDF_GGX( directLight.direction, retroViewDir, geometryNormal, material );
		specularBRDF = mix( specularBRDF, retroSpecularBRDF, saturate( material.retroreflectivity ) );
	#endif
	reflectedLight.directSpecular += irradiance * specularBRDF * material.multiScatteringCompensation;
	vec3 halfDir = normalize( directLight.direction + geometryViewDir );
	float dotVH = saturate( dot( geometryViewDir, halfDir ) );
	vec3 F = F_Schlick( material.specularColor, material.specularF90, dotVH );
	#ifdef USE_RETROREFLECTION
		vec3 retroHalfDir = normalize( directLight.direction + retroViewDir );
		float dotRetroVH = saturate( dot( retroViewDir, retroHalfDir ) );
		vec3 retroF = F_Schlick( material.specularColor, material.specularF90, dotRetroVH );
		F = mix( F, retroF, saturate( material.retroreflectivity ) );
	#endif
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseContribution ) * ( 1.0 - F );
}
void RE_IndirectDiffuse_Physical( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	vec3 singleScattering = vec3( 0.0 );
	vec3 multiScattering = vec3( 0.0 );
	#ifdef USE_IRIDESCENCE
		computeMultiscatteringIridescence( material.dfg, material.specularColor, material.specularF90, material.iridescence, material.iridescenceF0Dielectric, singleScattering, multiScattering );
	#else
		computeMultiscattering( material.dfg, material.specularColor, material.specularF90, singleScattering, multiScattering );
	#endif
	vec3 diffuse = irradiance * BRDF_Lambert( material.diffuseContribution ) * ( 1.0 - singleScattering - multiScattering );
	#ifdef USE_SHEEN
		float sheenAlbedo = IBLSheenBRDF( geometryNormal, geometryViewDir, material.sheenRoughness );
		sheenSpecularIndirect += irradiance * material.sheenColor * sheenAlbedo * RECIPROCAL_PI;
		float sheenEnergyComp = 1.0 - max3( material.sheenColor ) * sheenAlbedo;
		diffuse *= sheenEnergyComp;
	#endif
	reflectedLight.indirectDiffuse += diffuse;
}
void RE_IndirectSpecular_Physical( const in vec3 radiance, const in vec3 irradiance, const in vec3 clearcoatRadiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight) {
	#ifdef USE_CLEARCOAT
		clearcoatSpecularIndirect += clearcoatRadiance * EnvironmentBRDF( geometryClearcoatNormal, geometryViewDir, material.clearcoatF0, material.clearcoatF90, material.clearcoatRoughness );
	#endif
	#ifdef USE_SHEEN
		sheenSpecularIndirect += irradiance * material.sheenColor * IBLSheenBRDF( geometryNormal, geometryViewDir, material.sheenRoughness ) * RECIPROCAL_PI;
 	#endif
	vec3 singleScatteringDielectric = vec3( 0.0 );
	vec3 multiScatteringDielectric = vec3( 0.0 );
	vec3 singleScatteringMetallic = vec3( 0.0 );
	vec3 multiScatteringMetallic = vec3( 0.0 );
	#ifdef USE_IRIDESCENCE
		computeMultiscatteringIridescence( material.dfg, material.specularColor, material.specularF90, material.iridescence, material.iridescenceF0Dielectric, singleScatteringDielectric, multiScatteringDielectric );
		computeMultiscatteringIridescence( material.dfg, material.diffuseColor, material.specularF90, material.iridescence, material.iridescenceF0Metallic, singleScatteringMetallic, multiScatteringMetallic );
	#else
		computeMultiscattering( material.dfg, material.specularColor, material.specularF90, singleScatteringDielectric, multiScatteringDielectric );
		computeMultiscattering( material.dfg, material.diffuseColor, material.specularF90, singleScatteringMetallic, multiScatteringMetallic );
	#endif
	vec3 singleScattering = mix( singleScatteringDielectric, singleScatteringMetallic, material.metalness );
	vec3 multiScattering = mix( multiScatteringDielectric, multiScatteringMetallic, material.metalness );
	vec3 totalScatteringDielectric = singleScatteringDielectric + multiScatteringDielectric;
	vec3 diffuse = material.diffuseContribution * ( 1.0 - totalScatteringDielectric );
	vec3 cosineWeightedIrradiance = irradiance * RECIPROCAL_PI;
	vec3 indirectSpecular = radiance * singleScattering;
	indirectSpecular += multiScattering * cosineWeightedIrradiance;
	vec3 indirectDiffuse = diffuse * cosineWeightedIrradiance;
	#ifdef USE_SHEEN
		float sheenAlbedo = IBLSheenBRDF( geometryNormal, geometryViewDir, material.sheenRoughness );
		float sheenEnergyComp = 1.0 - max3( material.sheenColor ) * sheenAlbedo;
		indirectSpecular *= sheenEnergyComp;
		indirectDiffuse *= sheenEnergyComp;
	#endif
	reflectedLight.indirectSpecular += indirectSpecular;
	reflectedLight.indirectDiffuse += indirectDiffuse;
}
#define RE_Direct				RE_Direct_Physical
#define RE_Direct_RectArea		RE_Direct_RectArea_Physical
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Physical
#define RE_IndirectSpecular		RE_IndirectSpecular_Physical
float computeSpecularOcclusion( const in float dotNV, const in float ambientOcclusion, const in float roughness ) {
	return saturate( pow( dotNV + ambientOcclusion, exp2( - 16.0 * roughness - 1.0 ) ) - 1.0 + ambientOcclusion );
}`,mv=`
vec3 geometryPosition = - vViewPosition;
vec3 geometryNormal = normal;
vec3 geometryViewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( vViewPosition );
vec3 geometryClearcoatNormal = vec3( 0.0 );
#ifdef USE_CLEARCOAT
	geometryClearcoatNormal = clearcoatNormal;
#endif
#ifdef USE_IRIDESCENCE
	float dotNVi = saturate( dot( normal, geometryViewDir ) );
	if ( material.iridescenceThickness == 0.0 ) {
		material.iridescence = 0.0;
	} else {
		material.iridescence = saturate( material.iridescence );
	}
	if ( material.iridescence > 0.0 ) {
		vec3 iridescenceFresnelDielectric = evalIridescence( 1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.specularColor );
		vec3 iridescenceFresnelMetallic = evalIridescence( 1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.diffuseColor );
		material.iridescenceFresnel = mix( iridescenceFresnelDielectric, iridescenceFresnelMetallic, material.metalness );
		material.iridescenceF0Dielectric = Schlick_to_F0( iridescenceFresnelDielectric, 1.0, dotNVi );
		material.iridescenceF0Metallic = Schlick_to_F0( iridescenceFresnelMetallic, 1.0, dotNVi );
	}
#endif
#ifdef STANDARD
	float dotNVms = saturate( dot( geometryNormal, geometryViewDir ) );
	material.dfg = texture2D( dfgLUT, vec2( material.roughness, dotNVms ) ).rg;
	#if ( NUM_SUN_LIGHTS > 0 || NUM_DIR_LIGHTS > 0 || NUM_POINT_LIGHTS > 0 || NUM_SPOT_LIGHTS > 0 )
		float EssMs = material.dfg.x + material.dfg.y;
		material.multiScatteringCompensation = 1.0 + material.specularColorBlended * ( 1.0 / EssMs - 1.0 );
	#endif
#endif
IncidentLight directLight;
#if ( NUM_POINT_LIGHTS > 0 ) && defined( RE_Direct )
	PointLight pointLight;
	#if defined( USE_SHADOWMAP ) && NUM_POINT_LIGHT_SHADOWS > 0
	PointLightShadow pointLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_POINT_LIGHTS; i ++ ) {
		pointLight = pointLights[ i ];
		getPointLightInfo( pointLight, geometryPosition, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS ) && ( defined( SHADOWMAP_TYPE_PCF ) || defined( SHADOWMAP_TYPE_BASIC ) )
		pointLightShadow = pointLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getPointShadow( pointShadowMap[ i ], pointLightShadow.shadowMapSize, pointLightShadow.shadowIntensity, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[ i ], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_SPOT_LIGHTS > 0 ) && defined( RE_Direct )
	SpotLight spotLight;
	vec4 spotColor;
	vec3 spotLightCoord;
	bool inSpotLightMap;
	#if defined( USE_SHADOWMAP ) && NUM_SPOT_LIGHT_SHADOWS > 0
	SpotLightShadow spotLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHTS; i ++ ) {
		spotLight = spotLights[ i ];
		getSpotLightInfo( spotLight, geometryPosition, directLight );
		#if ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )
		#define SPOT_LIGHT_MAP_INDEX UNROLLED_LOOP_INDEX
		#elif ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
		#define SPOT_LIGHT_MAP_INDEX NUM_SPOT_LIGHT_MAPS
		#else
		#define SPOT_LIGHT_MAP_INDEX ( UNROLLED_LOOP_INDEX - NUM_SPOT_LIGHT_SHADOWS + NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )
		#endif
		#if ( SPOT_LIGHT_MAP_INDEX < NUM_SPOT_LIGHT_MAPS )
			spotLightCoord = vSpotLightCoord[ i ].xyz / vSpotLightCoord[ i ].w;
			inSpotLightMap = all( lessThan( abs( spotLightCoord * 2. - 1. ), vec3( 1.0 ) ) );
			spotColor = texture2D( spotLightMap[ SPOT_LIGHT_MAP_INDEX ], spotLightCoord.xy );
			directLight.color = inSpotLightMap ? directLight.color * spotColor.rgb : directLight.color;
		#endif
		#undef SPOT_LIGHT_MAP_INDEX
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
		spotLightShadow = spotLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( spotShadowMap[ i ], spotLightShadow.shadowMapSize, spotLightShadow.shadowIntensity, spotLightShadow.shadowBias, spotLightShadow.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_SUN_LIGHTS > 0 ) && defined( RE_Direct )
	SunLight sunLight;
	#if defined( USE_SHADOWMAP ) && NUM_SUN_LIGHT_SHADOWS > 0
	SunLightShadow sunLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SUN_LIGHTS; i ++ ) {
		sunLight = sunLights[ i ];
		getSunLightInfo( sunLight, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_SUN_LIGHT_SHADOWS )
		sunLightShadow = sunLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getSunShadow( sunShadowMap[ i ], sunLightShadow, UNROLLED_LOOP_INDEX ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_DIR_LIGHTS > 0 ) && defined( RE_Direct )
	DirectionalLight directionalLight;
	#if defined( USE_SHADOWMAP ) && NUM_DIR_LIGHT_SHADOWS > 0
	DirectionalLightShadow directionalLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_DIR_LIGHTS; i ++ ) {
		directionalLight = directionalLights[ i ];
		getDirectionalLightInfo( directionalLight, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_DIR_LIGHT_SHADOWS )
		directionalLightShadow = directionalLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( directionalShadowMap[ i ], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowIntensity, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_RECT_AREA_LIGHTS > 0 ) && defined( RE_Direct_RectArea )
	RectAreaLight rectAreaLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_RECT_AREA_LIGHTS; i ++ ) {
		rectAreaLight = rectAreaLights[ i ];
		RE_Direct_RectArea( rectAreaLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if defined( RE_IndirectDiffuse )
	vec3 iblIrradiance = vec3( 0.0 );
	vec3 irradiance = getAmbientLightIrradiance( ambientLightColor );
	#if defined( USE_LIGHT_PROBES )
		irradiance += getLightProbeIrradiance( lightProbe, geometryNormal );
	#endif
	#if ( NUM_HEMI_LIGHTS > 0 )
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_HEMI_LIGHTS; i ++ ) {
			irradiance += getHemisphereLightIrradiance( hemisphereLights[ i ], geometryNormal );
		}
		#pragma unroll_loop_end
	#endif
	#ifdef USE_LIGHT_PROBES_GRID
		vec3 probeWorldPos = ( ( vec4( geometryPosition, 1.0 ) - viewMatrix[ 3 ] ) * viewMatrix ).xyz;
		vec3 probeWorldNormal = transformNormalByInverseViewMatrix( geometryNormal, viewMatrix );
		irradiance += getLightProbeGridIrradiance( probeWorldPos, probeWorldNormal );
	#endif
#endif
#if defined( RE_IndirectSpecular )
	vec3 radiance = vec3( 0.0 );
	vec3 clearcoatRadiance = vec3( 0.0 );
#endif`,gv=`#if defined( RE_IndirectDiffuse )
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
		vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;
		irradiance += lightMapIrradiance;
	#endif
	#if defined( USE_ENVMAP ) && defined( ENVMAP_TYPE_CUBE_UV )
		#if defined( STANDARD ) || defined( LAMBERT ) || defined( PHONG )
			iblIrradiance += getIBLIrradiance( geometryNormal );
		#endif
	#endif
#endif
#if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )
	#ifdef USE_ANISOTROPY
		vec3 iblRadiance = getIBLAnisotropyRadiance( geometryViewDir, geometryNormal, material.roughness, material.anisotropyB, material.anisotropy );
	#else
		vec3 iblRadiance = getIBLRadiance( geometryViewDir, geometryNormal, material.roughness );
	#endif
	#ifdef USE_RETROREFLECTION
		#ifdef USE_ANISOTROPY
			vec3 retroIBLRadiance = getIBLAnisotropyRetroRadiance( geometryViewDir, geometryNormal, material.roughness, material.anisotropyB, material.anisotropy );
		#else
			vec3 retroIBLRadiance = getIBLRetroRadiance( geometryViewDir, geometryNormal, material.roughness );
		#endif
		iblRadiance = mix( iblRadiance, retroIBLRadiance, saturate( material.retroreflectivity ) );
	#endif
	radiance += iblRadiance;
	#ifdef USE_CLEARCOAT
		clearcoatRadiance += getIBLRadiance( geometryViewDir, geometryClearcoatNormal, material.clearcoatRoughness );
	#endif
#endif`,xv=`#if defined( RE_IndirectDiffuse )
	#if defined( LAMBERT ) || defined( PHONG )
		irradiance += iblIrradiance;
	#endif
	RE_IndirectDiffuse( irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
#endif
#if defined( RE_IndirectSpecular )
	RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
#endif`,_v=`#ifdef USE_LIGHT_PROBES_GRID
uniform highp sampler3D probesSH;
uniform vec3 probesMin;
uniform vec3 probesMax;
uniform vec3 probesResolution;
vec3 getLightProbeGridIrradiance( vec3 worldPos, vec3 worldNormal ) {
	vec3 res = probesResolution;
	vec3 gridRange = probesMax - probesMin;
	vec3 resMinusOne = res - 1.0;
	vec3 probeSpacing = gridRange / resMinusOne;
	vec3 samplePos = worldPos + worldNormal * probeSpacing * 0.5;
	vec3 uvw = clamp( ( samplePos - probesMin ) / gridRange, 0.0, 1.0 );
	uvw = uvw * resMinusOne / res + 0.5 / res;
	float nz          = res.z;
	float paddedSlices = nz + 2.0;
	float atlasDepth  = 7.0 * paddedSlices;
	float uvZBase     = uvw.z * nz + 1.0;
	vec4 s0 = texture( probesSH, vec3( uvw.xy, ( uvZBase                       ) / atlasDepth ) );
	vec4 s1 = texture( probesSH, vec3( uvw.xy, ( uvZBase +       paddedSlices   ) / atlasDepth ) );
	vec4 s2 = texture( probesSH, vec3( uvw.xy, ( uvZBase + 2.0 * paddedSlices   ) / atlasDepth ) );
	vec4 s3 = texture( probesSH, vec3( uvw.xy, ( uvZBase + 3.0 * paddedSlices   ) / atlasDepth ) );
	vec4 s4 = texture( probesSH, vec3( uvw.xy, ( uvZBase + 4.0 * paddedSlices   ) / atlasDepth ) );
	vec4 s5 = texture( probesSH, vec3( uvw.xy, ( uvZBase + 5.0 * paddedSlices   ) / atlasDepth ) );
	vec4 s6 = texture( probesSH, vec3( uvw.xy, ( uvZBase + 6.0 * paddedSlices   ) / atlasDepth ) );
	vec3 c0 = s0.xyz;
	vec3 c1 = vec3( s0.w, s1.xy );
	vec3 c2 = vec3( s1.zw, s2.x );
	vec3 c3 = s2.yzw;
	vec3 c4 = s3.xyz;
	vec3 c5 = vec3( s3.w, s4.xy );
	vec3 c6 = vec3( s4.zw, s5.x );
	vec3 c7 = s5.yzw;
	vec3 c8 = s6.xyz;
	float x = worldNormal.x, y = worldNormal.y, z = worldNormal.z;
	vec3 result = c0 * 0.886227;
	result += c1 * 2.0 * 0.511664 * y;
	result += c2 * 2.0 * 0.511664 * z;
	result += c3 * 2.0 * 0.511664 * x;
	result += c4 * 2.0 * 0.429043 * x * y;
	result += c5 * 2.0 * 0.429043 * y * z;
	result += c6 * ( 0.743125 * z * z - 0.247708 );
	result += c7 * 2.0 * 0.429043 * x * z;
	result += c8 * 0.429043 * ( x * x - y * y );
	return max( result, vec3( 0.0 ) );
}
#endif`,yv=`#if defined( USE_LOGARITHMIC_DEPTH_BUFFER )
	gl_FragDepth = vIsPerspective == 0.0 ? gl_FragCoord.z : log2( vFragDepth ) * logDepthBufFC * 0.5;
#endif`,vv=`#if defined( USE_LOGARITHMIC_DEPTH_BUFFER )
	uniform float logDepthBufFC;
	varying float vFragDepth;
	varying float vIsPerspective;
#endif`,Sv=`#ifdef USE_LOGARITHMIC_DEPTH_BUFFER
	varying float vFragDepth;
	varying float vIsPerspective;
#endif`,bv=`#ifdef USE_LOGARITHMIC_DEPTH_BUFFER
	vFragDepth = 1.0 + gl_Position.w;
	vIsPerspective = float( isPerspectiveMatrix( projectionMatrix ) );
#endif`,Mv=`#ifdef USE_MAP
	vec4 sampledDiffuseColor = texture2D( map, vMapUv );
	#ifdef DECODE_VIDEO_TEXTURE
		sampledDiffuseColor = sRGBTransferEOTF( sampledDiffuseColor );
	#endif
	diffuseColor *= sampledDiffuseColor;
#endif`,Tv=`#ifdef USE_MAP
	uniform sampler2D map;
#endif`,wv=`#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
	#if defined( USE_POINTS_UV )
		vec2 uv = vUv;
	#else
		vec2 uv = ( uvTransform * vec3( gl_PointCoord.x, 1.0 - gl_PointCoord.y, 1 ) ).xy;
	#endif
#endif
#ifdef USE_MAP
	diffuseColor *= texture2D( map, uv );
#endif
#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, uv ).g;
#endif`,Ev=`#if defined( USE_POINTS_UV )
	varying vec2 vUv;
#else
	#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
		uniform mat3 uvTransform;
	#endif
#endif
#ifdef USE_MAP
	uniform sampler2D map;
#endif
#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`,Av=`float metalnessFactor = metalness;
#ifdef USE_METALNESSMAP
	vec4 texelMetalness = texture2D( metalnessMap, vMetalnessMapUv );
	metalnessFactor *= texelMetalness.b;
#endif`,Rv=`#ifdef USE_METALNESSMAP
	uniform sampler2D metalnessMap;
#endif`,Cv=`#ifdef USE_INSTANCING_MORPH
	float morphTargetInfluences[ MORPHTARGETS_COUNT ];
	float morphTargetBaseInfluence = texelFetch( morphTexture, ivec2( 0, gl_InstanceID ), 0 ).r;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		morphTargetInfluences[i] =  texelFetch( morphTexture, ivec2( i + 1, gl_InstanceID ), 0 ).r;
	}
#endif`,Pv=`#if defined( USE_MORPHCOLORS )
	vColor *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		#if defined( USE_COLOR_ALPHA )
			if ( morphTargetInfluences[ i ] != 0.0 ) vColor += getMorph( gl_VertexID, i, 2 ) * morphTargetInfluences[ i ];
		#elif defined( USE_COLOR )
			if ( morphTargetInfluences[ i ] != 0.0 ) vColor += getMorph( gl_VertexID, i, 2 ).rgb * morphTargetInfluences[ i ];
		#endif
	}
#endif`,Iv=`#ifdef USE_MORPHNORMALS
	objectNormal *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		if ( morphTargetInfluences[ i ] != 0.0 ) objectNormal += getMorph( gl_VertexID, i, 1 ).xyz * morphTargetInfluences[ i ];
	}
#endif`,Lv=`#ifdef USE_MORPHTARGETS
	#ifndef USE_INSTANCING_MORPH
		uniform float morphTargetBaseInfluence;
		uniform float morphTargetInfluences[ MORPHTARGETS_COUNT ];
	#endif
	uniform sampler2DArray morphTargetsTexture;
	uniform ivec2 morphTargetsTextureSize;
	vec4 getMorph( const in int vertexIndex, const in int morphTargetIndex, const in int offset ) {
		int texelIndex = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;
		int y = texelIndex / morphTargetsTextureSize.x;
		int x = texelIndex - y * morphTargetsTextureSize.x;
		ivec3 morphUV = ivec3( x, y, morphTargetIndex );
		return texelFetch( morphTargetsTexture, morphUV, 0 );
	}
#endif`,Nv=`#ifdef USE_MORPHTARGETS
	transformed *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		if ( morphTargetInfluences[ i ] != 0.0 ) transformed += getMorph( gl_VertexID, i, 0 ).xyz * morphTargetInfluences[ i ];
	}
#endif`,Dv=`float faceDirection = gl_FrontFacing ? 1.0 : - 1.0;
#ifdef FLAT_SHADED
	vec3 fdx = dFdx( vViewPosition );
	vec3 fdy = dFdy( vViewPosition );
	vec3 normal = normalize( cross( fdx, fdy ) );
#else
	vec3 normal = normalize( vNormal );
	#ifdef DOUBLE_SIDED
		normal *= faceDirection;
	#endif
#endif
#if defined( USE_NORMALMAP_TANGENTSPACE ) || defined( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY )
	#ifdef USE_TANGENT
		mat3 tbn = mat3( normalize( vTangent ), normalize( vBitangent ), normal );
	#else
		mat3 tbn = getTangentFrame( - vViewPosition, normal,
		#if defined( USE_NORMALMAP )
			vNormalMapUv
		#elif defined( USE_CLEARCOAT_NORMALMAP )
			vClearcoatNormalMapUv
		#else
			vUv
		#endif
		);
	#endif
	#ifdef DOUBLE_SIDED
		tbn[0] *= faceDirection;
		tbn[1] *= faceDirection;
	#endif
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	#ifdef USE_TANGENT
		mat3 tbn2 = mat3( normalize( vTangent ), normalize( vBitangent ), normal );
	#else
		mat3 tbn2 = getTangentFrame( - vViewPosition, normal, vClearcoatNormalMapUv );
	#endif
	#ifdef DOUBLE_SIDED
		tbn2[0] *= faceDirection;
		tbn2[1] *= faceDirection;
	#endif
#endif
vec3 nonPerturbedNormal = normal;`,Uv=`#ifdef USE_NORMALMAP_OBJECTSPACE
	normal = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;
	#ifdef FLIP_SIDED
		normal = - normal;
	#endif
	#ifdef DOUBLE_SIDED
		normal = normal * faceDirection;
	#endif
	normal = normalize( normalMatrix * normal );
#elif defined( USE_NORMALMAP_TANGENTSPACE )
	vec3 mapN = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;
	#if defined( USE_PACKED_NORMALMAP )
		mapN = vec3( mapN.xy, sqrt( saturate( 1.0 - dot( mapN.xy, mapN.xy ) ) ) );
	#endif
	mapN.xy *= normalScale;
	normal = normalize( tbn * mapN );
#elif defined( USE_BUMPMAP )
	normal = perturbNormalArb( - vViewPosition, normal, dHdxy_fwd(), faceDirection );
#endif`,Fv=`#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`,Ov=`#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`,Bv=`#ifndef FLAT_SHADED
	vNormal = normalize( transformedNormal );
	#ifdef USE_TANGENT
		vTangent = normalize( transformedTangent );
		vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );
		#ifdef FLIP_SIDED
			vBitangent = - vBitangent;
		#endif
	#endif
#endif`,zv=`#ifdef USE_NORMALMAP
	uniform sampler2D normalMap;
	uniform vec2 normalScale;
#endif
#ifdef USE_NORMALMAP_OBJECTSPACE
	uniform mat3 normalMatrix;
#endif
#if ! defined ( USE_TANGENT ) && ( defined ( USE_NORMALMAP_TANGENTSPACE ) || defined ( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY ) )
	mat3 getTangentFrame( vec3 eye_pos, vec3 surf_norm, vec2 uv ) {
		vec3 q0 = dFdx( eye_pos.xyz );
		vec3 q1 = dFdy( eye_pos.xyz );
		vec2 st0 = dFdx( uv.st );
		vec2 st1 = dFdy( uv.st );
		vec3 N = surf_norm;
		vec3 q1perp = cross( q1, N );
		vec3 q0perp = cross( N, q0 );
		vec3 T = q1perp * st0.x + q0perp * st1.x;
		vec3 B = q1perp * st0.y + q0perp * st1.y;
		float det = max( dot( T, T ), dot( B, B ) );
		float scale = ( det == 0.0 ) ? 0.0 : inversesqrt( det );
		return mat3( T * scale, B * scale, N );
	}
#endif`,kv=`#ifdef USE_CLEARCOAT
	vec3 clearcoatNormal = nonPerturbedNormal;
#endif`,Vv=`#ifdef USE_CLEARCOAT_NORMALMAP
	vec3 clearcoatMapN = texture2D( clearcoatNormalMap, vClearcoatNormalMapUv ).xyz * 2.0 - 1.0;
	clearcoatMapN.xy *= clearcoatNormalScale;
	clearcoatNormal = normalize( tbn2 * clearcoatMapN );
#endif`,Hv=`#ifdef USE_CLEARCOATMAP
	uniform sampler2D clearcoatMap;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	uniform sampler2D clearcoatNormalMap;
	uniform vec2 clearcoatNormalScale;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	uniform sampler2D clearcoatRoughnessMap;
#endif`,Gv=`#ifdef USE_IRIDESCENCEMAP
	uniform sampler2D iridescenceMap;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	uniform sampler2D iridescenceThicknessMap;
#endif`,Wv=`#ifdef OPAQUE
diffuseColor.a = 1.0;
#endif
#ifdef USE_TRANSMISSION
diffuseColor.a *= material.transmissionAlpha;
#endif
gl_FragColor = vec4( outgoingLight, diffuseColor.a );`,Xv=`vec3 packNormalToRGB( const in vec3 normal ) {
	return normalize( normal ) * 0.5 + 0.5;
}
vec3 unpackRGBToNormal( const in vec3 rgb ) {
	return 2.0 * rgb.xyz - 1.0;
}
const float PackUpscale = 256. / 255.;const float UnpackDownscale = 255. / 256.;const float ShiftRight8 = 1. / 256.;
const float Inv255 = 1. / 255.;
const vec4 PackFactors = vec4( 1.0, 256.0, 256.0 * 256.0, 256.0 * 256.0 * 256.0 );
const vec2 UnpackFactors2 = vec2( UnpackDownscale, 1.0 / PackFactors.g );
const vec3 UnpackFactors3 = vec3( UnpackDownscale / PackFactors.rg, 1.0 / PackFactors.b );
const vec4 UnpackFactors4 = vec4( UnpackDownscale / PackFactors.rgb, 1.0 / PackFactors.a );
vec4 packDepthToRGBA( const in float v ) {
	if( v <= 0.0 )
		return vec4( 0., 0., 0., 0. );
	if( v >= 1.0 )
		return vec4( 1., 1., 1., 1. );
	float vuf;
	float af = modf( v * PackFactors.a, vuf );
	float bf = modf( vuf * ShiftRight8, vuf );
	float gf = modf( vuf * ShiftRight8, vuf );
	return vec4( vuf * Inv255, gf * PackUpscale, bf * PackUpscale, af );
}
vec3 packDepthToRGB( const in float v ) {
	if( v <= 0.0 )
		return vec3( 0., 0., 0. );
	if( v >= 1.0 )
		return vec3( 1., 1., 1. );
	float vuf;
	float bf = modf( v * PackFactors.b, vuf );
	float gf = modf( vuf * ShiftRight8, vuf );
	return vec3( vuf * Inv255, gf * PackUpscale, bf );
}
vec2 packDepthToRG( const in float v ) {
	if( v <= 0.0 )
		return vec2( 0., 0. );
	if( v >= 1.0 )
		return vec2( 1., 1. );
	float vuf;
	float gf = modf( v * 256., vuf );
	return vec2( vuf * Inv255, gf );
}
float unpackRGBAToDepth( const in vec4 v ) {
	return dot( v, UnpackFactors4 );
}
float unpackRGBToDepth( const in vec3 v ) {
	return dot( v, UnpackFactors3 );
}
float unpackRGToDepth( const in vec2 v ) {
	return v.r * UnpackFactors2.r + v.g * UnpackFactors2.g;
}
vec4 pack2HalfToRGBA( const in vec2 v ) {
	vec4 r = vec4( v.x, fract( v.x * 255.0 ), v.y, fract( v.y * 255.0 ) );
	return vec4( r.x - r.y / 255.0, r.y, r.z - r.w / 255.0, r.w );
}
vec2 unpackRGBATo2Half( const in vec4 v ) {
	return vec2( v.x + ( v.y / 255.0 ), v.z + ( v.w / 255.0 ) );
}
float viewZToOrthographicDepth( const in float viewZ, const in float near, const in float far ) {
	return ( viewZ + near ) / ( near - far );
}
float orthographicDepthToViewZ( const in float depth, const in float near, const in float far ) {
	#ifdef USE_REVERSED_DEPTH_BUFFER
	
		return depth * ( far - near ) - far;
	#else
		return depth * ( near - far ) - near;
	#endif
}
float viewZToPerspectiveDepth( const in float viewZ, const in float near, const in float far ) {
	return ( ( near + viewZ ) * far ) / ( ( far - near ) * viewZ );
}
float perspectiveDepthToViewZ( const in float depth, const in float near, const in float far ) {
	
	#ifdef USE_REVERSED_DEPTH_BUFFER
		return ( near * far ) / ( ( near - far ) * depth - near );
	#else
		return ( near * far ) / ( ( far - near ) * depth - far );
	#endif
}`,qv=`#ifdef PREMULTIPLIED_ALPHA
	gl_FragColor.rgb *= gl_FragColor.a;
#endif`,Yv=`vec4 mvPosition = vec4( transformed, 1.0 );
#ifdef USE_BATCHING
	mvPosition = batchingMatrix * mvPosition;
#endif
#ifdef USE_INSTANCING
	mvPosition = instanceMatrix * mvPosition;
#endif
mvPosition = modelViewMatrix * mvPosition;
gl_Position = projectionMatrix * mvPosition;`,Zv=`#ifdef DITHERING
	gl_FragColor.rgb = dithering( gl_FragColor.rgb );
#endif`,Kv=`#ifdef DITHERING
	vec3 dithering( vec3 color ) {
		float grid_position = rand( gl_FragCoord.xy );
		vec3 dither_shift_RGB = vec3( 0.25 / 255.0, -0.25 / 255.0, 0.25 / 255.0 );
		dither_shift_RGB = mix( 2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position );
		return color + dither_shift_RGB;
	}
#endif`,Jv=`float roughnessFactor = roughness;
#ifdef USE_ROUGHNESSMAP
	vec4 texelRoughness = texture2D( roughnessMap, vRoughnessMapUv );
	roughnessFactor *= texelRoughness.g;
#endif`,$v=`#ifdef USE_ROUGHNESSMAP
	uniform sampler2D roughnessMap;
#endif`,jv=`#if NUM_SPOT_LIGHT_COORDS > 0
	varying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ];
#endif
#if NUM_SPOT_LIGHT_MAPS > 0
	uniform sampler2D spotLightMap[ NUM_SPOT_LIGHT_MAPS ];
#endif
#ifdef USE_SHADOWMAP
	#if NUM_SUN_LIGHT_SHADOWS > 0
		#define SUN_LIGHT_CASCADES 2
		#if defined( SHADOWMAP_TYPE_PCF )
			uniform sampler2DShadow sunShadowMap[ NUM_SUN_LIGHT_SHADOWS ];
		#else
			uniform sampler2D sunShadowMap[ NUM_SUN_LIGHT_SHADOWS ];
		#endif
		uniform mat4 sunShadowMatrix[ NUM_SUN_LIGHT_SHADOWS * SUN_LIGHT_CASCADES ];
		uniform vec4 sunShadowCascade[ NUM_SUN_LIGHT_SHADOWS * SUN_LIGHT_CASCADES ];
		varying vec4 vSunShadowWorldPosition;
		varying vec3 vSunShadowWorldNormal;
		struct SunLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform SunLightShadow sunLightShadows[ NUM_SUN_LIGHT_SHADOWS ];
	#endif
	#if NUM_DIR_LIGHT_SHADOWS > 0
		#if defined( SHADOWMAP_TYPE_PCF )
			uniform sampler2DShadow directionalShadowMap[ NUM_DIR_LIGHT_SHADOWS ];
		#else
			uniform sampler2D directionalShadowMap[ NUM_DIR_LIGHT_SHADOWS ];
		#endif
		varying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ];
		struct DirectionalLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ];
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
		#if defined( SHADOWMAP_TYPE_PCF )
			uniform sampler2DShadow spotShadowMap[ NUM_SPOT_LIGHT_SHADOWS ];
		#else
			uniform sampler2D spotShadowMap[ NUM_SPOT_LIGHT_SHADOWS ];
		#endif
		struct SpotLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ];
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		#if defined( SHADOWMAP_TYPE_PCF )
			uniform samplerCubeShadow pointShadowMap[ NUM_POINT_LIGHT_SHADOWS ];
		#elif defined( SHADOWMAP_TYPE_BASIC )
			uniform samplerCube pointShadowMap[ NUM_POINT_LIGHT_SHADOWS ];
		#endif
		varying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ];
		struct PointLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
			float shadowCameraNear;
			float shadowCameraFar;
		};
		uniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ];
	#endif
	#if defined( SHADOWMAP_TYPE_PCF )
		float interleavedGradientNoise( vec2 position ) {
			return fract( 52.9829189 * fract( dot( position, vec2( 0.06711056, 0.00583715 ) ) ) );
		}
		vec2 vogelDiskSample( int sampleIndex, int samplesCount, float phi ) {
			const float goldenAngle = 2.399963229728653;
			float r = sqrt( ( float( sampleIndex ) + 0.5 ) / float( samplesCount ) );
			float theta = float( sampleIndex ) * goldenAngle + phi;
			return vec2( cos( theta ), sin( theta ) ) * r;
		}
	#endif
	#if defined( SHADOWMAP_TYPE_PCF )
		float getShadow( sampler2DShadow shadowMap, vec2 shadowMapSize, float shadowIntensity, float shadowBias, float shadowRadius, vec4 shadowCoord ) {
			float shadow = 1.0;
			shadowCoord.xyz /= shadowCoord.w;
			shadowCoord.z += shadowBias;
			bool inFrustum = shadowCoord.x >= 0.0 && shadowCoord.x <= 1.0 && shadowCoord.y >= 0.0 && shadowCoord.y <= 1.0;
			bool frustumTest = inFrustum && shadowCoord.z <= 1.0;
			if ( frustumTest ) {
				vec2 texelSize = vec2( 1.0 ) / shadowMapSize;
				float radius = shadowRadius * texelSize.x;
				float phi = interleavedGradientNoise( gl_FragCoord.xy ) * PI2;
				shadow = (
					texture( shadowMap, vec3( shadowCoord.xy + vogelDiskSample( 0, 5, phi ) * radius, shadowCoord.z ) ) +
					texture( shadowMap, vec3( shadowCoord.xy + vogelDiskSample( 1, 5, phi ) * radius, shadowCoord.z ) ) +
					texture( shadowMap, vec3( shadowCoord.xy + vogelDiskSample( 2, 5, phi ) * radius, shadowCoord.z ) ) +
					texture( shadowMap, vec3( shadowCoord.xy + vogelDiskSample( 3, 5, phi ) * radius, shadowCoord.z ) ) +
					texture( shadowMap, vec3( shadowCoord.xy + vogelDiskSample( 4, 5, phi ) * radius, shadowCoord.z ) )
				) * 0.2;
			}
			return mix( 1.0, shadow, shadowIntensity );
		}
	#elif defined( SHADOWMAP_TYPE_VSM )
		float getShadow( sampler2D shadowMap, vec2 shadowMapSize, float shadowIntensity, float shadowBias, float shadowRadius, vec4 shadowCoord ) {
			float shadow = 1.0;
			shadowCoord.xyz /= shadowCoord.w;
			#ifdef USE_REVERSED_DEPTH_BUFFER
				shadowCoord.z -= shadowBias;
			#else
				shadowCoord.z += shadowBias;
			#endif
			bool inFrustum = shadowCoord.x >= 0.0 && shadowCoord.x <= 1.0 && shadowCoord.y >= 0.0 && shadowCoord.y <= 1.0;
			bool frustumTest = inFrustum && shadowCoord.z <= 1.0;
			if ( frustumTest ) {
				vec2 distribution = texture2D( shadowMap, shadowCoord.xy ).rg;
				float mean = distribution.x;
				float variance = distribution.y * distribution.y;
				#ifdef USE_REVERSED_DEPTH_BUFFER
					float hard_shadow = step( mean, shadowCoord.z );
				#else
					float hard_shadow = step( shadowCoord.z, mean );
				#endif
				
				if ( hard_shadow == 1.0 ) {
					shadow = 1.0;
				} else {
					variance = max( variance, 0.0000001 );
					float d = shadowCoord.z - mean;
					float p_max = variance / ( variance + d * d );
					p_max = clamp( ( p_max - 0.3 ) / 0.65, 0.0, 1.0 );
					shadow = max( hard_shadow, p_max );
				}
			}
			return mix( 1.0, shadow, shadowIntensity );
		}
	#else
		float getShadow( sampler2D shadowMap, vec2 shadowMapSize, float shadowIntensity, float shadowBias, float shadowRadius, vec4 shadowCoord ) {
			float shadow = 1.0;
			shadowCoord.xyz /= shadowCoord.w;
			#ifdef USE_REVERSED_DEPTH_BUFFER
				shadowCoord.z -= shadowBias;
			#else
				shadowCoord.z += shadowBias;
			#endif
			bool inFrustum = shadowCoord.x >= 0.0 && shadowCoord.x <= 1.0 && shadowCoord.y >= 0.0 && shadowCoord.y <= 1.0;
			bool frustumTest = inFrustum && shadowCoord.z <= 1.0;
			if ( frustumTest ) {
				float depth = texture2D( shadowMap, shadowCoord.xy ).r;
				#ifdef USE_REVERSED_DEPTH_BUFFER
					shadow = step( depth, shadowCoord.z );
				#else
					shadow = step( shadowCoord.z, depth );
				#endif
			}
			return mix( 1.0, shadow, shadowIntensity );
		}
	#endif
	#if NUM_SUN_LIGHT_SHADOWS > 0
		float getSunShadow(
			#if defined( SHADOWMAP_TYPE_PCF )
				sampler2DShadow shadowMap,
			#else
				sampler2D shadowMap,
			#endif
			SunLightShadow sunLightShadow,
			int shadowIndex
		) {
			vec4 shadowWorldPosition = vec4( vSunShadowWorldPosition.xyz + vSunShadowWorldNormal * sunLightShadow.shadowNormalBias, 1.0 );
			float viewDepth = vSunShadowWorldPosition.w;
			int cascadeOffset = shadowIndex * SUN_LIGHT_CASCADES;
			float shadow = 1.0;
			for ( int i = SUN_LIGHT_CASCADES - 1; i >= 0; i -- ) {
				vec4 cascade = sunShadowCascade[ cascadeOffset + i ];
				if ( viewDepth >= cascade.x && viewDepth < cascade.y ) {
					float cascadeShadow = getShadow(
						shadowMap,
						sunLightShadow.shadowMapSize,
						sunLightShadow.shadowIntensity,
						sunLightShadow.shadowBias,
						sunLightShadow.shadowRadius,
						sunShadowMatrix[ cascadeOffset + i ] * shadowWorldPosition
					);
					shadow = mix( cascadeShadow, shadow, smoothstep( cascade.z, cascade.y, viewDepth ) );
				}
			}
			return shadow;
		}
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
	#if defined( SHADOWMAP_TYPE_PCF )
	float getPointShadow( samplerCubeShadow shadowMap, vec2 shadowMapSize, float shadowIntensity, float shadowBias, float shadowRadius, vec4 shadowCoord, float shadowCameraNear, float shadowCameraFar ) {
		float shadow = 1.0;
		vec3 lightToPosition = shadowCoord.xyz;
		vec3 bd3D = normalize( lightToPosition );
		vec3 absVec = abs( lightToPosition );
		float viewSpaceZ = max( max( absVec.x, absVec.y ), absVec.z );
		if ( viewSpaceZ - shadowCameraFar <= 0.0 && viewSpaceZ - shadowCameraNear >= 0.0 ) {
			#ifdef USE_REVERSED_DEPTH_BUFFER
				float dp = ( shadowCameraNear * ( shadowCameraFar - viewSpaceZ ) ) / ( viewSpaceZ * ( shadowCameraFar - shadowCameraNear ) );
				dp -= shadowBias;
			#else
				float dp = ( shadowCameraFar * ( viewSpaceZ - shadowCameraNear ) ) / ( viewSpaceZ * ( shadowCameraFar - shadowCameraNear ) );
				dp += shadowBias;
			#endif
			float texelSize = shadowRadius / shadowMapSize.x;
			vec3 absDir = abs( bd3D );
			vec3 tangent = absDir.x > absDir.z ? vec3( 0.0, 1.0, 0.0 ) : vec3( 1.0, 0.0, 0.0 );
			tangent = normalize( cross( bd3D, tangent ) );
			vec3 bitangent = cross( bd3D, tangent );
			float phi = interleavedGradientNoise( gl_FragCoord.xy ) * PI2;
			vec2 sample0 = vogelDiskSample( 0, 5, phi );
			vec2 sample1 = vogelDiskSample( 1, 5, phi );
			vec2 sample2 = vogelDiskSample( 2, 5, phi );
			vec2 sample3 = vogelDiskSample( 3, 5, phi );
			vec2 sample4 = vogelDiskSample( 4, 5, phi );
			shadow = (
				texture( shadowMap, vec4( bd3D + ( tangent * sample0.x + bitangent * sample0.y ) * texelSize, dp ) ) +
				texture( shadowMap, vec4( bd3D + ( tangent * sample1.x + bitangent * sample1.y ) * texelSize, dp ) ) +
				texture( shadowMap, vec4( bd3D + ( tangent * sample2.x + bitangent * sample2.y ) * texelSize, dp ) ) +
				texture( shadowMap, vec4( bd3D + ( tangent * sample3.x + bitangent * sample3.y ) * texelSize, dp ) ) +
				texture( shadowMap, vec4( bd3D + ( tangent * sample4.x + bitangent * sample4.y ) * texelSize, dp ) )
			) * 0.2;
		}
		return mix( 1.0, shadow, shadowIntensity );
	}
	#elif defined( SHADOWMAP_TYPE_BASIC )
	float getPointShadow( samplerCube shadowMap, vec2 shadowMapSize, float shadowIntensity, float shadowBias, float shadowRadius, vec4 shadowCoord, float shadowCameraNear, float shadowCameraFar ) {
		float shadow = 1.0;
		vec3 lightToPosition = shadowCoord.xyz;
		vec3 absVec = abs( lightToPosition );
		float viewSpaceZ = max( max( absVec.x, absVec.y ), absVec.z );
		if ( viewSpaceZ - shadowCameraFar <= 0.0 && viewSpaceZ - shadowCameraNear >= 0.0 ) {
			float dp = ( shadowCameraFar * ( viewSpaceZ - shadowCameraNear ) ) / ( viewSpaceZ * ( shadowCameraFar - shadowCameraNear ) );
			dp += shadowBias;
			vec3 bd3D = normalize( lightToPosition );
			float depth = textureCube( shadowMap, bd3D ).r;
			#ifdef USE_REVERSED_DEPTH_BUFFER
				depth = 1.0 - depth;
			#endif
			shadow = step( dp, depth );
		}
		return mix( 1.0, shadow, shadowIntensity );
	}
	#endif
	#endif
#endif`,Qv=`#if NUM_SPOT_LIGHT_COORDS > 0
	uniform mat4 spotLightMatrix[ NUM_SPOT_LIGHT_COORDS ];
	varying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ];
#endif
#ifdef USE_SHADOWMAP
	#if NUM_SUN_LIGHT_SHADOWS > 0
		varying vec4 vSunShadowWorldPosition;
		varying vec3 vSunShadowWorldNormal;
	#endif
	#if NUM_DIR_LIGHT_SHADOWS > 0
		uniform mat4 directionalShadowMatrix[ NUM_DIR_LIGHT_SHADOWS ];
		varying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ];
		struct DirectionalLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ];
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
		struct SpotLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ];
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		uniform mat4 pointShadowMatrix[ NUM_POINT_LIGHT_SHADOWS ];
		varying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ];
		struct PointLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
			float shadowCameraNear;
			float shadowCameraFar;
		};
		uniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ];
	#endif
#endif`,eS=`#if ( defined( USE_SHADOWMAP ) && ( NUM_DIR_LIGHT_SHADOWS > 0 || NUM_SUN_LIGHT_SHADOWS > 0 || NUM_POINT_LIGHT_SHADOWS > 0 ) ) || ( NUM_SPOT_LIGHT_COORDS > 0 )
	#ifdef HAS_NORMAL
		vec3 shadowWorldNormal = transformNormalByInverseViewMatrix( transformedNormal, viewMatrix );
	#else
		vec3 shadowWorldNormal = vec3( 0.0 );
	#endif
	vec4 shadowWorldPosition;
#endif
#if defined( USE_SHADOWMAP )
	#if NUM_SUN_LIGHT_SHADOWS > 0
		vSunShadowWorldPosition = vec4( worldPosition.xyz, - mvPosition.z );
		vSunShadowWorldNormal = shadowWorldNormal;
	#endif
	#if NUM_DIR_LIGHT_SHADOWS > 0
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {
			shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * directionalLightShadows[ i ].shadowNormalBias, 0 );
			vDirectionalShadowCoord[ i ] = directionalShadowMatrix[ i ] * shadowWorldPosition;
		}
		#pragma unroll_loop_end
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {
			shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * pointLightShadows[ i ].shadowNormalBias, 0 );
			vPointShadowCoord[ i ] = pointShadowMatrix[ i ] * shadowWorldPosition;
		}
		#pragma unroll_loop_end
	#endif
#endif
#if NUM_SPOT_LIGHT_COORDS > 0
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHT_COORDS; i ++ ) {
		shadowWorldPosition = worldPosition;
		#if ( defined( USE_SHADOWMAP ) && UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
			shadowWorldPosition.xyz += shadowWorldNormal * spotLightShadows[ i ].shadowNormalBias;
		#endif
		vSpotLightCoord[ i ] = spotLightMatrix[ i ] * shadowWorldPosition;
	}
	#pragma unroll_loop_end
#endif`,tS=`float getShadowMask() {
	float shadow = 1.0;
	#ifdef USE_SHADOWMAP
	#if NUM_SUN_LIGHT_SHADOWS > 0
	SunLightShadow sunLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SUN_LIGHT_SHADOWS; i ++ ) {
		sunLight = sunLightShadows[ i ];
		shadow *= receiveShadow ? getSunShadow( sunShadowMap[ i ], sunLight, UNROLLED_LOOP_INDEX ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_DIR_LIGHT_SHADOWS > 0
	DirectionalLightShadow directionalLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {
		directionalLight = directionalLightShadows[ i ];
		shadow *= receiveShadow ? getShadow( directionalShadowMap[ i ], directionalLight.shadowMapSize, directionalLight.shadowIntensity, directionalLight.shadowBias, directionalLight.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
	SpotLightShadow spotLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHT_SHADOWS; i ++ ) {
		spotLight = spotLightShadows[ i ];
		shadow *= receiveShadow ? getShadow( spotShadowMap[ i ], spotLight.shadowMapSize, spotLight.shadowIntensity, spotLight.shadowBias, spotLight.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0 && ( defined( SHADOWMAP_TYPE_PCF ) || defined( SHADOWMAP_TYPE_BASIC ) )
	PointLightShadow pointLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {
		pointLight = pointLightShadows[ i ];
		shadow *= receiveShadow ? getPointShadow( pointShadowMap[ i ], pointLight.shadowMapSize, pointLight.shadowIntensity, pointLight.shadowBias, pointLight.shadowRadius, vPointShadowCoord[ i ], pointLight.shadowCameraNear, pointLight.shadowCameraFar ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#endif
	return shadow;
}`,nS=`#ifdef USE_SKINNING
	mat4 boneMatX = getBoneMatrix( skinIndex.x );
	mat4 boneMatY = getBoneMatrix( skinIndex.y );
	mat4 boneMatZ = getBoneMatrix( skinIndex.z );
	mat4 boneMatW = getBoneMatrix( skinIndex.w );
#endif`,iS=`#ifdef USE_SKINNING
	uniform mat4 bindMatrix;
	uniform mat4 bindMatrixInverse;
	uniform highp sampler2D boneTexture;
	mat4 getBoneMatrix( const in float i ) {
		int size = textureSize( boneTexture, 0 ).x;
		int j = int( i ) * 4;
		int x = j % size;
		int y = j / size;
		vec4 v1 = texelFetch( boneTexture, ivec2( x, y ), 0 );
		vec4 v2 = texelFetch( boneTexture, ivec2( x + 1, y ), 0 );
		vec4 v3 = texelFetch( boneTexture, ivec2( x + 2, y ), 0 );
		vec4 v4 = texelFetch( boneTexture, ivec2( x + 3, y ), 0 );
		return mat4( v1, v2, v3, v4 );
	}
#endif`,sS=`#ifdef USE_SKINNING
	vec4 skinVertex = bindMatrix * vec4( transformed, 1.0 );
	vec4 skinned = vec4( 0.0 );
	skinned += boneMatX * skinVertex * skinWeight.x;
	skinned += boneMatY * skinVertex * skinWeight.y;
	skinned += boneMatZ * skinVertex * skinWeight.z;
	skinned += boneMatW * skinVertex * skinWeight.w;
	transformed = ( bindMatrixInverse * skinned ).xyz;
#endif`,rS=`#ifdef USE_SKINNING
	mat4 skinMatrix = mat4( 0.0 );
	skinMatrix += skinWeight.x * boneMatX;
	skinMatrix += skinWeight.y * boneMatY;
	skinMatrix += skinWeight.z * boneMatZ;
	skinMatrix += skinWeight.w * boneMatW;
	skinMatrix = bindMatrixInverse * skinMatrix * bindMatrix;
	objectNormal = vec4( skinMatrix * vec4( objectNormal, 0.0 ) ).xyz;
	#ifdef USE_TANGENT
		objectTangent = vec4( skinMatrix * vec4( objectTangent, 0.0 ) ).xyz;
	#endif
#endif`,oS=`float specularStrength;
#ifdef USE_SPECULARMAP
	vec4 texelSpecular = texture2D( specularMap, vSpecularMapUv );
	specularStrength = texelSpecular.r;
#else
	specularStrength = 1.0;
#endif`,aS=`#ifdef USE_SPECULARMAP
	uniform sampler2D specularMap;
#endif`,cS=`#if defined( TONE_MAPPING )
	gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );
#endif`,lS=`#ifndef saturate
#define saturate( a ) clamp( a, 0.0, 1.0 )
#endif
uniform float toneMappingExposure;
vec3 LinearToneMapping( vec3 color ) {
	return saturate( toneMappingExposure * color );
}
vec3 ReinhardToneMapping( vec3 color ) {
	color *= toneMappingExposure;
	return saturate( color / ( vec3( 1.0 ) + color ) );
}
vec3 CineonToneMapping( vec3 color ) {
	color *= toneMappingExposure;
	color = max( vec3( 0.0 ), color - 0.004 );
	return pow( ( color * ( 6.2 * color + 0.5 ) ) / ( color * ( 6.2 * color + 1.7 ) + 0.06 ), vec3( 2.2 ) );
}
vec3 RRTAndODTFit( vec3 v ) {
	vec3 a = v * ( v + 0.0245786 ) - 0.000090537;
	vec3 b = v * ( 0.983729 * v + 0.4329510 ) + 0.238081;
	return a / b;
}
vec3 ACESFilmicToneMapping( vec3 color ) {
	const mat3 ACESInputMat = mat3(
		vec3( 0.59719, 0.07600, 0.02840 ),		vec3( 0.35458, 0.90834, 0.13383 ),
		vec3( 0.04823, 0.01566, 0.83777 )
	);
	const mat3 ACESOutputMat = mat3(
		vec3(  1.60475, -0.10208, -0.00327 ),		vec3( -0.53108,  1.10813, -0.07276 ),
		vec3( -0.07367, -0.00605,  1.07602 )
	);
	color *= toneMappingExposure / 0.6;
	color = ACESInputMat * color;
	color = RRTAndODTFit( color );
	color = ACESOutputMat * color;
	return saturate( color );
}
const mat3 LINEAR_REC2020_TO_LINEAR_SRGB = mat3(
	vec3( 1.6605, - 0.1246, - 0.0182 ),
	vec3( - 0.5876, 1.1329, - 0.1006 ),
	vec3( - 0.0728, - 0.0083, 1.1187 )
);
const mat3 LINEAR_SRGB_TO_LINEAR_REC2020 = mat3(
	vec3( 0.6274, 0.0691, 0.0164 ),
	vec3( 0.3293, 0.9195, 0.0880 ),
	vec3( 0.0433, 0.0113, 0.8956 )
);
vec3 agxDefaultContrastApprox( vec3 x ) {
	vec3 x2 = x * x;
	vec3 x4 = x2 * x2;
	return + 15.5 * x4 * x2
		- 40.14 * x4 * x
		+ 31.96 * x4
		- 6.868 * x2 * x
		+ 0.4298 * x2
		+ 0.1191 * x
		- 0.00232;
}
vec3 AgXToneMapping( vec3 color ) {
	const mat3 AgXInsetMatrix = mat3(
		vec3( 0.856627153315983, 0.137318972929847, 0.11189821299995 ),
		vec3( 0.0951212405381588, 0.761241990602591, 0.0767994186031903 ),
		vec3( 0.0482516061458583, 0.101439036467562, 0.811302368396859 )
	);
	const mat3 AgXOutsetMatrix = mat3(
		vec3( 1.1271005818144368, - 0.1413297634984383, - 0.14132976349843826 ),
		vec3( - 0.11060664309660323, 1.157823702216272, - 0.11060664309660294 ),
		vec3( - 0.016493938717834573, - 0.016493938717834257, 1.2519364065950405 )
	);
	const float AgxMinEv = - 12.47393;	const float AgxMaxEv = 4.026069;
	color *= toneMappingExposure;
	color = LINEAR_SRGB_TO_LINEAR_REC2020 * color;
	color = AgXInsetMatrix * color;
	color = max( color, 1e-10 );	color = log2( color );
	color = ( color - AgxMinEv ) / ( AgxMaxEv - AgxMinEv );
	color = clamp( color, 0.0, 1.0 );
	color = agxDefaultContrastApprox( color );
	color = AgXOutsetMatrix * color;
	color = pow( max( vec3( 0.0 ), color ), vec3( 2.2 ) );
	color = LINEAR_REC2020_TO_LINEAR_SRGB * color;
	color = clamp( color, 0.0, 1.0 );
	return color;
}
vec3 NeutralToneMapping( vec3 color ) {
	const float StartCompression = 0.8 - 0.04;
	const float Desaturation = 0.15;
	color *= toneMappingExposure;
	float x = min( color.r, min( color.g, color.b ) );
	float offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
	color -= offset;
	float peak = max( color.r, max( color.g, color.b ) );
	if ( peak < StartCompression ) return color;
	float d = 1. - StartCompression;
	float newPeak = 1. - d * d / ( peak + d - StartCompression );
	color *= newPeak / peak;
	float g = 1. - 1. / ( Desaturation * ( peak - newPeak ) + 1. );
	return mix( color, vec3( newPeak ), g );
}
vec3 CustomToneMapping( vec3 color ) { return color; }`,uS=`#ifdef USE_TRANSMISSION
	material.transmission = transmission;
	material.transmissionAlpha = 1.0;
	material.thickness = thickness;
	material.attenuationDistance = attenuationDistance;
	material.attenuationColor = attenuationColor;
	#ifdef USE_TRANSMISSIONMAP
		material.transmission *= texture2D( transmissionMap, vTransmissionMapUv ).r;
	#endif
	#ifdef USE_THICKNESSMAP
		material.thickness *= texture2D( thicknessMap, vThicknessMapUv ).g;
	#endif
	vec3 pos = vWorldPosition;
	vec3 v = normalize( cameraPosition - pos );
	vec3 n = transformNormalByInverseViewMatrix( normal, viewMatrix );
	vec4 transmitted = getIBLVolumeRefraction(
		n, v, material.roughness, material.diffuseContribution, material.specularColorBlended, material.specularF90,
		pos, modelMatrix, viewMatrix, projectionMatrix, material.dispersion, material.ior, material.thickness,
		material.attenuationColor, material.attenuationDistance );
	material.transmissionAlpha = mix( material.transmissionAlpha, transmitted.a, material.transmission );
	totalDiffuse = mix( totalDiffuse, transmitted.rgb, material.transmission );
#endif`,hS=`#ifdef USE_TRANSMISSION
	uniform float transmission;
	uniform float thickness;
	uniform float attenuationDistance;
	uniform vec3 attenuationColor;
	#ifdef USE_TRANSMISSIONMAP
		uniform sampler2D transmissionMap;
	#endif
	#ifdef USE_THICKNESSMAP
		uniform sampler2D thicknessMap;
	#endif
	uniform vec2 transmissionSamplerSize;
	uniform sampler2D transmissionSamplerMap;
	uniform mat4 modelMatrix;
	uniform mat4 projectionMatrix;
	varying vec3 vWorldPosition;
	float w0( float a ) {
		return ( 1.0 / 6.0 ) * ( a * ( a * ( - a + 3.0 ) - 3.0 ) + 1.0 );
	}
	float w1( float a ) {
		return ( 1.0 / 6.0 ) * ( a *  a * ( 3.0 * a - 6.0 ) + 4.0 );
	}
	float w2( float a ){
		return ( 1.0 / 6.0 ) * ( a * ( a * ( - 3.0 * a + 3.0 ) + 3.0 ) + 1.0 );
	}
	float w3( float a ) {
		return ( 1.0 / 6.0 ) * ( a * a * a );
	}
	float g0( float a ) {
		return w0( a ) + w1( a );
	}
	float g1( float a ) {
		return w2( a ) + w3( a );
	}
	float h0( float a ) {
		return - 1.0 + w1( a ) / ( w0( a ) + w1( a ) );
	}
	float h1( float a ) {
		return 1.0 + w3( a ) / ( w2( a ) + w3( a ) );
	}
	vec4 bicubic( sampler2D tex, vec2 uv, vec4 texelSize, float lod ) {
		uv = uv * texelSize.zw + 0.5;
		vec2 iuv = floor( uv );
		vec2 fuv = fract( uv );
		float g0x = g0( fuv.x );
		float g1x = g1( fuv.x );
		float h0x = h0( fuv.x );
		float h1x = h1( fuv.x );
		float h0y = h0( fuv.y );
		float h1y = h1( fuv.y );
		vec2 p0 = ( vec2( iuv.x + h0x, iuv.y + h0y ) - 0.5 ) * texelSize.xy;
		vec2 p1 = ( vec2( iuv.x + h1x, iuv.y + h0y ) - 0.5 ) * texelSize.xy;
		vec2 p2 = ( vec2( iuv.x + h0x, iuv.y + h1y ) - 0.5 ) * texelSize.xy;
		vec2 p3 = ( vec2( iuv.x + h1x, iuv.y + h1y ) - 0.5 ) * texelSize.xy;
		return g0( fuv.y ) * ( g0x * textureLod( tex, p0, lod ) + g1x * textureLod( tex, p1, lod ) ) +
			g1( fuv.y ) * ( g0x * textureLod( tex, p2, lod ) + g1x * textureLod( tex, p3, lod ) );
	}
	vec4 textureBicubic( sampler2D sampler, vec2 uv, float lod ) {
		vec2 fLodSize = vec2( textureSize( sampler, int( lod ) ) );
		vec2 cLodSize = vec2( textureSize( sampler, int( lod + 1.0 ) ) );
		vec2 fLodSizeInv = 1.0 / fLodSize;
		vec2 cLodSizeInv = 1.0 / cLodSize;
		vec4 fSample = bicubic( sampler, uv, vec4( fLodSizeInv, fLodSize ), floor( lod ) );
		vec4 cSample = bicubic( sampler, uv, vec4( cLodSizeInv, cLodSize ), ceil( lod ) );
		return mix( fSample, cSample, fract( lod ) );
	}
	vec3 getVolumeTransmissionRay( const in vec3 n, const in vec3 v, const in float thickness, const in float ior, const in mat4 modelMatrix ) {
		vec3 refractionVector = refract( - v, normalize( n ), 1.0 / ior );
		vec3 modelScale;
		modelScale.x = length( vec3( modelMatrix[ 0 ].xyz ) );
		modelScale.y = length( vec3( modelMatrix[ 1 ].xyz ) );
		modelScale.z = length( vec3( modelMatrix[ 2 ].xyz ) );
		return normalize( refractionVector ) * thickness * modelScale;
	}
	float applyIorToRoughness( const in float roughness, const in float ior ) {
		return roughness * clamp( ior * 2.0 - 2.0, 0.0, 1.0 );
	}
	vec4 getTransmissionSample( const in vec2 fragCoord, const in float roughness, const in float ior ) {
		float lod = log2( transmissionSamplerSize.x ) * applyIorToRoughness( roughness, ior );
		return textureBicubic( transmissionSamplerMap, fragCoord.xy, lod );
	}
	vec3 volumeAttenuation( const in float transmissionDistance, const in vec3 attenuationColor, const in float attenuationDistance ) {
		if ( isinf( attenuationDistance ) ) {
			return vec3( 1.0 );
		} else {
			vec3 attenuationCoefficient = -log( attenuationColor ) / attenuationDistance;
			vec3 transmittance = exp( - attenuationCoefficient * transmissionDistance );			return transmittance;
		}
	}
	vec4 getIBLVolumeRefraction( const in vec3 n, const in vec3 v, const in float roughness, const in vec3 diffuseColor,
		const in vec3 specularColor, const in float specularF90, const in vec3 position, const in mat4 modelMatrix,
		const in mat4 viewMatrix, const in mat4 projMatrix, const in float dispersion, const in float ior, const in float thickness,
		const in vec3 attenuationColor, const in float attenuationDistance ) {
		vec4 transmittedLight;
		vec3 transmittance;
		#ifdef USE_DISPERSION
			float halfSpread = ( ior - 1.0 ) * 0.025 * dispersion;
			vec3 iors = vec3( ior - halfSpread, ior, ior + halfSpread );
			for ( int i = 0; i < 3; i ++ ) {
				vec3 transmissionRay = getVolumeTransmissionRay( n, v, thickness, iors[ i ], modelMatrix );
				vec3 refractedRayExit = position + transmissionRay;
				vec4 ndcPos = projMatrix * viewMatrix * vec4( refractedRayExit, 1.0 );
				vec2 refractionCoords = ndcPos.xy / ndcPos.w;
				refractionCoords += 1.0;
				refractionCoords /= 2.0;
				vec4 transmissionSample = getTransmissionSample( refractionCoords, roughness, iors[ i ] );
				transmittedLight[ i ] = transmissionSample[ i ];
				transmittedLight.a += transmissionSample.a;
				transmittance[ i ] = diffuseColor[ i ] * volumeAttenuation( length( transmissionRay ), attenuationColor, attenuationDistance )[ i ];
			}
			transmittedLight.a /= 3.0;
		#else
			vec3 transmissionRay = getVolumeTransmissionRay( n, v, thickness, ior, modelMatrix );
			vec3 refractedRayExit = position + transmissionRay;
			vec4 ndcPos = projMatrix * viewMatrix * vec4( refractedRayExit, 1.0 );
			vec2 refractionCoords = ndcPos.xy / ndcPos.w;
			refractionCoords += 1.0;
			refractionCoords /= 2.0;
			transmittedLight = getTransmissionSample( refractionCoords, roughness, ior );
			transmittance = diffuseColor * volumeAttenuation( length( transmissionRay ), attenuationColor, attenuationDistance );
		#endif
		vec3 attenuatedColor = transmittance * transmittedLight.rgb;
		vec3 F = EnvironmentBRDF( n, v, specularColor, specularF90, roughness );
		float transmittanceFactor = ( transmittance.r + transmittance.g + transmittance.b ) / 3.0;
		return vec4( ( 1.0 - F ) * attenuatedColor, 1.0 - ( 1.0 - transmittedLight.a ) * transmittanceFactor );
	}
#endif`,fS=`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	varying vec2 vUv;
#endif
#ifdef USE_MAP
	varying vec2 vMapUv;
#endif
#ifdef USE_ALPHAMAP
	varying vec2 vAlphaMapUv;
#endif
#ifdef USE_LIGHTMAP
	varying vec2 vLightMapUv;
#endif
#ifdef USE_AOMAP
	varying vec2 vAoMapUv;
#endif
#ifdef USE_BUMPMAP
	varying vec2 vBumpMapUv;
#endif
#ifdef USE_NORMALMAP
	varying vec2 vNormalMapUv;
#endif
#ifdef USE_EMISSIVEMAP
	varying vec2 vEmissiveMapUv;
#endif
#ifdef USE_METALNESSMAP
	varying vec2 vMetalnessMapUv;
#endif
#ifdef USE_ROUGHNESSMAP
	varying vec2 vRoughnessMapUv;
#endif
#ifdef USE_ANISOTROPYMAP
	varying vec2 vAnisotropyMapUv;
#endif
#ifdef USE_CLEARCOATMAP
	varying vec2 vClearcoatMapUv;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	varying vec2 vClearcoatNormalMapUv;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	varying vec2 vClearcoatRoughnessMapUv;
#endif
#ifdef USE_IRIDESCENCEMAP
	varying vec2 vIridescenceMapUv;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	varying vec2 vIridescenceThicknessMapUv;
#endif
#ifdef USE_SHEEN_COLORMAP
	varying vec2 vSheenColorMapUv;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	varying vec2 vSheenRoughnessMapUv;
#endif
#ifdef USE_SPECULARMAP
	varying vec2 vSpecularMapUv;
#endif
#ifdef USE_SPECULAR_COLORMAP
	varying vec2 vSpecularColorMapUv;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	varying vec2 vSpecularIntensityMapUv;
#endif
#ifdef USE_TRANSMISSIONMAP
	uniform mat3 transmissionMapTransform;
	varying vec2 vTransmissionMapUv;
#endif
#ifdef USE_THICKNESSMAP
	uniform mat3 thicknessMapTransform;
	varying vec2 vThicknessMapUv;
#endif`,dS=`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	varying vec2 vUv;
#endif
#ifdef USE_MAP
	uniform mat3 mapTransform;
	varying vec2 vMapUv;
#endif
#ifdef USE_ALPHAMAP
	uniform mat3 alphaMapTransform;
	varying vec2 vAlphaMapUv;
#endif
#ifdef USE_LIGHTMAP
	uniform mat3 lightMapTransform;
	varying vec2 vLightMapUv;
#endif
#ifdef USE_AOMAP
	uniform mat3 aoMapTransform;
	varying vec2 vAoMapUv;
#endif
#ifdef USE_BUMPMAP
	uniform mat3 bumpMapTransform;
	varying vec2 vBumpMapUv;
#endif
#ifdef USE_NORMALMAP
	uniform mat3 normalMapTransform;
	varying vec2 vNormalMapUv;
#endif
#ifdef USE_DISPLACEMENTMAP
	uniform mat3 displacementMapTransform;
	varying vec2 vDisplacementMapUv;
#endif
#ifdef USE_EMISSIVEMAP
	uniform mat3 emissiveMapTransform;
	varying vec2 vEmissiveMapUv;
#endif
#ifdef USE_METALNESSMAP
	uniform mat3 metalnessMapTransform;
	varying vec2 vMetalnessMapUv;
#endif
#ifdef USE_ROUGHNESSMAP
	uniform mat3 roughnessMapTransform;
	varying vec2 vRoughnessMapUv;
#endif
#ifdef USE_ANISOTROPYMAP
	uniform mat3 anisotropyMapTransform;
	varying vec2 vAnisotropyMapUv;
#endif
#ifdef USE_CLEARCOATMAP
	uniform mat3 clearcoatMapTransform;
	varying vec2 vClearcoatMapUv;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	uniform mat3 clearcoatNormalMapTransform;
	varying vec2 vClearcoatNormalMapUv;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	uniform mat3 clearcoatRoughnessMapTransform;
	varying vec2 vClearcoatRoughnessMapUv;
#endif
#ifdef USE_SHEEN_COLORMAP
	uniform mat3 sheenColorMapTransform;
	varying vec2 vSheenColorMapUv;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	uniform mat3 sheenRoughnessMapTransform;
	varying vec2 vSheenRoughnessMapUv;
#endif
#ifdef USE_IRIDESCENCEMAP
	uniform mat3 iridescenceMapTransform;
	varying vec2 vIridescenceMapUv;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	uniform mat3 iridescenceThicknessMapTransform;
	varying vec2 vIridescenceThicknessMapUv;
#endif
#ifdef USE_SPECULARMAP
	uniform mat3 specularMapTransform;
	varying vec2 vSpecularMapUv;
#endif
#ifdef USE_SPECULAR_COLORMAP
	uniform mat3 specularColorMapTransform;
	varying vec2 vSpecularColorMapUv;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	uniform mat3 specularIntensityMapTransform;
	varying vec2 vSpecularIntensityMapUv;
#endif
#ifdef USE_TRANSMISSIONMAP
	uniform mat3 transmissionMapTransform;
	varying vec2 vTransmissionMapUv;
#endif
#ifdef USE_THICKNESSMAP
	uniform mat3 thicknessMapTransform;
	varying vec2 vThicknessMapUv;
#endif`,pS=`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	vUv = vec3( uv, 1 ).xy;
#endif
#ifdef USE_MAP
	vMapUv = ( mapTransform * vec3( MAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ALPHAMAP
	vAlphaMapUv = ( alphaMapTransform * vec3( ALPHAMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_LIGHTMAP
	vLightMapUv = ( lightMapTransform * vec3( LIGHTMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_AOMAP
	vAoMapUv = ( aoMapTransform * vec3( AOMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_BUMPMAP
	vBumpMapUv = ( bumpMapTransform * vec3( BUMPMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_NORMALMAP
	vNormalMapUv = ( normalMapTransform * vec3( NORMALMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_DISPLACEMENTMAP
	vDisplacementMapUv = ( displacementMapTransform * vec3( DISPLACEMENTMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_EMISSIVEMAP
	vEmissiveMapUv = ( emissiveMapTransform * vec3( EMISSIVEMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_METALNESSMAP
	vMetalnessMapUv = ( metalnessMapTransform * vec3( METALNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ROUGHNESSMAP
	vRoughnessMapUv = ( roughnessMapTransform * vec3( ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ANISOTROPYMAP
	vAnisotropyMapUv = ( anisotropyMapTransform * vec3( ANISOTROPYMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOATMAP
	vClearcoatMapUv = ( clearcoatMapTransform * vec3( CLEARCOATMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	vClearcoatNormalMapUv = ( clearcoatNormalMapTransform * vec3( CLEARCOAT_NORMALMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	vClearcoatRoughnessMapUv = ( clearcoatRoughnessMapTransform * vec3( CLEARCOAT_ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_IRIDESCENCEMAP
	vIridescenceMapUv = ( iridescenceMapTransform * vec3( IRIDESCENCEMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	vIridescenceThicknessMapUv = ( iridescenceThicknessMapTransform * vec3( IRIDESCENCE_THICKNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SHEEN_COLORMAP
	vSheenColorMapUv = ( sheenColorMapTransform * vec3( SHEEN_COLORMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	vSheenRoughnessMapUv = ( sheenRoughnessMapTransform * vec3( SHEEN_ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULARMAP
	vSpecularMapUv = ( specularMapTransform * vec3( SPECULARMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULAR_COLORMAP
	vSpecularColorMapUv = ( specularColorMapTransform * vec3( SPECULAR_COLORMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	vSpecularIntensityMapUv = ( specularIntensityMapTransform * vec3( SPECULAR_INTENSITYMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_TRANSMISSIONMAP
	vTransmissionMapUv = ( transmissionMapTransform * vec3( TRANSMISSIONMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_THICKNESSMAP
	vThicknessMapUv = ( thicknessMapTransform * vec3( THICKNESSMAP_UV, 1 ) ).xy;
#endif`,mS=`#if defined( USE_ENVMAP ) || defined( DISTANCE ) || defined ( USE_SHADOWMAP ) || defined ( USE_TRANSMISSION ) || NUM_SPOT_LIGHT_COORDS > 0
	vec4 worldPosition = vec4( transformed, 1.0 );
	#ifdef USE_BATCHING
		worldPosition = batchingMatrix * worldPosition;
	#endif
	#ifdef USE_INSTANCING
		worldPosition = instanceMatrix * worldPosition;
	#endif
	worldPosition = modelMatrix * worldPosition;
#endif`,gS=`varying vec2 vUv;
uniform mat3 uvTransform;
void main() {
	vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
	gl_Position = vec4( position.xy, 1.0, 1.0 );
}`,xS=`uniform sampler2D t2D;
uniform float backgroundIntensity;
varying vec2 vUv;
void main() {
	vec4 texColor = texture2D( t2D, vUv );
	#ifdef DECODE_VIDEO_TEXTURE
		texColor = vec4( mix( pow( texColor.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), texColor.rgb * 0.0773993808, vec3( lessThanEqual( texColor.rgb, vec3( 0.04045 ) ) ) ), texColor.w );
	#endif
	texColor.rgb *= backgroundIntensity;
	gl_FragColor = texColor;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,_S=`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`,yS=`#ifdef ENVMAP_TYPE_CUBE
	uniform samplerCube envMap;
#elif defined( ENVMAP_TYPE_CUBE_UV )
	uniform sampler2D envMap;
#endif
uniform float backgroundBlurriness;
uniform float backgroundIntensity;
uniform mat3 backgroundRotation;
varying vec3 vWorldDirection;
#include <cube_uv_reflection_fragment>
void main() {
	#ifdef ENVMAP_TYPE_CUBE
		vec4 texColor = textureCube( envMap, backgroundRotation * vWorldDirection );
	#elif defined( ENVMAP_TYPE_CUBE_UV )
		vec4 texColor = textureCubeUV( envMap, backgroundRotation * vWorldDirection, backgroundBlurriness );
	#else
		vec4 texColor = vec4( 0.0, 0.0, 0.0, 1.0 );
	#endif
	texColor.rgb *= backgroundIntensity;
	gl_FragColor = texColor;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,vS=`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`,SS=`uniform samplerCube tCube;
uniform float tFlip;
uniform float opacity;
varying vec3 vWorldDirection;
void main() {
	vec4 texColor = textureCube( tCube, vec3( tFlip * vWorldDirection.x, vWorldDirection.yz ) );
	gl_FragColor = texColor;
	gl_FragColor.a *= opacity;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,bS=`#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
varying vec2 vHighPrecisionZW;
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <skinbase_vertex>
	#include <morphinstance_vertex>
	#ifdef USE_DISPLACEMENTMAP
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vHighPrecisionZW = gl_Position.zw;
}`,MS=`#if DEPTH_PACKING == 3200
	uniform float opacity;
#endif
#include <common>
#include <packing>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
varying vec2 vHighPrecisionZW;
void main() {
	vec4 diffuseColor = vec4( 1.0 );
	#include <clipping_planes_fragment>
	#if DEPTH_PACKING == 3200
		diffuseColor.a = opacity;
	#endif
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <logdepthbuf_fragment>
	#ifdef USE_REVERSED_DEPTH_BUFFER
		float fragCoordZ = vHighPrecisionZW[ 0 ] / vHighPrecisionZW[ 1 ];
	#else
		float fragCoordZ = 0.5 * vHighPrecisionZW[ 0 ] / vHighPrecisionZW[ 1 ] + 0.5;
	#endif
	#if DEPTH_PACKING == 3200
		gl_FragColor = vec4( vec3( 1.0 - fragCoordZ ), opacity );
	#elif DEPTH_PACKING == 3201
		gl_FragColor = packDepthToRGBA( fragCoordZ );
	#elif DEPTH_PACKING == 3202
		gl_FragColor = vec4( packDepthToRGB( fragCoordZ ), 1.0 );
	#elif DEPTH_PACKING == 3203
		gl_FragColor = vec4( packDepthToRG( fragCoordZ ), 0.0, 1.0 );
	#endif
}`,TS=`#define DISTANCE
varying vec3 vWorldPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <skinbase_vertex>
	#include <morphinstance_vertex>
	#ifdef USE_DISPLACEMENTMAP
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <worldpos_vertex>
	#include <clipping_planes_vertex>
	vWorldPosition = worldPosition.xyz;
}`,wS=`#define DISTANCE
uniform vec3 referencePosition;
uniform float nearDistance;
uniform float farDistance;
varying vec3 vWorldPosition;
#include <common>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( 1.0 );
	#include <clipping_planes_fragment>
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	float dist = length( vWorldPosition - referencePosition );
	dist = ( dist - nearDistance ) / ( farDistance - nearDistance );
	dist = saturate( dist );
	gl_FragColor = vec4( dist, 0.0, 0.0, 1.0 );
}`,ES=`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
}`,AS=`uniform sampler2D tEquirect;
varying vec3 vWorldDirection;
#include <common>
void main() {
	vec3 direction = normalize( vWorldDirection );
	vec2 sampleUV = equirectUv( direction );
	gl_FragColor = texture2D( tEquirect, sampleUV );
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,RS=`uniform float scale;
attribute float lineDistance;
varying float vLineDistance;
#include <common>
#include <uv_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	vLineDistance = scale * lineDistance;
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
}`,CS=`uniform vec3 diffuse;
uniform float opacity;
uniform float dashSize;
uniform float totalSize;
varying float vLineDistance;
#include <common>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	if ( mod( vLineDistance, totalSize ) > dashSize ) {
		discard;
	}
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`,PS=`#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#if defined ( USE_ENVMAP ) || defined ( USE_SKINNING )
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinbase_vertex>
		#include <skinnormal_vertex>
		#include <defaultnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <fog_vertex>
}`,IS=`uniform vec3 diffuse;
uniform float opacity;
#ifndef FLAT_SHADED
	varying vec3 vNormal;
#endif
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
		reflectedLight.indirectDiffuse += lightMapTexel.rgb * lightMapIntensity * RECIPROCAL_PI;
	#else
		reflectedLight.indirectDiffuse += vec3( 1.0 );
	#endif
	#include <aomap_fragment>
	reflectedLight.indirectDiffuse *= diffuseColor.rgb;
	vec3 outgoingLight = reflectedLight.indirectDiffuse;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,LS=`#define LAMBERT
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,NS=`#define LAMBERT
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <cube_uv_reflection_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <envmap_physical_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_lambert_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_lambert_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,DS=`#define MATCAP
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <color_pars_vertex>
#include <displacementmap_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
	vViewPosition = - mvPosition.xyz;
}`,US=`#define MATCAP
uniform vec3 diffuse;
uniform float opacity;
uniform sampler2D matcap;
varying vec3 vViewPosition;
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <normal_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	vec3 viewDir = normalize( vViewPosition );
	vec3 x = normalize( vec3( viewDir.z, 0.0, - viewDir.x ) );
	vec3 y = cross( viewDir, x );
	vec2 uv = vec2( dot( x, normal ), dot( y, normal ) ) * 0.495 + 0.5;
	#ifdef USE_MATCAP
		vec4 matcapColor = texture2D( matcap, uv );
	#else
		vec4 matcapColor = vec4( vec3( mix( 0.2, 0.8, uv.y ) ), 1.0 );
	#endif
	vec3 outgoingLight = diffuseColor.rgb * matcapColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,FS=`#define NORMAL
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	varying vec3 vViewPosition;
#endif
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	vViewPosition = - mvPosition.xyz;
#endif
}`,OS=`#define NORMAL
uniform float opacity;
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	varying vec3 vViewPosition;
#endif
#include <uv_pars_fragment>
#include <normal_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( 0.0, 0.0, 0.0, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	gl_FragColor = vec4( normalize( normal ) * 0.5 + 0.5, diffuseColor.a );
	#ifdef OPAQUE
		gl_FragColor.a = 1.0;
	#endif
}`,BS=`#define PHONG
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,zS=`#define PHONG
uniform vec3 diffuse;
uniform vec3 emissive;
uniform vec3 specular;
uniform float shininess;
uniform float opacity;
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <cube_uv_reflection_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <envmap_physical_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_phong_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_phong_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + reflectedLight.directSpecular + reflectedLight.indirectSpecular + totalEmissiveRadiance;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,kS=`#define STANDARD
varying vec3 vViewPosition;
#ifdef USE_TRANSMISSION
	varying vec3 vWorldPosition;
#endif
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
#ifdef USE_TRANSMISSION
	vWorldPosition = worldPosition.xyz;
#endif
}`,VS=`#define STANDARD
#ifdef PHYSICAL
	#define IOR
	#define USE_SPECULAR
#endif
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float roughness;
uniform float metalness;
uniform float opacity;
#ifdef IOR
	uniform float ior;
#endif
#ifdef USE_SPECULAR
	uniform float specularIntensity;
	uniform vec3 specularColor;
	#ifdef USE_SPECULAR_COLORMAP
		uniform sampler2D specularColorMap;
	#endif
	#ifdef USE_SPECULAR_INTENSITYMAP
		uniform sampler2D specularIntensityMap;
	#endif
#endif
#ifdef USE_CLEARCOAT
	uniform float clearcoat;
	uniform float clearcoatRoughness;
#endif
#ifdef USE_DISPERSION
	uniform float dispersion;
#endif
#ifdef USE_RETROREFLECTION
	uniform float retroreflectivity;
#endif
#ifdef USE_IRIDESCENCE
	uniform float iridescence;
	uniform float iridescenceIOR;
	uniform float iridescenceThicknessMinimum;
	uniform float iridescenceThicknessMaximum;
#endif
#ifdef USE_SHEEN
	uniform vec3 sheenColor;
	uniform float sheenRoughness;
	#ifdef USE_SHEEN_COLORMAP
		uniform sampler2D sheenColorMap;
	#endif
	#ifdef USE_SHEEN_ROUGHNESSMAP
		uniform sampler2D sheenRoughnessMap;
	#endif
#endif
#ifdef USE_ANISOTROPY
	uniform vec2 anisotropyVector;
	#ifdef USE_ANISOTROPYMAP
		uniform sampler2D anisotropyMap;
	#endif
#endif
varying vec3 vViewPosition;
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <iridescence_fragment>
#include <cube_uv_reflection_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_physical_pars_fragment>
#include <fog_pars_fragment>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_physical_pars_fragment>
#include <transmission_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <clearcoat_pars_fragment>
#include <iridescence_pars_fragment>
#include <roughnessmap_pars_fragment>
#include <metalnessmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <roughnessmap_fragment>
	#include <metalnessmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <clearcoat_normal_fragment_begin>
	#include <clearcoat_normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_physical_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 totalDiffuse = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse;
	vec3 totalSpecular = reflectedLight.directSpecular + reflectedLight.indirectSpecular;
	#include <transmission_fragment>
	vec3 outgoingLight = totalDiffuse + totalSpecular + totalEmissiveRadiance;
	#ifdef USE_SHEEN
 
		outgoingLight = outgoingLight + sheenSpecularDirect + sheenSpecularIndirect;
 
 	#endif
	#ifdef USE_CLEARCOAT
		float dotNVcc = saturate( dot( geometryClearcoatNormal, geometryViewDir ) );
		vec3 Fcc = F_Schlick( material.clearcoatF0, material.clearcoatF90, dotNVcc );
		outgoingLight = outgoingLight * ( 1.0 - material.clearcoat * Fcc ) + ( clearcoatSpecularDirect + clearcoatSpecularIndirect ) * material.clearcoat;
	#endif
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,HS=`#define TOON
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,GS=`#define TOON
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <gradientmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_toon_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_toon_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,WS=`uniform float size;
uniform float scale;
#include <common>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
#ifdef USE_POINTS_UV
	varying vec2 vUv;
	uniform mat3 uvTransform;
#endif
void main() {
	#ifdef USE_POINTS_UV
		vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
	#endif
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <project_vertex>
	gl_PointSize = size;
	#ifdef USE_SIZEATTENUATION
		bool isPerspective = isPerspectiveMatrix( projectionMatrix );
		if ( isPerspective ) gl_PointSize *= ( scale / - mvPosition.z );
	#endif
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <fog_vertex>
}`,XS=`uniform vec3 diffuse;
uniform float opacity;
#include <common>
#include <color_pars_fragment>
#include <map_particle_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_particle_fragment>
	#include <color_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`,qS=`#include <common>
#include <batching_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <shadowmap_pars_vertex>
void main() {
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,YS=`uniform vec3 color;
uniform float opacity;
#include <common>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <logdepthbuf_pars_fragment>
#include <shadowmap_pars_fragment>
#include <shadowmask_pars_fragment>
void main() {
	#include <logdepthbuf_fragment>
	gl_FragColor = vec4( color, opacity * ( 1.0 - getShadowMask() ) );
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`,ZS=`uniform float rotation;
uniform vec2 center;
#include <common>
#include <uv_pars_vertex>
#include <fog_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	vec4 mvPosition = modelViewMatrix[ 3 ];
	vec2 scale = vec2( length( modelMatrix[ 0 ].xyz ), length( modelMatrix[ 1 ].xyz ) );
	#ifndef USE_SIZEATTENUATION
		bool isPerspective = isPerspectiveMatrix( projectionMatrix );
		if ( isPerspective ) scale *= - mvPosition.z;
	#endif
	vec2 alignedPosition = ( position.xy - ( center - vec2( 0.5 ) ) ) * scale;
	vec2 rotatedPosition;
	rotatedPosition.x = cos( rotation ) * alignedPosition.x - sin( rotation ) * alignedPosition.y;
	rotatedPosition.y = sin( rotation ) * alignedPosition.x + cos( rotation ) * alignedPosition.y;
	mvPosition.xy += rotatedPosition;
	gl_Position = projectionMatrix * mvPosition;
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
}`,KS=`uniform vec3 diffuse;
uniform float opacity;
#include <common>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
}`,Qe={alphahash_fragment:gy,alphahash_pars_fragment:xy,alphamap_fragment:_y,alphamap_pars_fragment:yy,alphatest_fragment:vy,alphatest_pars_fragment:Sy,aomap_fragment:by,aomap_pars_fragment:My,batching_pars_vertex:Ty,batching_vertex:wy,begin_vertex:Ey,beginnormal_vertex:Ay,bsdfs:Ry,iridescence_fragment:Cy,bumpmap_pars_fragment:Py,clipping_planes_fragment:Iy,clipping_planes_pars_fragment:Ly,clipping_planes_pars_vertex:Ny,clipping_planes_vertex:Dy,color_fragment:Uy,color_pars_fragment:Fy,color_pars_vertex:Oy,color_vertex:By,common:zy,cube_uv_reflection_fragment:ky,defaultnormal_vertex:Vy,displacementmap_pars_vertex:Hy,displacementmap_vertex:Gy,emissivemap_fragment:Wy,emissivemap_pars_fragment:Xy,colorspace_fragment:qy,colorspace_pars_fragment:Yy,envmap_fragment:Zy,envmap_common_pars_fragment:Ky,envmap_pars_fragment:Jy,envmap_pars_vertex:$y,envmap_physical_pars_fragment:cv,envmap_vertex:jy,fog_vertex:Qy,fog_pars_vertex:ev,fog_fragment:tv,fog_pars_fragment:nv,gradientmap_pars_fragment:iv,lightmap_pars_fragment:sv,lights_lambert_fragment:rv,lights_lambert_pars_fragment:ov,lights_pars_begin:av,lights_toon_fragment:lv,lights_toon_pars_fragment:uv,lights_phong_fragment:hv,lights_phong_pars_fragment:fv,lights_physical_fragment:dv,lights_physical_pars_fragment:pv,lights_fragment_begin:mv,lights_fragment_maps:gv,lights_fragment_end:xv,lightprobes_pars_fragment:_v,logdepthbuf_fragment:yv,logdepthbuf_pars_fragment:vv,logdepthbuf_pars_vertex:Sv,logdepthbuf_vertex:bv,map_fragment:Mv,map_pars_fragment:Tv,map_particle_fragment:wv,map_particle_pars_fragment:Ev,metalnessmap_fragment:Av,metalnessmap_pars_fragment:Rv,morphinstance_vertex:Cv,morphcolor_vertex:Pv,morphnormal_vertex:Iv,morphtarget_pars_vertex:Lv,morphtarget_vertex:Nv,normal_fragment_begin:Dv,normal_fragment_maps:Uv,normal_pars_fragment:Fv,normal_pars_vertex:Ov,normal_vertex:Bv,normalmap_pars_fragment:zv,clearcoat_normal_fragment_begin:kv,clearcoat_normal_fragment_maps:Vv,clearcoat_pars_fragment:Hv,iridescence_pars_fragment:Gv,opaque_fragment:Wv,packing:Xv,premultiplied_alpha_fragment:qv,project_vertex:Yv,dithering_fragment:Zv,dithering_pars_fragment:Kv,roughnessmap_fragment:Jv,roughnessmap_pars_fragment:$v,shadowmap_pars_fragment:jv,shadowmap_pars_vertex:Qv,shadowmap_vertex:eS,shadowmask_pars_fragment:tS,skinbase_vertex:nS,skinning_pars_vertex:iS,skinning_vertex:sS,skinnormal_vertex:rS,specularmap_fragment:oS,specularmap_pars_fragment:aS,tonemapping_fragment:cS,tonemapping_pars_fragment:lS,transmission_fragment:uS,transmission_pars_fragment:hS,uv_pars_fragment:fS,uv_pars_vertex:dS,uv_vertex:pS,worldpos_vertex:mS,background_vert:gS,background_frag:xS,backgroundCube_vert:_S,backgroundCube_frag:yS,cube_vert:vS,cube_frag:SS,depth_vert:bS,depth_frag:MS,distance_vert:TS,distance_frag:wS,equirect_vert:ES,equirect_frag:AS,linedashed_vert:RS,linedashed_frag:CS,meshbasic_vert:PS,meshbasic_frag:IS,meshlambert_vert:LS,meshlambert_frag:NS,meshmatcap_vert:DS,meshmatcap_frag:US,meshnormal_vert:FS,meshnormal_frag:OS,meshphong_vert:BS,meshphong_frag:zS,meshphysical_vert:kS,meshphysical_frag:VS,meshtoon_vert:HS,meshtoon_frag:GS,points_vert:WS,points_frag:XS,shadow_vert:qS,shadow_frag:YS,sprite_vert:ZS,sprite_frag:KS},Me={common:{diffuse:{value:new Ve(16777215)},opacity:{value:1},map:{value:null},mapTransform:{value:new Ye},alphaMap:{value:null},alphaMapTransform:{value:new Ye},alphaTest:{value:0}},specularmap:{specularMap:{value:null},specularMapTransform:{value:new Ye}},envmap:{envMap:{value:null},envMapRotation:{value:new Ye},reflectivity:{value:1},ior:{value:1.5},refractionRatio:{value:.98},dfgLUT:{value:null}},aomap:{aoMap:{value:null},aoMapIntensity:{value:1},aoMapTransform:{value:new Ye}},lightmap:{lightMap:{value:null},lightMapIntensity:{value:1},lightMapTransform:{value:new Ye}},bumpmap:{bumpMap:{value:null},bumpMapTransform:{value:new Ye},bumpScale:{value:1}},normalmap:{normalMap:{value:null},normalMapTransform:{value:new Ye},normalScale:{value:new ce(1,1)}},displacementmap:{displacementMap:{value:null},displacementMapTransform:{value:new Ye},displacementScale:{value:1},displacementBias:{value:0}},emissivemap:{emissiveMap:{value:null},emissiveMapTransform:{value:new Ye}},metalnessmap:{metalnessMap:{value:null},metalnessMapTransform:{value:new Ye}},roughnessmap:{roughnessMap:{value:null},roughnessMapTransform:{value:new Ye}},gradientmap:{gradientMap:{value:null}},fog:{fogDensity:{value:25e-5},fogNear:{value:1},fogFar:{value:2e3},fogColor:{value:new Ve(16777215)}},lights:{ambientLightColor:{value:[]},lightProbe:{value:[]},sunLights:{value:[],properties:{direction:{},color:{}}},sunLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{}}},sunShadowMatrix:{value:[]},sunShadowCascade:{value:[]},directionalLights:{value:[],properties:{direction:{},color:{}}},directionalLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{}}},directionalShadowMatrix:{value:[]},spotLights:{value:[],properties:{color:{},position:{},direction:{},distance:{},coneCos:{},penumbraCos:{},decay:{}}},spotLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{}}},spotLightMap:{value:[]},spotLightMatrix:{value:[]},pointLights:{value:[],properties:{color:{},position:{},decay:{},distance:{}}},pointLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{},shadowCameraNear:{},shadowCameraFar:{}}},pointShadowMatrix:{value:[]},hemisphereLights:{value:[],properties:{direction:{},skyColor:{},groundColor:{}}},rectAreaLights:{value:[],properties:{color:{},position:{},width:{},height:{}}},ltc_1:{value:null},ltc_2:{value:null},probesSH:{value:null},probesMin:{value:new I},probesMax:{value:new I},probesResolution:{value:new I}},points:{diffuse:{value:new Ve(16777215)},opacity:{value:1},size:{value:1},scale:{value:1},map:{value:null},alphaMap:{value:null},alphaMapTransform:{value:new Ye},alphaTest:{value:0},uvTransform:{value:new Ye}},sprite:{diffuse:{value:new Ve(16777215)},opacity:{value:1},center:{value:new ce(.5,.5)},rotation:{value:0},map:{value:null},mapTransform:{value:new Ye},alphaMap:{value:null},alphaMapTransform:{value:new Ye},alphaTest:{value:0}}},Mi={basic:{uniforms:mn([Me.common,Me.specularmap,Me.envmap,Me.aomap,Me.lightmap,Me.fog]),vertexShader:Qe.meshbasic_vert,fragmentShader:Qe.meshbasic_frag},lambert:{uniforms:mn([Me.common,Me.specularmap,Me.envmap,Me.aomap,Me.lightmap,Me.emissivemap,Me.bumpmap,Me.normalmap,Me.displacementmap,Me.fog,Me.lights,{emissive:{value:new Ve(0)},envMapIntensity:{value:1}}]),vertexShader:Qe.meshlambert_vert,fragmentShader:Qe.meshlambert_frag},phong:{uniforms:mn([Me.common,Me.specularmap,Me.envmap,Me.aomap,Me.lightmap,Me.emissivemap,Me.bumpmap,Me.normalmap,Me.displacementmap,Me.fog,Me.lights,{emissive:{value:new Ve(0)},specular:{value:new Ve(1118481)},shininess:{value:30},envMapIntensity:{value:1}}]),vertexShader:Qe.meshphong_vert,fragmentShader:Qe.meshphong_frag},standard:{uniforms:mn([Me.common,Me.envmap,Me.aomap,Me.lightmap,Me.emissivemap,Me.bumpmap,Me.normalmap,Me.displacementmap,Me.roughnessmap,Me.metalnessmap,Me.fog,Me.lights,{emissive:{value:new Ve(0)},roughness:{value:1},metalness:{value:0},envMapIntensity:{value:1}}]),vertexShader:Qe.meshphysical_vert,fragmentShader:Qe.meshphysical_frag},toon:{uniforms:mn([Me.common,Me.aomap,Me.lightmap,Me.emissivemap,Me.bumpmap,Me.normalmap,Me.displacementmap,Me.gradientmap,Me.fog,Me.lights,{emissive:{value:new Ve(0)}}]),vertexShader:Qe.meshtoon_vert,fragmentShader:Qe.meshtoon_frag},matcap:{uniforms:mn([Me.common,Me.bumpmap,Me.normalmap,Me.displacementmap,Me.fog,{matcap:{value:null}}]),vertexShader:Qe.meshmatcap_vert,fragmentShader:Qe.meshmatcap_frag},points:{uniforms:mn([Me.points,Me.fog]),vertexShader:Qe.points_vert,fragmentShader:Qe.points_frag},dashed:{uniforms:mn([Me.common,Me.fog,{scale:{value:1},dashSize:{value:1},totalSize:{value:2}}]),vertexShader:Qe.linedashed_vert,fragmentShader:Qe.linedashed_frag},depth:{uniforms:mn([Me.common,Me.displacementmap]),vertexShader:Qe.depth_vert,fragmentShader:Qe.depth_frag},normal:{uniforms:mn([Me.common,Me.bumpmap,Me.normalmap,Me.displacementmap,{opacity:{value:1}}]),vertexShader:Qe.meshnormal_vert,fragmentShader:Qe.meshnormal_frag},sprite:{uniforms:mn([Me.sprite,Me.fog]),vertexShader:Qe.sprite_vert,fragmentShader:Qe.sprite_frag},background:{uniforms:{uvTransform:{value:new Ye},t2D:{value:null},backgroundIntensity:{value:1}},vertexShader:Qe.background_vert,fragmentShader:Qe.background_frag},backgroundCube:{uniforms:{envMap:{value:null},backgroundBlurriness:{value:0},backgroundIntensity:{value:1},backgroundRotation:{value:new Ye}},vertexShader:Qe.backgroundCube_vert,fragmentShader:Qe.backgroundCube_frag},cube:{uniforms:{tCube:{value:null},tFlip:{value:-1},opacity:{value:1}},vertexShader:Qe.cube_vert,fragmentShader:Qe.cube_frag},equirect:{uniforms:{tEquirect:{value:null}},vertexShader:Qe.equirect_vert,fragmentShader:Qe.equirect_frag},distance:{uniforms:mn([Me.common,Me.displacementmap,{referencePosition:{value:new I},nearDistance:{value:1},farDistance:{value:1e3}}]),vertexShader:Qe.distance_vert,fragmentShader:Qe.distance_frag},shadow:{uniforms:mn([Me.lights,Me.fog,{color:{value:new Ve(0)},opacity:{value:1}}]),vertexShader:Qe.shadow_vert,fragmentShader:Qe.shadow_frag}};Mi.physical={uniforms:mn([Mi.standard.uniforms,{clearcoat:{value:0},clearcoatMap:{value:null},clearcoatMapTransform:{value:new Ye},clearcoatNormalMap:{value:null},clearcoatNormalMapTransform:{value:new Ye},clearcoatNormalScale:{value:new ce(1,1)},clearcoatRoughness:{value:0},clearcoatRoughnessMap:{value:null},clearcoatRoughnessMapTransform:{value:new Ye},dispersion:{value:0},retroreflectivity:{value:0},iridescence:{value:0},iridescenceMap:{value:null},iridescenceMapTransform:{value:new Ye},iridescenceIOR:{value:1.3},iridescenceThicknessMinimum:{value:100},iridescenceThicknessMaximum:{value:400},iridescenceThicknessMap:{value:null},iridescenceThicknessMapTransform:{value:new Ye},sheen:{value:0},sheenColor:{value:new Ve(0)},sheenColorMap:{value:null},sheenColorMapTransform:{value:new Ye},sheenRoughness:{value:1},sheenRoughnessMap:{value:null},sheenRoughnessMapTransform:{value:new Ye},transmission:{value:0},transmissionMap:{value:null},transmissionMapTransform:{value:new Ye},transmissionSamplerSize:{value:new ce},transmissionSamplerMap:{value:null},thickness:{value:0},thicknessMap:{value:null},thicknessMapTransform:{value:new Ye},attenuationDistance:{value:0},attenuationColor:{value:new Ve(0)},specularColor:{value:new Ve(1,1,1)},specularColorMap:{value:null},specularColorMapTransform:{value:new Ye},specularIntensity:{value:1},specularIntensityMap:{value:null},specularIntensityMapTransform:{value:new Ye},anisotropyVector:{value:new ce},anisotropyMap:{value:null},anisotropyMapTransform:{value:new Ye}}]),vertexShader:Qe.meshphysical_vert,fragmentShader:Qe.meshphysical_frag};var gu={r:0,b:0,g:0},JS=new Ie,Kg=new Ye;Kg.set(-1,0,0,0,1,0,0,0,1);function $S(i,e,t,n,s,r){let o=new Ve(0),a=s===!0?0:1,c,l,u=null,h=0,f=null;function d(v){let b=v.isScene===!0?v.background:null;if(b&&b.isTexture){let _=v.backgroundBlurriness>0;b=e.get(b,_)}return b}function m(v){let b=!1,_=d(v);_===null?g(o,a):_&&_.isColor&&(g(_,1),b=!0);let S=i.xr.getEnvironmentBlendMode();S==="additive"?t.buffers.color.setClear(0,0,0,1,r):S==="alpha-blend"&&t.buffers.color.setClear(0,0,0,0,r),(i.autoClear||b)&&(t.buffers.depth.setTest(!0),t.buffers.depth.setMask(!0),t.buffers.color.setMask(!0),i.clear(i.autoClearColor,i.autoClearDepth,i.autoClearStencil))}function x(v,b){let _=d(b);_&&(_.isCubeTexture||_.mapping===Ia)?(l===void 0&&(l=new it(new In(1,1,1),new ln({name:"BackgroundCubeMaterial",uniforms:Ks(Mi.backgroundCube.uniforms),vertexShader:Mi.backgroundCube.vertexShader,fragmentShader:Mi.backgroundCube.fragmentShader,side:jt,depthTest:!1,depthWrite:!1,fog:!1,allowOverride:!1})),l.geometry.deleteAttribute("normal"),l.geometry.deleteAttribute("uv"),l.onBeforeRender=function(S,M,E){this.matrixWorld.copyPosition(E.matrixWorld)},Object.defineProperty(l.material,"envMap",{get:function(){return this.uniforms.envMap.value}}),n.update(l)),l.material.uniforms.envMap.value=_,l.material.uniforms.backgroundBlurriness.value=b.backgroundBlurriness,l.material.uniforms.backgroundIntensity.value=b.backgroundIntensity,l.material.uniforms.backgroundRotation.value.setFromMatrix4(JS.makeRotationFromEuler(b.backgroundRotation)).transpose(),_.isCubeTexture&&_.isRenderTargetTexture===!1&&l.material.uniforms.backgroundRotation.value.premultiply(Kg),l.material.toneMapped=tt.getTransfer(_.colorSpace)!==yt,(u!==_||h!==_.version||f!==i.toneMapping)&&(l.material.needsUpdate=!0,u=_,h=_.version,f=i.toneMapping),l.layers.enableAll(),v.unshift(l,l.geometry,l.material,0,0,null)):_&&_.isTexture&&(c===void 0&&(c=new it(new _a(2,2),new ln({name:"BackgroundMaterial",uniforms:Ks(Mi.background.uniforms),vertexShader:Mi.background.vertexShader,fragmentShader:Mi.background.fragmentShader,side:kn,depthTest:!1,depthWrite:!1,fog:!1,allowOverride:!1})),c.geometry.deleteAttribute("normal"),Object.defineProperty(c.material,"map",{get:function(){return this.uniforms.t2D.value}}),n.update(c)),c.material.uniforms.t2D.value=_,c.material.uniforms.backgroundIntensity.value=b.backgroundIntensity,c.material.toneMapped=tt.getTransfer(_.colorSpace)!==yt,_.matrixAutoUpdate===!0&&_.updateMatrix(),c.material.uniforms.uvTransform.value.copy(_.matrix),(u!==_||h!==_.version||f!==i.toneMapping)&&(c.material.needsUpdate=!0,u=_,h=_.version,f=i.toneMapping),c.layers.enableAll(),v.unshift(c,c.geometry,c.material,0,0,null))}function g(v,b){v.getRGB(gu,Ff(i)),t.buffers.color.setClear(gu.r,gu.g,gu.b,b,r)}function p(){l!==void 0&&(l.geometry.dispose(),l.material.dispose(),l=void 0),c!==void 0&&(c.geometry.dispose(),c.material.dispose(),c=void 0)}return{getClearColor:function(){return o},setClearColor:function(v,b=1){o.set(v),a=b,g(o,a)},getClearAlpha:function(){return a},setClearAlpha:function(v){a=v,g(o,a)},render:m,addToRenderList:x,dispose:p}}function jS(i,e){let t=i.getParameter(i.MAX_VERTEX_ATTRIBS),n={},s=f(null),r=s,o=!1;function a(P,C,D,L,U){let G=!1,Z=h(P,L,D,C);r!==Z&&(r=Z,l(r.object)),G=d(P,L,D,U),G&&m(P,L,D,U),U!==null&&e.update(U,i.ELEMENT_ARRAY_BUFFER),(G||o)&&(o=!1,_(P,C,D,L),U!==null&&i.bindBuffer(i.ELEMENT_ARRAY_BUFFER,e.get(U).buffer))}function c(){return i.createVertexArray()}function l(P){return i.bindVertexArray(P)}function u(P){return i.deleteVertexArray(P)}function h(P,C,D,L){let U=L.wireframe===!0,G=n[C.id];G===void 0&&(G={},n[C.id]=G);let Z=P.isInstancedMesh===!0?P.id:0,oe=G[Z];oe===void 0&&(oe={},G[Z]=oe);let K=oe[D.id];K===void 0&&(K={},oe[D.id]=K);let te=K[U];return te===void 0&&(te=f(c()),K[U]=te),te}function f(P){let C=[],D=[],L=[];for(let U=0;U<t;U++)C[U]=0,D[U]=0,L[U]=0;return{geometry:null,program:null,wireframe:!1,newAttributes:C,enabledAttributes:D,attributeDivisors:L,object:P,attributes:{},index:null}}function d(P,C,D,L){let U=r.attributes,G=C.attributes,Z=0,oe=D.getAttributes();for(let K in oe)if(oe[K].location>=0){let se=U[K],Re=G[K];if(Re===void 0&&(K==="instanceMatrix"&&P.instanceMatrix&&(Re=P.instanceMatrix),K==="instanceColor"&&P.instanceColor&&(Re=P.instanceColor)),se===void 0||se.attribute!==Re||Re&&se.data!==Re.data)return!0;Z++}return r.attributesNum!==Z||r.index!==L}function m(P,C,D,L){let U={},G=C.attributes,Z=0,oe=D.getAttributes();for(let K in oe)if(oe[K].location>=0){let se=G[K];se===void 0&&(K==="instanceMatrix"&&P.instanceMatrix&&(se=P.instanceMatrix),K==="instanceColor"&&P.instanceColor&&(se=P.instanceColor));let Re={};Re.attribute=se,se&&se.data&&(Re.data=se.data),U[K]=Re,Z++}r.attributes=U,r.attributesNum=Z,r.index=L}function x(){let P=r.newAttributes;for(let C=0,D=P.length;C<D;C++)P[C]=0}function g(P){p(P,0)}function p(P,C){let D=r.newAttributes,L=r.enabledAttributes,U=r.attributeDivisors;D[P]=1,L[P]===0&&(i.enableVertexAttribArray(P),L[P]=1),U[P]!==C&&(i.vertexAttribDivisor(P,C),U[P]=C)}function v(){let P=r.newAttributes,C=r.enabledAttributes;for(let D=0,L=C.length;D<L;D++)C[D]!==P[D]&&(i.disableVertexAttribArray(D),C[D]=0)}function b(P,C,D,L,U,G,Z){Z===!0?i.vertexAttribIPointer(P,C,D,U,G):i.vertexAttribPointer(P,C,D,L,U,G)}function _(P,C,D,L){x();let U=L.attributes,G=D.getAttributes(),Z=C.defaultAttributeValues;for(let oe in G){let K=G[oe];if(K.location>=0){let te=U[oe];if(te===void 0&&(oe==="instanceMatrix"&&P.instanceMatrix&&(te=P.instanceMatrix),oe==="instanceColor"&&P.instanceColor&&(te=P.instanceColor)),te!==void 0){let se=te.normalized,Re=te.itemSize,Te=e.get(te);if(Te===void 0)continue;let nt=Te.buffer,He=Te.type,$e=Te.bytesPerElement,$=He===i.INT||He===i.UNSIGNED_INT||te.gpuType===Cl;if(te.isInterleavedBufferAttribute){let z=te.data,j=z.stride,me=te.offset;if(z.isInstancedInterleavedBuffer){for(let fe=0;fe<K.locationSize;fe++)p(K.location+fe,z.meshPerAttribute);P.isInstancedMesh!==!0&&L._maxInstanceCount===void 0&&(L._maxInstanceCount=z.meshPerAttribute*z.count)}else for(let fe=0;fe<K.locationSize;fe++)g(K.location+fe);i.bindBuffer(i.ARRAY_BUFFER,nt);for(let fe=0;fe<K.locationSize;fe++)b(K.location+fe,Re/K.locationSize,He,se,j*$e,(me+Re/K.locationSize*fe)*$e,$)}else{if(te.isInstancedBufferAttribute){for(let z=0;z<K.locationSize;z++)p(K.location+z,te.meshPerAttribute);P.isInstancedMesh!==!0&&L._maxInstanceCount===void 0&&(L._maxInstanceCount=te.meshPerAttribute*te.count)}else for(let z=0;z<K.locationSize;z++)g(K.location+z);i.bindBuffer(i.ARRAY_BUFFER,nt);for(let z=0;z<K.locationSize;z++)b(K.location+z,Re/K.locationSize,He,se,Re*$e,Re/K.locationSize*z*$e,$)}}else if(Z!==void 0){let se=Z[oe];if(se!==void 0)switch(se.length){case 2:i.vertexAttrib2fv(K.location,se);break;case 3:i.vertexAttrib3fv(K.location,se);break;case 4:i.vertexAttrib4fv(K.location,se);break;default:i.vertexAttrib1fv(K.location,se)}}}}v()}function S(){w();for(let P in n){let C=n[P];for(let D in C){let L=C[D];for(let U in L){let G=L[U];for(let Z in G)u(G[Z].object),delete G[Z];delete L[U]}}delete n[P]}}function M(P){if(n[P.id]===void 0)return;let C=n[P.id];for(let D in C){let L=C[D];for(let U in L){let G=L[U];for(let Z in G)u(G[Z].object),delete G[Z];delete L[U]}}delete n[P.id]}function E(P){for(let C in n){let D=n[C];for(let L in D){let U=D[L];if(U[P.id]===void 0)continue;let G=U[P.id];for(let Z in G)u(G[Z].object),delete G[Z];delete U[P.id]}}}function y(P){for(let C in n){let D=n[C],L=P.isInstancedMesh===!0?P.id:0,U=D[L];if(U!==void 0){for(let G in U){let Z=U[G];for(let oe in Z)u(Z[oe].object),delete Z[oe];delete U[G]}delete D[L],Object.keys(D).length===0&&delete n[C]}}}function w(){A(),o=!0,r!==s&&(r=s,l(r.object))}function A(){s.geometry=null,s.program=null,s.wireframe=!1}return{setup:a,reset:w,resetDefaultState:A,dispose:S,releaseStatesOfGeometry:M,releaseStatesOfObject:y,releaseStatesOfProgram:E,initAttributes:x,enableAttribute:g,disableUnusedAttributes:v}}function QS(i,e,t){let n;function s(c){n=c}function r(c,l){i.drawArrays(n,c,l),t.update(l,n,1)}function o(c,l,u){u!==0&&(i.drawArraysInstanced(n,c,l,u),t.update(l,n,u))}function a(c,l,u){if(u===0)return;e.get("WEBGL_multi_draw").multiDrawArraysWEBGL(n,c,0,l,0,u);let f=0;for(let d=0;d<u;d++)f+=l[d];t.update(f,n,1)}this.setMode=s,this.render=r,this.renderInstances=o,this.renderMultiDraw=a}function eb(i,e,t,n){let s;function r(){if(s!==void 0)return s;if(e.has("EXT_texture_filter_anisotropic")===!0){let E=e.get("EXT_texture_filter_anisotropic");s=i.getParameter(E.MAX_TEXTURE_MAX_ANISOTROPY_EXT)}else s=0;return s}function o(E){return!(E!==Hn&&n.convert(E)!==i.getParameter(i.IMPLEMENTATION_COLOR_READ_FORMAT))}function a(E){let y=E===li&&(e.has("EXT_color_buffer_half_float")||e.has("EXT_color_buffer_float"));return!(E!==Dn&&E!==Vn&&!y&&n.convert(E)!==i.getParameter(i.IMPLEMENTATION_COLOR_READ_TYPE))}function c(E){if(E==="highp"){if(i.getShaderPrecisionFormat(i.VERTEX_SHADER,i.HIGH_FLOAT).precision>0&&i.getShaderPrecisionFormat(i.FRAGMENT_SHADER,i.HIGH_FLOAT).precision>0)return"highp";E="mediump"}return E==="mediump"&&i.getShaderPrecisionFormat(i.VERTEX_SHADER,i.MEDIUM_FLOAT).precision>0&&i.getShaderPrecisionFormat(i.FRAGMENT_SHADER,i.MEDIUM_FLOAT).precision>0?"mediump":"lowp"}let l=t.precision!==void 0?t.precision:"highp",u=c(l);u!==l&&(Fe("WebGLRenderer:",l,"not supported, using",u,"instead."),l=u);let h=t.logarithmicDepthBuffer===!0,f=t.reversedDepthBuffer===!0&&e.has("EXT_clip_control");t.reversedDepthBuffer===!0&&f===!1&&Fe("WebGLRenderer: Unable to use reversed depth buffer due to missing EXT_clip_control extension. Fallback to default depth buffer.");let d=i.getParameter(i.MAX_TEXTURE_IMAGE_UNITS),m=i.getParameter(i.MAX_VERTEX_TEXTURE_IMAGE_UNITS),x=i.getParameter(i.MAX_TEXTURE_SIZE),g=i.getParameter(i.MAX_CUBE_MAP_TEXTURE_SIZE),p=i.getParameter(i.MAX_VERTEX_ATTRIBS),v=i.getParameter(i.MAX_VERTEX_UNIFORM_VECTORS),b=i.getParameter(i.MAX_VARYING_VECTORS),_=i.getParameter(i.MAX_FRAGMENT_UNIFORM_VECTORS),S=i.getParameter(i.MAX_SAMPLES),M=i.getParameter(i.SAMPLES);return{isWebGL2:!0,getMaxAnisotropy:r,getMaxPrecision:c,textureFormatReadable:o,textureTypeReadable:a,precision:l,logarithmicDepthBuffer:h,reversedDepthBuffer:f,maxTextures:d,maxVertexTextures:m,maxTextureSize:x,maxCubemapSize:g,maxAttributes:p,maxVertexUniforms:v,maxVaryings:b,maxFragmentUniforms:_,maxSamples:S,samples:M}}function tb(i){let e=this,t=null,n=0,s=!1,r=!1,o=new an,a=new Ye,c={value:null,needsUpdate:!1};this.uniform=c,this.numPlanes=0,this.numIntersection=0,this.init=function(h,f){let d=h.length!==0||f||n!==0||s;return s=f,n=h.length,d},this.beginShadows=function(){r=!0,u(null)},this.endShadows=function(){r=!1},this.setGlobalState=function(h,f){t=u(h,f,0)},this.setState=function(h,f,d){let m=h.clippingPlanes,x=h.clipIntersection,g=h.clipShadows,p=i.get(h);if(!s||m===null||m.length===0||r&&!g)r?u(null):l();else{let v=r?0:n,b=v*4,_=p.clippingState||null;c.value=_,_=u(m,f,b,d);for(let S=0;S!==b;++S)_[S]=t[S];p.clippingState=_,this.numIntersection=x?this.numPlanes:0,this.numPlanes+=v}};function l(){c.value!==t&&(c.value=t,c.needsUpdate=n>0),e.numPlanes=n,e.numIntersection=0}function u(h,f,d,m){let x=h!==null?h.length:0,g=null;if(x!==0){if(g=c.value,m!==!0||g===null){let p=d+x*4,v=f.matrixWorldInverse;a.getNormalMatrix(v),(g===null||g.length<p)&&(g=new Float32Array(p));for(let b=0,_=d;b!==x;++b,_+=4)o.copy(h[b]).applyMatrix4(v,a),o.normal.toArray(g,_),g[_+3]=o.constant}c.value=g,c.needsUpdate=!0}return e.numPlanes=x,e.numIntersection=0,g}}var so=4,nb=6,ib=20,sb=256,za=new ps,Ag=new Ve,Xf=null,qf=0,Yf=0,Zf=!1,rb=new I,Js=new I,oo=class{constructor(e){this._renderer=e,this._pingPongRenderTarget=null,this._lodMax=0,this._cubeSize=0,this._sizeLods=[],this._lodMeshes=[],this._backgroundBox=null,this._cubemapMaterial=null,this._equirectMaterial=null,this._blurMaterial=null,this._ggxMaterial=null}fromScene(e,t=0,n=.1,s=100,r={}){let{size:o=256,position:a=rb}=r;Xf=this._renderer.getRenderTarget(),qf=this._renderer.getActiveCubeFace(),Yf=this._renderer.getActiveMipmapLevel(),Zf=this._renderer.xr.enabled,this._renderer.xr.enabled=!1,this._setSize(o);let c=this._allocateTargets();return c.depthBuffer=!0,this._sceneToCubeUV(e,n,s,c,a),t>0&&this._blur(c,0,0,t),this._applyPMREM(c),this._cleanup(c),c}fromEquirectangular(e,t=null){return this._fromTexture(e,t)}fromCubemap(e,t=null){return this._fromTexture(e,t)}compileCubemapShader(){this._cubemapMaterial===null&&(this._cubemapMaterial=Pg(),this._compileMaterial(this._cubemapMaterial))}compileEquirectangularShader(){this._equirectMaterial===null&&(this._equirectMaterial=Cg(),this._compileMaterial(this._equirectMaterial))}dispose(){this._dispose(),this._cubemapMaterial!==null&&this._cubemapMaterial.dispose(),this._equirectMaterial!==null&&this._equirectMaterial.dispose(),this._backgroundBox!==null&&(this._backgroundBox.geometry.dispose(),this._backgroundBox.material.dispose())}_setSize(e){this._lodMax=Math.floor(Math.log2(e)),this._cubeSize=Math.pow(2,this._lodMax)}_dispose(){this._blurMaterial!==null&&this._blurMaterial.dispose(),this._ggxMaterial!==null&&this._ggxMaterial.dispose(),this._pingPongRenderTarget!==null&&this._pingPongRenderTarget.dispose();for(let e=0;e<this._lodMeshes.length;e++)this._lodMeshes[e].geometry.dispose()}_cleanup(e){this._renderer.setRenderTarget(Xf,qf,Yf),this._renderer.xr.enabled=Zf,e.scissorTest=!1,io(e,0,0,e.width,e.height)}_fromTexture(e,t){e.mapping===xs||e.mapping===Ys?this._setSize(e.image.length===0?16:e.image[0].width||e.image[0].image.width):this._setSize(e.image.width/4),Xf=this._renderer.getRenderTarget(),qf=this._renderer.getActiveCubeFace(),Yf=this._renderer.getActiveMipmapLevel(),Zf=this._renderer.xr.enabled,this._renderer.xr.enabled=!1;let n=t||this._allocateTargets();return this._textureToCubeUV(e,n),this._applyPMREM(n),this._cleanup(n),n}_allocateTargets(){let e=3*Math.max(this._cubeSize,112),t=4*this._cubeSize,n={magFilter:Gt,minFilter:Gt,generateMipmaps:!1,type:li,format:Hn,colorSpace:bn,depthBuffer:!1},s=Rg(e,t,n);if(this._pingPongRenderTarget===null||this._pingPongRenderTarget.width!==e||this._pingPongRenderTarget.height!==t){this._pingPongRenderTarget!==null&&this._dispose(),this._pingPongRenderTarget=Rg(e,t,n);let{_lodMax:r}=this;({lodMeshes:this._lodMeshes,sizeLods:this._sizeLods}=ob(r)),this._blurMaterial=cb(r,e,t),this._ggxMaterial=ab(r,e,t)}return s}_compileMaterial(e){let t=new it(new ht,e);this._renderer.compile(t,za)}_sceneToCubeUV(e,t,n,s,r){let c=new Yt(90,1,t,n),l=[1,-1,1,1,1,1],u=[1,1,1,-1,-1,-1],h=this._renderer,f=h.autoClear,d=h.toneMapping;h.getClearColor(Ag),h.toneMapping=oi,h.autoClear=!1,h.state.buffers.depth.getReversed()&&(h.setRenderTarget(s),h.clearDepth(),h.setRenderTarget(null)),this._backgroundBox===null&&(this._backgroundBox=new it(new In,new Bn({name:"PMREM.Background",side:jt,depthWrite:!1,depthTest:!1})));let x=this._backgroundBox,g=x.material,p=!1,v=e.background;v?v.isColor&&(g.color.copy(v),e.background=null,p=!0):(g.color.copy(Ag),p=!0);for(let b=0;b<6;b++){let _=b%3;_===0?(c.up.set(0,l[b],0),c.position.set(r.x,r.y,r.z),c.lookAt(r.x+u[b],r.y,r.z)):_===1?(c.up.set(0,0,l[b]),c.position.set(r.x,r.y,r.z),c.lookAt(r.x,r.y+u[b],r.z)):(c.up.set(0,l[b],0),c.position.set(r.x,r.y,r.z),c.lookAt(r.x,r.y,r.z+u[b]));let S=this._cubeSize;io(s,_*S,b>2?S:0,S,S),h.setRenderTarget(s),p&&h.render(x,c),h.render(e,c)}h.toneMapping=d,h.autoClear=f,e.background=v}_textureToCubeUV(e,t){let n=this._renderer,s=e.mapping===xs||e.mapping===Ys;s?(this._cubemapMaterial===null&&(this._cubemapMaterial=Pg()),this._cubemapMaterial.uniforms.flipEnvMap.value=e.isRenderTargetTexture===!1?-1:1):this._equirectMaterial===null&&(this._equirectMaterial=Cg());let r=s?this._cubemapMaterial:this._equirectMaterial,o=this._lodMeshes[0];o.material=r;let a=r.uniforms;a.envMap.value=e;let c=this._cubeSize;io(t,0,0,3*c,2*c),n.setRenderTarget(t),n.render(o,za)}_applyPMREM(e){let t=this._renderer,n=t.autoClear;t.autoClear=!1;let s=this._lodMeshes.length;for(let r=1;r<s;r++)this._applyGGXFilter(e,r-1,r);t.autoClear=n}_applyGGXFilter(e,t,n){let s=this._renderer,r=this._pingPongRenderTarget,o=this._ggxMaterial,a=this._lodMeshes[n];a.material=o;let c=o.uniforms,l=n/(this._lodMeshes.length-1),u=t/(this._lodMeshes.length-1),h=Math.sqrt(l*l-u*u),f=l*1.25,d=h*f,{_lodMax:m}=this,x=this._sizeLods[n],g=3*x*(n>m-so?n-m+so:0),p=4*(this._cubeSize-x);c.envMap.value=e.texture,c.roughness.value=d,c.mipInt.value=m-t,io(r,g,p,3*x,2*x),s.setRenderTarget(r),s.render(a,za),c.envMap.value=r.texture,c.roughness.value=0,c.mipInt.value=m-n,io(e,g,p,3*x,2*x),s.setRenderTarget(e),s.render(a,za)}_blur(e,t,n,s){let r=this._pingPongRenderTarget,o=Math.min(s,Math.PI)/Math.SQRT2;this._blurPass(e,r,t,n,o),this._blurPass(r,e,n,n,o)}_blurPass(e,t,n,s,r){let o=this._renderer,a=this._blurMaterial,c=this._lodMeshes[s];c.material=a;let l=a.uniforms;l.envMap.value=e.texture,l.sigma.value=r,l.mipInt.value=this._lodMax-n;let u=this._sizeLods[s],h=3*u*(s>this._lodMax-so?s-this._lodMax+so:0),f=4*(this._cubeSize-u);io(t,h,f,3*u,2*u),o.setRenderTarget(t),o.render(c,za)}};function ob(i){let e=[],t=[],n=i,s=i-so+1+nb;for(let r=0;r<s;r++){let o=Math.pow(2,n);e.push(o);let a=1/(o-2),c=-a,l=1+a,u=[c,c,l,c,l,l,c,c,l,l,c,l],h=6,f=6,d=3,m=new Float32Array(d*f*h),x=new Float32Array(d*f*h);for(let p=0;p<h;p++){let v=p%3*2/3-1,b=p>2?0:-1,_=[v,b,0,v+2/3,b,0,v+2/3,b+1,0,v,b,0,v+2/3,b+1,0,v,b+1,0];m.set(_,d*f*p);for(let S=0;S<f;S++){let M=u[S*2]*2-1,E=u[S*2+1]*2-1;p===0?Js.set(1,E,M):p===1?Js.set(-M,1,-E):p===2?Js.set(-M,E,1):p===3?Js.set(-1,E,-M):p===4?Js.set(-M,-1,E):Js.set(M,E,-1),Js.toArray(x,(p*f+S)*d)}}let g=new ht;g.setAttribute("position",new Tt(m,d)),g.setAttribute("outputDirection",new Tt(x,d)),t.push(new it(g,null)),n>so&&n--}return{lodMeshes:t,sizeLods:e}}function Rg(i,e,t){let n=new Rn(i,e,t);return n.texture.mapping=Ia,n.texture.name="PMREM.cubeUv",n.scissorTest=!0,n}function io(i,e,t,n,s){i.viewport.set(e,t,n,s),i.scissor.set(e,t,n,s)}function ab(i,e,t){return new ln({name:"PMREMGGXConvolution",defines:{GGX_SAMPLES:sb,CUBEUV_TEXEL_WIDTH:1/e,CUBEUV_TEXEL_HEIGHT:1/t,CUBEUV_MAX_MIP:`${i}.0`},uniforms:{envMap:{value:null},roughness:{value:0},mipInt:{value:0}},vertexShader:Su(),fragmentShader:`

			precision highp float;
			precision highp int;

			varying vec3 vOutputDirection;

			uniform sampler2D envMap;
			uniform float roughness;
			uniform float mipInt;

			#define ENVMAP_TYPE_CUBE_UV
			#include <cube_uv_reflection_fragment>

			#define PI 3.14159265359

			// Van der Corput radical inverse
			float radicalInverse_VdC(uint bits) {
				bits = (bits << 16u) | (bits >> 16u);
				bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
				bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
				bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
				bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
				return float(bits) * 2.3283064365386963e-10; // / 0x100000000
			}

			// Hammersley sequence
			vec2 hammersley(uint i, uint N) {
				return vec2(float(i) / float(N), radicalInverse_VdC(i));
			}

			// GGX VNDF importance sampling (Eric Heitz 2018)
			// "Sampling the GGX Distribution of Visible Normals"
			// https://jcgt.org/published/0007/04/01/
			vec3 importanceSampleGGX_VNDF(vec2 Xi, vec3 V, float roughness) {
				float alpha = roughness * roughness;

				// Section 4.1: Orthonormal basis
				vec3 T1 = vec3(1.0, 0.0, 0.0);
				vec3 T2 = cross(V, T1);

				// Section 4.2: Parameterization of projected area
				float r = sqrt(Xi.x);
				float phi = 2.0 * PI * Xi.y;
				float t1 = r * cos(phi);
				float t2 = r * sin(phi);
				float s = 0.5 * (1.0 + V.z);
				t2 = (1.0 - s) * sqrt(1.0 - t1 * t1) + s * t2;

				// Section 4.3: Reprojection onto hemisphere
				vec3 Nh = t1 * T1 + t2 * T2 + sqrt(max(0.0, 1.0 - t1 * t1 - t2 * t2)) * V;

				// Section 3.4: Transform back to ellipsoid configuration
				return normalize(vec3(alpha * Nh.x, alpha * Nh.y, max(0.0, Nh.z)));
			}

			void main() {
				vec3 N = normalize(vOutputDirection);
				vec3 V = N; // Assume view direction equals normal for pre-filtering

				vec3 prefilteredColor = vec3(0.0);
				float totalWeight = 0.0;

				// For very low roughness, just sample the environment directly
				if (roughness < 0.001) {
					gl_FragColor = vec4(bilinearCubeUV(envMap, N, mipInt), 1.0);
					return;
				}

				// Tangent space basis for VNDF sampling
				vec3 up = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
				vec3 tangent = normalize(cross(up, N));
				vec3 bitangent = cross(N, tangent);

				for(uint i = 0u; i < uint(GGX_SAMPLES); i++) {
					vec2 Xi = hammersley(i, uint(GGX_SAMPLES));

					// For PMREM, V = N, so in tangent space V is always (0, 0, 1)
					vec3 H_tangent = importanceSampleGGX_VNDF(Xi, vec3(0.0, 0.0, 1.0), roughness);

					// Transform H back to world space
					vec3 H = normalize(tangent * H_tangent.x + bitangent * H_tangent.y + N * H_tangent.z);
					vec3 L = normalize(2.0 * dot(V, H) * H - V);

					float NdotL = max(dot(N, L), 0.0);

					if(NdotL > 0.0) {
						// Sample environment at fixed mip level
						// VNDF importance sampling handles the distribution filtering
						vec3 sampleColor = bilinearCubeUV(envMap, L, mipInt);

						// Weight by NdotL for the split-sum approximation
						// VNDF PDF naturally accounts for the visible microfacet distribution
						prefilteredColor += sampleColor * NdotL;
						totalWeight += NdotL;
					}
				}

				if (totalWeight > 0.0) {
					prefilteredColor = prefilteredColor / totalWeight;
				}

				gl_FragColor = vec4(prefilteredColor, 1.0);
			}
		`,blending:Si,depthTest:!1,depthWrite:!1})}function cb(i,e,t){return new ln({name:"SphericalGaussianBlur",defines:{SAMPLES:ib,CUBEUV_TEXEL_WIDTH:1/e,CUBEUV_TEXEL_HEIGHT:1/t,CUBEUV_MAX_MIP:`${i}.0`},uniforms:{envMap:{value:null},sigma:{value:0},mipInt:{value:0}},vertexShader:Su(),fragmentShader:`

			precision highp float;
			precision highp int;

			varying vec3 vOutputDirection;

			uniform sampler2D envMap;
			uniform float sigma;
			uniform float mipInt;

			#define ENVMAP_TYPE_CUBE_UV
			#include <cube_uv_reflection_fragment>

			#define PI 3.14159265359
			#define GOLDEN_ANGLE 2.39996322973

			void main() {

				if ( sigma == 0.0 ) {

					gl_FragColor = vec4( bilinearCubeUV( envMap, vOutputDirection, mipInt ), 1.0 );
					return;

				}

				vec3 outputDirection = normalize( vOutputDirection );

				vec3 up = abs( outputDirection.z ) < 0.999 ? vec3( 0.0, 0.0, 1.0 ) : vec3( 1.0, 0.0, 0.0 );
				vec3 tangent = normalize( cross( up, outputDirection ) );
				vec3 bitangent = cross( outputDirection, tangent );

				// Truncate the kernel at three standard deviations or at the antipode.
				float thetaMax = min( 3.0 * sigma, PI );
				float truncation = 1.0 - exp( - 0.5 * thetaMax * thetaMax / ( sigma * sigma ) );

				vec3 accumColor = vec3( 0.0 );
				float accumWeight = 0.0;

				for ( int i = 0; i < SAMPLES; i ++ ) {

					// Stratified inverse-CDF sampling of the Gaussian, placed on a golden-angle spiral.
					float stratum = ( float( i ) + 0.5 ) / float( SAMPLES );
					float theta = sigma * sqrt( - 2.0 * log( 1.0 - stratum * truncation ) );
					float phi = float( i ) * GOLDEN_ANGLE;

					vec3 offset = cos( phi ) * tangent + sin( phi ) * bitangent;
					vec3 sampleDirection = cos( theta ) * outputDirection + sin( theta ) * offset;

					// Correct the planar sample density to solid angle.
					float weight = sin( theta ) / theta;

					accumColor += weight * bilinearCubeUV( envMap, sampleDirection, mipInt );
					accumWeight += weight;

				}

				gl_FragColor = vec4( accumColor / accumWeight, 1.0 );

			}
		`,blending:Si,depthTest:!1,depthWrite:!1})}function Cg(){return new ln({name:"EquirectangularToCubeUV",uniforms:{envMap:{value:null}},vertexShader:Su(),fragmentShader:`

			precision mediump float;
			precision mediump int;

			varying vec3 vOutputDirection;

			uniform sampler2D envMap;

			#include <common>

			void main() {

				vec3 outputDirection = normalize( vOutputDirection );
				vec2 uv = equirectUv( outputDirection );

				gl_FragColor = vec4( texture2D ( envMap, uv ).rgb, 1.0 );

			}
		`,blending:Si,depthTest:!1,depthWrite:!1})}function Pg(){return new ln({name:"CubemapToCubeUV",uniforms:{envMap:{value:null},flipEnvMap:{value:-1}},vertexShader:Su(),fragmentShader:`

			precision mediump float;
			precision mediump int;

			uniform float flipEnvMap;

			varying vec3 vOutputDirection;

			uniform samplerCube envMap;

			void main() {

				gl_FragColor = textureCube( envMap, vec3( flipEnvMap * vOutputDirection.x, vOutputDirection.yz ) );

			}
		`,blending:Si,depthTest:!1,depthWrite:!1})}function Su(){return`

		precision mediump float;
		precision mediump int;

		attribute vec3 outputDirection;

		varying vec3 vOutputDirection;

		void main() {

			vOutputDirection = outputDirection;
			gl_Position = vec4( position, 1.0 );

		}
	`}var _u=class extends Rn{constructor(e=1,t={}){super(e,e,t),this.isWebGLCubeRenderTarget=!0;let n={width:e,height:e,depth:1},s=[n,n,n,n,n,n];this.texture=new oa(s),this._setTextureOptions(t),this.texture.isRenderTargetTexture=!0}fromEquirectangularTexture(e,t){this.texture.type=t.type,this.texture.colorSpace=t.colorSpace,this.texture.generateMipmaps=t.generateMipmaps,this.texture.minFilter=t.minFilter,this.texture.magFilter=t.magFilter;let n={uniforms:{tEquirect:{value:null}},vertexShader:`

				varying vec3 vWorldDirection;

				vec3 transformDirection( in vec3 dir, in mat4 matrix ) {

					return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );

				}

				void main() {

					vWorldDirection = transformDirection( position, modelMatrix );

					#include <begin_vertex>
					#include <project_vertex>

				}
			`,fragmentShader:`

				uniform sampler2D tEquirect;

				varying vec3 vWorldDirection;

				#include <common>

				void main() {

					vec3 direction = normalize( vWorldDirection );

					vec2 sampleUV = equirectUv( direction );

					gl_FragColor = texture2D( tEquirect, sampleUV );

				}
			`},s=new In(5,5,5),r=new ln({name:"CubemapFromEquirect",uniforms:Ks(n.uniforms),vertexShader:n.vertexShader,fragmentShader:n.fragmentShader,side:jt,blending:Si});r.uniforms.tEquirect.value=t;let o=new it(s,r),a=t.minFilter;return t.minFilter===ai&&(t.minFilter=Gt),new bl(1,10,this).update(e,o),t.minFilter=a,o.geometry.dispose(),o.material.dispose(),this}clear(e,t=!0,n=!0,s=!0){let r=e.getRenderTarget();for(let o=0;o<6;o++)e.setRenderTarget(this,o),e.clear(t,n,s);e.setRenderTarget(r)}};function lb(i){let e=new WeakMap,t=new WeakMap,n=null;function s(f,d=!1){return f==null?null:d?o(f):r(f)}function r(f){if(f&&f.isTexture){let d=f.mapping;if(d===El||d===Al)if(e.has(f)){let m=e.get(f).texture;return a(m,f.mapping)}else{let m=f.image;if(m&&m.height>0){let x=new _u(m.height);return x.fromEquirectangularTexture(i,f),e.set(f,x),f.addEventListener("dispose",l),a(x.texture,f.mapping)}else return null}}return f}function o(f){if(f&&f.isTexture){let d=f.mapping,m=d===El||d===Al,x=d===xs||d===Ys;if(m||x){let g=t.get(f),p=g!==void 0?g.texture.pmremVersion:0;if(f.isRenderTargetTexture&&f.pmremVersion!==p)return n===null&&(n=new oo(i)),g=m?n.fromEquirectangular(f,g):n.fromCubemap(f,g),g.texture.pmremVersion=f.pmremVersion,t.set(f,g),g.texture;if(g!==void 0)return g.texture;{let v=f.image;return m&&v&&v.height>0||x&&v&&c(v)?(n===null&&(n=new oo(i)),g=m?n.fromEquirectangular(f):n.fromCubemap(f),g.texture.pmremVersion=f.pmremVersion,t.set(f,g),f.addEventListener("dispose",u),g.texture):null}}}return f}function a(f,d){return d===El?f.mapping=xs:d===Al&&(f.mapping=Ys),f}function c(f){let d=0,m=6;for(let x=0;x<m;x++)f[x]!==void 0&&d++;return d===m}function l(f){let d=f.target;d.removeEventListener("dispose",l);let m=e.get(d);m!==void 0&&(e.delete(d),m.dispose())}function u(f){let d=f.target;d.removeEventListener("dispose",u);let m=t.get(d);m!==void 0&&(t.delete(d),m.dispose())}function h(){e=new WeakMap,t=new WeakMap,n!==null&&(n.dispose(),n=null)}return{get:s,dispose:h}}function ub(i){let e={};function t(n){if(e[n]!==void 0)return e[n];let s=i.getExtension(n);return e[n]=s,s}return{has:function(n){return t(n)!==null},init:function(){t("EXT_color_buffer_float"),t("WEBGL_clip_cull_distance"),t("OES_texture_float_linear"),t("EXT_color_buffer_half_float"),t("WEBGL_multisampled_render_to_texture"),t("WEBGL_render_shared_exponent")},get:function(n){let s=t(n);return s===null&&Ds("WebGLRenderer: "+n+" extension not supported."),s}}}function hb(i,e,t,n){let s={},r=new WeakMap;function o(h){let f=h.target;f.index!==null&&e.remove(f.index);for(let m in f.attributes)e.remove(f.attributes[m]);f.removeEventListener("dispose",o),delete s[f.id];let d=r.get(f);d&&(e.remove(d),r.delete(f)),n.releaseStatesOfGeometry(f),f.isInstancedBufferGeometry===!0&&delete f._maxInstanceCount,t.memory.geometries--}function a(h,f){return s[f.id]===!0||(f.addEventListener("dispose",o),s[f.id]=!0,t.memory.geometries++),f}function c(h){let f=h.attributes;for(let d in f)e.update(f[d],i.ARRAY_BUFFER)}function l(h){let f=[],d=h.index,m=h.attributes.position,x=0;if(m===void 0)return;if(d!==null){let v=d.array;x=d.version;for(let b=0,_=v.length;b<_;b+=3){let S=v[b+0],M=v[b+1],E=v[b+2];f.push(S,M,M,E,E,S)}}else{let v=m.array;x=m.version;for(let b=0,_=v.length/3-1;b<_;b+=3){let S=b+0,M=b+1,E=b+2;f.push(S,M,M,E,E,S)}}let g=new(m.count>=65535?jo:$o)(f,1);g.version=x;let p=r.get(h);p&&e.remove(p),r.set(h,g)}function u(h){let f=r.get(h);if(f){let d=h.index;d!==null&&f.version<d.version&&l(h)}else l(h);return r.get(h)}return{get:a,update:c,getWireframeAttribute:u}}function fb(i,e,t){let n;function s(h){n=h}let r,o;function a(h){r=h.type,o=h.bytesPerElement}function c(h,f){i.drawElements(n,f,r,h*o),t.update(f,n,1)}function l(h,f,d){d!==0&&(i.drawElementsInstanced(n,f,r,h*o,d),t.update(f,n,d))}function u(h,f,d){if(d===0)return;e.get("WEBGL_multi_draw").multiDrawElementsWEBGL(n,f,0,r,h,0,d);let x=0;for(let g=0;g<d;g++)x+=f[g];t.update(x,n,1)}this.setMode=s,this.setIndex=a,this.render=c,this.renderInstances=l,this.renderMultiDraw=u}function db(i){let e={geometries:0,textures:0},t={frame:0,calls:0,triangles:0,points:0,lines:0};function n(r,o,a){switch(t.calls++,o){case i.TRIANGLES:t.triangles+=a*(r/3);break;case i.LINES:t.lines+=a*(r/2);break;case i.LINE_STRIP:t.lines+=a*(r-1);break;case i.LINE_LOOP:t.lines+=a*r;break;case i.POINTS:t.points+=a*r;break;default:We("WebGLInfo: Unknown draw mode:",o);break}}function s(){t.calls=0,t.triangles=0,t.points=0,t.lines=0}return{memory:e,render:t,programs:null,autoReset:!0,reset:s,update:n}}function pb(i,e,t){let n=new WeakMap,s=new ut;function r(o,a,c){let l=o.morphTargetInfluences,u=a.morphAttributes.position||a.morphAttributes.normal||a.morphAttributes.color,h=u!==void 0?u.length:0,f=n.get(a);if(f===void 0||f.count!==h){let w=function(){E.dispose(),n.delete(a),a.removeEventListener("dispose",w)};f!==void 0&&f.texture.dispose();let d=a.morphAttributes.position!==void 0,m=a.morphAttributes.normal!==void 0,x=a.morphAttributes.color!==void 0,g=a.morphAttributes.position||[],p=a.morphAttributes.normal||[],v=a.morphAttributes.color||[],b=0;d===!0&&(b=1),m===!0&&(b=2),x===!0&&(b=3);let _=a.attributes.position.count*b,S=1;_>e.maxTextureSize&&(S=Math.ceil(_/e.maxTextureSize),_=e.maxTextureSize);let M=new Float32Array(_*S*4*h),E=new Ko(M,_,S,h);E.type=Vn,E.needsUpdate=!0;let y=b*4;for(let A=0;A<h;A++){let P=g[A],C=p[A],D=v[A],L=_*S*4*A;for(let U=0;U<P.count;U++){let G=U*y;d===!0&&(s.fromBufferAttribute(P,U),M[L+G+0]=s.x,M[L+G+1]=s.y,M[L+G+2]=s.z,M[L+G+3]=0),m===!0&&(s.fromBufferAttribute(C,U),M[L+G+4]=s.x,M[L+G+5]=s.y,M[L+G+6]=s.z,M[L+G+7]=0),x===!0&&(s.fromBufferAttribute(D,U),M[L+G+8]=s.x,M[L+G+9]=s.y,M[L+G+10]=s.z,M[L+G+11]=D.itemSize===4?s.w:1)}}f={count:h,texture:E,size:new ce(_,S)},n.set(a,f),a.addEventListener("dispose",w)}if(o.isInstancedMesh===!0&&o.morphTexture!==null)c.getUniforms().setValue(i,"morphTexture",o.morphTexture,t);else{let d=0;for(let x=0;x<l.length;x++)d+=l[x];let m=a.morphTargetsRelative?1:1-d;c.getUniforms().setValue(i,"morphTargetBaseInfluence",m),c.getUniforms().setValue(i,"morphTargetInfluences",l)}c.getUniforms().setValue(i,"morphTargetsTexture",f.texture,t),c.getUniforms().setValue(i,"morphTargetsTextureSize",f.size)}return{update:r}}function mb(i,e,t,n,s){let r=new WeakMap;function o(l){let u=s.render.frame,h=l.geometry,f=e.get(l,h);if(r.get(f)!==u&&(e.update(f),r.set(f,u)),l.isInstancedMesh&&(l.hasEventListener("dispose",c)===!1&&l.addEventListener("dispose",c),r.get(l)!==u&&(t.update(l.instanceMatrix,i.ARRAY_BUFFER),l.instanceColor!==null&&t.update(l.instanceColor,i.ARRAY_BUFFER),r.set(l,u))),l.isSkinnedMesh){let d=l.skeleton;r.get(d)!==u&&(d.update(),r.set(d,u))}return f}function a(){r=new WeakMap}function c(l){let u=l.target;u.removeEventListener("dispose",c),n.releaseStatesOfObject(u),t.remove(u.instanceMatrix),u.instanceColor!==null&&t.remove(u.instanceColor)}return{update:o,dispose:a}}var gb={[_f]:"LINEAR_TONE_MAPPING",[yf]:"REINHARD_TONE_MAPPING",[vf]:"CINEON_TONE_MAPPING",[Pa]:"ACES_FILMIC_TONE_MAPPING",[bf]:"AGX_TONE_MAPPING",[Mf]:"NEUTRAL_TONE_MAPPING",[Sf]:"CUSTOM_TONE_MAPPING"};function xb(i,e,t,n,s,r){let o=new Rn(e,t,{type:i,depthBuffer:s,stencilBuffer:r,samples:n?4:0,storeMultisampledDepthBuffer:!1,storeMultisampledStencilBuffer:!1,resolveDepthBuffer:!1,resolveStencilBuffer:!1}),a=null,c=null,l=new ht;l.setAttribute("position",new lt([-1,3,0,-1,-1,0,3,-1,0],3)),l.setAttribute("uv",new lt([0,2,0,0,2,0],2));let u=new fl({uniforms:{tDiffuse:{value:null}},vertexShader:`
			precision highp float;

			uniform mat4 modelViewMatrix;
			uniform mat4 projectionMatrix;

			attribute vec3 position;
			attribute vec2 uv;

			varying vec2 vUv;

			void main() {
				vUv = uv;
				gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
			}`,fragmentShader:`
			precision highp float;

			uniform sampler2D tDiffuse;

			varying vec2 vUv;

			#include <tonemapping_pars_fragment>
			#include <colorspace_pars_fragment>

			void main() {
				gl_FragColor = texture2D( tDiffuse, vUv );

				#ifdef LINEAR_TONE_MAPPING
					gl_FragColor.rgb = LinearToneMapping( gl_FragColor.rgb );
				#elif defined( REINHARD_TONE_MAPPING )
					gl_FragColor.rgb = ReinhardToneMapping( gl_FragColor.rgb );
				#elif defined( CINEON_TONE_MAPPING )
					gl_FragColor.rgb = CineonToneMapping( gl_FragColor.rgb );
				#elif defined( ACES_FILMIC_TONE_MAPPING )
					gl_FragColor.rgb = ACESFilmicToneMapping( gl_FragColor.rgb );
				#elif defined( AGX_TONE_MAPPING )
					gl_FragColor.rgb = AgXToneMapping( gl_FragColor.rgb );
				#elif defined( NEUTRAL_TONE_MAPPING )
					gl_FragColor.rgb = NeutralToneMapping( gl_FragColor.rgb );
				#elif defined( CUSTOM_TONE_MAPPING )
					gl_FragColor.rgb = CustomToneMapping( gl_FragColor.rgb );
				#endif

				#ifdef SRGB_TRANSFER
					gl_FragColor = sRGBTransferOETF( gl_FragColor );
				#endif
			}`,depthTest:!1,depthWrite:!1}),h=new it(l,u),f=new ps(-1,1,1,-1,0,1),d=null,m=null,x=!1,g,p=null,v=[],b=!1;this.setSize=function(_,S){o.setSize(_,S),a!==null&&a.setSize(_,S),c!==null&&c.setSize(_,S);for(let M=0;M<v.length;M++){let E=v[M];E.setSize&&E.setSize(_,S)}},this.setEffects=function(_){v=_,b=v.length>0&&v[0].isRenderPass===!0;let S=o.width,M=o.height;v.length>0&&a===null&&(a=new Rn(S,M,{type:li,depthBuffer:!1,stencilBuffer:!1}),c=new Rn(S,M,{type:li,depthBuffer:!1,stencilBuffer:!1}));for(let E=0;E<v.length;E++){let y=v[E];y.setSize&&y.setSize(S,M)}},this.begin=function(_,S){if(x||_.toneMapping===oi&&v.length===0)return!1;if(p=S,S!==null){let M=S.width,E=S.height;(o.width!==M||o.height!==E)&&this.setSize(M,E)}return b===!1&&_.setRenderTarget(o),g=_.toneMapping,_.toneMapping=oi,!0},this.hasRenderPass=function(){return b},this.end=function(_,S){_.toneMapping=g,x=!0;let M=o,E=a;for(let y=0;y<v.length;y++){let w=v[y];w.enabled!==!1&&(w.render(_,E,M,S),w.needsSwap!==!1&&(M=E,E=E===a?c:a))}if(d!==_.outputColorSpace||m!==_.toneMapping){d=_.outputColorSpace,m=_.toneMapping,u.defines={},tt.getTransfer(d)===yt&&(u.defines.SRGB_TRANSFER="");let y=gb[m];y&&(u.defines[y]=""),u.needsUpdate=!0}u.uniforms.tDiffuse.value=M.texture,_.setRenderTarget(p),_.render(h,f),p=null,x=!1},this.isCompositing=function(){return x},this.dispose=function(){o.dispose(),a!==null&&a.dispose(),c!==null&&c.dispose(),l.dispose(),u.dispose()}}var Jg=new Jt,$f=new hs(1,1),$g=new Ko,jg=new nl,Qg=new oa,Ig=[],Lg=[],Ng=new Float32Array(16),Dg=new Float32Array(9),Ug=new Float32Array(4);function ao(i,e,t){let n=i[0];if(n<=0||n>0)return i;let s=e*t,r=Ig[s];if(r===void 0&&(r=new Float32Array(s),Ig[s]=r),e!==0){n.toArray(r,0);for(let o=1,a=0;o!==e;++o)a+=t,i[o].toArray(r,a)}return r}function Qt(i,e){if(i.length!==e.length)return!1;for(let t=0,n=i.length;t<n;t++)if(i[t]!==e[t])return!1;return!0}function en(i,e){for(let t=0,n=e.length;t<n;t++)i[t]=e[t]}function bu(i,e){let t=Lg[e];t===void 0&&(t=new Int32Array(e),Lg[e]=t);for(let n=0;n!==e;++n)t[n]=i.allocateTextureUnit();return t}function _b(i,e){let t=this.cache;t[0]!==e&&(i.uniform1f(this.addr,e),t[0]=e)}function yb(i,e){let t=this.cache;if(e.x!==void 0)(t[0]!==e.x||t[1]!==e.y)&&(i.uniform2f(this.addr,e.x,e.y),t[0]=e.x,t[1]=e.y);else{if(Qt(t,e))return;i.uniform2fv(this.addr,e),en(t,e)}}function vb(i,e){let t=this.cache;if(e.x!==void 0)(t[0]!==e.x||t[1]!==e.y||t[2]!==e.z)&&(i.uniform3f(this.addr,e.x,e.y,e.z),t[0]=e.x,t[1]=e.y,t[2]=e.z);else if(e.r!==void 0)(t[0]!==e.r||t[1]!==e.g||t[2]!==e.b)&&(i.uniform3f(this.addr,e.r,e.g,e.b),t[0]=e.r,t[1]=e.g,t[2]=e.b);else{if(Qt(t,e))return;i.uniform3fv(this.addr,e),en(t,e)}}function Sb(i,e){let t=this.cache;if(e.x!==void 0)(t[0]!==e.x||t[1]!==e.y||t[2]!==e.z||t[3]!==e.w)&&(i.uniform4f(this.addr,e.x,e.y,e.z,e.w),t[0]=e.x,t[1]=e.y,t[2]=e.z,t[3]=e.w);else{if(Qt(t,e))return;i.uniform4fv(this.addr,e),en(t,e)}}function bb(i,e){let t=this.cache,n=e.elements;if(n===void 0){if(Qt(t,e))return;i.uniformMatrix2fv(this.addr,!1,e),en(t,e)}else{if(Qt(t,n))return;Ug.set(n),i.uniformMatrix2fv(this.addr,!1,Ug),en(t,n)}}function Mb(i,e){let t=this.cache,n=e.elements;if(n===void 0){if(Qt(t,e))return;i.uniformMatrix3fv(this.addr,!1,e),en(t,e)}else{if(Qt(t,n))return;Dg.set(n),i.uniformMatrix3fv(this.addr,!1,Dg),en(t,n)}}function Tb(i,e){let t=this.cache,n=e.elements;if(n===void 0){if(Qt(t,e))return;i.uniformMatrix4fv(this.addr,!1,e),en(t,e)}else{if(Qt(t,n))return;Ng.set(n),i.uniformMatrix4fv(this.addr,!1,Ng),en(t,n)}}function wb(i,e){let t=this.cache;t[0]!==e&&(i.uniform1i(this.addr,e),t[0]=e)}function Eb(i,e){let t=this.cache;if(e.x!==void 0)(t[0]!==e.x||t[1]!==e.y)&&(i.uniform2i(this.addr,e.x,e.y),t[0]=e.x,t[1]=e.y);else{if(Qt(t,e))return;i.uniform2iv(this.addr,e),en(t,e)}}function Ab(i,e){let t=this.cache;if(e.x!==void 0)(t[0]!==e.x||t[1]!==e.y||t[2]!==e.z)&&(i.uniform3i(this.addr,e.x,e.y,e.z),t[0]=e.x,t[1]=e.y,t[2]=e.z);else{if(Qt(t,e))return;i.uniform3iv(this.addr,e),en(t,e)}}function Rb(i,e){let t=this.cache;if(e.x!==void 0)(t[0]!==e.x||t[1]!==e.y||t[2]!==e.z||t[3]!==e.w)&&(i.uniform4i(this.addr,e.x,e.y,e.z,e.w),t[0]=e.x,t[1]=e.y,t[2]=e.z,t[3]=e.w);else{if(Qt(t,e))return;i.uniform4iv(this.addr,e),en(t,e)}}function Cb(i,e){let t=this.cache;t[0]!==e&&(i.uniform1ui(this.addr,e),t[0]=e)}function Pb(i,e){let t=this.cache;if(e.x!==void 0)(t[0]!==e.x||t[1]!==e.y)&&(i.uniform2ui(this.addr,e.x,e.y),t[0]=e.x,t[1]=e.y);else{if(Qt(t,e))return;i.uniform2uiv(this.addr,e),en(t,e)}}function Ib(i,e){let t=this.cache;if(e.x!==void 0)(t[0]!==e.x||t[1]!==e.y||t[2]!==e.z)&&(i.uniform3ui(this.addr,e.x,e.y,e.z),t[0]=e.x,t[1]=e.y,t[2]=e.z);else{if(Qt(t,e))return;i.uniform3uiv(this.addr,e),en(t,e)}}function Lb(i,e){let t=this.cache;if(e.x!==void 0)(t[0]!==e.x||t[1]!==e.y||t[2]!==e.z||t[3]!==e.w)&&(i.uniform4ui(this.addr,e.x,e.y,e.z,e.w),t[0]=e.x,t[1]=e.y,t[2]=e.z,t[3]=e.w);else{if(Qt(t,e))return;i.uniform4uiv(this.addr,e),en(t,e)}}function Nb(i,e,t){let n=this.cache,s=t.allocateTextureUnit();n[0]!==s&&(i.uniform1i(this.addr,s),n[0]=s);let r;this.type===i.SAMPLER_2D_SHADOW?($f.compareFunction=t.isReversedDepthBuffer()?pu:du,r=$f):r=Jg,t.setTexture2D(e||r,s)}function Db(i,e,t){let n=this.cache,s=t.allocateTextureUnit();n[0]!==s&&(i.uniform1i(this.addr,s),n[0]=s),t.setTexture3D(e||jg,s)}function Ub(i,e,t){let n=this.cache,s=t.allocateTextureUnit();n[0]!==s&&(i.uniform1i(this.addr,s),n[0]=s),t.setTextureCube(e||Qg,s)}function Fb(i,e,t){let n=this.cache,s=t.allocateTextureUnit();n[0]!==s&&(i.uniform1i(this.addr,s),n[0]=s),t.setTexture2DArray(e||$g,s)}function Ob(i){switch(i){case 5126:return _b;case 35664:return yb;case 35665:return vb;case 35666:return Sb;case 35674:return bb;case 35675:return Mb;case 35676:return Tb;case 5124:case 35670:return wb;case 35667:case 35671:return Eb;case 35668:case 35672:return Ab;case 35669:case 35673:return Rb;case 5125:return Cb;case 36294:return Pb;case 36295:return Ib;case 36296:return Lb;case 35678:case 36198:case 36298:case 36306:case 35682:return Nb;case 35679:case 36299:case 36307:return Db;case 35680:case 36300:case 36308:case 36293:return Ub;case 36289:case 36303:case 36311:case 36292:return Fb}}function Bb(i,e){i.uniform1fv(this.addr,e)}function zb(i,e){let t=ao(e,this.size,2);i.uniform2fv(this.addr,t)}function kb(i,e){let t=ao(e,this.size,3);i.uniform3fv(this.addr,t)}function Vb(i,e){let t=ao(e,this.size,4);i.uniform4fv(this.addr,t)}function Hb(i,e){let t=ao(e,this.size,4);i.uniformMatrix2fv(this.addr,!1,t)}function Gb(i,e){let t=ao(e,this.size,9);i.uniformMatrix3fv(this.addr,!1,t)}function Wb(i,e){let t=ao(e,this.size,16);i.uniformMatrix4fv(this.addr,!1,t)}function Xb(i,e){i.uniform1iv(this.addr,e)}function qb(i,e){i.uniform2iv(this.addr,e)}function Yb(i,e){i.uniform3iv(this.addr,e)}function Zb(i,e){i.uniform4iv(this.addr,e)}function Kb(i,e){i.uniform1uiv(this.addr,e)}function Jb(i,e){i.uniform2uiv(this.addr,e)}function $b(i,e){i.uniform3uiv(this.addr,e)}function jb(i,e){i.uniform4uiv(this.addr,e)}function Qb(i,e,t){let n=this.cache,s=e.length,r=bu(t,s);Qt(n,r)||(i.uniform1iv(this.addr,r),en(n,r));let o;this.type===i.SAMPLER_2D_SHADOW?o=$f:o=Jg;for(let a=0;a!==s;++a)t.setTexture2D(e[a]||o,r[a])}function eM(i,e,t){let n=this.cache,s=e.length,r=bu(t,s);Qt(n,r)||(i.uniform1iv(this.addr,r),en(n,r));for(let o=0;o!==s;++o)t.setTexture3D(e[o]||jg,r[o])}function tM(i,e,t){let n=this.cache,s=e.length,r=bu(t,s);Qt(n,r)||(i.uniform1iv(this.addr,r),en(n,r));for(let o=0;o!==s;++o)t.setTextureCube(e[o]||Qg,r[o])}function nM(i,e,t){let n=this.cache,s=e.length,r=bu(t,s);Qt(n,r)||(i.uniform1iv(this.addr,r),en(n,r));for(let o=0;o!==s;++o)t.setTexture2DArray(e[o]||$g,r[o])}function iM(i){switch(i){case 5126:return Bb;case 35664:return zb;case 35665:return kb;case 35666:return Vb;case 35674:return Hb;case 35675:return Gb;case 35676:return Wb;case 5124:case 35670:return Xb;case 35667:case 35671:return qb;case 35668:case 35672:return Yb;case 35669:case 35673:return Zb;case 5125:return Kb;case 36294:return Jb;case 36295:return $b;case 36296:return jb;case 35678:case 36198:case 36298:case 36306:case 35682:return Qb;case 35679:case 36299:case 36307:return eM;case 35680:case 36300:case 36308:case 36293:return tM;case 36289:case 36303:case 36311:case 36292:return nM}}var jf=class{constructor(e,t,n){this.id=e,this.addr=n,this.cache=[],this.type=t.type,this.setValue=Ob(t.type)}},Qf=class{constructor(e,t,n){this.id=e,this.addr=n,this.cache=[],this.type=t.type,this.size=t.size,this.setValue=iM(t.type)}},ed=class{constructor(e){this.id=e,this.seq=[],this.map={}}setValue(e,t,n){let s=this.seq;for(let r=0,o=s.length;r!==o;++r){let a=s[r];a.setValue(e,t[a.id],n)}}},Kf=/(\w+)(\])?(\[|\.)?/g;function Fg(i,e){i.seq.push(e),i.map[e.id]=e}function sM(i,e,t){let n=i.name,s=n.length;for(Kf.lastIndex=0;;){let r=Kf.exec(n),o=Kf.lastIndex,a=r[1],c=r[2]==="]",l=r[3];if(c&&(a=a|0),l===void 0||l==="["&&o+2===s){Fg(t,l===void 0?new jf(a,i,e):new Qf(a,i,e));break}else{let h=t.map[a];h===void 0&&(h=new ed(a),Fg(t,h)),t=h}}}var ro=class{constructor(e,t){this.seq=[],this.map={};let n=e.getProgramParameter(t,e.ACTIVE_UNIFORMS);for(let o=0;o<n;++o){let a=e.getActiveUniform(t,o),c=e.getUniformLocation(t,a.name);sM(a,c,this)}let s=[],r=[];for(let o of this.seq)o.type===e.SAMPLER_2D_SHADOW||o.type===e.SAMPLER_CUBE_SHADOW||o.type===e.SAMPLER_2D_ARRAY_SHADOW?s.push(o):r.push(o);s.length>0&&(this.seq=s.concat(r))}setValue(e,t,n,s){let r=this.map[t];r!==void 0&&r.setValue(e,n,s)}setOptional(e,t,n){let s=t[n];s!==void 0&&this.setValue(e,n,s)}static upload(e,t,n,s){for(let r=0,o=t.length;r!==o;++r){let a=t[r],c=n[a.id];c.needsUpdate!==!1&&a.setValue(e,c.value,s)}}static seqWithValue(e,t){let n=[];for(let s=0,r=e.length;s!==r;++s){let o=e[s];o.id in t&&n.push(o)}return n}};function Og(i,e,t){let n=i.createShader(e);return i.shaderSource(n,t),i.compileShader(n),n}var rM=37297,oM=0;function aM(i,e){let t=i.split(`
`),n=[],s=Math.max(e-6,0),r=Math.min(e+6,t.length);for(let o=s;o<r;o++){let a=o+1;n.push(`${a===e?">":" "} ${a}: ${t[o]}`)}return n.join(`
`)}var Bg=new Ye;function cM(i){tt._getMatrix(Bg,tt.workingColorSpace,i);let e=`mat3( ${Bg.elements.map(t=>t.toFixed(4))} )`;switch(tt.getTransfer(i)){case Yo:return[e,"LinearTransferOETF"];case yt:return[e,"sRGBTransferOETF"];default:return Fe("WebGLProgram: Unsupported color space: ",i),[e,"LinearTransferOETF"]}}function zg(i,e,t){let n=i.getShaderParameter(e,i.COMPILE_STATUS),r=(i.getShaderInfoLog(e)||"").trim();if(n&&r==="")return"";let o=/ERROR: 0:(\d+)/.exec(r);if(o){let a=parseInt(o[1]);return t.toUpperCase()+`

`+r+`

`+aM(i.getShaderSource(e),a)}else return r}function lM(i,e){let t=cM(e);return[`vec4 ${i}( vec4 value ) {`,`	return ${t[1]}( vec4( value.rgb * ${t[0]}, value.a ) );`,"}"].join(`
`)}var uM={[_f]:"Linear",[yf]:"Reinhard",[vf]:"Cineon",[Pa]:"ACESFilmic",[bf]:"AgX",[Mf]:"Neutral",[Sf]:"Custom"};function hM(i,e){let t=uM[e];return t===void 0?(Fe("WebGLProgram: Unsupported toneMapping:",e),"vec3 "+i+"( vec3 color ) { return LinearToneMapping( color ); }"):"vec3 "+i+"( vec3 color ) { return "+t+"ToneMapping( color ); }"}var xu=new I;function fM(){tt.getLuminanceCoefficients(xu);let i=xu.x.toFixed(4),e=xu.y.toFixed(4),t=xu.z.toFixed(4);return["float luminance( const in vec3 rgb ) {",`	const vec3 weights = vec3( ${i}, ${e}, ${t} );`,"	return dot( weights, rgb );","}"].join(`
`)}function dM(i){return[i.extensionClipCullDistance?"#extension GL_ANGLE_clip_cull_distance : require":"",i.extensionMultiDraw?"#extension GL_ANGLE_multi_draw : require":""].filter(Va).join(`
`)}function pM(i){let e=[];for(let t in i){let n=i[t];n!==!1&&e.push("#define "+t+" "+n)}return e.join(`
`)}function mM(i,e){let t={},n=i.getProgramParameter(e,i.ACTIVE_ATTRIBUTES);for(let s=0;s<n;s++){let r=i.getActiveAttrib(e,s),o=r.name,a=1;r.type===i.FLOAT_MAT2&&(a=2),r.type===i.FLOAT_MAT3&&(a=3),r.type===i.FLOAT_MAT4&&(a=4),t[o]={type:r.type,location:i.getAttribLocation(e,o),locationSize:a}}return t}function Va(i){return i!==""}function kg(i,e){let t=e.numSpotLightShadows+e.numSpotLightMaps-e.numSpotLightShadowsWithMaps;return i.replace(/NUM_SUN_LIGHTS/g,e.numSunLights).replace(/NUM_DIR_LIGHTS/g,e.numDirLights).replace(/NUM_SPOT_LIGHTS/g,e.numSpotLights).replace(/NUM_SPOT_LIGHT_MAPS/g,e.numSpotLightMaps).replace(/NUM_SPOT_LIGHT_COORDS/g,t).replace(/NUM_RECT_AREA_LIGHTS/g,e.numRectAreaLights).replace(/NUM_POINT_LIGHTS/g,e.numPointLights).replace(/NUM_HEMI_LIGHTS/g,e.numHemiLights).replace(/NUM_SUN_LIGHT_SHADOWS/g,e.numSunLightShadows).replace(/NUM_DIR_LIGHT_SHADOWS/g,e.numDirLightShadows).replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g,e.numSpotLightShadowsWithMaps).replace(/NUM_SPOT_LIGHT_SHADOWS/g,e.numSpotLightShadows).replace(/NUM_POINT_LIGHT_SHADOWS/g,e.numPointLightShadows)}function Vg(i,e){return i.replace(/NUM_CLIPPING_PLANES/g,e.numClippingPlanes).replace(/UNION_CLIPPING_PLANES/g,e.numClippingPlanes-e.numClipIntersection)}var gM=/^[ \t]*#include +<([\w\d./]+)>/gm;function td(i){return i.replace(gM,_M)}var xM=new Map;function _M(i,e){let t=Qe[e];if(t===void 0){let n=xM.get(e);if(n!==void 0)t=Qe[n],Fe('WebGLRenderer: Shader chunk "%s" has been deprecated. Use "%s" instead.',e,n);else throw new Error("THREE.WebGLProgram: Can not resolve #include <"+e+">")}return td(t)}var yM=/#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end/g;function Hg(i){return i.replace(yM,vM)}function vM(i,e,t,n){let s="";for(let r=parseInt(e);r<parseInt(t);r++)s+=n.replace(/\[\s*i\s*\]/g,"[ "+r+" ]").replace(/UNROLLED_LOOP_INDEX/g,r);return s}function Gg(i){let e=`precision ${i.precision} float;
	precision ${i.precision} int;
	precision ${i.precision} sampler2D;
	precision ${i.precision} samplerCube;
	precision ${i.precision} sampler3D;
	precision ${i.precision} sampler2DArray;
	precision ${i.precision} sampler2DShadow;
	precision ${i.precision} samplerCubeShadow;
	precision ${i.precision} sampler2DArrayShadow;
	precision ${i.precision} isampler2D;
	precision ${i.precision} isampler3D;
	precision ${i.precision} isamplerCube;
	precision ${i.precision} isampler2DArray;
	precision ${i.precision} usampler2D;
	precision ${i.precision} usampler3D;
	precision ${i.precision} usamplerCube;
	precision ${i.precision} usampler2DArray;
	`;return i.precision==="highp"?e+=`
#define HIGH_PRECISION`:i.precision==="mediump"?e+=`
#define MEDIUM_PRECISION`:i.precision==="lowp"&&(e+=`
#define LOW_PRECISION`),e}var SM={[Ca]:"SHADOWMAP_TYPE_PCF",[$r]:"SHADOWMAP_TYPE_VSM"};function bM(i){return SM[i.shadowMapType]||"SHADOWMAP_TYPE_BASIC"}var MM={[xs]:"ENVMAP_TYPE_CUBE",[Ys]:"ENVMAP_TYPE_CUBE",[Ia]:"ENVMAP_TYPE_CUBE_UV"};function TM(i){return i.envMap===!1?"ENVMAP_TYPE_CUBE":MM[i.envMapMode]||"ENVMAP_TYPE_CUBE"}var wM={[Ys]:"ENVMAP_MODE_REFRACTION"};function EM(i){return i.envMap===!1?"ENVMAP_MODE_REFLECTION":wM[i.envMapMode]||"ENVMAP_MODE_REFLECTION"}var AM={[xf]:"ENVMAP_BLENDING_MULTIPLY",[ng]:"ENVMAP_BLENDING_MIX",[ig]:"ENVMAP_BLENDING_ADD"};function RM(i){return i.envMap===!1?"ENVMAP_BLENDING_NONE":AM[i.combine]||"ENVMAP_BLENDING_NONE"}function CM(i){let e=i.envMapCubeUVHeight;if(e===null)return null;let t=Math.log2(e)-2,n=1/e;return{texelWidth:1/(3*Math.max(Math.pow(2,t),112)),texelHeight:n,maxMip:t}}function PM(i,e,t,n){let s=i.getContext(),r=t.defines,o=t.vertexShader,a=t.fragmentShader,c=bM(t),l=TM(t),u=EM(t),h=RM(t),f=CM(t),d=dM(t),m=pM(r),x=s.createProgram(),g,p,v=t.glslVersion?"#version "+t.glslVersion+`
`:"";t.isRawShaderMaterial?(g=["#define SHADER_TYPE "+t.shaderType,"#define SHADER_NAME "+t.shaderName,m].filter(Va).join(`
`),g.length>0&&(g+=`
`),p=["#define SHADER_TYPE "+t.shaderType,"#define SHADER_NAME "+t.shaderName,m].filter(Va).join(`
`),p.length>0&&(p+=`
`)):(g=[Gg(t),"#define SHADER_TYPE "+t.shaderType,"#define SHADER_NAME "+t.shaderName,m,t.extensionClipCullDistance?"#define USE_CLIP_DISTANCE":"",t.batching?"#define USE_BATCHING":"",t.batchingColor?"#define USE_BATCHING_COLOR":"",t.instancing?"#define USE_INSTANCING":"",t.instancingColor?"#define USE_INSTANCING_COLOR":"",t.instancingMorph?"#define USE_INSTANCING_MORPH":"",t.useFog&&t.fog?"#define USE_FOG":"",t.useFog&&t.fogExp2?"#define FOG_EXP2":"",t.map?"#define USE_MAP":"",t.envMap?"#define USE_ENVMAP":"",t.envMap?"#define "+u:"",t.lightMap?"#define USE_LIGHTMAP":"",t.aoMap?"#define USE_AOMAP":"",t.bumpMap?"#define USE_BUMPMAP":"",t.normalMap?"#define USE_NORMALMAP":"",t.normalMapObjectSpace?"#define USE_NORMALMAP_OBJECTSPACE":"",t.normalMapTangentSpace?"#define USE_NORMALMAP_TANGENTSPACE":"",t.displacementMap?"#define USE_DISPLACEMENTMAP":"",t.emissiveMap?"#define USE_EMISSIVEMAP":"",t.anisotropy?"#define USE_ANISOTROPY":"",t.anisotropyMap?"#define USE_ANISOTROPYMAP":"",t.clearcoatMap?"#define USE_CLEARCOATMAP":"",t.clearcoatRoughnessMap?"#define USE_CLEARCOAT_ROUGHNESSMAP":"",t.clearcoatNormalMap?"#define USE_CLEARCOAT_NORMALMAP":"",t.iridescenceMap?"#define USE_IRIDESCENCEMAP":"",t.iridescenceThicknessMap?"#define USE_IRIDESCENCE_THICKNESSMAP":"",t.specularMap?"#define USE_SPECULARMAP":"",t.specularColorMap?"#define USE_SPECULAR_COLORMAP":"",t.specularIntensityMap?"#define USE_SPECULAR_INTENSITYMAP":"",t.roughnessMap?"#define USE_ROUGHNESSMAP":"",t.metalnessMap?"#define USE_METALNESSMAP":"",t.alphaMap?"#define USE_ALPHAMAP":"",t.alphaHash?"#define USE_ALPHAHASH":"",t.transmission?"#define USE_TRANSMISSION":"",t.transmissionMap?"#define USE_TRANSMISSIONMAP":"",t.thicknessMap?"#define USE_THICKNESSMAP":"",t.sheenColorMap?"#define USE_SHEEN_COLORMAP":"",t.sheenRoughnessMap?"#define USE_SHEEN_ROUGHNESSMAP":"",t.mapUv?"#define MAP_UV "+t.mapUv:"",t.alphaMapUv?"#define ALPHAMAP_UV "+t.alphaMapUv:"",t.lightMapUv?"#define LIGHTMAP_UV "+t.lightMapUv:"",t.aoMapUv?"#define AOMAP_UV "+t.aoMapUv:"",t.emissiveMapUv?"#define EMISSIVEMAP_UV "+t.emissiveMapUv:"",t.bumpMapUv?"#define BUMPMAP_UV "+t.bumpMapUv:"",t.normalMapUv?"#define NORMALMAP_UV "+t.normalMapUv:"",t.displacementMapUv?"#define DISPLACEMENTMAP_UV "+t.displacementMapUv:"",t.metalnessMapUv?"#define METALNESSMAP_UV "+t.metalnessMapUv:"",t.roughnessMapUv?"#define ROUGHNESSMAP_UV "+t.roughnessMapUv:"",t.anisotropyMapUv?"#define ANISOTROPYMAP_UV "+t.anisotropyMapUv:"",t.clearcoatMapUv?"#define CLEARCOATMAP_UV "+t.clearcoatMapUv:"",t.clearcoatNormalMapUv?"#define CLEARCOAT_NORMALMAP_UV "+t.clearcoatNormalMapUv:"",t.clearcoatRoughnessMapUv?"#define CLEARCOAT_ROUGHNESSMAP_UV "+t.clearcoatRoughnessMapUv:"",t.iridescenceMapUv?"#define IRIDESCENCEMAP_UV "+t.iridescenceMapUv:"",t.iridescenceThicknessMapUv?"#define IRIDESCENCE_THICKNESSMAP_UV "+t.iridescenceThicknessMapUv:"",t.sheenColorMapUv?"#define SHEEN_COLORMAP_UV "+t.sheenColorMapUv:"",t.sheenRoughnessMapUv?"#define SHEEN_ROUGHNESSMAP_UV "+t.sheenRoughnessMapUv:"",t.specularMapUv?"#define SPECULARMAP_UV "+t.specularMapUv:"",t.specularColorMapUv?"#define SPECULAR_COLORMAP_UV "+t.specularColorMapUv:"",t.specularIntensityMapUv?"#define SPECULAR_INTENSITYMAP_UV "+t.specularIntensityMapUv:"",t.transmissionMapUv?"#define TRANSMISSIONMAP_UV "+t.transmissionMapUv:"",t.thicknessMapUv?"#define THICKNESSMAP_UV "+t.thicknessMapUv:"",t.vertexTangents&&t.flatShading===!1?"#define USE_TANGENT":"",t.vertexNormals?"#define HAS_NORMAL":"",t.vertexColors?"#define USE_COLOR":"",t.vertexAlphas?"#define USE_COLOR_ALPHA":"",t.vertexUv1s?"#define USE_UV1":"",t.vertexUv2s?"#define USE_UV2":"",t.vertexUv3s?"#define USE_UV3":"",t.pointsUvs?"#define USE_POINTS_UV":"",t.flatShading?"#define FLAT_SHADED":"",t.skinning?"#define USE_SKINNING":"",t.morphTargets?"#define USE_MORPHTARGETS":"",t.morphNormals&&t.flatShading===!1?"#define USE_MORPHNORMALS":"",t.morphColors?"#define USE_MORPHCOLORS":"",t.morphTargetsCount>0?"#define MORPHTARGETS_TEXTURE_STRIDE "+t.morphTextureStride:"",t.morphTargetsCount>0?"#define MORPHTARGETS_COUNT "+t.morphTargetsCount:"",t.doubleSided?"#define DOUBLE_SIDED":"",t.flipSided?"#define FLIP_SIDED":"",t.shadowMapEnabled?"#define USE_SHADOWMAP":"",t.shadowMapEnabled?"#define "+c:"",t.sizeAttenuation?"#define USE_SIZEATTENUATION":"",t.numLightProbes>0?"#define USE_LIGHT_PROBES":"",t.logarithmicDepthBuffer?"#define USE_LOGARITHMIC_DEPTH_BUFFER":"",t.reversedDepthBuffer?"#define USE_REVERSED_DEPTH_BUFFER":"","uniform mat4 modelMatrix;","uniform mat4 modelViewMatrix;","uniform mat4 projectionMatrix;","uniform mat4 viewMatrix;","uniform mat3 normalMatrix;","uniform vec3 cameraPosition;","uniform bool isOrthographic;","#ifdef USE_INSTANCING","	attribute mat4 instanceMatrix;","#endif","#ifdef USE_INSTANCING_COLOR","	attribute vec3 instanceColor;","#endif","#ifdef USE_INSTANCING_MORPH","	uniform sampler2D morphTexture;","#endif","attribute vec3 position;","attribute vec3 normal;","attribute vec2 uv;","#ifdef USE_UV1","	attribute vec2 uv1;","#endif","#ifdef USE_UV2","	attribute vec2 uv2;","#endif","#ifdef USE_UV3","	attribute vec2 uv3;","#endif","#ifdef USE_TANGENT","	attribute vec4 tangent;","#endif","#if defined( USE_COLOR_ALPHA )","	attribute vec4 color;","#elif defined( USE_COLOR )","	attribute vec3 color;","#endif","#ifdef USE_SKINNING","	attribute vec4 skinIndex;","	attribute vec4 skinWeight;","#endif",`
`].filter(Va).join(`
`),p=[Gg(t),"#define SHADER_TYPE "+t.shaderType,"#define SHADER_NAME "+t.shaderName,m,t.useFog&&t.fog?"#define USE_FOG":"",t.useFog&&t.fogExp2?"#define FOG_EXP2":"",t.alphaToCoverage?"#define ALPHA_TO_COVERAGE":"",t.map?"#define USE_MAP":"",t.matcap?"#define USE_MATCAP":"",t.envMap?"#define USE_ENVMAP":"",t.envMap?"#define "+l:"",t.envMap?"#define "+u:"",t.envMap?"#define "+h:"",f?"#define CUBEUV_TEXEL_WIDTH "+f.texelWidth:"",f?"#define CUBEUV_TEXEL_HEIGHT "+f.texelHeight:"",f?"#define CUBEUV_MAX_MIP "+f.maxMip+".0":"",t.lightMap?"#define USE_LIGHTMAP":"",t.aoMap?"#define USE_AOMAP":"",t.bumpMap?"#define USE_BUMPMAP":"",t.normalMap?"#define USE_NORMALMAP":"",t.normalMapObjectSpace?"#define USE_NORMALMAP_OBJECTSPACE":"",t.normalMapTangentSpace?"#define USE_NORMALMAP_TANGENTSPACE":"",t.packedNormalMap?"#define USE_PACKED_NORMALMAP":"",t.emissiveMap?"#define USE_EMISSIVEMAP":"",t.anisotropy?"#define USE_ANISOTROPY":"",t.anisotropyMap?"#define USE_ANISOTROPYMAP":"",t.clearcoat?"#define USE_CLEARCOAT":"",t.clearcoatMap?"#define USE_CLEARCOATMAP":"",t.clearcoatRoughnessMap?"#define USE_CLEARCOAT_ROUGHNESSMAP":"",t.clearcoatNormalMap?"#define USE_CLEARCOAT_NORMALMAP":"",t.dispersion?"#define USE_DISPERSION":"",t.retroreflection?"#define USE_RETROREFLECTION":"",t.iridescence?"#define USE_IRIDESCENCE":"",t.iridescenceMap?"#define USE_IRIDESCENCEMAP":"",t.iridescenceThicknessMap?"#define USE_IRIDESCENCE_THICKNESSMAP":"",t.specularMap?"#define USE_SPECULARMAP":"",t.specularColorMap?"#define USE_SPECULAR_COLORMAP":"",t.specularIntensityMap?"#define USE_SPECULAR_INTENSITYMAP":"",t.roughnessMap?"#define USE_ROUGHNESSMAP":"",t.metalnessMap?"#define USE_METALNESSMAP":"",t.alphaMap?"#define USE_ALPHAMAP":"",t.alphaTest?"#define USE_ALPHATEST":"",t.alphaHash?"#define USE_ALPHAHASH":"",t.sheen?"#define USE_SHEEN":"",t.sheenColorMap?"#define USE_SHEEN_COLORMAP":"",t.sheenRoughnessMap?"#define USE_SHEEN_ROUGHNESSMAP":"",t.transmission?"#define USE_TRANSMISSION":"",t.transmissionMap?"#define USE_TRANSMISSIONMAP":"",t.thicknessMap?"#define USE_THICKNESSMAP":"",t.vertexTangents&&t.flatShading===!1?"#define USE_TANGENT":"",t.vertexColors||t.instancingColor?"#define USE_COLOR":"",t.vertexAlphas||t.batchingColor?"#define USE_COLOR_ALPHA":"",t.vertexUv1s?"#define USE_UV1":"",t.vertexUv2s?"#define USE_UV2":"",t.vertexUv3s?"#define USE_UV3":"",t.pointsUvs?"#define USE_POINTS_UV":"",t.gradientMap?"#define USE_GRADIENTMAP":"",t.flatShading?"#define FLAT_SHADED":"",t.doubleSided?"#define DOUBLE_SIDED":"",t.flipSided?"#define FLIP_SIDED":"",t.shadowMapEnabled?"#define USE_SHADOWMAP":"",t.shadowMapEnabled?"#define "+c:"",t.premultipliedAlpha?"#define PREMULTIPLIED_ALPHA":"",t.numLightProbes>0?"#define USE_LIGHT_PROBES":"",t.numLightProbeGrids>0?"#define USE_LIGHT_PROBES_GRID":"",t.decodeVideoTexture?"#define DECODE_VIDEO_TEXTURE":"",t.decodeVideoTextureEmissive?"#define DECODE_VIDEO_TEXTURE_EMISSIVE":"",t.logarithmicDepthBuffer?"#define USE_LOGARITHMIC_DEPTH_BUFFER":"",t.reversedDepthBuffer?"#define USE_REVERSED_DEPTH_BUFFER":"","uniform mat4 viewMatrix;","uniform vec3 cameraPosition;","uniform bool isOrthographic;",t.toneMapping!==oi?"#define TONE_MAPPING":"",t.toneMapping!==oi?Qe.tonemapping_pars_fragment:"",t.toneMapping!==oi?hM("toneMapping",t.toneMapping):"",t.dithering?"#define DITHERING":"",t.opaque?"#define OPAQUE":"",Qe.colorspace_pars_fragment,lM("linearToOutputTexel",t.outputColorSpace),fM(),t.useDepthPacking?"#define DEPTH_PACKING "+t.depthPacking:"",`
`].filter(Va).join(`
`)),o=td(o),o=kg(o,t),o=Vg(o,t),a=td(a),a=kg(a,t),a=Vg(a,t),o=Hg(o),a=Hg(a),t.isRawShaderMaterial!==!0&&(v=`#version 300 es
`,g=[d,"#define attribute in","#define varying out","#define texture2D texture"].join(`
`)+`
`+g,p=["#define varying in",t.glslVersion===Nf?"":"layout(location = 0) out highp vec4 pc_fragColor;",t.glslVersion===Nf?"":"#define gl_FragColor pc_fragColor","#define gl_FragDepthEXT gl_FragDepth","#define texture2D texture","#define textureCube texture","#define texture2DProj textureProj","#define texture2DLodEXT textureLod","#define texture2DProjLodEXT textureProjLod","#define textureCubeLodEXT textureLod","#define texture2DGradEXT textureGrad","#define texture2DProjGradEXT textureProjGrad","#define textureCubeGradEXT textureGrad"].join(`
`)+`
`+p);let b=v+g+o,_=v+p+a,S=Og(s,s.VERTEX_SHADER,b),M=Og(s,s.FRAGMENT_SHADER,_);s.attachShader(x,S),s.attachShader(x,M),t.index0AttributeName!==void 0?s.bindAttribLocation(x,0,t.index0AttributeName):t.hasPositionAttribute===!0&&s.bindAttribLocation(x,0,"position"),s.linkProgram(x);function E(P){if(i.debug.checkShaderErrors){let C=s.getProgramInfoLog(x)||"",D=s.getShaderInfoLog(S)||"",L=s.getShaderInfoLog(M)||"",U=C.trim(),G=D.trim(),Z=L.trim(),oe=!0,K=!0;if(s.getProgramParameter(x,s.LINK_STATUS)===!1)if(oe=!1,typeof i.debug.onShaderError=="function")i.debug.onShaderError(s,x,S,M);else{let te=zg(s,S,"vertex"),se=zg(s,M,"fragment");We("WebGLProgram: Shader Error "+s.getError()+" - VALIDATE_STATUS "+s.getProgramParameter(x,s.VALIDATE_STATUS)+`

Material Name: `+P.name+`
Material Type: `+P.type+`

Program Info Log: `+U+`
`+te+`
`+se)}else U!==""?Fe("WebGLProgram: Program Info Log:",U):(G===""||Z==="")&&(K=!1);K&&(P.diagnostics={runnable:oe,programLog:U,vertexShader:{log:G,prefix:g},fragmentShader:{log:Z,prefix:p}})}s.deleteShader(S),s.deleteShader(M),y=new ro(s,x),w=mM(s,x)}let y;this.getUniforms=function(){return y===void 0&&E(this),y};let w;this.getAttributes=function(){return w===void 0&&E(this),w};let A=t.rendererExtensionParallelShaderCompile===!1;return this.isReady=function(){return A===!1&&(A=s.getProgramParameter(x,rM)),A},this.destroy=function(){n.releaseStatesOfProgram(this),s.deleteProgram(x),this.program=void 0},this.type=t.shaderType,this.name=t.shaderName,this.id=oM++,this.cacheKey=e,this.usedTimes=1,this.program=x,this.vertexShader=S,this.fragmentShader=M,this}var IM=0,nd=class{constructor(){this.shaderCache=new Map,this.materialCache=new Map}update(e,t,n){let s=this._getShaderCacheForMaterial(e);return s.has(t)===!1&&(s.add(t),t.usedTimes++),s.has(n)===!1&&(s.add(n),n.usedTimes++),this}remove(e){let t=this.materialCache.get(e);for(let n of t)n.usedTimes--,n.usedTimes===0&&this.shaderCache.delete(n.code);return this.materialCache.delete(e),this}getVertexShaderStage(e){return this._getShaderStage(e.vertexShader)}getFragmentShaderStage(e){return this._getShaderStage(e.fragmentShader)}dispose(){this.shaderCache.clear(),this.materialCache.clear()}_getShaderCacheForMaterial(e){let t=this.materialCache,n=t.get(e);return n===void 0&&(n=new Set,t.set(e,n)),n}_getShaderStage(e){let t=this.shaderCache,n=t.get(e);return n===void 0&&(n=new id(e),t.set(e,n)),n}},id=class{constructor(e){this.id=IM++,this.code=e,this.usedTimes=0}};function LM(i){return i===ys||i===Fa||i===Oa}function NM(i,e,t,n,s,r){let o=new Br,a=new nd,c=new Set,l=[],u=new Map,h=n.logarithmicDepthBuffer,f=n.precision,d={MeshDepthMaterial:"depth",MeshDistanceMaterial:"distance",MeshNormalMaterial:"normal",MeshBasicMaterial:"basic",MeshLambertMaterial:"lambert",MeshPhongMaterial:"phong",MeshToonMaterial:"toon",MeshStandardMaterial:"physical",MeshPhysicalMaterial:"physical",MeshMatcapMaterial:"matcap",LineBasicMaterial:"basic",LineDashedMaterial:"dashed",PointsMaterial:"points",ShadowMaterial:"shadow",SpriteMaterial:"sprite"};function m(y){return c.add(y),y===0?"uv":`uv${y}`}function x(y,w,A,P,C,D){let L=P.fog,U=C.geometry,G=y.isMeshStandardMaterial||y.isMeshLambertMaterial||y.isMeshPhongMaterial?P.environment:null,Z=y.isMeshStandardMaterial||y.isMeshLambertMaterial&&!y.envMap||y.isMeshPhongMaterial&&!y.envMap,oe=e.get(y.envMap||G,Z),K=oe&&oe.mapping===Ia?oe.image.height:null,te=d[y.type];y.precision!==null&&(f=n.getMaxPrecision(y.precision),f!==y.precision&&Fe("WebGLProgram.getParameters:",y.precision,"not supported, using",f,"instead."));let se=U.morphAttributes.position||U.morphAttributes.normal||U.morphAttributes.color,Re=se!==void 0?se.length:0,Te=0;U.morphAttributes.position!==void 0&&(Te=1),U.morphAttributes.normal!==void 0&&(Te=2),U.morphAttributes.color!==void 0&&(Te=3);let nt,He,$e,$;if(te){let Pt=Mi[te];nt=Pt.vertexShader,He=Pt.fragmentShader}else{nt=y.vertexShader,He=y.fragmentShader;let Pt=a.getVertexShaderStage(y),xt=a.getFragmentShaderStage(y);a.update(y,Pt,xt),$e=Pt.id,$=xt.id}let z=i.getRenderTarget(),j=i.state.buffers.depth.getReversed(),me=C.isInstancedMesh===!0,fe=C.isBatchedMesh===!0,de=!!y.map,et=!!y.matcap,ne=!!oe,F=!!y.aoMap,V=!!y.lightMap,q=!!y.bumpMap&&y.wireframe===!1,ie=!!y.normalMap,le=!!y.displacementMap,ge=!!y.emissiveMap,he=!!y.metalnessMap,ze=!!y.roughnessMap,O=y.anisotropy>0,gt=y.clearcoat>0,rt=y.dispersion>0,N=y.retroreflectivity>0,T=y.iridescence>0,H=y.sheen>0,Y=y.transmission>0,Q=O&&!!y.anisotropyMap,pe=gt&&!!y.clearcoatMap,xe=gt&&!!y.clearcoatNormalMap,ee=gt&&!!y.clearcoatRoughnessMap,ae=T&&!!y.iridescenceMap,_e=T&&!!y.iridescenceThicknessMap,Oe=H&&!!y.sheenColorMap,be=H&&!!y.sheenRoughnessMap,ye=!!y.specularMap,Be=!!y.specularColorMap,Ge=!!y.specularIntensityMap,Je=Y&&!!y.transmissionMap,k=Y&&!!y.thicknessMap,ve=!!y.gradientMap,re=!!y.alphaMap,Se=y.alphaTest>0,Ae=!!y.alphaHash,ue=!!y.extensions,ke=oi;y.toneMapped&&(z===null||z.isXRRenderTarget===!0)&&(ke=i.toneMapping);let De={shaderID:te,shaderType:y.type,shaderName:y.name,vertexShader:nt,fragmentShader:He,defines:y.defines,customVertexShaderID:$e,customFragmentShaderID:$,isRawShaderMaterial:y.isRawShaderMaterial===!0,glslVersion:y.glslVersion,precision:f,batching:fe,batchingColor:fe&&C._colorsTexture!==null,instancing:me,instancingColor:me&&C.instanceColor!==null,instancingMorph:me&&C.morphTexture!==null,outputColorSpace:z===null?i.outputColorSpace:z.isXRRenderTarget===!0?z.texture.colorSpace:tt.workingColorSpace,alphaToCoverage:!!y.alphaToCoverage,map:de,matcap:et,envMap:ne,envMapMode:ne&&oe.mapping,envMapCubeUVHeight:K,aoMap:F,lightMap:V,bumpMap:q,normalMap:ie,displacementMap:le,emissiveMap:ge,normalMapObjectSpace:ie&&y.normalMapType===ag,normalMapTangentSpace:ie&&y.normalMapType===fu,packedNormalMap:ie&&y.normalMapType===fu&&LM(y.normalMap.format),metalnessMap:he,roughnessMap:ze,anisotropy:O,anisotropyMap:Q,clearcoat:gt,clearcoatMap:pe,clearcoatNormalMap:xe,clearcoatRoughnessMap:ee,dispersion:rt,retroreflection:N,iridescence:T,iridescenceMap:ae,iridescenceThicknessMap:_e,sheen:H,sheenColorMap:Oe,sheenRoughnessMap:be,specularMap:ye,specularColorMap:Be,specularIntensityMap:Ge,transmission:Y,transmissionMap:Je,thicknessMap:k,gradientMap:ve,opaque:y.transparent===!1&&y.blending===jr&&y.alphaToCoverage===!1,alphaMap:re,alphaTest:Se,alphaHash:Ae,combine:y.combine,mapUv:de&&m(y.map.channel),aoMapUv:F&&m(y.aoMap.channel),lightMapUv:V&&m(y.lightMap.channel),bumpMapUv:q&&m(y.bumpMap.channel),normalMapUv:ie&&m(y.normalMap.channel),displacementMapUv:le&&m(y.displacementMap.channel),emissiveMapUv:ge&&m(y.emissiveMap.channel),metalnessMapUv:he&&m(y.metalnessMap.channel),roughnessMapUv:ze&&m(y.roughnessMap.channel),anisotropyMapUv:Q&&m(y.anisotropyMap.channel),clearcoatMapUv:pe&&m(y.clearcoatMap.channel),clearcoatNormalMapUv:xe&&m(y.clearcoatNormalMap.channel),clearcoatRoughnessMapUv:ee&&m(y.clearcoatRoughnessMap.channel),iridescenceMapUv:ae&&m(y.iridescenceMap.channel),iridescenceThicknessMapUv:_e&&m(y.iridescenceThicknessMap.channel),sheenColorMapUv:Oe&&m(y.sheenColorMap.channel),sheenRoughnessMapUv:be&&m(y.sheenRoughnessMap.channel),specularMapUv:ye&&m(y.specularMap.channel),specularColorMapUv:Be&&m(y.specularColorMap.channel),specularIntensityMapUv:Ge&&m(y.specularIntensityMap.channel),transmissionMapUv:Je&&m(y.transmissionMap.channel),thicknessMapUv:k&&m(y.thicknessMap.channel),alphaMapUv:re&&m(y.alphaMap.channel),vertexTangents:!!U.attributes.tangent&&(ie||O),vertexNormals:!!U.attributes.normal,vertexColors:y.vertexColors,vertexAlphas:y.vertexColors===!0&&!!U.attributes.color&&U.attributes.color.itemSize===4,pointsUvs:C.isPoints===!0&&!!U.attributes.uv&&(de||re),fog:!!L,useFog:y.fog===!0,fogExp2:!!L&&L.isFogExp2,flatShading:y.wireframe===!1&&(y.flatShading===!0||U.attributes.normal===void 0&&ie===!1&&(y.isMeshLambertMaterial||y.isMeshPhongMaterial||y.isMeshStandardMaterial||y.isMeshPhysicalMaterial)),sizeAttenuation:y.sizeAttenuation===!0,logarithmicDepthBuffer:h,reversedDepthBuffer:j,skinning:C.isSkinnedMesh===!0,hasPositionAttribute:U.attributes.position!==void 0,morphTargets:U.morphAttributes.position!==void 0,morphNormals:U.morphAttributes.normal!==void 0,morphColors:U.morphAttributes.color!==void 0,morphTargetsCount:Re,morphTextureStride:Te,numSunLights:w.sun.length,numDirLights:w.directional.length,numPointLights:w.point.length,numSpotLights:w.spot.length,numSpotLightMaps:w.spotLightMap.length,numRectAreaLights:w.rectArea.length,numHemiLights:w.hemi.length,numSunLightShadows:w.sunShadowMap.length,numDirLightShadows:w.directionalShadowMap.length,numPointLightShadows:w.pointShadowMap.length,numSpotLightShadows:w.spotShadowMap.length,numSpotLightShadowsWithMaps:w.numSpotLightShadowsWithMaps,numLightProbes:w.numLightProbes,numLightProbeGrids:D.length,numClippingPlanes:r.numPlanes,numClipIntersection:r.numIntersection,dithering:y.dithering,shadowMapEnabled:i.shadowMap.enabled&&A.length>0,shadowMapType:i.shadowMap.type,toneMapping:ke,decodeVideoTexture:de&&y.map.isVideoTexture===!0&&tt.getTransfer(y.map.colorSpace)===yt,decodeVideoTextureEmissive:ge&&y.emissiveMap.isVideoTexture===!0&&tt.getTransfer(y.emissiveMap.colorSpace)===yt,premultipliedAlpha:y.premultipliedAlpha,doubleSided:y.side===Dt,flipSided:y.side===jt,useDepthPacking:y.depthPacking>=0,depthPacking:y.depthPacking||0,index0AttributeName:y.index0AttributeName,extensionClipCullDistance:ue&&y.extensions.clipCullDistance===!0&&t.has("WEBGL_clip_cull_distance"),extensionMultiDraw:(ue&&y.extensions.multiDraw===!0||fe)&&t.has("WEBGL_multi_draw"),rendererExtensionParallelShaderCompile:t.has("KHR_parallel_shader_compile"),customProgramCacheKey:y.customProgramCacheKey()};return De.vertexUv1s=c.has(1),De.vertexUv2s=c.has(2),De.vertexUv3s=c.has(3),c.clear(),De}function g(y){let w=[];if(y.shaderID?w.push(y.shaderID):(w.push(y.customVertexShaderID),w.push(y.customFragmentShaderID)),y.defines!==void 0)for(let A in y.defines)w.push(A),w.push(y.defines[A]);return y.isRawShaderMaterial===!1&&(p(w,y),v(w,y),w.push(i.outputColorSpace)),w.push(y.customProgramCacheKey),w.join()}function p(y,w){y.push(w.precision),y.push(w.outputColorSpace),y.push(w.envMapMode),y.push(w.envMapCubeUVHeight),y.push(w.mapUv),y.push(w.alphaMapUv),y.push(w.lightMapUv),y.push(w.aoMapUv),y.push(w.bumpMapUv),y.push(w.normalMapUv),y.push(w.displacementMapUv),y.push(w.emissiveMapUv),y.push(w.metalnessMapUv),y.push(w.roughnessMapUv),y.push(w.anisotropyMapUv),y.push(w.clearcoatMapUv),y.push(w.clearcoatNormalMapUv),y.push(w.clearcoatRoughnessMapUv),y.push(w.iridescenceMapUv),y.push(w.iridescenceThicknessMapUv),y.push(w.sheenColorMapUv),y.push(w.sheenRoughnessMapUv),y.push(w.specularMapUv),y.push(w.specularColorMapUv),y.push(w.specularIntensityMapUv),y.push(w.transmissionMapUv),y.push(w.thicknessMapUv),y.push(w.combine),y.push(w.fogExp2),y.push(w.sizeAttenuation),y.push(w.morphTargetsCount),y.push(w.morphAttributeCount),y.push(w.numSunLights),y.push(w.numDirLights),y.push(w.numPointLights),y.push(w.numSpotLights),y.push(w.numSpotLightMaps),y.push(w.numHemiLights),y.push(w.numRectAreaLights),y.push(w.numSunLightShadows),y.push(w.numDirLightShadows),y.push(w.numPointLightShadows),y.push(w.numSpotLightShadows),y.push(w.numSpotLightShadowsWithMaps),y.push(w.numLightProbes),y.push(w.shadowMapType),y.push(w.toneMapping),y.push(w.numClippingPlanes),y.push(w.numClipIntersection),y.push(w.depthPacking)}function v(y,w){o.disableAll(),w.instancing&&o.enable(0),w.instancingColor&&o.enable(1),w.instancingMorph&&o.enable(2),w.matcap&&o.enable(3),w.envMap&&o.enable(4),w.normalMapObjectSpace&&o.enable(5),w.normalMapTangentSpace&&o.enable(6),w.clearcoat&&o.enable(7),w.iridescence&&o.enable(8),w.alphaTest&&o.enable(9),w.vertexColors&&o.enable(10),w.vertexAlphas&&o.enable(11),w.vertexUv1s&&o.enable(12),w.vertexUv2s&&o.enable(13),w.vertexUv3s&&o.enable(14),w.vertexTangents&&o.enable(15),w.anisotropy&&o.enable(16),w.alphaHash&&o.enable(17),w.batching&&o.enable(18),w.dispersion&&o.enable(19),w.retroreflection&&o.enable(24),w.batchingColor&&o.enable(20),w.gradientMap&&o.enable(21),w.packedNormalMap&&o.enable(22),w.vertexNormals&&o.enable(23),y.push(o.mask),o.disableAll(),w.fog&&o.enable(0),w.useFog&&o.enable(1),w.flatShading&&o.enable(2),w.logarithmicDepthBuffer&&o.enable(3),w.reversedDepthBuffer&&o.enable(4),w.skinning&&o.enable(5),w.morphTargets&&o.enable(6),w.morphNormals&&o.enable(7),w.morphColors&&o.enable(8),w.premultipliedAlpha&&o.enable(9),w.shadowMapEnabled&&o.enable(10),w.doubleSided&&o.enable(11),w.flipSided&&o.enable(12),w.useDepthPacking&&o.enable(13),w.dithering&&o.enable(14),w.transmission&&o.enable(15),w.sheen&&o.enable(16),w.opaque&&o.enable(17),w.pointsUvs&&o.enable(18),w.decodeVideoTexture&&o.enable(19),w.decodeVideoTextureEmissive&&o.enable(20),w.alphaToCoverage&&o.enable(21),w.numLightProbeGrids>0&&o.enable(22),w.hasPositionAttribute&&o.enable(23),y.push(o.mask)}function b(y){let w=d[y.type],A;if(w){let P=Mi[w];A=mu.clone(P.uniforms)}else A=y.uniforms;return A}function _(y,w){let A=u.get(w);return A!==void 0?++A.usedTimes:(A=new PM(i,w,y,s),l.push(A),u.set(w,A)),A}function S(y){if(--y.usedTimes===0){let w=l.indexOf(y);l[w]=l[l.length-1],l.pop(),u.delete(y.cacheKey),y.destroy()}}function M(y){a.remove(y)}function E(){a.dispose()}return{getParameters:x,getProgramCacheKey:g,getUniforms:b,acquireProgram:_,releaseProgram:S,releaseShaderCache:M,programs:l,dispose:E}}function DM(){let i=new WeakMap;function e(o){return i.has(o)}function t(o){let a=i.get(o);return a===void 0&&(a={},i.set(o,a)),a}function n(o){i.delete(o)}function s(o,a,c){i.get(o)[a]=c}function r(){i=new WeakMap}return{has:e,get:t,remove:n,update:s,dispose:r}}function UM(i,e){return i.groupOrder!==e.groupOrder?i.groupOrder-e.groupOrder:i.renderOrder!==e.renderOrder?i.renderOrder-e.renderOrder:i.material.id!==e.material.id?i.material.id-e.material.id:i.materialVariant!==e.materialVariant?i.materialVariant-e.materialVariant:i.z!==e.z?i.z-e.z:i.id-e.id}function Wg(i,e){return i.groupOrder!==e.groupOrder?i.groupOrder-e.groupOrder:i.renderOrder!==e.renderOrder?i.renderOrder-e.renderOrder:i.z!==e.z?e.z-i.z:i.id-e.id}function Xg(){let i=[],e=0,t=[],n=[],s=[];function r(){e=0,t.length=0,n.length=0,s.length=0}function o(f){let d=0;return f.isInstancedMesh&&(d+=2),f.isSkinnedMesh&&(d+=1),d}function a(f,d,m,x,g,p){let v=i[e];return v===void 0?(v={id:f.id,object:f,geometry:d,material:m,materialVariant:o(f),groupOrder:x,renderOrder:f.renderOrder,z:g,group:p},i[e]=v):(v.id=f.id,v.object=f,v.geometry=d,v.material=m,v.materialVariant=o(f),v.groupOrder=x,v.renderOrder=f.renderOrder,v.z=g,v.group=p),e++,v}function c(f,d,m,x,g,p,v){v.reversedDepth===!0&&(g=-g);let b=a(f,d,m,x,g,p);m.transmission>0?n.push(b):m.transparent===!0?s.push(b):t.push(b)}function l(f,d,m,x,g,p){let v=a(f,d,m,x,g,p);m.transmission>0?n.unshift(v):m.transparent===!0?s.unshift(v):t.unshift(v)}function u(f,d){t.length>1&&t.sort(f||UM),n.length>1&&n.sort(d||Wg),s.length>1&&s.sort(d||Wg)}function h(){for(let f=e,d=i.length;f<d;f++){let m=i[f];if(m.id===null)break;m.id=null,m.object=null,m.geometry=null,m.material=null,m.group=null}}return{opaque:t,transmissive:n,transparent:s,init:r,push:c,unshift:l,finish:h,sort:u}}function FM(){let i=new WeakMap;function e(n,s){let r=i.get(n),o;return r===void 0?(o=new Xg,i.set(n,[o])):s>=r.length?(o=new Xg,r.push(o)):o=r[s],o}function t(){i=new WeakMap}return{get:e,dispose:t}}function OM(){let i={};return{get:function(e){if(i[e.id]!==void 0)return i[e.id];let t;switch(e.type){case"SunLight":case"DirectionalLight":t={direction:new I,color:new Ve};break;case"SpotLight":t={position:new I,direction:new I,color:new Ve,distance:0,coneCos:0,penumbraCos:0,decay:0};break;case"PointLight":t={position:new I,color:new Ve,distance:0,decay:0};break;case"HemisphereLight":t={direction:new I,skyColor:new Ve,groundColor:new Ve};break;case"RectAreaLight":t={color:new Ve,position:new I,halfWidth:new I,halfHeight:new I};break}return i[e.id]=t,t}}}function BM(){let i={};return{get:function(e){if(i[e.id]!==void 0)return i[e.id];let t;switch(e.type){case"SunLight":case"DirectionalLight":t={shadowIntensity:1,shadowBias:0,shadowNormalBias:0,shadowRadius:1,shadowMapSize:new ce};break;case"SpotLight":t={shadowIntensity:1,shadowBias:0,shadowNormalBias:0,shadowRadius:1,shadowMapSize:new ce};break;case"PointLight":t={shadowIntensity:1,shadowBias:0,shadowNormalBias:0,shadowRadius:1,shadowMapSize:new ce,shadowCameraNear:1,shadowCameraFar:1e3};break}return i[e.id]=t,t}}}var zM=0;function kM(i,e){return(e.castShadow?2:0)-(i.castShadow?2:0)+(e.map?1:0)-(i.map?1:0)}function VM(i){let e=new OM,t=BM(),n={version:0,hash:{sunLength:-1,directionalLength:-1,pointLength:-1,spotLength:-1,rectAreaLength:-1,hemiLength:-1,numSunShadows:-1,numDirectionalShadows:-1,numPointShadows:-1,numSpotShadows:-1,numSpotMaps:-1,numLightProbes:-1},ambient:[0,0,0],probe:[],sun:[],sunShadow:[],sunShadowMap:[],sunShadowMatrix:[],sunShadowCascade:[],directional:[],directionalShadow:[],directionalShadowMap:[],directionalShadowMatrix:[],spot:[],spotLightMap:[],spotShadow:[],spotShadowMap:[],spotLightMatrix:[],rectArea:[],rectAreaLTC1:null,rectAreaLTC2:null,point:[],pointShadow:[],pointShadowMap:[],pointShadowMatrix:[],hemi:[],numSpotLightShadowsWithMaps:0,numLightProbes:0};for(let l=0;l<9;l++)n.probe.push(new I);let s=new I,r=new Ie,o=new Ie;function a(l){let u=0,h=0,f=0;for(let C=0;C<9;C++)n.probe[C].set(0,0,0);let d=0,m=0,x=0,g=0,p=0,v=0,b=0,_=0,S=0,M=0,E=0,y=0,w=0,A=0;l.sort(kM);for(let C=0,D=l.length;C<D;C++){let L=l[C],U=L.color,G=L.intensity,Z=L.distance,oe=null;if(L.shadow&&L.shadow.map&&(L.shadow.map.texture.format===ys?oe=L.shadow.map.texture:oe=L.shadow.map.depthTexture||L.shadow.map.texture),L.isAmbientLight)u+=U.r*G,h+=U.g*G,f+=U.b*G;else if(L.isLightProbe){for(let K=0;K<9;K++)n.probe[K].addScaledVector(L.sh.coefficients[K],G);A++}else if(L.isSunLight){let K=e.get(L);if(K.color.copy(L.color).multiplyScalar(L.intensity),L.castShadow){let te=L.shadow,se=t.get(L);se.shadowIntensity=te.intensity,se.shadowBias=te.bias,se.shadowNormalBias=te.normalBias,se.shadowRadius=te.radius,se.shadowMapSize.copy(te.mapSize).multiply(te.getFrameExtents()),n.sunShadow[m]=se,n.sunShadowMap[m]=oe;let Re=te.getViewportCount();for(let Te=0;Te<Re;Te++)n.sunShadowMatrix[x+Te]=te.getMatrix(Te),n.sunShadowCascade[x+Te]=te._cascadeData[Te];x+=Re,m++}n.sun[d]=K,d++}else if(L.isDirectionalLight){let K=e.get(L);if(K.color.copy(L.color).multiplyScalar(L.intensity),L.castShadow){let te=L.shadow,se=t.get(L);se.shadowIntensity=te.intensity,se.shadowBias=te.bias,se.shadowNormalBias=te.normalBias,se.shadowRadius=te.radius,se.shadowMapSize=te.mapSize,n.directionalShadow[g]=se,n.directionalShadowMap[g]=oe,n.directionalShadowMatrix[g]=L.shadow.matrix,S++}n.directional[g]=K,g++}else if(L.isSpotLight){let K=e.get(L);K.position.setFromMatrixPosition(L.matrixWorld),K.color.copy(U).multiplyScalar(G),K.distance=Z,K.coneCos=Math.cos(L.angle),K.penumbraCos=Math.cos(L.angle*(1-L.penumbra)),K.decay=L.decay,n.spot[v]=K;let te=L.shadow;if(L.map&&(n.spotLightMap[y]=L.map,y++,te.updateMatrices(L),L.castShadow&&w++),n.spotLightMatrix[v]=te.matrix,L.castShadow){let se=t.get(L);se.shadowIntensity=te.intensity,se.shadowBias=te.bias,se.shadowNormalBias=te.normalBias,se.shadowRadius=te.radius,se.shadowMapSize=te.mapSize,n.spotShadow[v]=se,n.spotShadowMap[v]=oe,E++}v++}else if(L.isRectAreaLight){let K=e.get(L);K.color.copy(U).multiplyScalar(G),K.halfWidth.set(L.width*.5,0,0),K.halfHeight.set(0,L.height*.5,0),n.rectArea[b]=K,b++}else if(L.isPointLight){let K=e.get(L);if(K.color.copy(L.color).multiplyScalar(L.intensity),K.distance=L.distance,K.decay=L.decay,L.castShadow){let te=L.shadow,se=t.get(L);se.shadowIntensity=te.intensity,se.shadowBias=te.bias,se.shadowNormalBias=te.normalBias,se.shadowRadius=te.radius,se.shadowMapSize=te.mapSize,se.shadowCameraNear=te.camera.near,se.shadowCameraFar=te.camera.far,n.pointShadow[p]=se,n.pointShadowMap[p]=oe,n.pointShadowMatrix[p]=L.shadow.matrix,M++}n.point[p]=K,p++}else if(L.isHemisphereLight){let K=e.get(L);K.skyColor.copy(L.color).multiplyScalar(G),K.groundColor.copy(L.groundColor).multiplyScalar(G),n.hemi[_]=K,_++}}b>0&&(i.has("OES_texture_float_linear")===!0?(n.rectAreaLTC1=Me.LTC_FLOAT_1,n.rectAreaLTC2=Me.LTC_FLOAT_2):(n.rectAreaLTC1=Me.LTC_HALF_1,n.rectAreaLTC2=Me.LTC_HALF_2)),n.ambient[0]=u,n.ambient[1]=h,n.ambient[2]=f;let P=n.hash;(P.sunLength!==d||P.directionalLength!==g||P.pointLength!==p||P.spotLength!==v||P.rectAreaLength!==b||P.hemiLength!==_||P.numSunShadows!==m||P.numDirectionalShadows!==S||P.numPointShadows!==M||P.numSpotShadows!==E||P.numSpotMaps!==y||P.numLightProbes!==A)&&(n.sun.length=d,n.directional.length=g,n.spot.length=v,n.rectArea.length=b,n.point.length=p,n.hemi.length=_,n.sunShadow.length=m,n.sunShadowMap.length=m,n.sunShadowMatrix.length=x,n.sunShadowCascade.length=x,n.directionalShadow.length=S,n.directionalShadowMap.length=S,n.directionalShadowMatrix.length=S,n.pointShadow.length=M,n.pointShadowMap.length=M,n.pointShadowMatrix.length=M,n.spotShadow.length=E,n.spotShadowMap.length=E,n.spotLightMatrix.length=E+y-w,n.spotLightMap.length=y,n.numSpotLightShadowsWithMaps=w,n.numLightProbes=A,P.sunLength=d,P.directionalLength=g,P.pointLength=p,P.spotLength=v,P.rectAreaLength=b,P.hemiLength=_,P.numSunShadows=m,P.numDirectionalShadows=S,P.numPointShadows=M,P.numSpotShadows=E,P.numSpotMaps=y,P.numLightProbes=A,n.version=zM++)}function c(l,u){let h=0,f=0,d=0,m=0,x=0,g=0,p=u.matrixWorldInverse;for(let v=0,b=l.length;v<b;v++){let _=l[v];if(_.isSunLight){let S=n.sun[h];S.direction.setFromMatrixPosition(_.matrixWorld),S.direction.transformDirection(p),h++}else if(_.isDirectionalLight){let S=n.directional[f];S.direction.setFromMatrixPosition(_.matrixWorld),s.setFromMatrixPosition(_.target.matrixWorld),S.direction.sub(s),S.direction.transformDirection(p),f++}else if(_.isSpotLight){let S=n.spot[m];S.position.setFromMatrixPosition(_.matrixWorld),S.position.applyMatrix4(p),S.direction.setFromMatrixPosition(_.matrixWorld),s.setFromMatrixPosition(_.target.matrixWorld),S.direction.sub(s),S.direction.transformDirection(p),m++}else if(_.isRectAreaLight){let S=n.rectArea[x];S.position.setFromMatrixPosition(_.matrixWorld),S.position.applyMatrix4(p),o.identity(),r.copy(_.matrixWorld),r.premultiply(p),o.extractRotation(r),S.halfWidth.set(_.width*.5,0,0),S.halfHeight.set(0,_.height*.5,0),S.halfWidth.applyMatrix4(o),S.halfHeight.applyMatrix4(o),x++}else if(_.isPointLight){let S=n.point[d];S.position.setFromMatrixPosition(_.matrixWorld),S.position.applyMatrix4(p),d++}else if(_.isHemisphereLight){let S=n.hemi[g];S.direction.setFromMatrixPosition(_.matrixWorld),S.direction.transformDirection(p),g++}}}return{setup:a,setupView:c,state:n}}function qg(i){let e=new VM(i),t=[],n=[],s=[];function r(f){h.camera=f,t.length=0,n.length=0,s.length=0}function o(f){t.push(f)}function a(f){n.push(f)}function c(f){s.push(f)}function l(){e.setup(t)}function u(f){e.setupView(t,f)}let h={lightsArray:t,shadowsArray:n,lightProbeGridArray:s,camera:null,lights:e,transmissionRenderTarget:{},textureUnits:0};return{init:r,state:h,setupLights:l,setupLightsView:u,pushLight:o,pushShadow:a,pushLightProbeGrid:c}}function HM(i){let e=new WeakMap;function t(s,r=0){let o=e.get(s),a;return o===void 0?(a=new qg(i),e.set(s,[a])):r>=o.length?(a=new qg(i),o.push(a)):a=o[r],a}function n(){e=new WeakMap}return{get:t,dispose:n}}var GM=`void main() {
	gl_Position = vec4( position, 1.0 );
}`,WM=`uniform sampler2D shadow_pass;
uniform vec2 resolution;
uniform float radius;
void main() {
	const float samples = float( VSM_SAMPLES );
	float mean = 0.0;
	float squared_mean = 0.0;
	float uvStride = samples <= 1.0 ? 0.0 : 2.0 / ( samples - 1.0 );
	float uvStart = samples <= 1.0 ? 0.0 : - 1.0;
	for ( float i = 0.0; i < samples; i ++ ) {
		float uvOffset = uvStart + i * uvStride;
		#ifdef HORIZONTAL_PASS
			vec2 distribution = texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( uvOffset, 0.0 ) * radius ) / resolution ).rg;
			mean += distribution.x;
			squared_mean += distribution.y * distribution.y + distribution.x * distribution.x;
		#else
			float depth = texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( 0.0, uvOffset ) * radius ) / resolution ).r;
			mean += depth;
			squared_mean += depth * depth;
		#endif
	}
	mean = mean / samples;
	squared_mean = squared_mean / samples;
	float std_dev = sqrt( max( 0.0, squared_mean - mean * mean ) );
	gl_FragColor = vec4( mean, std_dev, 0.0, 1.0 );
}`,XM=[new I(1,0,0),new I(-1,0,0),new I(0,1,0),new I(0,-1,0),new I(0,0,1),new I(0,0,-1)],qM=[new I(0,-1,0),new I(0,-1,0),new I(0,0,1),new I(0,0,-1),new I(0,-1,0),new I(0,-1,0)],Yg=new Ie,ka=new I,Jf=new I;function YM(i,e,t){let n=new Gr,s=new ce,r=new ce,o=new ut,a=new dl,c=new pl,l={},u=t.maxTextureSize,h={[kn]:jt,[jt]:kn,[Dt]:Dt},f=new ln({defines:{VSM_SAMPLES:8},uniforms:{shadow_pass:{value:null},resolution:{value:new ce},radius:{value:4}},vertexShader:GM,fragmentShader:WM}),d=f.clone();d.defines.HORIZONTAL_PASS=1;let m=new ht;m.setAttribute("position",new Tt(new Float32Array([-1,-1,.5,3,-1,.5,-1,3,.5]),3));let x=new it(m,f),g=this;this.enabled=!1,this.autoUpdate=!0,this.needsUpdate=!1,this.type=Ca;let p=this.type;this.render=function(M,E,y){if(g.enabled===!1||g.autoUpdate===!1&&g.needsUpdate===!1||M.length===0)return;this.type===wl&&(Fe("WebGLShadowMap: PCFSoftShadowMap has been removed. Using PCFShadowMap instead."),this.type=Ca);let w=i.getRenderTarget(),A=i.getActiveCubeFace(),P=i.getActiveMipmapLevel(),C=i.state;C.setBlending(Si),C.buffers.depth.getReversed()===!0?C.buffers.color.setClear(0,0,0,0):C.buffers.color.setClear(1,1,1,1),C.buffers.depth.setTest(!0),C.setScissorTest(!1);let D=p!==this.type;D&&E.traverse(function(L){L.material&&(Array.isArray(L.material)?L.material.forEach(U=>U.needsUpdate=!0):L.material.needsUpdate=!0)});for(let L=0,U=M.length;L<U;L++){let G=M[L],Z=G.shadow;if(Z===void 0){Fe("WebGLShadowMap:",G,"has no shadow.");continue}if(Z.autoUpdate===!1&&Z.needsUpdate===!1)continue;s.copy(Z.mapSize);let oe=Z.getFrameExtents();s.multiply(oe),r.copy(Z.mapSize),(s.x>u||s.y>u)&&(s.x>u&&(r.x=Math.floor(u/oe.x),s.x=r.x*oe.x,Z.mapSize.x=r.x),s.y>u&&(r.y=Math.floor(u/oe.y),s.y=r.y*oe.y,Z.mapSize.y=r.y));let K=i.state.buffers.depth.getReversed();if(Z.camera._reversedDepth=K,Z.map===null||D===!0){if(Z.map!==null&&(Z.map.depthTexture!==null&&(Z.map.depthTexture.dispose(),Z.map.depthTexture=null),Z.map.dispose()),this.type===$r){if(G.isPointLight){Fe("WebGLShadowMap: VSM shadow maps are not supported for PointLights. Use PCF or BasicShadowMap instead.");continue}Z.map=new Rn(s.x,s.y,{format:ys,type:li,minFilter:Gt,magFilter:Gt,generateMipmaps:!1}),Z.map.texture.name=G.name+".shadowMap",Z.map.depthTexture=new hs(s.x,s.y,Vn),Z.map.depthTexture.name=G.name+".shadowMapDepth",Z.map.depthTexture.format=_i,Z.map.depthTexture.compareFunction=null,Z.map.depthTexture.minFilter=Ht,Z.map.depthTexture.magFilter=Ht}else G.isPointLight?(Z.map=new _u(s.x),Z.map.depthTexture=new rl(s.x,ci)):(Z.map=new Rn(s.x,s.y),Z.map.depthTexture=new hs(s.x,s.y,ci)),Z.map.depthTexture.name=G.name+".shadowMap",Z.map.depthTexture.format=_i,this.type===Ca?(Z.map.depthTexture.compareFunction=K?pu:du,Z.map.depthTexture.minFilter=Gt,Z.map.depthTexture.magFilter=Gt):(Z.map.depthTexture.compareFunction=null,Z.map.depthTexture.minFilter=Ht,Z.map.depthTexture.magFilter=Ht);Z.camera.updateProjectionMatrix()}Z.map.isWebGLCubeRenderTarget!==!0&&(Z.map.width!==s.x||Z.map.height!==s.y)&&Z.map.setSize(s.x,s.y);let te=Z.map.isWebGLCubeRenderTarget?6:Z.getViewportCount();G.isPointLight!==!0&&Z.updateMatrices(G,y);for(let se=0;se<te;se++){let Re=Z.getCamera(se);if(G.isPointLight){let Te=Z.camera,nt=Z.matrix,He=G.distance||Te.far;He!==Te.far&&(Te.far=He,Te.updateProjectionMatrix()),ka.setFromMatrixPosition(G.matrixWorld),Te.position.copy(ka),Jf.copy(Te.position),Jf.add(XM[se]),Te.up.copy(qM[se]),Te.lookAt(Jf),Te.updateMatrixWorld(),nt.makeTranslation(-ka.x,-ka.y,-ka.z),Yg.multiplyMatrices(Te.projectionMatrix,Te.matrixWorldInverse),Z._frustum.setFromProjectionMatrix(Yg,Te.coordinateSystem,Te.reversedDepth)}if(Z.map.isWebGLCubeRenderTarget)i.setRenderTarget(Z.map,se),i.clear();else{se===0&&(i.setRenderTarget(Z.map),i.clear());let Te=Z.getViewport(se);o.set(r.x*Te.x,r.y*Te.y,r.x*Te.z,r.y*Te.w),C.viewport(o)}n=Z.getFrustum(se),_(E,y,Re,G,this.type)}Z.isPointLightShadow!==!0&&this.type===$r&&v(Z,y),Z.needsUpdate=!1}p=this.type,g.needsUpdate=!1,i.setRenderTarget(w,A,P)};function v(M,E){let y=e.update(x);f.defines.VSM_SAMPLES!==M.blurSamples&&(f.defines.VSM_SAMPLES=M.blurSamples,d.defines.VSM_SAMPLES=M.blurSamples,f.needsUpdate=!0,d.needsUpdate=!0),M.mapPass===null?M.mapPass=new Rn(s.x,s.y,{format:ys,type:li}):(M.mapPass.width!==M.map.width||M.mapPass.height!==M.map.height)&&M.mapPass.setSize(M.map.width,M.map.height),f.uniforms.shadow_pass.value=M.map.depthTexture,f.uniforms.resolution.value.set(M.map.width,M.map.height),f.uniforms.radius.value=M.radius,i.setRenderTarget(M.mapPass),i.clear(),i.renderBufferDirect(E,null,y,f,x,null),d.uniforms.shadow_pass.value=M.mapPass.texture,d.uniforms.resolution.value.set(M.map.width,M.map.height),d.uniforms.radius.value=M.radius,i.setRenderTarget(M.map),i.clear(),i.renderBufferDirect(E,null,y,d,x,null)}function b(M,E,y,w){let A=null,P=y.isPointLight===!0?M.customDistanceMaterial:M.customDepthMaterial;if(P!==void 0)A=P;else if(A=y.isPointLight===!0?c:a,i.localClippingEnabled&&E.clipShadows===!0&&Array.isArray(E.clippingPlanes)&&E.clippingPlanes.length!==0||E.displacementMap&&E.displacementScale!==0||E.alphaMap&&E.alphaTest>0||E.map&&E.alphaTest>0||E.alphaToCoverage===!0){let C=A.uuid,D=E.uuid,L=l[C];L===void 0&&(L={},l[C]=L);let U=L[D];U===void 0&&(U=A.clone(),L[D]=U,E.addEventListener("dispose",S)),A=U}if(A.visible=E.visible,A.wireframe=E.wireframe,w===$r?A.side=E.shadowSide!==null?E.shadowSide:E.side:A.side=E.shadowSide!==null?E.shadowSide:h[E.side],A.alphaMap=E.alphaMap,A.alphaTest=E.alphaToCoverage===!0?.5:E.alphaTest,A.map=E.map,A.clipShadows=E.clipShadows,A.clippingPlanes=E.clippingPlanes,A.clipIntersection=E.clipIntersection,A.displacementMap=E.displacementMap,A.displacementScale=E.displacementScale,A.displacementBias=E.displacementBias,A.wireframeLinewidth=E.wireframeLinewidth,A.linewidth=E.linewidth,y.isPointLight===!0&&A.isMeshDistanceMaterial===!0){let C=i.properties.get(A);C.light=y}return A}function _(M,E,y,w,A){if(M.visible===!1)return;if(M.layers.test(E.layers)&&(M.isMesh||M.isLine||M.isPoints)&&(M.castShadow||M.receiveShadow&&A===$r)&&(!M.frustumCulled||M.intersectsFrustum(n))){M.modelViewMatrix.multiplyMatrices(y.matrixWorldInverse,M.matrixWorld);let D=e.update(M),L=M.material;if(Array.isArray(L)){let U=D.groups;for(let G=0,Z=U.length;G<Z;G++){let oe=U[G],K=L[oe.materialIndex];if(K&&K.visible){let te=b(M,K,w,A);M.onBeforeShadow(i,M,E,y,D,te,oe),i.renderBufferDirect(y,null,D,te,M,oe),M.onAfterShadow(i,M,E,y,D,te,oe)}}}else if(L.visible){let U=b(M,L,w,A);M.onBeforeShadow(i,M,E,y,D,U,null),i.renderBufferDirect(y,null,D,U,M,null),M.onAfterShadow(i,M,E,y,D,U,null)}}let C=M.children;for(let D=0,L=C.length;D<L;D++)_(C[D],E,y,w,A)}function S(M){M.target.removeEventListener("dispose",S);for(let y in l){let w=l[y],A=M.target.uuid;A in w&&(w[A].dispose(),delete w[A])}}}function ZM(i,e){function t(){let k=!1,ve=new ut,re=null,Se=new ut(0,0,0,0);return{setMask:function(Ae){re!==Ae&&!k&&(i.colorMask(Ae,Ae,Ae,Ae),re=Ae)},setLocked:function(Ae){k=Ae},setClear:function(Ae,ue,ke,De,Pt){Pt===!0&&(Ae*=De,ue*=De,ke*=De),ve.set(Ae,ue,ke,De),Se.equals(ve)===!1&&(i.clearColor(Ae,ue,ke,De),Se.copy(ve))},reset:function(){k=!1,re=null,Se.set(-1,0,0,0)}}}function n(){let k=!1,ve=!1,re=null,Se=null,Ae=null;return{setReversed:function(ue){if(ve!==ue){let ke=e.get("EXT_clip_control");ue?ke.clipControlEXT(ke.LOWER_LEFT_EXT,ke.ZERO_TO_ONE_EXT):ke.clipControlEXT(ke.LOWER_LEFT_EXT,ke.NEGATIVE_ONE_TO_ONE_EXT),ve=ue;let De=Ae;Ae=null,this.setClear(De)}},getReversed:function(){return ve},setTest:function(ue){ue?z(i.DEPTH_TEST):j(i.DEPTH_TEST)},setMask:function(ue){re!==ue&&!k&&(i.depthMask(ue),re=ue)},setFunc:function(ue){if(ve&&(ue=_g[ue]),Se!==ue){switch(ue){case Yc:i.depthFunc(i.NEVER);break;case Zc:i.depthFunc(i.ALWAYS);break;case Kc:i.depthFunc(i.LESS);break;case Lr:i.depthFunc(i.LEQUAL);break;case Jc:i.depthFunc(i.EQUAL);break;case $c:i.depthFunc(i.GEQUAL);break;case jc:i.depthFunc(i.GREATER);break;case Qc:i.depthFunc(i.NOTEQUAL);break;default:i.depthFunc(i.LEQUAL)}Se=ue}},setLocked:function(ue){k=ue},setClear:function(ue){Ae!==ue&&(Ae=ue,ve&&(ue=1-ue),i.clearDepth(ue))},reset:function(){k=!1,re=null,Se=null,Ae=null,ve=!1}}}function s(){let k=!1,ve=null,re=null,Se=null,Ae=null,ue=null,ke=null,De=null,Pt=null;return{setTest:function(xt){k||(xt?z(i.STENCIL_TEST):j(i.STENCIL_TEST))},setMask:function(xt){ve!==xt&&!k&&(i.stencilMask(xt),ve=xt)},setFunc:function(xt,Qn,pi){(re!==xt||Se!==Qn||Ae!==pi)&&(i.stencilFunc(xt,Qn,pi),re=xt,Se=Qn,Ae=pi)},setOp:function(xt,Qn,pi){(ue!==xt||ke!==Qn||De!==pi)&&(i.stencilOp(xt,Qn,pi),ue=xt,ke=Qn,De=pi)},setLocked:function(xt){k=xt},setClear:function(xt){Pt!==xt&&(i.clearStencil(xt),Pt=xt)},reset:function(){k=!1,ve=null,re=null,Se=null,Ae=null,ue=null,ke=null,De=null,Pt=null}}}let r=new t,o=new n,a=new s,c=new WeakMap,l=new WeakMap,u={},h={},f={},d=new WeakMap,m=[],x=null,g=!1,p=null,v=null,b=null,_=null,S=null,M=null,E=null,y=new Ve(0,0,0),w=0,A=!1,P=null,C=null,D=null,L=null,U=null,G=i.getParameter(i.MAX_COMBINED_TEXTURE_IMAGE_UNITS),Z=!1,oe=0,K=i.getParameter(i.VERSION);K.indexOf("WebGL")!==-1?(oe=parseFloat(/^WebGL (\d)/.exec(K)[1]),Z=oe>=1):K.indexOf("OpenGL ES")!==-1&&(oe=parseFloat(/^OpenGL ES (\d)/.exec(K)[1]),Z=oe>=2);let te=null,se={},Re=i.getParameter(i.SCISSOR_BOX),Te=i.getParameter(i.VIEWPORT),nt=new ut().fromArray(Re),He=new ut().fromArray(Te);function $e(k,ve,re,Se){let Ae=new Uint8Array(4),ue=i.createTexture();i.bindTexture(k,ue),i.texParameteri(k,i.TEXTURE_MIN_FILTER,i.NEAREST),i.texParameteri(k,i.TEXTURE_MAG_FILTER,i.NEAREST);for(let ke=0;ke<re;ke++)k===i.TEXTURE_3D||k===i.TEXTURE_2D_ARRAY?i.texImage3D(ve,0,i.RGBA,1,1,Se,0,i.RGBA,i.UNSIGNED_BYTE,Ae):i.texImage2D(ve+ke,0,i.RGBA,1,1,0,i.RGBA,i.UNSIGNED_BYTE,Ae);return ue}let $={};$[i.TEXTURE_2D]=$e(i.TEXTURE_2D,i.TEXTURE_2D,1),$[i.TEXTURE_CUBE_MAP]=$e(i.TEXTURE_CUBE_MAP,i.TEXTURE_CUBE_MAP_POSITIVE_X,6),$[i.TEXTURE_2D_ARRAY]=$e(i.TEXTURE_2D_ARRAY,i.TEXTURE_2D_ARRAY,1,1),$[i.TEXTURE_3D]=$e(i.TEXTURE_3D,i.TEXTURE_3D,1,1),r.setClear(0,0,0,1),o.setClear(1),a.setClear(0),z(i.DEPTH_TEST),o.setFunc(Lr),q(!1),ie(hf),z(i.CULL_FACE),F(Si);function z(k){u[k]!==!0&&(i.enable(k),u[k]=!0)}function j(k){u[k]!==!1&&(i.disable(k),u[k]=!1)}function me(k,ve){return f[k]!==ve?(i.bindFramebuffer(k,ve),f[k]=ve,k===i.DRAW_FRAMEBUFFER&&(f[i.FRAMEBUFFER]=ve),k===i.FRAMEBUFFER&&(f[i.DRAW_FRAMEBUFFER]=ve),!0):!1}function fe(k,ve){let re=m,Se=!1;if(k){re=d.get(ve),re===void 0&&(re=[],d.set(ve,re));let Ae=k.textures;if(re.length!==Ae.length||re[0]!==i.COLOR_ATTACHMENT0){for(let ue=0,ke=Ae.length;ue<ke;ue++)re[ue]=i.COLOR_ATTACHMENT0+ue;re.length=Ae.length,Se=!0}}else re[0]!==i.BACK&&(re[0]=i.BACK,Se=!0);Se&&i.drawBuffers(re)}function de(k){return x!==k?(i.useProgram(k),x=k,!0):!1}let et={[qs]:i.FUNC_ADD,[zm]:i.FUNC_SUBTRACT,[km]:i.FUNC_REVERSE_SUBTRACT};et[Vm]=i.MIN,et[Hm]=i.MAX;let ne={[Gm]:i.ZERO,[Wm]:i.ONE,[Xm]:i.SRC_COLOR,[mf]:i.SRC_ALPHA,[$m]:i.SRC_ALPHA_SATURATE,[Km]:i.DST_COLOR,[Ym]:i.DST_ALPHA,[qm]:i.ONE_MINUS_SRC_COLOR,[gf]:i.ONE_MINUS_SRC_ALPHA,[Jm]:i.ONE_MINUS_DST_COLOR,[Zm]:i.ONE_MINUS_DST_ALPHA,[jm]:i.CONSTANT_COLOR,[Qm]:i.ONE_MINUS_CONSTANT_COLOR,[eg]:i.CONSTANT_ALPHA,[tg]:i.ONE_MINUS_CONSTANT_ALPHA};function F(k,ve,re,Se,Ae,ue,ke,De,Pt,xt){if(k===Si){g===!0&&(j(i.BLEND),g=!1);return}if(g===!1&&(z(i.BLEND),g=!0),k!==Bm){if(k!==p||xt!==A){if((v!==qs||S!==qs)&&(i.blendEquation(i.FUNC_ADD),v=qs,S=qs),xt)switch(k){case jr:i.blendFuncSeparate(i.ONE,i.ONE_MINUS_SRC_ALPHA,i.ONE,i.ONE_MINUS_SRC_ALPHA);break;case ff:i.blendFunc(i.ONE,i.ONE);break;case df:i.blendFuncSeparate(i.ZERO,i.ONE_MINUS_SRC_COLOR,i.ZERO,i.ONE);break;case pf:i.blendFuncSeparate(i.DST_COLOR,i.ONE_MINUS_SRC_ALPHA,i.ZERO,i.ONE);break;default:We("WebGLState: Invalid blending: ",k);break}else switch(k){case jr:i.blendFuncSeparate(i.SRC_ALPHA,i.ONE_MINUS_SRC_ALPHA,i.ONE,i.ONE_MINUS_SRC_ALPHA);break;case ff:i.blendFuncSeparate(i.SRC_ALPHA,i.ONE,i.ONE,i.ONE);break;case df:We("WebGLState: SubtractiveBlending requires material.premultipliedAlpha = true");break;case pf:We("WebGLState: MultiplyBlending requires material.premultipliedAlpha = true");break;default:We("WebGLState: Invalid blending: ",k);break}b=null,_=null,M=null,E=null,y.set(0,0,0),w=0,p=k,A=xt}return}Ae=Ae||ve,ue=ue||re,ke=ke||Se,(ve!==v||Ae!==S)&&(i.blendEquationSeparate(et[ve],et[Ae]),v=ve,S=Ae),(re!==b||Se!==_||ue!==M||ke!==E)&&(i.blendFuncSeparate(ne[re],ne[Se],ne[ue],ne[ke]),b=re,_=Se,M=ue,E=ke),(De.equals(y)===!1||Pt!==w)&&(i.blendColor(De.r,De.g,De.b,Pt),y.copy(De),w=Pt),p=k,A=!1}function V(k,ve){k.side===Dt?j(i.CULL_FACE):z(i.CULL_FACE);let re=k.side===jt;ve&&(re=!re),q(re),k.blending===jr&&k.transparent===!1?F(Si):F(k.blending,k.blendEquation,k.blendSrc,k.blendDst,k.blendEquationAlpha,k.blendSrcAlpha,k.blendDstAlpha,k.blendColor,k.blendAlpha,k.premultipliedAlpha),o.setFunc(k.depthFunc),o.setTest(k.depthTest),o.setMask(k.depthWrite),r.setMask(k.colorWrite);let Se=k.stencilWrite;a.setTest(Se),Se&&(a.setMask(k.stencilWriteMask),a.setFunc(k.stencilFunc,k.stencilRef,k.stencilFuncMask),a.setOp(k.stencilFail,k.stencilZFail,k.stencilZPass)),ge(k.polygonOffset,k.polygonOffsetFactor,k.polygonOffsetUnits),k.alphaToCoverage===!0?z(i.SAMPLE_ALPHA_TO_COVERAGE):j(i.SAMPLE_ALPHA_TO_COVERAGE)}function q(k){P!==k&&(k?i.frontFace(i.CW):i.frontFace(i.CCW),P=k)}function ie(k){k!==Fm?(z(i.CULL_FACE),k!==C&&(k===hf?i.cullFace(i.BACK):k===Om?i.cullFace(i.FRONT):i.cullFace(i.FRONT_AND_BACK))):j(i.CULL_FACE),C=k}function le(k){k!==D&&(Z&&i.lineWidth(k),D=k)}function ge(k,ve,re){k?(z(i.POLYGON_OFFSET_FILL),(L!==ve||U!==re)&&(L=ve,U=re,o.getReversed()&&(ve=-ve),i.polygonOffset(ve,re))):j(i.POLYGON_OFFSET_FILL)}function he(k){k?z(i.SCISSOR_TEST):j(i.SCISSOR_TEST)}function ze(k){k===void 0&&(k=i.TEXTURE0+G-1),te!==k&&(i.activeTexture(k),te=k)}function O(k,ve,re){re===void 0&&(te===null?re=i.TEXTURE0+G-1:re=te);let Se=se[re];Se===void 0&&(Se={type:void 0,texture:void 0},se[re]=Se),(Se.type!==k||Se.texture!==ve)&&(te!==re&&(i.activeTexture(re),te=re),i.bindTexture(k,ve||$[k]),Se.type=k,Se.texture=ve)}function gt(){let k=se[te];k!==void 0&&k.type!==void 0&&(i.bindTexture(k.type,null),k.type=void 0,k.texture=void 0)}function rt(){try{i.compressedTexImage2D(...arguments)}catch(k){We("WebGLState:",k)}}function N(){try{i.compressedTexImage3D(...arguments)}catch(k){We("WebGLState:",k)}}function T(){try{i.texSubImage2D(...arguments)}catch(k){We("WebGLState:",k)}}function H(){try{i.texSubImage3D(...arguments)}catch(k){We("WebGLState:",k)}}function Y(){try{i.compressedTexSubImage2D(...arguments)}catch(k){We("WebGLState:",k)}}function Q(){try{i.compressedTexSubImage3D(...arguments)}catch(k){We("WebGLState:",k)}}function pe(){try{i.texStorage2D(...arguments)}catch(k){We("WebGLState:",k)}}function xe(){try{i.texStorage3D(...arguments)}catch(k){We("WebGLState:",k)}}function ee(){try{i.texImage2D(...arguments)}catch(k){We("WebGLState:",k)}}function ae(){try{i.texImage3D(...arguments)}catch(k){We("WebGLState:",k)}}function _e(k){return h[k]!==void 0?h[k]:i.getParameter(k)}function Oe(k,ve){h[k]!==ve&&(i.pixelStorei(k,ve),h[k]=ve)}function be(k){nt.equals(k)===!1&&(i.scissor(k.x,k.y,k.z,k.w),nt.copy(k))}function ye(k){He.equals(k)===!1&&(i.viewport(k.x,k.y,k.z,k.w),He.copy(k))}function Be(k,ve){let re=l.get(ve);re===void 0&&(re=new WeakMap,l.set(ve,re));let Se=re.get(k);Se===void 0&&(Se=i.getUniformBlockIndex(ve,k.name),re.set(k,Se))}function Ge(k,ve){let Se=l.get(ve).get(k);c.get(ve)!==Se&&(i.uniformBlockBinding(ve,Se,k.__bindingPointIndex),c.set(ve,Se))}function Je(){i.disable(i.BLEND),i.disable(i.CULL_FACE),i.disable(i.DEPTH_TEST),i.disable(i.POLYGON_OFFSET_FILL),i.disable(i.SCISSOR_TEST),i.disable(i.STENCIL_TEST),i.disable(i.SAMPLE_ALPHA_TO_COVERAGE),i.blendEquation(i.FUNC_ADD),i.blendFunc(i.ONE,i.ZERO),i.blendFuncSeparate(i.ONE,i.ZERO,i.ONE,i.ZERO),i.blendColor(0,0,0,0),i.colorMask(!0,!0,!0,!0),i.clearColor(0,0,0,0),i.depthMask(!0),i.depthFunc(i.LESS),o.setReversed(!1),i.clearDepth(1),i.stencilMask(4294967295),i.stencilFunc(i.ALWAYS,0,4294967295),i.stencilOp(i.KEEP,i.KEEP,i.KEEP),i.clearStencil(0),i.cullFace(i.BACK),i.frontFace(i.CCW),i.polygonOffset(0,0),i.activeTexture(i.TEXTURE0),i.bindFramebuffer(i.FRAMEBUFFER,null),i.bindFramebuffer(i.DRAW_FRAMEBUFFER,null),i.bindFramebuffer(i.READ_FRAMEBUFFER,null),i.useProgram(null),i.lineWidth(1),i.scissor(0,0,i.canvas.width,i.canvas.height),i.viewport(0,0,i.canvas.width,i.canvas.height),i.pixelStorei(i.PACK_ALIGNMENT,4),i.pixelStorei(i.UNPACK_ALIGNMENT,4),i.pixelStorei(i.UNPACK_FLIP_Y_WEBGL,!1),i.pixelStorei(i.UNPACK_PREMULTIPLY_ALPHA_WEBGL,!1),i.pixelStorei(i.UNPACK_COLORSPACE_CONVERSION_WEBGL,i.BROWSER_DEFAULT_WEBGL),i.pixelStorei(i.PACK_ROW_LENGTH,0),i.pixelStorei(i.PACK_SKIP_PIXELS,0),i.pixelStorei(i.PACK_SKIP_ROWS,0),i.pixelStorei(i.UNPACK_ROW_LENGTH,0),i.pixelStorei(i.UNPACK_IMAGE_HEIGHT,0),i.pixelStorei(i.UNPACK_SKIP_PIXELS,0),i.pixelStorei(i.UNPACK_SKIP_ROWS,0),i.pixelStorei(i.UNPACK_SKIP_IMAGES,0),u={},h={},te=null,se={},f={},d=new WeakMap,m=[],x=null,g=!1,p=null,v=null,b=null,_=null,S=null,M=null,E=null,y=new Ve(0,0,0),w=0,A=!1,P=null,C=null,D=null,L=null,U=null,nt.set(0,0,i.canvas.width,i.canvas.height),He.set(0,0,i.canvas.width,i.canvas.height),r.reset(),o.reset(),a.reset()}return{buffers:{color:r,depth:o,stencil:a},enable:z,disable:j,bindFramebuffer:me,drawBuffers:fe,useProgram:de,setBlending:F,setMaterial:V,setFlipSided:q,setCullFace:ie,setLineWidth:le,setPolygonOffset:ge,setScissorTest:he,activeTexture:ze,bindTexture:O,unbindTexture:gt,compressedTexImage2D:rt,compressedTexImage3D:N,texImage2D:ee,texImage3D:ae,pixelStorei:Oe,getParameter:_e,updateUBOMapping:Be,uniformBlockBinding:Ge,texStorage2D:pe,texStorage3D:xe,texSubImage2D:T,texSubImage3D:H,compressedTexSubImage2D:Y,compressedTexSubImage3D:Q,scissor:be,viewport:ye,reset:Je}}function KM(i,e,t,n,s,r,o){let a=e.has("WEBGL_multisampled_render_to_texture")?e.get("WEBGL_multisampled_render_to_texture"):null,c=typeof navigator>"u"?!1:/OculusBrowser/g.test(navigator.userAgent),l=new ce,u=new WeakMap,h=new Set,f,d=new WeakMap,m=!1;try{m=typeof OffscreenCanvas<"u"&&new OffscreenCanvas(1,1).getContext("2d")!==null}catch{}function x(N,T){return m?new OffscreenCanvas(N,T):Ur("canvas")}function g(N,T,H){let Y=1,Q=rt(N);if((Q.width>H||Q.height>H)&&(Y=H/Math.max(Q.width,Q.height)),Y<1)if(typeof HTMLImageElement<"u"&&N instanceof HTMLImageElement||typeof HTMLCanvasElement<"u"&&N instanceof HTMLCanvasElement||typeof ImageBitmap<"u"&&N instanceof ImageBitmap||typeof VideoFrame<"u"&&N instanceof VideoFrame){let pe=Math.floor(Y*Q.width),xe=Math.floor(Y*Q.height);f===void 0&&(f=x(pe,xe));let ee=T?x(pe,xe):f;return ee.width=pe,ee.height=xe,ee.getContext("2d").drawImage(N,0,0,pe,xe),Fe("WebGLRenderer: Texture has been resized from ("+Q.width+"x"+Q.height+") to ("+pe+"x"+xe+")."),ee}else return"data"in N&&Fe("WebGLRenderer: Image in DataTexture is too big ("+Q.width+"x"+Q.height+")."),N;return N}function p(N){return N.generateMipmaps}function v(N){i.generateMipmap(N)}function b(N){return N.isWebGLCubeRenderTarget?i.TEXTURE_CUBE_MAP:N.isWebGL3DRenderTarget?i.TEXTURE_3D:N.isWebGLArrayRenderTarget||N.isCompressedArrayTexture?i.TEXTURE_2D_ARRAY:i.TEXTURE_2D}function _(N,T,H,Y,Q,pe=!1){if(N!==null){if(i[N]!==void 0)return i[N];Fe("WebGLRenderer: Attempt to use non-existing WebGL internal format '"+N+"'")}let xe;Y&&(xe=e.get("EXT_texture_norm16"),xe||Fe("WebGLRenderer: Unable to use normalized textures without EXT_texture_norm16 extension"));let ee=T;if(T===i.RED&&(H===i.FLOAT&&(ee=i.R32F),H===i.HALF_FLOAT&&(ee=i.R16F),H===i.UNSIGNED_BYTE&&(ee=i.R8),H===i.UNSIGNED_SHORT&&xe&&(ee=xe.R16_EXT),H===i.SHORT&&xe&&(ee=xe.R16_SNORM_EXT)),T===i.RED_INTEGER&&(H===i.UNSIGNED_BYTE&&(ee=i.R8UI),H===i.UNSIGNED_SHORT&&(ee=i.R16UI),H===i.UNSIGNED_INT&&(ee=i.R32UI),H===i.BYTE&&(ee=i.R8I),H===i.SHORT&&(ee=i.R16I),H===i.INT&&(ee=i.R32I)),T===i.RG&&(H===i.FLOAT&&(ee=i.RG32F),H===i.HALF_FLOAT&&(ee=i.RG16F),H===i.UNSIGNED_BYTE&&(ee=i.RG8),H===i.UNSIGNED_SHORT&&xe&&(ee=xe.RG16_EXT),H===i.SHORT&&xe&&(ee=xe.RG16_SNORM_EXT)),T===i.RG_INTEGER&&(H===i.UNSIGNED_BYTE&&(ee=i.RG8UI),H===i.UNSIGNED_SHORT&&(ee=i.RG16UI),H===i.UNSIGNED_INT&&(ee=i.RG32UI),H===i.BYTE&&(ee=i.RG8I),H===i.SHORT&&(ee=i.RG16I),H===i.INT&&(ee=i.RG32I)),T===i.RGB_INTEGER&&(H===i.UNSIGNED_BYTE&&(ee=i.RGB8UI),H===i.UNSIGNED_SHORT&&(ee=i.RGB16UI),H===i.UNSIGNED_INT&&(ee=i.RGB32UI),H===i.BYTE&&(ee=i.RGB8I),H===i.SHORT&&(ee=i.RGB16I),H===i.INT&&(ee=i.RGB32I)),T===i.RGBA_INTEGER&&(H===i.UNSIGNED_BYTE&&(ee=i.RGBA8UI),H===i.UNSIGNED_SHORT&&(ee=i.RGBA16UI),H===i.UNSIGNED_INT&&(ee=i.RGBA32UI),H===i.BYTE&&(ee=i.RGBA8I),H===i.SHORT&&(ee=i.RGBA16I),H===i.INT&&(ee=i.RGBA32I)),T===i.RGB&&(H===i.UNSIGNED_SHORT&&xe&&(ee=xe.RGB16_EXT),H===i.SHORT&&xe&&(ee=xe.RGB16_SNORM_EXT),H===i.UNSIGNED_INT_5_9_9_9_REV&&(ee=i.RGB9_E5),H===i.UNSIGNED_INT_10F_11F_11F_REV&&(ee=i.R11F_G11F_B10F)),T===i.RGBA){let ae=pe?Yo:tt.getTransfer(Q);H===i.FLOAT&&(ee=i.RGBA32F),H===i.HALF_FLOAT&&(ee=i.RGBA16F),H===i.UNSIGNED_BYTE&&(ee=ae===yt?i.SRGB8_ALPHA8:i.RGBA8),H===i.UNSIGNED_SHORT&&xe&&(ee=xe.RGBA16_EXT),H===i.SHORT&&xe&&(ee=xe.RGBA16_SNORM_EXT),H===i.UNSIGNED_SHORT_4_4_4_4&&(ee=i.RGBA4),H===i.UNSIGNED_SHORT_5_5_5_1&&(ee=i.RGB5_A1)}return(ee===i.R16F||ee===i.R32F||ee===i.RG16F||ee===i.RG32F||ee===i.RGBA16F||ee===i.RGBA32F)&&e.get("EXT_color_buffer_float"),ee}function S(N,T){let H;return N?T===null||T===ci||T===to?H=i.DEPTH24_STENCIL8:T===Vn?H=i.DEPTH32F_STENCIL8:T===eo&&(H=i.DEPTH24_STENCIL8,Fe("DepthTexture: 16 bit depth attachment is not supported with stencil. Using 24-bit attachment.")):T===null||T===ci||T===to?H=i.DEPTH_COMPONENT24:T===Vn?H=i.DEPTH_COMPONENT32F:T===eo&&(H=i.DEPTH_COMPONENT16),H}function M(N,T){return p(N)===!0||N.isFramebufferTexture&&N.minFilter!==Ht&&N.minFilter!==Gt?Math.log2(Math.max(T.width,T.height))+1:N.mipmaps!==void 0&&N.mipmaps.length>0?N.mipmaps.length:N.isCompressedTexture&&Array.isArray(N.image)?T.mipmaps.length:1}function E(N){let T=N.target;T.removeEventListener("dispose",E),w(T),T.isVideoTexture&&u.delete(T),T.isHTMLTexture&&h.delete(T)}function y(N){let T=N.target;T.removeEventListener("dispose",y),P(T)}function w(N){let T=n.get(N);if(T.__webglInit===void 0)return;let H=N.source,Y=d.get(H);if(Y){let Q=Y[T.__cacheKey];Q.usedTimes--,Q.usedTimes===0&&A(N),Object.keys(Y).length===0&&d.delete(H)}n.remove(N)}function A(N){let T=n.get(N);i.deleteTexture(T.__webglTexture);let H=N.source,Y=d.get(H);delete Y[T.__cacheKey],o.memory.textures--}function P(N){let T=n.get(N);if(N.depthTexture&&(N.depthTexture.dispose(),n.remove(N.depthTexture)),N.isWebGLCubeRenderTarget)for(let Y=0;Y<6;Y++){if(Array.isArray(T.__webglFramebuffer[Y]))for(let Q=0;Q<T.__webglFramebuffer[Y].length;Q++)i.deleteFramebuffer(T.__webglFramebuffer[Y][Q]);else i.deleteFramebuffer(T.__webglFramebuffer[Y]);T.__webglDepthbuffer&&i.deleteRenderbuffer(T.__webglDepthbuffer[Y])}else{if(Array.isArray(T.__webglFramebuffer))for(let Y=0;Y<T.__webglFramebuffer.length;Y++)i.deleteFramebuffer(T.__webglFramebuffer[Y]);else i.deleteFramebuffer(T.__webglFramebuffer);if(T.__webglDepthbuffer&&i.deleteRenderbuffer(T.__webglDepthbuffer),T.__webglMultisampledFramebuffer&&i.deleteFramebuffer(T.__webglMultisampledFramebuffer),T.__webglColorRenderbuffer)for(let Y=0;Y<T.__webglColorRenderbuffer.length;Y++)T.__webglColorRenderbuffer[Y]&&i.deleteRenderbuffer(T.__webglColorRenderbuffer[Y]);T.__webglDepthRenderbuffer&&i.deleteRenderbuffer(T.__webglDepthRenderbuffer)}let H=N.textures;for(let Y=0,Q=H.length;Y<Q;Y++){let pe=n.get(H[Y]);pe.__webglTexture&&(i.deleteTexture(pe.__webglTexture),o.memory.textures--),n.remove(H[Y])}n.remove(N)}let C=0;function D(){C=0}function L(){return C}function U(N){C=N}function G(){let N=C;return N>=s.maxTextures&&Fe("WebGLTextures: Trying to use "+(N+1)+" texture units while this GPU supports only "+s.maxTextures),C+=1,N}function Z(N){let T=[];return T.push(N.wrapS),T.push(N.wrapT),T.push(N.wrapR||0),T.push(N.magFilter),T.push(N.minFilter),T.push(N.anisotropy),T.push(N.internalFormat),T.push(N.format),T.push(N.type),T.push(N.generateMipmaps),T.push(N.premultiplyAlpha),T.push(N.flipY),T.push(N.unpackAlignment),T.push(N.colorSpace),T.join()}function oe(N,T){let H=n.get(N);if(N.isVideoTexture&&O(N),N.isRenderTargetTexture===!1&&N.isExternalTexture!==!0&&N.version>0&&H.__version!==N.version){let Y=N.image;if(Y===null)Fe("WebGLRenderer: Texture marked for update but no image data found.");else if(Y.complete===!1)Fe("WebGLRenderer: Texture marked for update but image is incomplete");else{j(H,N,T);return}}else N.isExternalTexture&&(H.__webglTexture=N.sourceTexture?N.sourceTexture:null);t.bindTexture(i.TEXTURE_2D,H.__webglTexture,i.TEXTURE0+T)}function K(N,T){let H=n.get(N);if(N.isRenderTargetTexture===!1&&N.version>0&&H.__version!==N.version){j(H,N,T);return}else N.isExternalTexture&&(H.__webglTexture=N.sourceTexture?N.sourceTexture:null);t.bindTexture(i.TEXTURE_2D_ARRAY,H.__webglTexture,i.TEXTURE0+T)}function te(N,T){let H=n.get(N);if(N.isRenderTargetTexture===!1&&N.version>0&&H.__version!==N.version){j(H,N,T);return}t.bindTexture(i.TEXTURE_3D,H.__webglTexture,i.TEXTURE0+T)}function se(N,T){let H=n.get(N);if(N.isCubeDepthTexture!==!0&&N.version>0&&H.__version!==N.version){me(H,N,T);return}t.bindTexture(i.TEXTURE_CUBE_MAP,H.__webglTexture,i.TEXTURE0+T)}let Re={[cs]:i.REPEAT,[Zn]:i.CLAMP_TO_EDGE,[Nr]:i.MIRRORED_REPEAT},Te={[Ht]:i.NEAREST,[Rl]:i.NEAREST_MIPMAP_NEAREST,[Zs]:i.NEAREST_MIPMAP_LINEAR,[Gt]:i.LINEAR,[Qr]:i.LINEAR_MIPMAP_NEAREST,[ai]:i.LINEAR_MIPMAP_LINEAR},nt={[lg]:i.NEVER,[pg]:i.ALWAYS,[ug]:i.LESS,[du]:i.LEQUAL,[hg]:i.EQUAL,[pu]:i.GEQUAL,[fg]:i.GREATER,[dg]:i.NOTEQUAL};function He(N,T){if(T.type===Vn&&e.has("OES_texture_float_linear")===!1&&(T.magFilter===Gt||T.magFilter===Qr||T.magFilter===Zs||T.magFilter===ai||T.minFilter===Gt||T.minFilter===Qr||T.minFilter===Zs||T.minFilter===ai)&&Fe("WebGLRenderer: Unable to use linear filtering with floating point textures. OES_texture_float_linear not supported on this device."),i.texParameteri(N,i.TEXTURE_WRAP_S,Re[T.wrapS]),i.texParameteri(N,i.TEXTURE_WRAP_T,Re[T.wrapT]),(N===i.TEXTURE_3D||N===i.TEXTURE_2D_ARRAY)&&i.texParameteri(N,i.TEXTURE_WRAP_R,Re[T.wrapR]),i.texParameteri(N,i.TEXTURE_MAG_FILTER,Te[T.magFilter]),i.texParameteri(N,i.TEXTURE_MIN_FILTER,Te[T.minFilter]),T.compareFunction&&(i.texParameteri(N,i.TEXTURE_COMPARE_MODE,i.COMPARE_REF_TO_TEXTURE),i.texParameteri(N,i.TEXTURE_COMPARE_FUNC,nt[T.compareFunction])),e.has("EXT_texture_filter_anisotropic")===!0){if(T.magFilter===Ht||T.minFilter!==Zs&&T.minFilter!==ai||T.type===Vn&&e.has("OES_texture_float_linear")===!1)return;if(T.anisotropy>1||n.get(T).__currentAnisotropy){let H=e.get("EXT_texture_filter_anisotropic");i.texParameterf(N,H.TEXTURE_MAX_ANISOTROPY_EXT,Math.min(T.anisotropy,s.getMaxAnisotropy())),n.get(T).__currentAnisotropy=T.anisotropy}}}function $e(N,T){let H=!1;N.__webglInit===void 0&&(N.__webglInit=!0,T.addEventListener("dispose",E));let Y=T.source,Q=d.get(Y);Q===void 0&&(Q={},d.set(Y,Q));let pe=Z(T);if(pe!==N.__cacheKey){Q[pe]===void 0&&(Q[pe]={texture:i.createTexture(),usedTimes:0},o.memory.textures++,H=!0),Q[pe].usedTimes++;let xe=Q[N.__cacheKey];xe!==void 0&&(Q[N.__cacheKey].usedTimes--,xe.usedTimes===0&&A(T)),N.__cacheKey=pe,N.__webglTexture=Q[pe].texture}return H}function $(N,T,H){return Math.floor(Math.floor(N/H)/T)}function z(N,T,H,Y){let pe=N.updateRanges;if(pe.length===0)t.texSubImage2D(i.TEXTURE_2D,0,0,0,T.width,T.height,H,Y,T.data);else{pe.sort((Oe,be)=>Oe.start-be.start);let xe=0;for(let Oe=1;Oe<pe.length;Oe++){let be=pe[xe],ye=pe[Oe],Be=be.start+be.count,Ge=$(ye.start,T.width,4),Je=$(be.start,T.width,4);ye.start<=Be+1&&Ge===Je&&$(ye.start+ye.count-1,T.width,4)===Ge?be.count=Math.max(be.count,ye.start+ye.count-be.start):(++xe,pe[xe]=ye)}pe.length=xe+1;let ee=t.getParameter(i.UNPACK_ROW_LENGTH),ae=t.getParameter(i.UNPACK_SKIP_PIXELS),_e=t.getParameter(i.UNPACK_SKIP_ROWS);t.pixelStorei(i.UNPACK_ROW_LENGTH,T.width);for(let Oe=0,be=pe.length;Oe<be;Oe++){let ye=pe[Oe],Be=Math.floor(ye.start/4),Ge=Math.ceil(ye.count/4),Je=Be%T.width,k=Math.floor(Be/T.width),ve=Ge,re=1;t.pixelStorei(i.UNPACK_SKIP_PIXELS,Je),t.pixelStorei(i.UNPACK_SKIP_ROWS,k),t.texSubImage2D(i.TEXTURE_2D,0,Je,k,ve,re,H,Y,T.data)}N.clearUpdateRanges(),t.pixelStorei(i.UNPACK_ROW_LENGTH,ee),t.pixelStorei(i.UNPACK_SKIP_PIXELS,ae),t.pixelStorei(i.UNPACK_SKIP_ROWS,_e)}}function j(N,T,H){let Y=i.TEXTURE_2D;(T.isDataArrayTexture||T.isCompressedArrayTexture)&&(Y=i.TEXTURE_2D_ARRAY),T.isData3DTexture&&(Y=i.TEXTURE_3D);let Q=$e(N,T),pe=T.source;t.bindTexture(Y,N.__webglTexture,i.TEXTURE0+H);let xe=n.get(pe);if(pe.version!==xe.__version||Q===!0){if(t.activeTexture(i.TEXTURE0+H),(typeof ImageBitmap<"u"&&T.image instanceof ImageBitmap)===!1){let re=tt.getPrimaries(tt.workingColorSpace),Se=T.colorSpace===Xi?null:tt.getPrimaries(T.colorSpace),Ae=T.colorSpace===Xi||re===Se?i.NONE:i.BROWSER_DEFAULT_WEBGL;t.pixelStorei(i.UNPACK_FLIP_Y_WEBGL,T.flipY),t.pixelStorei(i.UNPACK_PREMULTIPLY_ALPHA_WEBGL,T.premultiplyAlpha),t.pixelStorei(i.UNPACK_COLORSPACE_CONVERSION_WEBGL,Ae)}t.pixelStorei(i.UNPACK_ALIGNMENT,T.unpackAlignment);let ae=g(T.image,!1,s.maxTextureSize);ae=gt(T,ae);let _e=r.convert(T.format,T.colorSpace),Oe=r.convert(T.type),be=_(T.internalFormat,_e,Oe,T.normalized,T.colorSpace,T.isVideoTexture);He(Y,T);let ye,Be=T.mipmaps,Ge=T.isVideoTexture!==!0,Je=xe.__version===void 0||Q===!0,k=pe.dataReady,ve=M(T,ae);if(T.isDepthTexture)be=S(T.format===_s,T.type),Je&&(Ge?t.texStorage2D(i.TEXTURE_2D,1,be,ae.width,ae.height):t.texImage2D(i.TEXTURE_2D,0,be,ae.width,ae.height,0,_e,Oe,null));else if(T.isDataTexture)if(Be.length>0){Ge&&Je&&t.texStorage2D(i.TEXTURE_2D,ve,be,Be[0].width,Be[0].height);for(let re=0,Se=Be.length;re<Se;re++)ye=Be[re],Ge?k&&t.texSubImage2D(i.TEXTURE_2D,re,0,0,ye.width,ye.height,_e,Oe,ye.data):t.texImage2D(i.TEXTURE_2D,re,be,ye.width,ye.height,0,_e,Oe,ye.data);T.generateMipmaps=!1}else Ge?(Je&&t.texStorage2D(i.TEXTURE_2D,ve,be,ae.width,ae.height),k&&z(T,ae,_e,Oe)):t.texImage2D(i.TEXTURE_2D,0,be,ae.width,ae.height,0,_e,Oe,ae.data);else if(T.isCompressedTexture)if(T.isCompressedArrayTexture){Ge&&Je&&t.texStorage3D(i.TEXTURE_2D_ARRAY,ve,be,Be[0].width,Be[0].height,ae.depth);for(let re=0,Se=Be.length;re<Se;re++)if(ye=Be[re],T.format!==Hn)if(_e!==null)if(Ge){if(k)if(T.layerUpdates.size>0){let Ae=zf(ye.width,ye.height,T.format,T.type);for(let ue of T.layerUpdates){let ke=ye.data.subarray(ue*Ae/ye.data.BYTES_PER_ELEMENT,(ue+1)*Ae/ye.data.BYTES_PER_ELEMENT);t.compressedTexSubImage3D(i.TEXTURE_2D_ARRAY,re,0,0,ue,ye.width,ye.height,1,_e,ke)}}else t.compressedTexSubImage3D(i.TEXTURE_2D_ARRAY,re,0,0,0,ye.width,ye.height,ae.depth,_e,ye.data)}else t.compressedTexImage3D(i.TEXTURE_2D_ARRAY,re,be,ye.width,ye.height,ae.depth,0,ye.data,0,0);else Fe("WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()");else Ge?k&&t.texSubImage3D(i.TEXTURE_2D_ARRAY,re,0,0,0,ye.width,ye.height,ae.depth,_e,Oe,ye.data):t.texImage3D(i.TEXTURE_2D_ARRAY,re,be,ye.width,ye.height,ae.depth,0,_e,Oe,ye.data);T.layerUpdates.size>0&&T.clearLayerUpdates()}else{Ge&&Je&&t.texStorage2D(i.TEXTURE_2D,ve,be,Be[0].width,Be[0].height);for(let re=0,Se=Be.length;re<Se;re++)ye=Be[re],T.format!==Hn?_e!==null?Ge?k&&t.compressedTexSubImage2D(i.TEXTURE_2D,re,0,0,ye.width,ye.height,_e,ye.data):t.compressedTexImage2D(i.TEXTURE_2D,re,be,ye.width,ye.height,0,ye.data):Fe("WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()"):Ge?k&&t.texSubImage2D(i.TEXTURE_2D,re,0,0,ye.width,ye.height,_e,Oe,ye.data):t.texImage2D(i.TEXTURE_2D,re,be,ye.width,ye.height,0,_e,Oe,ye.data)}else if(T.isDataArrayTexture)if(Ge){if(Je&&t.texStorage3D(i.TEXTURE_2D_ARRAY,ve,be,ae.width,ae.height,ae.depth),k)if(T.layerUpdates.size>0){let re=zf(ae.width,ae.height,T.format,T.type);for(let Se of T.layerUpdates){let Ae=ae.data.subarray(Se*re/ae.data.BYTES_PER_ELEMENT,(Se+1)*re/ae.data.BYTES_PER_ELEMENT);t.texSubImage3D(i.TEXTURE_2D_ARRAY,0,0,0,Se,ae.width,ae.height,1,_e,Oe,Ae)}T.clearLayerUpdates()}else t.texSubImage3D(i.TEXTURE_2D_ARRAY,0,0,0,0,ae.width,ae.height,ae.depth,_e,Oe,ae.data)}else t.texImage3D(i.TEXTURE_2D_ARRAY,0,be,ae.width,ae.height,ae.depth,0,_e,Oe,ae.data);else if(T.isData3DTexture)Ge?(Je&&t.texStorage3D(i.TEXTURE_3D,ve,be,ae.width,ae.height,ae.depth),k&&t.texSubImage3D(i.TEXTURE_3D,0,0,0,0,ae.width,ae.height,ae.depth,_e,Oe,ae.data)):t.texImage3D(i.TEXTURE_3D,0,be,ae.width,ae.height,ae.depth,0,_e,Oe,ae.data);else if(T.isFramebufferTexture){if(Je)if(Ge)t.texStorage2D(i.TEXTURE_2D,ve,be,ae.width,ae.height);else{let re=ae.width,Se=ae.height;for(let Ae=0;Ae<ve;Ae++)t.texImage2D(i.TEXTURE_2D,Ae,be,re,Se,0,_e,Oe,null),re>>=1,Se>>=1}}else if(T.isHTMLTexture){if("texElementImage2D"in i){let re=i.canvas;if(re.hasAttribute("layoutsubtree")||re.setAttribute("layoutsubtree","true"),ae.parentNode!==re){re.appendChild(ae),h.add(T),re.onpaint=Se=>{let Ae=Se.changedElements;for(let ue of h)Ae.includes(ue.image)&&(ue.needsUpdate=!0)},re.requestPaint();return}if(i.texElementImage2D.length===3)i.texElementImage2D(i.TEXTURE_2D,i.RGBA8,ae);else{let Ae=i.RGBA,ue=i.RGBA,ke=i.UNSIGNED_BYTE;i.texElementImage2D(i.TEXTURE_2D,0,Ae,ue,ke,ae)}i.texParameteri(i.TEXTURE_2D,i.TEXTURE_MIN_FILTER,i.LINEAR),i.texParameteri(i.TEXTURE_2D,i.TEXTURE_WRAP_S,i.CLAMP_TO_EDGE),i.texParameteri(i.TEXTURE_2D,i.TEXTURE_WRAP_T,i.CLAMP_TO_EDGE)}}else if(Be.length>0){if(Ge&&Je){let re=rt(Be[0]);t.texStorage2D(i.TEXTURE_2D,ve,be,re.width,re.height)}for(let re=0,Se=Be.length;re<Se;re++)ye=Be[re],Ge?k&&t.texSubImage2D(i.TEXTURE_2D,re,0,0,_e,Oe,ye):t.texImage2D(i.TEXTURE_2D,re,be,_e,Oe,ye);T.generateMipmaps=!1}else if(Ge){if(Je){let re=rt(ae);t.texStorage2D(i.TEXTURE_2D,ve,be,re.width,re.height)}k&&t.texSubImage2D(i.TEXTURE_2D,0,0,0,_e,Oe,ae)}else t.texImage2D(i.TEXTURE_2D,0,be,_e,Oe,ae);p(T)&&v(Y),xe.__version=pe.version,T.onUpdate&&T.onUpdate(T)}N.__version=T.version}function me(N,T,H){if(T.image.length!==6)return;let Y=$e(N,T),Q=T.source;t.bindTexture(i.TEXTURE_CUBE_MAP,N.__webglTexture,i.TEXTURE0+H);let pe=n.get(Q);if(Q.version!==pe.__version||Y===!0){t.activeTexture(i.TEXTURE0+H);let xe=tt.getPrimaries(tt.workingColorSpace),ee=T.colorSpace===Xi?null:tt.getPrimaries(T.colorSpace),ae=T.colorSpace===Xi||xe===ee?i.NONE:i.BROWSER_DEFAULT_WEBGL;t.pixelStorei(i.UNPACK_FLIP_Y_WEBGL,T.flipY),t.pixelStorei(i.UNPACK_PREMULTIPLY_ALPHA_WEBGL,T.premultiplyAlpha),t.pixelStorei(i.UNPACK_ALIGNMENT,T.unpackAlignment),t.pixelStorei(i.UNPACK_COLORSPACE_CONVERSION_WEBGL,ae);let _e=T.isCompressedTexture||T.image[0].isCompressedTexture,Oe=T.image[0]&&T.image[0].isDataTexture,be=[];for(let ue=0;ue<6;ue++)!_e&&!Oe?be[ue]=g(T.image[ue],!0,s.maxCubemapSize):be[ue]=Oe?T.image[ue].image:T.image[ue],be[ue]=gt(T,be[ue]);let ye=be[0],Be=r.convert(T.format,T.colorSpace),Ge=r.convert(T.type),Je=_(T.internalFormat,Be,Ge,T.normalized,T.colorSpace),k=T.isVideoTexture!==!0,ve=pe.__version===void 0||Y===!0,re=Q.dataReady,Se=M(T,ye);He(i.TEXTURE_CUBE_MAP,T);let Ae;if(_e){k&&ve&&t.texStorage2D(i.TEXTURE_CUBE_MAP,Se,Je,ye.width,ye.height);for(let ue=0;ue<6;ue++){Ae=be[ue].mipmaps;for(let ke=0;ke<Ae.length;ke++){let De=Ae[ke];T.format!==Hn?Be!==null?k?re&&t.compressedTexSubImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+ue,ke,0,0,De.width,De.height,Be,De.data):t.compressedTexImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+ue,ke,Je,De.width,De.height,0,De.data):Fe("WebGLRenderer: Attempt to load unsupported compressed texture format in .setTextureCube()"):k?re&&t.texSubImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+ue,ke,0,0,De.width,De.height,Be,Ge,De.data):t.texImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+ue,ke,Je,De.width,De.height,0,Be,Ge,De.data)}}}else{if(Ae=T.mipmaps,k&&ve){Ae.length>0&&Se++;let ue=rt(be[0]);t.texStorage2D(i.TEXTURE_CUBE_MAP,Se,Je,ue.width,ue.height)}for(let ue=0;ue<6;ue++)if(Oe){k?re&&t.texSubImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+ue,0,0,0,be[ue].width,be[ue].height,Be,Ge,be[ue].data):t.texImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+ue,0,Je,be[ue].width,be[ue].height,0,Be,Ge,be[ue].data);for(let ke=0;ke<Ae.length;ke++){let Pt=Ae[ke].image[ue].image;k?re&&t.texSubImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+ue,ke+1,0,0,Pt.width,Pt.height,Be,Ge,Pt.data):t.texImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+ue,ke+1,Je,Pt.width,Pt.height,0,Be,Ge,Pt.data)}}else{k?re&&t.texSubImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+ue,0,0,0,Be,Ge,be[ue]):t.texImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+ue,0,Je,Be,Ge,be[ue]);for(let ke=0;ke<Ae.length;ke++){let De=Ae[ke];k?re&&t.texSubImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+ue,ke+1,0,0,Be,Ge,De.image[ue]):t.texImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+ue,ke+1,Je,Be,Ge,De.image[ue])}}}p(T)&&v(i.TEXTURE_CUBE_MAP),pe.__version=Q.version,T.onUpdate&&T.onUpdate(T)}N.__version=T.version}function fe(N,T,H,Y,Q,pe){let xe=r.convert(H.format,H.colorSpace),ee=r.convert(H.type),ae=_(H.internalFormat,xe,ee,H.normalized,H.colorSpace),_e=n.get(T),Oe=n.get(H);if(Oe.__renderTarget=T,!_e.__hasExternalTextures){let be=Math.max(1,T.width>>pe),ye=Math.max(1,T.height>>pe);Q===i.TEXTURE_3D||Q===i.TEXTURE_2D_ARRAY?t.texImage3D(Q,pe,ae,be,ye,T.depth,0,xe,ee,null):t.texImage2D(Q,pe,ae,be,ye,0,xe,ee,null)}t.bindFramebuffer(i.FRAMEBUFFER,N),ze(T)?a.framebufferTexture2DMultisampleEXT(i.FRAMEBUFFER,Y,Q,Oe.__webglTexture,0,he(T)):(Q===i.TEXTURE_2D||Q>=i.TEXTURE_CUBE_MAP_POSITIVE_X&&Q<=i.TEXTURE_CUBE_MAP_NEGATIVE_Z)&&i.framebufferTexture2D(i.FRAMEBUFFER,Y,Q,Oe.__webglTexture,pe),t.bindFramebuffer(i.FRAMEBUFFER,null)}function de(N,T,H){if(i.bindRenderbuffer(i.RENDERBUFFER,N),T.depthBuffer){let Y=T.depthTexture,Q=Y&&Y.isDepthTexture?Y.type:null,pe=S(T.stencilBuffer,Q),xe=T.stencilBuffer?i.DEPTH_STENCIL_ATTACHMENT:i.DEPTH_ATTACHMENT;ze(T)?a.renderbufferStorageMultisampleEXT(i.RENDERBUFFER,he(T),pe,T.width,T.height):H?i.renderbufferStorageMultisample(i.RENDERBUFFER,he(T),pe,T.width,T.height):i.renderbufferStorage(i.RENDERBUFFER,pe,T.width,T.height),i.framebufferRenderbuffer(i.FRAMEBUFFER,xe,i.RENDERBUFFER,N)}else{let Y=T.textures;for(let Q=0;Q<Y.length;Q++){let pe=Y[Q],xe=r.convert(pe.format,pe.colorSpace),ee=r.convert(pe.type),ae=_(pe.internalFormat,xe,ee,pe.normalized,pe.colorSpace);ze(T)?a.renderbufferStorageMultisampleEXT(i.RENDERBUFFER,he(T),ae,T.width,T.height):H?i.renderbufferStorageMultisample(i.RENDERBUFFER,he(T),ae,T.width,T.height):i.renderbufferStorage(i.RENDERBUFFER,ae,T.width,T.height)}}i.bindRenderbuffer(i.RENDERBUFFER,null)}function et(N,T,H){let Y=T.isWebGLCubeRenderTarget===!0;if(t.bindFramebuffer(i.FRAMEBUFFER,N),!(T.depthTexture&&T.depthTexture.isDepthTexture))throw new Error("THREE.WebGLTextures: renderTarget.depthTexture must be an instance of THREE.DepthTexture.");let Q=n.get(T.depthTexture);if(Q.__renderTarget=T,(!Q.__webglTexture||T.depthTexture.image.width!==T.width||T.depthTexture.image.height!==T.height)&&(T.depthTexture.image.width=T.width,T.depthTexture.image.height=T.height,T.depthTexture.needsUpdate=!0),Y){if(Q.__webglInit===void 0&&(Q.__webglInit=!0,T.depthTexture.addEventListener("dispose",E)),Q.__webglTexture===void 0){Q.__webglTexture=i.createTexture(),t.bindTexture(i.TEXTURE_CUBE_MAP,Q.__webglTexture),He(i.TEXTURE_CUBE_MAP,T.depthTexture);let _e=r.convert(T.depthTexture.format),Oe=r.convert(T.depthTexture.type),be;T.depthTexture.format===_i?be=i.DEPTH_COMPONENT24:T.depthTexture.format===_s&&(be=i.DEPTH24_STENCIL8);for(let ye=0;ye<6;ye++)i.texImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+ye,0,be,T.width,T.height,0,_e,Oe,null)}}else oe(T.depthTexture,0);let pe=Q.__webglTexture,xe=he(T),ee=Y?i.TEXTURE_CUBE_MAP_POSITIVE_X+H:i.TEXTURE_2D,ae=T.depthTexture.format===_s?i.DEPTH_STENCIL_ATTACHMENT:i.DEPTH_ATTACHMENT;if(T.depthTexture.format===_i)ze(T)?a.framebufferTexture2DMultisampleEXT(i.FRAMEBUFFER,ae,ee,pe,0,xe):i.framebufferTexture2D(i.FRAMEBUFFER,ae,ee,pe,0);else if(T.depthTexture.format===_s)ze(T)?a.framebufferTexture2DMultisampleEXT(i.FRAMEBUFFER,ae,ee,pe,0,xe):i.framebufferTexture2D(i.FRAMEBUFFER,ae,ee,pe,0);else throw new Error("THREE.WebGLTextures: Unknown depthTexture format.")}function ne(N){let T=n.get(N),H=N.isWebGLCubeRenderTarget===!0;if(T.__boundDepthTexture!==N.depthTexture){let Y=N.depthTexture;if(T.__depthDisposeCallback&&T.__depthDisposeCallback(),Y){let Q=()=>{delete T.__boundDepthTexture,delete T.__depthDisposeCallback,Y.removeEventListener("dispose",Q)};Y.addEventListener("dispose",Q),T.__depthDisposeCallback=Q}T.__boundDepthTexture=Y}if(N.depthTexture&&!T.__autoAllocateDepthBuffer)if(H)for(let Y=0;Y<6;Y++)et(T.__webglFramebuffer[Y],N,Y);else{let Y=N.texture.mipmaps;Y&&Y.length>0?et(T.__webglFramebuffer[0],N,0):et(T.__webglFramebuffer,N,0)}else if(H){T.__webglDepthbuffer=[];for(let Y=0;Y<6;Y++)if(t.bindFramebuffer(i.FRAMEBUFFER,T.__webglFramebuffer[Y]),T.__webglDepthbuffer[Y]===void 0)T.__webglDepthbuffer[Y]=i.createRenderbuffer(),de(T.__webglDepthbuffer[Y],N,!1);else{let Q=N.stencilBuffer?i.DEPTH_STENCIL_ATTACHMENT:i.DEPTH_ATTACHMENT,pe=T.__webglDepthbuffer[Y];i.bindRenderbuffer(i.RENDERBUFFER,pe),i.framebufferRenderbuffer(i.FRAMEBUFFER,Q,i.RENDERBUFFER,pe)}}else{let Y=N.texture.mipmaps;if(Y&&Y.length>0?t.bindFramebuffer(i.FRAMEBUFFER,T.__webglFramebuffer[0]):t.bindFramebuffer(i.FRAMEBUFFER,T.__webglFramebuffer),T.__webglDepthbuffer===void 0)T.__webglDepthbuffer=i.createRenderbuffer(),de(T.__webglDepthbuffer,N,!1);else{let Q=N.stencilBuffer?i.DEPTH_STENCIL_ATTACHMENT:i.DEPTH_ATTACHMENT,pe=T.__webglDepthbuffer;i.bindRenderbuffer(i.RENDERBUFFER,pe),i.framebufferRenderbuffer(i.FRAMEBUFFER,Q,i.RENDERBUFFER,pe)}}t.bindFramebuffer(i.FRAMEBUFFER,null)}function F(N,T,H){let Y=n.get(N);T!==void 0&&fe(Y.__webglFramebuffer,N,N.texture,i.COLOR_ATTACHMENT0,i.TEXTURE_2D,0),H!==void 0&&ne(N)}function V(N){let T=N.texture,H=n.get(N),Y=n.get(T);N.addEventListener("dispose",y);let Q=N.textures,pe=N.isWebGLCubeRenderTarget===!0,xe=Q.length>1;if(xe||(Y.__webglTexture===void 0&&(Y.__webglTexture=i.createTexture()),Y.__version=T.version,o.memory.textures++),pe){H.__webglFramebuffer=[];for(let ee=0;ee<6;ee++)if(T.mipmaps&&T.mipmaps.length>0){H.__webglFramebuffer[ee]=[];for(let ae=0;ae<T.mipmaps.length;ae++)H.__webglFramebuffer[ee][ae]=i.createFramebuffer()}else H.__webglFramebuffer[ee]=i.createFramebuffer()}else{if(T.mipmaps&&T.mipmaps.length>0){H.__webglFramebuffer=[];for(let ee=0;ee<T.mipmaps.length;ee++)H.__webglFramebuffer[ee]=i.createFramebuffer()}else H.__webglFramebuffer=i.createFramebuffer();if(xe)for(let ee=0,ae=Q.length;ee<ae;ee++){let _e=n.get(Q[ee]);_e.__webglTexture===void 0&&(_e.__webglTexture=i.createTexture(),o.memory.textures++)}if(N.samples>0&&ze(N)===!1){H.__webglMultisampledFramebuffer=i.createFramebuffer(),H.__webglColorRenderbuffer=[],t.bindFramebuffer(i.FRAMEBUFFER,H.__webglMultisampledFramebuffer);for(let ee=0;ee<Q.length;ee++){let ae=Q[ee];H.__webglColorRenderbuffer[ee]=i.createRenderbuffer(),i.bindRenderbuffer(i.RENDERBUFFER,H.__webglColorRenderbuffer[ee]);let _e=r.convert(ae.format,ae.colorSpace),Oe=r.convert(ae.type),be=_(ae.internalFormat,_e,Oe,ae.normalized,ae.colorSpace,N.isXRRenderTarget===!0),ye=he(N);i.renderbufferStorageMultisample(i.RENDERBUFFER,ye,be,N.width,N.height),i.framebufferRenderbuffer(i.FRAMEBUFFER,i.COLOR_ATTACHMENT0+ee,i.RENDERBUFFER,H.__webglColorRenderbuffer[ee])}i.bindRenderbuffer(i.RENDERBUFFER,null),N.depthBuffer&&(H.__webglDepthRenderbuffer=i.createRenderbuffer(),de(H.__webglDepthRenderbuffer,N,!0)),t.bindFramebuffer(i.FRAMEBUFFER,null)}}if(pe){t.bindTexture(i.TEXTURE_CUBE_MAP,Y.__webglTexture),He(i.TEXTURE_CUBE_MAP,T);for(let ee=0;ee<6;ee++)if(T.mipmaps&&T.mipmaps.length>0)for(let ae=0;ae<T.mipmaps.length;ae++)fe(H.__webglFramebuffer[ee][ae],N,T,i.COLOR_ATTACHMENT0,i.TEXTURE_CUBE_MAP_POSITIVE_X+ee,ae);else fe(H.__webglFramebuffer[ee],N,T,i.COLOR_ATTACHMENT0,i.TEXTURE_CUBE_MAP_POSITIVE_X+ee,0);p(T)&&v(i.TEXTURE_CUBE_MAP),t.unbindTexture()}else if(xe){for(let ee=0,ae=Q.length;ee<ae;ee++){let _e=Q[ee],Oe=n.get(_e),be=i.TEXTURE_2D;(N.isWebGL3DRenderTarget||N.isWebGLArrayRenderTarget)&&(be=N.isWebGL3DRenderTarget?i.TEXTURE_3D:i.TEXTURE_2D_ARRAY),t.bindTexture(be,Oe.__webglTexture),He(be,_e),fe(H.__webglFramebuffer,N,_e,i.COLOR_ATTACHMENT0+ee,be,0),p(_e)&&v(be)}t.unbindTexture()}else{let ee=i.TEXTURE_2D;if((N.isWebGL3DRenderTarget||N.isWebGLArrayRenderTarget)&&(ee=N.isWebGL3DRenderTarget?i.TEXTURE_3D:i.TEXTURE_2D_ARRAY),t.bindTexture(ee,Y.__webglTexture),He(ee,T),T.mipmaps&&T.mipmaps.length>0)for(let ae=0;ae<T.mipmaps.length;ae++)fe(H.__webglFramebuffer[ae],N,T,i.COLOR_ATTACHMENT0,ee,ae);else fe(H.__webglFramebuffer,N,T,i.COLOR_ATTACHMENT0,ee,0);p(T)&&v(ee),t.unbindTexture()}N.depthBuffer&&ne(N)}function q(N){let T=N.textures;for(let H=0,Y=T.length;H<Y;H++){let Q=T[H];if(p(Q)){let pe=b(N),xe=n.get(Q).__webglTexture;t.bindTexture(pe,xe),v(pe),t.unbindTexture()}}}let ie=[],le=[];function ge(N){if(N.samples>0){if(ze(N)===!1){let T=N.textures,H=N.width,Y=N.height,Q=i.COLOR_BUFFER_BIT,pe=N.stencilBuffer?i.DEPTH_STENCIL_ATTACHMENT:i.DEPTH_ATTACHMENT,xe=n.get(N),ee=T.length>1;if(ee)for(let _e=0;_e<T.length;_e++)t.bindFramebuffer(i.FRAMEBUFFER,xe.__webglMultisampledFramebuffer),i.framebufferRenderbuffer(i.FRAMEBUFFER,i.COLOR_ATTACHMENT0+_e,i.RENDERBUFFER,null),t.bindFramebuffer(i.FRAMEBUFFER,xe.__webglFramebuffer),i.framebufferTexture2D(i.DRAW_FRAMEBUFFER,i.COLOR_ATTACHMENT0+_e,i.TEXTURE_2D,null,0);t.bindFramebuffer(i.READ_FRAMEBUFFER,xe.__webglMultisampledFramebuffer);let ae=N.texture.mipmaps;ae&&ae.length>0?t.bindFramebuffer(i.DRAW_FRAMEBUFFER,xe.__webglFramebuffer[0]):t.bindFramebuffer(i.DRAW_FRAMEBUFFER,xe.__webglFramebuffer);for(let _e=0;_e<T.length;_e++){if(N.resolveDepthBuffer&&(N.depthBuffer&&(Q|=i.DEPTH_BUFFER_BIT),N.stencilBuffer&&N.resolveStencilBuffer&&(Q|=i.STENCIL_BUFFER_BIT)),ee){i.framebufferRenderbuffer(i.READ_FRAMEBUFFER,i.COLOR_ATTACHMENT0,i.RENDERBUFFER,xe.__webglColorRenderbuffer[_e]);let Oe=n.get(T[_e]).__webglTexture;i.framebufferTexture2D(i.DRAW_FRAMEBUFFER,i.COLOR_ATTACHMENT0,i.TEXTURE_2D,Oe,0)}i.blitFramebuffer(0,0,H,Y,0,0,H,Y,Q,i.NEAREST),c===!0&&(ie.length=0,le.length=0,ie.push(i.COLOR_ATTACHMENT0+_e),N.depthBuffer&&N.storeMultisampledDepthBuffer===!1&&(ie.push(pe),le.push(pe),i.invalidateFramebuffer(i.DRAW_FRAMEBUFFER,le)),i.invalidateFramebuffer(i.READ_FRAMEBUFFER,ie))}if(t.bindFramebuffer(i.READ_FRAMEBUFFER,null),t.bindFramebuffer(i.DRAW_FRAMEBUFFER,null),ee)for(let _e=0;_e<T.length;_e++){t.bindFramebuffer(i.FRAMEBUFFER,xe.__webglMultisampledFramebuffer),i.framebufferRenderbuffer(i.FRAMEBUFFER,i.COLOR_ATTACHMENT0+_e,i.RENDERBUFFER,xe.__webglColorRenderbuffer[_e]);let Oe=n.get(T[_e]).__webglTexture;t.bindFramebuffer(i.FRAMEBUFFER,xe.__webglFramebuffer),i.framebufferTexture2D(i.DRAW_FRAMEBUFFER,i.COLOR_ATTACHMENT0+_e,i.TEXTURE_2D,Oe,0)}t.bindFramebuffer(i.DRAW_FRAMEBUFFER,xe.__webglMultisampledFramebuffer)}else if(N.depthBuffer&&N.storeMultisampledDepthBuffer===!1&&c){let T=N.stencilBuffer?i.DEPTH_STENCIL_ATTACHMENT:i.DEPTH_ATTACHMENT;i.invalidateFramebuffer(i.DRAW_FRAMEBUFFER,[T])}}}function he(N){return Math.min(s.maxSamples,N.samples)}function ze(N){let T=n.get(N);return N.samples>0&&e.has("WEBGL_multisampled_render_to_texture")===!0&&T.__useRenderToTexture!==!1}function O(N){let T=o.render.frame;u.get(N)!==T&&(u.set(N,T),N.update())}function gt(N,T){let H=N.colorSpace,Y=N.format,Q=N.type;return N.isCompressedTexture===!0||N.isVideoTexture===!0||H!==bn&&H!==Xi&&(tt.getTransfer(H)===yt?(Y!==Hn||Q!==Dn)&&Fe("WebGLTextures: sRGB encoded textures have to use RGBAFormat and UnsignedByteType."):We("WebGLTextures: Unsupported texture color space:",H)),T}function rt(N){return typeof HTMLImageElement<"u"&&N instanceof HTMLImageElement?(l.width=N.naturalWidth||N.width,l.height=N.naturalHeight||N.height):typeof VideoFrame<"u"&&N instanceof VideoFrame?(l.width=N.displayWidth,l.height=N.displayHeight):(l.width=N.width,l.height=N.height),l}this.allocateTextureUnit=G,this.resetTextureUnits=D,this.getTextureUnits=L,this.setTextureUnits=U,this.setTexture2D=oe,this.setTexture2DArray=K,this.setTexture3D=te,this.setTextureCube=se,this.rebindTextures=F,this.setupRenderTarget=V,this.updateRenderTargetMipmap=q,this.updateMultisampleRenderTarget=ge,this.setupDepthRenderbuffer=ne,this.setupFrameBufferTexture=fe,this.useMultisampledRTT=ze,this.isReversedDepthBuffer=function(){return t.buffers.depth.getReversed()}}function JM(i,e){function t(n,s=Xi){let r,o=tt.getTransfer(s);if(n===Dn)return i.UNSIGNED_BYTE;if(n===Pl)return i.UNSIGNED_SHORT_4_4_4_4;if(n===Il)return i.UNSIGNED_SHORT_5_5_5_1;if(n===Af)return i.UNSIGNED_INT_5_9_9_9_REV;if(n===Rf)return i.UNSIGNED_INT_10F_11F_11F_REV;if(n===wf)return i.BYTE;if(n===Ef)return i.SHORT;if(n===eo)return i.UNSIGNED_SHORT;if(n===Cl)return i.INT;if(n===ci)return i.UNSIGNED_INT;if(n===Vn)return i.FLOAT;if(n===li)return i.HALF_FLOAT;if(n===Cf)return i.ALPHA;if(n===Pf)return i.RGB;if(n===Hn)return i.RGBA;if(n===_i)return i.DEPTH_COMPONENT;if(n===_s)return i.DEPTH_STENCIL;if(n===Ll)return i.RED;if(n===Nl)return i.RED_INTEGER;if(n===ys)return i.RG;if(n===Dl)return i.RG_INTEGER;if(n===Ul)return i.RGBA_INTEGER;if(n===La||n===Na||n===Da||n===Ua)if(o===yt)if(r=e.get("WEBGL_compressed_texture_s3tc_srgb"),r!==null){if(n===La)return r.COMPRESSED_SRGB_S3TC_DXT1_EXT;if(n===Na)return r.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;if(n===Da)return r.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;if(n===Ua)return r.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT}else return null;else if(r=e.get("WEBGL_compressed_texture_s3tc"),r!==null){if(n===La)return r.COMPRESSED_RGB_S3TC_DXT1_EXT;if(n===Na)return r.COMPRESSED_RGBA_S3TC_DXT1_EXT;if(n===Da)return r.COMPRESSED_RGBA_S3TC_DXT3_EXT;if(n===Ua)return r.COMPRESSED_RGBA_S3TC_DXT5_EXT}else return null;if(n===Fl||n===Ol||n===Bl||n===zl)if(r=e.get("WEBGL_compressed_texture_pvrtc"),r!==null){if(n===Fl)return r.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;if(n===Ol)return r.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;if(n===Bl)return r.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;if(n===zl)return r.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG}else return null;if(n===kl||n===Vl||n===Hl||n===Gl||n===Wl||n===Fa||n===Xl)if(r=e.get("WEBGL_compressed_texture_etc"),r!==null){if(n===kl||n===Vl)return o===yt?r.COMPRESSED_SRGB8_ETC2:r.COMPRESSED_RGB8_ETC2;if(n===Hl)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC:r.COMPRESSED_RGBA8_ETC2_EAC;if(n===Gl)return r.COMPRESSED_R11_EAC;if(n===Wl)return r.COMPRESSED_SIGNED_R11_EAC;if(n===Fa)return r.COMPRESSED_RG11_EAC;if(n===Xl)return r.COMPRESSED_SIGNED_RG11_EAC}else return null;if(n===ql||n===Yl||n===Zl||n===Kl||n===Jl||n===$l||n===jl||n===Ql||n===eu||n===tu||n===nu||n===iu||n===su||n===ru)if(r=e.get("WEBGL_compressed_texture_astc"),r!==null){if(n===ql)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR:r.COMPRESSED_RGBA_ASTC_4x4_KHR;if(n===Yl)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR:r.COMPRESSED_RGBA_ASTC_5x4_KHR;if(n===Zl)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR:r.COMPRESSED_RGBA_ASTC_5x5_KHR;if(n===Kl)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR:r.COMPRESSED_RGBA_ASTC_6x5_KHR;if(n===Jl)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR:r.COMPRESSED_RGBA_ASTC_6x6_KHR;if(n===$l)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR:r.COMPRESSED_RGBA_ASTC_8x5_KHR;if(n===jl)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR:r.COMPRESSED_RGBA_ASTC_8x6_KHR;if(n===Ql)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR:r.COMPRESSED_RGBA_ASTC_8x8_KHR;if(n===eu)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR:r.COMPRESSED_RGBA_ASTC_10x5_KHR;if(n===tu)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR:r.COMPRESSED_RGBA_ASTC_10x6_KHR;if(n===nu)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR:r.COMPRESSED_RGBA_ASTC_10x8_KHR;if(n===iu)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR:r.COMPRESSED_RGBA_ASTC_10x10_KHR;if(n===su)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR:r.COMPRESSED_RGBA_ASTC_12x10_KHR;if(n===ru)return o===yt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR:r.COMPRESSED_RGBA_ASTC_12x12_KHR}else return null;if(n===ou||n===au||n===cu)if(r=e.get("EXT_texture_compression_bptc"),r!==null){if(n===ou)return o===yt?r.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT:r.COMPRESSED_RGBA_BPTC_UNORM_EXT;if(n===au)return r.COMPRESSED_RGB_BPTC_SIGNED_FLOAT_EXT;if(n===cu)return r.COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_EXT}else return null;if(n===lu||n===uu||n===Oa||n===hu)if(r=e.get("EXT_texture_compression_rgtc"),r!==null){if(n===lu)return r.COMPRESSED_RED_RGTC1_EXT;if(n===uu)return r.COMPRESSED_SIGNED_RED_RGTC1_EXT;if(n===Oa)return r.COMPRESSED_RED_GREEN_RGTC2_EXT;if(n===hu)return r.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT}else return null;return n===to?i.UNSIGNED_INT_24_8:i[n]!==void 0?i[n]:null}return{convert:t}}var $M=`
void main() {

	gl_Position = vec4( position, 1.0 );

}`,jM=`
uniform sampler2DArray depthColor;
uniform float depthWidth;
uniform float depthHeight;

void main() {

	vec2 coord = vec2( gl_FragCoord.x / depthWidth, gl_FragCoord.y / depthHeight );

	if ( coord.x >= 1.0 ) {

		gl_FragDepth = texture( depthColor, vec3( coord.x - 1.0, coord.y, 1 ) ).r;

	} else {

		gl_FragDepth = texture( depthColor, vec3( coord.x, coord.y, 0 ) ).r;

	}

}`,sd=class{constructor(){this.texture=null,this.mesh=null,this.depthNear=0,this.depthFar=0}init(e,t){if(this.texture===null){let n=new ca(e.texture);(e.depthNear!==t.depthNear||e.depthFar!==t.depthFar)&&(this.depthNear=e.depthNear,this.depthFar=e.depthFar),this.texture=n}}getMesh(e){if(this.texture!==null&&this.mesh===null){let t=e.cameras[0].viewport,n=new ln({vertexShader:$M,fragmentShader:jM,uniforms:{depthColor:{value:this.texture},depthWidth:{value:t.z},depthHeight:{value:t.w}}});this.mesh=new it(new _a(20,20),n)}return this.mesh}reset(){this.texture=null,this.mesh=null}getDepthTexture(){return this.texture}},rd=class extends ri{constructor(e,t){super();let n=this,s=null,r=1,o=null,a="local-floor",c=1,l=null,u=null,h=null,f=null,d=null,m=null,x=typeof XRWebGLBinding<"u",g=new sd,p={},v=t.getContextAttributes(),b=null,_=null,S=[],M=[],E=new ce,y=null,w=null,A=new Yt;A.viewport=new ut;let P=new Yt;P.viewport=new ut;let C=[A,P],D=new Ml,L=null,U=null;this.cameraAutoUpdate=!0,this.enabled=!1,this.isPresenting=!1,this.getController=function($){let z=S[$];return z===void 0&&(z=new zr,S[$]=z),z.getTargetRaySpace()},this.getControllerGrip=function($){let z=S[$];return z===void 0&&(z=new zr,S[$]=z),z.getGripSpace()},this.getHand=function($){let z=S[$];return z===void 0&&(z=new zr,S[$]=z),z.getHandSpace()};function G($){let z=M.indexOf($.inputSource);if(z===-1)return;let j=S[z];j!==void 0&&(j.update($.inputSource,$.frame,l||o),j.dispatchEvent({type:$.type,data:$.inputSource}))}function Z(){s.removeEventListener("select",G),s.removeEventListener("selectstart",G),s.removeEventListener("selectend",G),s.removeEventListener("squeeze",G),s.removeEventListener("squeezestart",G),s.removeEventListener("squeezeend",G),s.removeEventListener("end",Z),s.removeEventListener("inputsourceschange",oe);for(let $=0;$<S.length;$++){let z=M[$];z!==null&&(M[$]=null,S[$].disconnect(z))}L=null,U=null,g.reset();for(let $ in p)delete p[$];if(e.setRenderTarget(b),d=null,f=null,h=null,s=null,_=null,$e.stop(),n.isPresenting=!1,e.setPixelRatio(y),e.setSize(E.width,E.height,!1),w!==null){let $=w.camera;$.fov=w.fov,$.zoom=w.zoom,$.updateProjectionMatrix(),w=null}n.dispatchEvent({type:"sessionend"})}this.setFramebufferScaleFactor=function($){r=$,n.isPresenting===!0&&Fe("WebXRManager: Cannot change framebuffer scale while presenting.")},this.setReferenceSpaceType=function($){a=$,n.isPresenting===!0&&Fe("WebXRManager: Cannot change reference space type while presenting.")},this.getReferenceSpace=function(){return l||o},this.setReferenceSpace=function($){l=$},this.getBaseLayer=function(){return f!==null?f:d},this.getBinding=function(){return h===null&&x&&(h=new XRWebGLBinding(s,t)),h},this.getFrame=function(){return m},this.getSession=function(){return s},this.setSession=async function($){if(s=$,s!==null){if(b=e.getRenderTarget(),s.addEventListener("select",G),s.addEventListener("selectstart",G),s.addEventListener("selectend",G),s.addEventListener("squeeze",G),s.addEventListener("squeezestart",G),s.addEventListener("squeezeend",G),s.addEventListener("end",Z),s.addEventListener("inputsourceschange",oe),v.xrCompatible!==!0&&await t.makeXRCompatible(),y=e.getPixelRatio(),e.getSize(E),x&&"createProjectionLayer"in XRWebGLBinding.prototype){let j=null,me=null,fe=null;v.depth&&(fe=v.stencil?t.DEPTH24_STENCIL8:t.DEPTH_COMPONENT24,j=v.stencil?_s:_i,me=v.stencil?to:ci);let de={colorFormat:t.RGBA8,depthFormat:fe,scaleFactor:r};h=this.getBinding(),f=h.createProjectionLayer(de),s.updateRenderState({layers:[f]}),e.setPixelRatio(1),e.setSize(f.textureWidth,f.textureHeight,!1),_=new Rn(f.textureWidth,f.textureHeight,{format:Hn,type:Dn,depthTexture:new hs(f.textureWidth,f.textureHeight,me,void 0,void 0,void 0,void 0,void 0,void 0,j),stencilBuffer:v.stencil,colorSpace:e.outputColorSpace,samples:v.antialias?4:0,resolveDepthBuffer:f.ignoreDepthValues===!1,resolveStencilBuffer:f.ignoreDepthValues===!1,storeMultisampledDepthBuffer:f.ignoreDepthValues===!1,storeMultisampledStencilBuffer:f.ignoreDepthValues===!1})}else{let j={antialias:v.antialias,alpha:!0,depth:v.depth,stencil:v.stencil,framebufferScaleFactor:r};d=new XRWebGLLayer(s,t,j),s.updateRenderState({baseLayer:d}),e.setPixelRatio(1),e.setSize(d.framebufferWidth,d.framebufferHeight,!1),_=new Rn(d.framebufferWidth,d.framebufferHeight,{format:Hn,type:Dn,colorSpace:e.outputColorSpace,stencilBuffer:v.stencil,resolveDepthBuffer:d.ignoreDepthValues===!1,resolveStencilBuffer:d.ignoreDepthValues===!1,storeMultisampledDepthBuffer:d.ignoreDepthValues===!1,storeMultisampledStencilBuffer:d.ignoreDepthValues===!1})}_.isXRRenderTarget=!0,this.setFoveation(c),l=null,o=await s.requestReferenceSpace(a),$e.setContext(s),$e.start(),n.isPresenting=!0,n.dispatchEvent({type:"sessionstart"})}},this.getEnvironmentBlendMode=function(){if(s!==null)return s.environmentBlendMode},this.getDepthTexture=function(){return g.getDepthTexture()};function oe($){for(let z=0;z<$.removed.length;z++){let j=$.removed[z],me=M.indexOf(j);me>=0&&(M[me]=null,S[me].disconnect(j))}for(let z=0;z<$.added.length;z++){let j=$.added[z],me=M.indexOf(j);if(me===-1){for(let de=0;de<S.length;de++)if(de>=M.length){M.push(j),me=de;break}else if(M[de]===null){M[de]=j,me=de;break}if(me===-1)break}let fe=S[me];fe&&fe.connect(j)}}let K=new I,te=new I;function se($,z,j){K.setFromMatrixPosition(z.matrixWorld),te.setFromMatrixPosition(j.matrixWorld);let me=K.distanceTo(te),fe=z.projectionMatrix.elements,de=j.projectionMatrix.elements,et=fe[14]/(fe[10]-1),ne=fe[14]/(fe[10]+1),F=(fe[9]+1)/fe[5],V=(fe[9]-1)/fe[5],q=(fe[8]-1)/fe[0],ie=(de[8]+1)/de[0],le=et*q,ge=et*ie,he=me/(-q+ie),ze=he*-q;if(z.matrixWorld.decompose($.position,$.quaternion,$.scale),$.translateX(ze),$.translateZ(he),$.matrixWorld.compose($.position,$.quaternion,$.scale),$.matrixWorldInverse.copy($.matrixWorld).invert(),fe[10]===-1)$.projectionMatrix.copy(z.projectionMatrix),$.projectionMatrixInverse.copy(z.projectionMatrixInverse);else{let O=et+he,gt=ne+he,rt=le-ze,N=ge+(me-ze),T=F*ne/gt*O,H=V*ne/gt*O;$.projectionMatrix.makePerspective(rt,N,T,H,O,gt),$.projectionMatrixInverse.copy($.projectionMatrix).invert()}}function Re($,z){z===null?$.matrixWorld.copy($.matrix):$.matrixWorld.multiplyMatrices(z.matrixWorld,$.matrix),$.matrixWorldInverse.copy($.matrixWorld).invert()}this.updateCamera=function($){if(s===null)return;let z=$.near,j=$.far;g.texture!==null&&(g.depthNear>0&&(z=g.depthNear),g.depthFar>0&&(j=g.depthFar)),D.near=P.near=A.near=z,D.far=P.far=A.far=j,(L!==D.near||U!==D.far)&&(s.updateRenderState({depthNear:D.near,depthFar:D.far}),L=D.near,U=D.far),D.layers.mask=$.layers.mask|6,A.layers.mask=D.layers.mask&-5,P.layers.mask=D.layers.mask&-3;let me=$.parent,fe=D.cameras;Re(D,me);for(let de=0;de<fe.length;de++)Re(fe[de],me);fe.length===2?se(D,A,P):D.projectionMatrix.copy(A.projectionMatrix),w===null&&$.isPerspectiveCamera&&(w={camera:$,fov:$.fov,zoom:$.zoom}),Te($,D,me)};function Te($,z,j){j===null?$.matrix.copy(z.matrixWorld):($.matrix.copy(j.matrixWorld),$.matrix.invert(),$.matrix.multiply(z.matrixWorld)),$.matrix.decompose($.position,$.quaternion,$.scale),$.updateMatrixWorld(!0),$.projectionMatrix.copy(z.projectionMatrix),$.projectionMatrixInverse.copy(z.projectionMatrixInverse),$.isPerspectiveCamera&&($.fov=Os*2*Math.atan(1/$.projectionMatrix.elements[5]),$.zoom=1)}this.getCamera=function(){return D},this.getFoveation=function(){if(!(f===null&&d===null))return c},this.setFoveation=function($){c=$,f!==null&&(f.fixedFoveation=$),d!==null&&d.fixedFoveation!==void 0&&(d.fixedFoveation=$)},this.hasDepthSensing=function(){return g.texture!==null},this.getDepthSensingMesh=function(){return g.getMesh(D)},this.getCameraTexture=function($){return p[$]};let nt=null;function He($,z){if(u=z.getViewerPose(l||o),m=z,u!==null){let j=u.views;d!==null&&(e.setRenderTargetFramebuffer(_,d.framebuffer),e.setRenderTarget(_));let me=!1;j.length!==D.cameras.length&&(D.cameras.length=0,me=!0);for(let ne=0;ne<j.length;ne++){let F=j[ne],V=null;if(d!==null)V=d.getViewport(F);else{let ie=h.getViewSubImage(f,F);V=ie.viewport,ne===0&&(e.setRenderTargetTextures(_,ie.colorTexture,ie.depthStencilTexture),e.setRenderTarget(_))}let q=C[ne];q===void 0&&(q=new Yt,q.layers.enable(ne),q.viewport=new ut,C[ne]=q),q.matrix.fromArray(F.transform.matrix),q.matrix.decompose(q.position,q.quaternion,q.scale),q.projectionMatrix.fromArray(F.projectionMatrix),q.projectionMatrixInverse.copy(q.projectionMatrix).invert(),q.viewport.set(V.x,V.y,V.width,V.height),ne===0&&(D.matrix.copy(q.matrix),D.matrix.decompose(D.position,D.quaternion,D.scale)),me===!0&&D.cameras.push(q)}let fe=s.enabledFeatures;if(fe&&fe.includes("depth-sensing")&&s.depthUsage=="gpu-optimized"&&x){h=n.getBinding();let ne=h.getDepthInformation(j[0]);ne&&ne.isValid&&ne.texture&&g.init(ne,s.renderState)}if(fe&&fe.includes("camera-access")&&x){e.state.unbindTexture(),h=n.getBinding();for(let ne=0;ne<j.length;ne++){let F=j[ne].camera;if(F){let V=p[F];V||(V=new ca,p[F]=V);let q=h.getCameraImage(F);V.sourceTexture=q}}}}for(let j=0;j<S.length;j++){let me=M[j],fe=S[j];me!==null&&fe!==void 0&&fe.update(me,z,l||o)}nt&&nt($,z),z.detectedPlanes&&n.dispatchEvent({type:"planesdetected",data:z}),m=null}let $e=new Zg;$e.setAnimationLoop(He),this.setAnimationLoop=function($){nt=$},this.dispose=function(){}}},QM=new Ie,e0=new Ye;e0.set(-1,0,0,0,1,0,0,0,1);function eT(i,e){function t(g,p){g.matrixAutoUpdate===!0&&g.updateMatrix(),p.value.copy(g.matrix)}function n(g,p){p.color.getRGB(g.fogColor.value,Ff(i)),p.isFog?(g.fogNear.value=p.near,g.fogFar.value=p.far):p.isFogExp2&&(g.fogDensity.value=p.density)}function s(g,p,v,b,_){p.isNodeMaterial?p.uniformsNeedUpdate=!1:p.isMeshBasicMaterial?r(g,p):p.isMeshLambertMaterial?(r(g,p),p.envMap&&(g.envMapIntensity.value=p.envMapIntensity)):p.isMeshToonMaterial?(r(g,p),h(g,p)):p.isMeshPhongMaterial?(r(g,p),u(g,p),p.envMap&&(g.envMapIntensity.value=p.envMapIntensity)):p.isMeshStandardMaterial?(r(g,p),f(g,p),p.isMeshPhysicalMaterial&&d(g,p,_)):p.isMeshMatcapMaterial?(r(g,p),m(g,p)):p.isMeshDepthMaterial?r(g,p):p.isMeshDistanceMaterial?(r(g,p),x(g,p)):p.isMeshNormalMaterial?r(g,p):p.isLineBasicMaterial?(o(g,p),p.isLineDashedMaterial&&a(g,p)):p.isPointsMaterial?c(g,p,v,b):p.isSpriteMaterial?l(g,p):p.isShadowMaterial?(g.color.value.copy(p.color),g.opacity.value=p.opacity):p.isShaderMaterial&&(p.uniformsNeedUpdate=!1)}function r(g,p){g.opacity.value=p.opacity,p.color&&g.diffuse.value.copy(p.color),p.emissive&&g.emissive.value.copy(p.emissive).multiplyScalar(p.emissiveIntensity),p.map&&(g.map.value=p.map,t(p.map,g.mapTransform)),p.alphaMap&&(g.alphaMap.value=p.alphaMap,t(p.alphaMap,g.alphaMapTransform)),p.bumpMap&&(g.bumpMap.value=p.bumpMap,t(p.bumpMap,g.bumpMapTransform),g.bumpScale.value=p.bumpScale,p.side===jt&&(g.bumpScale.value*=-1)),p.normalMap&&(g.normalMap.value=p.normalMap,t(p.normalMap,g.normalMapTransform),g.normalScale.value.copy(p.normalScale),p.side===jt&&g.normalScale.value.negate()),p.displacementMap&&(g.displacementMap.value=p.displacementMap,t(p.displacementMap,g.displacementMapTransform),g.displacementScale.value=p.displacementScale,g.displacementBias.value=p.displacementBias),p.emissiveMap&&(g.emissiveMap.value=p.emissiveMap,t(p.emissiveMap,g.emissiveMapTransform)),p.specularMap&&(g.specularMap.value=p.specularMap,t(p.specularMap,g.specularMapTransform)),p.alphaTest>0&&(g.alphaTest.value=p.alphaTest);let v=e.get(p),b=v.envMap,_=v.envMapRotation;b&&(g.envMap.value=b,g.envMapRotation.value.setFromMatrix4(QM.makeRotationFromEuler(_)).transpose(),b.isCubeTexture&&b.isRenderTargetTexture===!1&&g.envMapRotation.value.premultiply(e0),g.reflectivity.value=p.reflectivity,g.ior.value=p.ior,g.refractionRatio.value=p.refractionRatio),p.lightMap&&(g.lightMap.value=p.lightMap,g.lightMapIntensity.value=p.lightMapIntensity,t(p.lightMap,g.lightMapTransform)),p.aoMap&&(g.aoMap.value=p.aoMap,g.aoMapIntensity.value=p.aoMapIntensity,t(p.aoMap,g.aoMapTransform))}function o(g,p){g.diffuse.value.copy(p.color),g.opacity.value=p.opacity,p.map&&(g.map.value=p.map,t(p.map,g.mapTransform))}function a(g,p){g.dashSize.value=p.dashSize,g.totalSize.value=p.dashSize+p.gapSize,g.scale.value=p.scale}function c(g,p,v,b){g.diffuse.value.copy(p.color),g.opacity.value=p.opacity,g.size.value=p.size*v,g.scale.value=b*.5,p.map&&(g.map.value=p.map,t(p.map,g.uvTransform)),p.alphaMap&&(g.alphaMap.value=p.alphaMap,t(p.alphaMap,g.alphaMapTransform)),p.alphaTest>0&&(g.alphaTest.value=p.alphaTest)}function l(g,p){g.diffuse.value.copy(p.color),g.opacity.value=p.opacity,g.rotation.value=p.rotation,p.map&&(g.map.value=p.map,t(p.map,g.mapTransform)),p.alphaMap&&(g.alphaMap.value=p.alphaMap,t(p.alphaMap,g.alphaMapTransform)),p.alphaTest>0&&(g.alphaTest.value=p.alphaTest)}function u(g,p){g.specular.value.copy(p.specular),g.shininess.value=Math.max(p.shininess,1e-4)}function h(g,p){p.gradientMap&&(g.gradientMap.value=p.gradientMap)}function f(g,p){g.metalness.value=p.metalness,p.metalnessMap&&(g.metalnessMap.value=p.metalnessMap,t(p.metalnessMap,g.metalnessMapTransform)),g.roughness.value=p.roughness,p.roughnessMap&&(g.roughnessMap.value=p.roughnessMap,t(p.roughnessMap,g.roughnessMapTransform)),p.envMap&&(g.envMapIntensity.value=p.envMapIntensity)}function d(g,p,v){g.ior.value=p.ior,p.sheen>0&&(g.sheenColor.value.copy(p.sheenColor).multiplyScalar(p.sheen),g.sheenRoughness.value=p.sheenRoughness,p.sheenColorMap&&(g.sheenColorMap.value=p.sheenColorMap,t(p.sheenColorMap,g.sheenColorMapTransform)),p.sheenRoughnessMap&&(g.sheenRoughnessMap.value=p.sheenRoughnessMap,t(p.sheenRoughnessMap,g.sheenRoughnessMapTransform))),p.clearcoat>0&&(g.clearcoat.value=p.clearcoat,g.clearcoatRoughness.value=p.clearcoatRoughness,p.clearcoatMap&&(g.clearcoatMap.value=p.clearcoatMap,t(p.clearcoatMap,g.clearcoatMapTransform)),p.clearcoatRoughnessMap&&(g.clearcoatRoughnessMap.value=p.clearcoatRoughnessMap,t(p.clearcoatRoughnessMap,g.clearcoatRoughnessMapTransform)),p.clearcoatNormalMap&&(g.clearcoatNormalMap.value=p.clearcoatNormalMap,t(p.clearcoatNormalMap,g.clearcoatNormalMapTransform),g.clearcoatNormalScale.value.copy(p.clearcoatNormalScale),p.side===jt&&g.clearcoatNormalScale.value.negate())),p.dispersion>0&&(g.dispersion.value=p.dispersion),p.retroreflectivity>0&&(g.retroreflectivity.value=p.retroreflectivity),p.iridescence>0&&(g.iridescence.value=p.iridescence,g.iridescenceIOR.value=p.iridescenceIOR,g.iridescenceThicknessMinimum.value=p.iridescenceThicknessRange[0],g.iridescenceThicknessMaximum.value=p.iridescenceThicknessRange[1],p.iridescenceMap&&(g.iridescenceMap.value=p.iridescenceMap,t(p.iridescenceMap,g.iridescenceMapTransform)),p.iridescenceThicknessMap&&(g.iridescenceThicknessMap.value=p.iridescenceThicknessMap,t(p.iridescenceThicknessMap,g.iridescenceThicknessMapTransform))),p.transmission>0&&(g.transmission.value=p.transmission,g.transmissionSamplerMap.value=v.texture,g.transmissionSamplerSize.value.set(v.width,v.height),p.transmissionMap&&(g.transmissionMap.value=p.transmissionMap,t(p.transmissionMap,g.transmissionMapTransform)),g.thickness.value=p.thickness,p.thicknessMap&&(g.thicknessMap.value=p.thicknessMap,t(p.thicknessMap,g.thicknessMapTransform)),g.attenuationDistance.value=p.attenuationDistance,g.attenuationColor.value.copy(p.attenuationColor)),p.anisotropy>0&&(g.anisotropyVector.value.set(p.anisotropy*Math.cos(p.anisotropyRotation),p.anisotropy*Math.sin(p.anisotropyRotation)),p.anisotropyMap&&(g.anisotropyMap.value=p.anisotropyMap,t(p.anisotropyMap,g.anisotropyMapTransform))),g.specularIntensity.value=p.specularIntensity,g.specularColor.value.copy(p.specularColor),p.specularColorMap&&(g.specularColorMap.value=p.specularColorMap,t(p.specularColorMap,g.specularColorMapTransform)),p.specularIntensityMap&&(g.specularIntensityMap.value=p.specularIntensityMap,t(p.specularIntensityMap,g.specularIntensityMapTransform))}function m(g,p){p.matcap&&(g.matcap.value=p.matcap)}function x(g,p){let v=e.get(p).light;g.referencePosition.value.setFromMatrixPosition(v.matrixWorld),g.nearDistance.value=v.shadow.camera.near,g.farDistance.value=v.shadow.camera.far}return{refreshFogUniforms:n,refreshMaterialUniforms:s}}function tT(i,e,t,n){let s={},r={},o=[],a=i.getParameter(i.MAX_UNIFORM_BUFFER_BINDINGS);function c(_,S){let M=S.program;n.uniformBlockBinding(_,M)}function l(_,S){let M=s[_.id];M===void 0&&(g(_),M=u(_),s[_.id]=M,_.addEventListener("dispose",v));let E=S.program;n.updateUBOMapping(_,E);let y=e.render.frame;r[_.id]!==y&&(f(_),r[_.id]=y)}function u(_){let S=h();_.__bindingPointIndex=S;let M=i.createBuffer(),E=_.__size,y=_.usage;return i.bindBuffer(i.UNIFORM_BUFFER,M),i.bufferData(i.UNIFORM_BUFFER,E,y),i.bindBuffer(i.UNIFORM_BUFFER,null),i.bindBufferBase(i.UNIFORM_BUFFER,S,M),M}function h(){for(let _=0;_<a;_++)if(o.indexOf(_)===-1)return o.push(_),_;return We("WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached."),0}function f(_){let S=s[_.id],M=_.uniforms,E=_.__cache;i.bindBuffer(i.UNIFORM_BUFFER,S);for(let y=0,w=M.length;y<w;y++){let A=M[y];if(Array.isArray(A))for(let P=0,C=A.length;P<C;P++)d(A[P],y,P,E);else d(A,y,0,E)}i.bindBuffer(i.UNIFORM_BUFFER,null)}function d(_,S,M,E){if(x(_,S,M,E)===!0){let y=_.__offset,w=_.value;if(Array.isArray(w)){let A=0;for(let P=0;P<w.length;P++){let C=w[P],D=p(C);m(C,_.__data,A),typeof C!="number"&&typeof C!="boolean"&&!C.isMatrix3&&!ArrayBuffer.isView(C)&&(A+=D.storage/Float32Array.BYTES_PER_ELEMENT)}}else m(w,_.__data,0);i.bufferSubData(i.UNIFORM_BUFFER,y,_.__data)}}function m(_,S,M){typeof _=="number"||typeof _=="boolean"?S[0]=_:_.isMatrix3?(S[0]=_.elements[0],S[1]=_.elements[1],S[2]=_.elements[2],S[3]=0,S[4]=_.elements[3],S[5]=_.elements[4],S[6]=_.elements[5],S[7]=0,S[8]=_.elements[6],S[9]=_.elements[7],S[10]=_.elements[8],S[11]=0):ArrayBuffer.isView(_)?S.set(new _.constructor(_.buffer,_.byteOffset,S.length)):_.toArray(S,M)}function x(_,S,M,E){let y=_.value,w=S+"_"+M;if(E[w]===void 0)return typeof y=="number"||typeof y=="boolean"?E[w]=y:ArrayBuffer.isView(y)?E[w]=y.slice():E[w]=y.clone(),!0;{let A=E[w];if(typeof y=="number"||typeof y=="boolean"){if(A!==y)return E[w]=y,!0}else{if(ArrayBuffer.isView(y))return!0;if(A.equals(y)===!1)return A.copy(y),!0}}return!1}function g(_){let S=_.uniforms,M=0,E=16;for(let w=0,A=S.length;w<A;w++){let P=Array.isArray(S[w])?S[w]:[S[w]];for(let C=0,D=P.length;C<D;C++){let L=P[C],U=Array.isArray(L.value)?L.value:[L.value];for(let G=0,Z=U.length;G<Z;G++){let oe=U[G],K=p(oe),te=M%E,se=te%K.boundary,Re=te+se;M+=se,Re!==0&&E-Re<K.storage&&(M+=E-Re),L.__data=new Float32Array(K.storage/Float32Array.BYTES_PER_ELEMENT),L.__offset=M,M+=K.storage}}}let y=M%E;return y>0&&(M+=E-y),_.__size=M,_.__cache={},this}function p(_){let S={boundary:0,storage:0};return typeof _=="number"||typeof _=="boolean"?(S.boundary=4,S.storage=4):_.isVector2?(S.boundary=8,S.storage=8):_.isVector3||_.isColor?(S.boundary=16,S.storage=12):_.isVector4?(S.boundary=16,S.storage=16):_.isMatrix3?(S.boundary=48,S.storage=48):_.isMatrix4?(S.boundary=64,S.storage=64):_.isTexture?Fe("WebGLRenderer: Texture samplers can not be part of an uniforms group."):ArrayBuffer.isView(_)?(S.boundary=16,S.storage=_.byteLength):Fe("WebGLRenderer: Unsupported uniform value type.",_),S}function v(_){let S=_.target;S.removeEventListener("dispose",v);let M=o.indexOf(S.__bindingPointIndex);o.splice(M,1),i.deleteBuffer(s[S.id]),delete s[S.id],delete r[S.id]}function b(){for(let _ in s)i.deleteBuffer(s[_]);o=[],s={},r={}}return{bind:c,update:l,dispose:b}}var nT=new Uint16Array([12469,15057,12620,14925,13266,14620,13807,14376,14323,13990,14545,13625,14713,13328,14840,12882,14931,12528,14996,12233,15039,11829,15066,11525,15080,11295,15085,10976,15082,10705,15073,10495,13880,14564,13898,14542,13977,14430,14158,14124,14393,13732,14556,13410,14702,12996,14814,12596,14891,12291,14937,11834,14957,11489,14958,11194,14943,10803,14921,10506,14893,10278,14858,9960,14484,14039,14487,14025,14499,13941,14524,13740,14574,13468,14654,13106,14743,12678,14818,12344,14867,11893,14889,11509,14893,11180,14881,10751,14852,10428,14812,10128,14765,9754,14712,9466,14764,13480,14764,13475,14766,13440,14766,13347,14769,13070,14786,12713,14816,12387,14844,11957,14860,11549,14868,11215,14855,10751,14825,10403,14782,10044,14729,9651,14666,9352,14599,9029,14967,12835,14966,12831,14963,12804,14954,12723,14936,12564,14917,12347,14900,11958,14886,11569,14878,11247,14859,10765,14828,10401,14784,10011,14727,9600,14660,9289,14586,8893,14508,8533,15111,12234,15110,12234,15104,12216,15092,12156,15067,12010,15028,11776,14981,11500,14942,11205,14902,10752,14861,10393,14812,9991,14752,9570,14682,9252,14603,8808,14519,8445,14431,8145,15209,11449,15208,11451,15202,11451,15190,11438,15163,11384,15117,11274,15055,10979,14994,10648,14932,10343,14871,9936,14803,9532,14729,9218,14645,8742,14556,8381,14461,8020,14365,7603,15273,10603,15272,10607,15267,10619,15256,10631,15231,10614,15182,10535,15118,10389,15042,10167,14963,9787,14883,9447,14800,9115,14710,8665,14615,8318,14514,7911,14411,7507,14279,7198,15314,9675,15313,9683,15309,9712,15298,9759,15277,9797,15229,9773,15166,9668,15084,9487,14995,9274,14898,8910,14800,8539,14697,8234,14590,7790,14479,7409,14367,7067,14178,6621,15337,8619,15337,8631,15333,8677,15325,8769,15305,8871,15264,8940,15202,8909,15119,8775,15022,8565,14916,8328,14804,8009,14688,7614,14569,7287,14448,6888,14321,6483,14088,6171,15350,7402,15350,7419,15347,7480,15340,7613,15322,7804,15287,7973,15229,8057,15148,8012,15046,7846,14933,7611,14810,7357,14682,7069,14552,6656,14421,6316,14251,5948,14007,5528,15356,5942,15356,5977,15353,6119,15348,6294,15332,6551,15302,6824,15249,7044,15171,7122,15070,7050,14949,6861,14818,6611,14679,6349,14538,6067,14398,5651,14189,5311,13935,4958,15359,4123,15359,4153,15356,4296,15353,4646,15338,5160,15311,5508,15263,5829,15188,6042,15088,6094,14966,6001,14826,5796,14678,5543,14527,5287,14377,4985,14133,4586,13869,4257,15360,1563,15360,1642,15358,2076,15354,2636,15341,3350,15317,4019,15273,4429,15203,4732,15105,4911,14981,4932,14836,4818,14679,4621,14517,4386,14359,4156,14083,3795,13808,3437,15360,122,15360,137,15358,285,15355,636,15344,1274,15322,2177,15281,2765,15215,3223,15120,3451,14995,3569,14846,3567,14681,3466,14511,3305,14344,3121,14037,2800,13753,2467,15360,0,15360,1,15359,21,15355,89,15346,253,15325,479,15287,796,15225,1148,15133,1492,15008,1749,14856,1882,14685,1886,14506,1783,14324,1608,13996,1398,13702,1183]),bi=null;function iT(){return bi===null&&(bi=new Hr(nT,16,16,ys,li),bi.name="DFG_LUT",bi.minFilter=Gt,bi.magFilter=Gt,bi.wrapS=Zn,bi.wrapT=Zn,bi.generateMipmaps=!1,bi.needsUpdate=!0),bi}var yu=class{constructor(e={}){let{canvas:t=mg(),context:n=null,depth:s=!0,stencil:r=!1,alpha:o=!1,antialias:a=!1,premultipliedAlpha:c=!0,preserveDrawingBuffer:l=!1,powerPreference:u="default",failIfMajorPerformanceCaveat:h=!1,reversedDepthBuffer:f=!1,outputBufferType:d=Dn}=e;this.isWebGLRenderer=!0;let m;if(n!==null){if(typeof WebGLRenderingContext<"u"&&n instanceof WebGLRenderingContext)throw new Error("THREE.WebGLRenderer: WebGL 1 is not supported since r163.");m=n.getContextAttributes().alpha}else m=o;let x=d,g=new Set([Ul,Dl,Nl]),p=new Set([Dn,ci,eo,to,Pl,Il]),v=new Uint32Array(4),b=new Int32Array(4),_=new I,S=null,M=null,E=[],y=[],w=null;this.domElement=t,this.debug={checkShaderErrors:!0,diagnostics:{keywords:!1},onShaderError:null},this.autoClear=!0,this.autoClearColor=!0,this.autoClearDepth=!0,this.autoClearStencil=!0,this.sortObjects=!0,this.clippingPlanes=[],this.localClippingEnabled=!1,this.toneMapping=oi,this.toneMappingExposure=1,this.transmissionResolutionScale=1;let A=this,P=!1,C=null,D=null,L=null,U=null;this._outputColorSpace=Ft;let G=0,Z=0,oe=null,K=-1,te=null,se=new ut,Re=new ut,Te=null,nt=new Ve(0),He=0,$e=t.width,$=t.height,z=1,j=null,me=null,fe=new ut(0,0,$e,$),de=new ut(0,0,$e,$),et=!1,ne=new Gr,F=!1,V=!1,q=new Ie,ie=new I,le=new ut,ge={background:null,fog:null,environment:null,overrideMaterial:null,isScene:!0},he=!1;function ze(){return oe===null?z:1}let O=n;function gt(R,B){return t.getContext(R,B)}let rt,N,T,H,Y,Q,pe,xe,ee,ae,_e,Oe,be,ye,Be,Ge,Je,k,ve,re,Se,Ae,ue;try{let R={alpha:!0,depth:s,stencil:r,antialias:a,premultipliedAlpha:c,preserveDrawingBuffer:l,powerPreference:u,failIfMajorPerformanceCaveat:h};if("setAttribute"in t&&t.setAttribute("data-engine",`three.js r${"186"}`),t.addEventListener("webglcontextlost",Pt,!1),t.addEventListener("webglcontextrestored",xt,!1),t.addEventListener("webglcontextcreationerror",Qn,!1),O===null){let B="webgl2";if(O=gt(B,R),O===null)throw gt(B)?new Error("THREE.WebGLRenderer: Error creating WebGL context with your selected attributes."):new Error("THREE.WebGLRenderer: Error creating WebGL context.")}ke()}catch(R){throw t.removeEventListener("webglcontextlost",Pt,!1),t.removeEventListener("webglcontextrestored",xt,!1),t.removeEventListener("webglcontextcreationerror",Qn,!1),We("WebGLRenderer: "+R.message),R}function ke(){rt=new ub(O),rt.init(),Se=new JM(O,rt),N=new eb(O,rt,e,Se),T=new ZM(O,rt),N.reversedDepthBuffer&&f&&T.buffers.depth.setReversed(!0),D=O.createFramebuffer(),L=O.createFramebuffer(),U=O.createFramebuffer(),H=new db(O),Y=new DM,Q=new KM(O,rt,T,Y,N,Se,H),pe=new lb(A),xe=new my(O),Ae=new jS(O,xe),ee=new hb(O,xe,H,Ae),ae=new mb(O,ee,xe,Ae,H),k=new pb(O,N,Q),Be=new tb(Y),_e=new NM(A,pe,rt,N,Ae,Be),Oe=new eT(A,Y),be=new FM,ye=new HM(rt),Je=new $S(A,pe,T,ae,m,c),Ge=new YM(A,ae,N),ue=new tT(O,H,N,T),ve=new QS(O,rt,H),re=new fb(O,rt,H),H.programs=_e.programs,A.capabilities=N,A.extensions=rt,A.properties=Y,A.renderLists=be,A.shadowMap=Ge,A.state=T,A.info=H}x!==Dn&&(w=new xb(x,t.width,t.height,a,s,r));let De=new rd(A,O);this.xr=De,this.getContext=function(){return O},this.getContextAttributes=function(){return O.getContextAttributes()},this.forceContextLoss=function(){let R=rt.get("WEBGL_lose_context");R&&R.loseContext()},this.forceContextRestore=function(){let R=rt.get("WEBGL_lose_context");R&&R.restoreContext()},this.getPixelRatio=function(){return z},this.setPixelRatio=function(R){R!==void 0&&(z=R,this.setSize($e,$,!1))},this.getSize=function(R){return R.set($e,$)},this.setSize=function(R,B,J=!0){if(De.isPresenting){Fe("WebGLRenderer: Can't change size while VR device is presenting.");return}$e=R,$=B,t.width=Math.floor(R*z),t.height=Math.floor(B*z),J===!0&&(t.style.width=R+"px",t.style.height=B+"px"),w!==null&&w.setSize(t.width,t.height),this.setViewport(0,0,R,B)},this.getDrawingBufferSize=function(R){return R.set($e*z,$*z).floor()},this.setDrawingBufferSize=function(R,B,J){$e=R,$=B,z=J,t.width=Math.floor(R*J),t.height=Math.floor(B*J),this.setViewport(0,0,R,B)},this.setEffects=function(R){if(x===Dn){We("WebGLRenderer: setEffects() requires outputBufferType set to HalfFloatType or FloatType.");return}if(R){for(let B=0;B<R.length;B++)if(R[B].isOutputPass===!0){Fe("WebGLRenderer: OutputPass is not needed in setEffects(). Tone mapping and color space conversion are applied automatically.");break}}w.setEffects(R||[])},this.getCurrentViewport=function(R){return R.copy(se)},this.getViewport=function(R){return R.copy(fe)},this.setViewport=function(R,B,J,W){R.isVector4?fe.set(R.x,R.y,R.z,R.w):fe.set(R,B,J,W),T.viewport(se.copy(fe).multiplyScalar(z).round())},this.getScissor=function(R){return R.copy(de)},this.setScissor=function(R,B,J,W){R.isVector4?de.set(R.x,R.y,R.z,R.w):de.set(R,B,J,W),T.scissor(Re.copy(de).multiplyScalar(z).round())},this.getScissorTest=function(){return et},this.setScissorTest=function(R){T.setScissorTest(et=R)},this.setOpaqueSort=function(R){j=R},this.setTransparentSort=function(R){me=R},this.getClearColor=function(R){return R.copy(Je.getClearColor())},this.setClearColor=function(){Je.setClearColor(...arguments)},this.getClearAlpha=function(){return Je.getClearAlpha()},this.setClearAlpha=function(){Je.setClearAlpha(...arguments)},this.clear=function(R=!0,B=!0,J=!0){let W=0;if(R){let X=!1;if(oe!==null){let Ee=oe.texture.format;X=g.has(Ee)}if(X){let Ee=oe.texture.type,Pe=p.has(Ee),we=Je.getClearColor(),Le=Je.getClearAlpha(),Ue=we.r,je=we.g,ot=we.b;Pe?(v[0]=Ue,v[1]=je,v[2]=ot,v[3]=Le,O.clearBufferuiv(O.COLOR,0,v)):(b[0]=Ue,b[1]=je,b[2]=ot,b[3]=Le,O.clearBufferiv(O.COLOR,0,b))}else W|=O.COLOR_BUFFER_BIT}B&&(W|=O.DEPTH_BUFFER_BIT,this.state.buffers.depth.setMask(!0)),J&&(W|=O.STENCIL_BUFFER_BIT,this.state.buffers.stencil.setMask(4294967295)),W!==0&&O.clear(W)},this.clearColor=function(){this.clear(!0,!1,!1)},this.clearDepth=function(){this.clear(!1,!0,!1)},this.clearStencil=function(){this.clear(!1,!1,!0)},this.setNodesHandler=function(R){R.setRenderer(this),C=R},this.dispose=function(){t.removeEventListener("webglcontextlost",Pt,!1),t.removeEventListener("webglcontextrestored",xt,!1),t.removeEventListener("webglcontextcreationerror",Qn,!1),Je.dispose(),be.dispose(),ye.dispose(),Y.dispose(),pe.dispose(),ae.dispose(),Ae.dispose(),ue.dispose(),_e.dispose(),De.dispose(),De.removeEventListener("sessionstart",Lp),De.removeEventListener("sessionend",Np),Rs.stop()};function Pt(R){R.preventDefault(),Zo("WebGLRenderer: Context Lost."),P=!0}function xt(){Zo("WebGLRenderer: Context Restored."),P=!1;let R=H.autoReset,B=Ge.enabled,J=Ge.autoUpdate,W=Ge.needsUpdate,X=Ge.type;ke(),H.autoReset=R,Ge.enabled=B,Ge.autoUpdate=J,Ge.needsUpdate=W,Ge.type=X}function Qn(R){We("WebGLRenderer: A WebGL context could not be created. Reason: ",R.statusMessage)}function pi(R){let B=R.target;B.removeEventListener("dispose",pi),Ix(B)}function Ix(R){Lx(R),Y.remove(R)}function Lx(R){let B=Y.get(R).programs;B!==void 0&&(B.forEach(function(J){_e.releaseProgram(J)}),R.isShaderMaterial&&_e.releaseShaderCache(R))}this.renderBufferDirect=function(R,B,J,W,X,Ee){B===null&&(B=ge);let Pe=X.isMesh&&X.matrixWorld.determinantAffine()<0,we=Ux(R,B,J,W,X);T.setMaterial(W,Pe);let Le=J.index,Ue=1;if(W.wireframe===!0){if(Le=ee.getWireframeAttribute(J),Le===void 0)return;Ue=2}let je=J.drawRange,ot=J.attributes.position,Ne=je.start*Ue,_t=(je.start+je.count)*Ue;Ee!==null&&(Ne=Math.max(Ne,Ee.start*Ue),_t=Math.min(_t,(Ee.start+Ee.count)*Ue)),Le!==null?(Ne=Math.max(Ne,0),_t=Math.min(_t,Le.count)):ot!=null&&(Ne=Math.max(Ne,0),_t=Math.min(_t,ot.count));let Xt=_t-Ne;if(Xt<0||Xt===1/0)return;Ae.setup(X,W,we,J,Le);let Lt,Et=ve;if(Le!==null&&(Lt=xe.get(Le),Et=re,Et.setIndex(Lt)),X.isMesh)W.wireframe===!0?(T.setLineWidth(W.wireframeLinewidth*ze()),Et.setMode(O.LINES)):Et.setMode(O.TRIANGLES);else if(X.isLine){let hn=W.linewidth;hn===void 0&&(hn=1),T.setLineWidth(hn*ze()),X.isLineSegments?Et.setMode(O.LINES):X.isLineLoop?Et.setMode(O.LINE_LOOP):Et.setMode(O.LINE_STRIP)}else X.isPoints?Et.setMode(O.POINTS):X.isSprite&&Et.setMode(O.TRIANGLES);if(X.isBatchedMesh)if(rt.get("WEBGL_multi_draw"))Et.renderMultiDraw(X._multiDrawStarts,X._multiDrawCounts,X._multiDrawCount);else{let hn=X._multiDrawStarts,Ce=X._multiDrawCounts,vn=X._multiDrawCount,ct=Le?xe.get(Le).bytesPerElement:1,qn=Y.get(W).currentProgram.getUniforms();for(let mi=0;mi<vn;mi++)qn.setValue(O,"_gl_DrawID",mi),Et.render(hn[mi]/ct,Ce[mi])}else if(X.isInstancedMesh)Et.renderInstances(Ne,Xt,X.count);else if(J.isInstancedBufferGeometry){let hn=J._maxInstanceCount!==void 0?J._maxInstanceCount:1/0,Ce=Math.min(J.instanceCount,hn);Et.renderInstances(Ne,Xt,Ce)}else Et.render(Ne,Xt)};function Ip(R,B,J,W){C!==null&&R.isNodeMaterial&&C.setObject(W,R),F===!0&&Be.setState(R,J,!1),R.transparent===!0&&R.side===Dt&&R.forceSinglePass===!1?(R.side=jt,R.needsUpdate=!0,fc(R,B,W),R.side=kn,R.needsUpdate=!0,fc(R,B,W),R.side=Dt):fc(R,B,W)}this.compile=function(R,B,J=null){J===null&&(J=R),C!==null&&C.renderStart(R,B,J),M=ye.get(J),M.init(B),y.push(M),J.traverseVisible(function(X){X.isLight&&X.layers.test(B.layers)&&(M.pushLight(X),X.castShadow&&M.pushShadow(X))}),R!==J&&R.traverseVisible(function(X){X.isLight&&X.layers.test(B.layers)&&(M.pushLight(X),X.castShadow&&M.pushShadow(X))}),M.setupLights(),C!==null&&C.updateLights(M.state.lightsArray),V=this.localClippingEnabled,F=Be.init(this.clippingPlanes,V),F===!0&&Be.setGlobalState(this.clippingPlanes,B),C!==null&&Ge.render(M.state.shadowsArray,J,B);let W=new Set;return R.traverse(function(X){if(!(X.isMesh||X.isPoints||X.isLine||X.isSprite))return;let Ee=X.material;if(Ee)if(Array.isArray(Ee))for(let Pe=0;Pe<Ee.length;Pe++){let we=Ee[Pe];Ip(we,J,B,X),W.add(we)}else Ip(Ee,J,B,X),W.add(Ee)}),M=y.pop(),C!==null&&C.renderEnd(),W},this.compileAsync=function(R,B,J=null){let W=this.compile(R,B,J);return new Promise(X=>{function Ee(){if(W.forEach(function(Pe){let Le=Y.get(Pe).currentProgram;(Le===void 0||Le.isReady())&&W.delete(Pe)}),W.size===0){X(R);return}setTimeout(Ee,10)}rt.get("KHR_parallel_shader_compile")!==null?Ee():setTimeout(Ee,10)})};let gh=null;function Nx(R){gh&&gh(R)}function Lp(){Rs.stop()}function Np(){Rs.start()}let Rs=new Zg;Rs.setAnimationLoop(Nx),typeof self<"u"&&Rs.setContext(self),this.setAnimationLoop=function(R){gh=R,De.setAnimationLoop(R),R===null?Rs.stop():Rs.start()},De.addEventListener("sessionstart",Lp),De.addEventListener("sessionend",Np),this.render=function(R,B){if(B!==void 0&&B.isCamera!==!0){We("WebGLRenderer.render: camera is not an instance of THREE.Camera.");return}if(P===!0)return;C!==null&&C.renderStart(R,B);let J=De.enabled===!0&&De.isPresenting===!0,W=w!==null&&(oe===null||J)&&w.begin(A,oe);if(R.matrixWorldAutoUpdate===!0&&R.updateMatrixWorld(),B.parent===null&&B.matrixWorldAutoUpdate===!0&&B.updateMatrixWorld(),De.enabled===!0&&De.isPresenting===!0&&(w===null||w.isCompositing()===!1)&&(De.cameraAutoUpdate===!0&&De.updateCamera(B),B=De.getCamera()),R.isScene===!0&&R.onBeforeRender(A,R,B,oe),M=ye.get(R,y.length),M.init(B),M.state.textureUnits=Q.getTextureUnits(),y.push(M),q.multiplyMatrices(B.projectionMatrix,B.matrixWorldInverse),ne.setFromProjectionMatrix(q,si,B.reversedDepth),V=this.localClippingEnabled,F=Be.init(this.clippingPlanes,V),S=be.get(R,E.length),S.init(),E.push(S),De.enabled===!0&&De.isPresenting===!0){let Pe=A.xr.getDepthSensingMesh();Pe!==null&&xh(Pe,B,-1/0,A.sortObjects)}xh(R,B,0,A.sortObjects),S.finish(),C!==null&&C.updateLights(M.state.lightsArray),A.sortObjects===!0&&S.sort(j,me),he=De.enabled===!1||De.isPresenting===!1||De.hasDepthSensing()===!1,he&&Je.addToRenderList(S,R),this.info.render.frame++,this.info.autoReset===!0&&this.info.reset(),F===!0&&Be.beginShadows();let X=M.state.shadowsArray;if(Ge.render(X,R,B),F===!0&&Be.endShadows(),(W&&w.hasRenderPass())===!1){let Pe=S.opaque,we=S.transmissive;if(M.setupLights(),B.isArrayCamera){let Le=B.cameras;if(we.length>0)for(let Ue=0,je=Le.length;Ue<je;Ue++){let ot=Le[Ue];Up(Pe,we,R,ot)}he&&Je.render(R);for(let Ue=0,je=Le.length;Ue<je;Ue++){let ot=Le[Ue];Dp(S,R,ot,ot.viewport)}}else we.length>0&&Up(Pe,we,R,B),he&&Je.render(R),Dp(S,R,B)}oe!==null&&Z===0&&(Q.updateMultisampleRenderTarget(oe),Q.updateRenderTargetMipmap(oe)),W&&w.end(A),R.isScene===!0&&R.onAfterRender(A,R,B),Ae.resetDefaultState(),K=-1,te=null,y.pop(),y.length>0?(M=y[y.length-1],Q.setTextureUnits(M.state.textureUnits),F===!0&&Be.setGlobalState(A.clippingPlanes,M.state.camera)):M=null,E.pop(),E.length>0?S=E[E.length-1]:S=null,C!==null&&C.renderEnd()};function xh(R,B,J,W){if(R.visible===!1)return;if(R.layers.test(B.layers)){if(R.isGroup)J=R.renderOrder;else if(R.isLOD)R.autoUpdate===!0&&R.update(B);else if(R.isLightProbeGrid)M.pushLightProbeGrid(R);else if(R.isLight)M.pushLight(R),R.castShadow&&M.pushShadow(R);else if(R.isSprite){if(!R.frustumCulled||R.intersectsFrustum(ne)){W&&le.setFromMatrixPosition(R.matrixWorld).applyMatrix4(q);let Pe=ae.update(R),we=R.material;we.visible&&S.push(R,Pe,we,J,le.z,null,B)}}else if((R.isMesh||R.isLine||R.isPoints)&&(!R.frustumCulled||R.intersectsFrustum(ne))){let Pe=ae.update(R),we=R.material;if(W&&(R.boundingSphere!==void 0?(R.boundingSphere===null&&R.computeBoundingSphere(),le.copy(R.boundingSphere.center)):(Pe.boundingSphere===null&&Pe.computeBoundingSphere(),le.copy(Pe.boundingSphere.center)),le.applyMatrix4(R.matrixWorld).applyMatrix4(q)),Array.isArray(we)){let Le=Pe.groups;for(let Ue=0,je=Le.length;Ue<je;Ue++){let ot=Le[Ue],Ne=we[ot.materialIndex];Ne&&Ne.visible&&S.push(R,Pe,Ne,J,le.z,ot,B)}}else we.visible&&S.push(R,Pe,we,J,le.z,null,B)}}let Ee=R.children;for(let Pe=0,we=Ee.length;Pe<we;Pe++)xh(Ee[Pe],B,J,W)}function Dp(R,B,J,W){let{opaque:X,transmissive:Ee,transparent:Pe}=R;M.setupLightsView(J),F===!0&&Be.setGlobalState(A.clippingPlanes,J),W&&T.viewport(se.copy(W)),X.length>0&&hc(X,B,J),Ee.length>0&&hc(Ee,B,J),Pe.length>0&&hc(Pe,B,J),T.buffers.depth.setTest(!0),T.buffers.depth.setMask(!0),T.buffers.color.setMask(!0),T.setPolygonOffset(!1)}function Up(R,B,J,W){if((J.isScene===!0?J.overrideMaterial:null)!==null)return;if(M.state.transmissionRenderTarget[W.id]===void 0){let Ne=rt.has("EXT_color_buffer_half_float")||rt.has("EXT_color_buffer_float");M.state.transmissionRenderTarget[W.id]=new Rn(1,1,{generateMipmaps:!0,type:Ne?li:Dn,minFilter:ai,samples:Math.max(4,N.samples),stencilBuffer:r,resolveDepthBuffer:!1,resolveStencilBuffer:!1,storeMultisampledDepthBuffer:!1,storeMultisampledStencilBuffer:!1,colorSpace:tt.workingColorSpace})}let Ee=M.state.transmissionRenderTarget[W.id],Pe=W.viewport||se;Ee.setSize(Pe.z*A.transmissionResolutionScale,Pe.w*A.transmissionResolutionScale);let we=A.getRenderTarget(),Le=A.getActiveCubeFace(),Ue=A.getActiveMipmapLevel();A.setRenderTarget(Ee),A.getClearColor(nt),He=A.getClearAlpha(),He<1&&A.setClearColor(16777215,.5),A.clear(),he&&Je.render(J);let je=A.toneMapping;A.toneMapping=oi;let ot=W.viewport;if(W.viewport!==void 0&&(W.viewport=void 0),M.setupLightsView(W),F===!0&&Be.setGlobalState(A.clippingPlanes,W),hc(R,J,W),Q.updateMultisampleRenderTarget(Ee),Q.updateRenderTargetMipmap(Ee),rt.has("WEBGL_multisampled_render_to_texture")===!1){let Ne=!1;for(let _t=0,Xt=B.length;_t<Xt;_t++){let Lt=B[_t],{object:Et,geometry:hn,material:Ce,group:vn}=Lt;if(Ce.side===Dt&&Et.layers.test(W.layers)){let ct=Ce.side;Ce.side=jt,Ce.needsUpdate=!0,Fp(Et,J,W,hn,Ce,vn),Ce.side=ct,Ce.needsUpdate=!0,Ne=!0}}Ne===!0&&(Q.updateMultisampleRenderTarget(Ee),Q.updateRenderTargetMipmap(Ee))}A.setRenderTarget(we,Le,Ue),A.setClearColor(nt,He),ot!==void 0&&(W.viewport=ot),A.toneMapping=je}function hc(R,B,J){let W=B.isScene===!0?B.overrideMaterial:null;for(let X=0,Ee=R.length;X<Ee;X++){let Pe=R[X],{object:we,geometry:Le,group:Ue}=Pe,je=Pe.material;je.allowOverride===!0&&W!==null&&(je=W),we.layers.test(J.layers)&&Fp(we,B,J,Le,je,Ue)}}function Fp(R,B,J,W,X,Ee){C!==null&&X.isNodeMaterial&&C.setObject(R,X),R.onBeforeRender(A,B,J,W,X,Ee),R.modelViewMatrix.multiplyMatrices(J.matrixWorldInverse,R.matrixWorld),R.normalMatrix.getNormalMatrix(R.modelViewMatrix),X.onBeforeRender(A,B,J,W,R,Ee),X.transparent===!0&&X.side===Dt&&X.forceSinglePass===!1?(X.side=jt,X.needsUpdate=!0,A.renderBufferDirect(J,B,W,X,R,Ee),X.side=kn,X.needsUpdate=!0,A.renderBufferDirect(J,B,W,X,R,Ee),X.side=Dt):A.renderBufferDirect(J,B,W,X,R,Ee),R.onAfterRender(A,B,J,W,X,Ee)}function fc(R,B,J){B.isScene!==!0&&(B=ge);let W=Y.get(R),X=M.state.lights,Ee=M.state.shadowsArray,Pe=X.state.version,we=_e.getParameters(R,X.state,Ee,B,J,M.state.lightProbeGridArray),Le=_e.getProgramCacheKey(we),Ue=W.programs;W.environment=R.isMeshStandardMaterial||R.isMeshLambertMaterial||R.isMeshPhongMaterial?B.environment:null,W.fog=B.fog;let je=R.isMeshStandardMaterial||R.isMeshLambertMaterial&&!R.envMap||R.isMeshPhongMaterial&&!R.envMap;W.envMap=pe.get(R.envMap||W.environment,je),W.envMapRotation=W.environment!==null&&R.envMap===null?B.environmentRotation:R.envMapRotation,Ue===void 0&&(R.addEventListener("dispose",pi),Ue=new Map,W.programs=Ue);let ot=Ue.get(Le);if(ot!==void 0){if(W.currentProgram===ot&&W.lightsStateVersion===Pe)return Bp(R,we),ot}else we.uniforms=_e.getUniforms(R),C!==null&&R.isNodeMaterial&&C.build(R,J,we),R.onBeforeCompile(we,A),ot=_e.acquireProgram(we,Le),Ue.set(Le,ot),W.uniforms=we.uniforms;let Ne=W.uniforms;return(!R.isShaderMaterial&&!R.isRawShaderMaterial||R.clipping===!0)&&(Ne.clippingPlanes=Be.uniform),Bp(R,we),W.needsLights=Ox(R),W.lightsStateVersion=Pe,W.needsLights&&(Ne.ambientLightColor.value=X.state.ambient,Ne.lightProbe.value=X.state.probe,Ne.sunLights.value=X.state.sun,Ne.sunLightShadows.value=X.state.sunShadow,Ne.directionalLights.value=X.state.directional,Ne.directionalLightShadows.value=X.state.directionalShadow,Ne.spotLights.value=X.state.spot,Ne.spotLightShadows.value=X.state.spotShadow,Ne.rectAreaLights.value=X.state.rectArea,Ne.ltc_1.value=X.state.rectAreaLTC1,Ne.ltc_2.value=X.state.rectAreaLTC2,Ne.pointLights.value=X.state.point,Ne.pointLightShadows.value=X.state.pointShadow,Ne.hemisphereLights.value=X.state.hemi,Ne.sunShadowMatrix.value=X.state.sunShadowMatrix,Ne.sunShadowCascade.value=X.state.sunShadowCascade,Ne.directionalShadowMatrix.value=X.state.directionalShadowMatrix,Ne.spotLightMatrix.value=X.state.spotLightMatrix,Ne.spotLightMap.value=X.state.spotLightMap,Ne.pointShadowMatrix.value=X.state.pointShadowMatrix),W.lightProbeGrid=M.state.lightProbeGridArray.length>0,W.currentProgram=ot,W.uniformsList=null,ot}function Op(R){if(R.uniformsList===null){let B=R.currentProgram.getUniforms();R.uniformsList=ro.seqWithValue(B.seq,R.uniforms)}return R.uniformsList}function Bp(R,B){let J=Y.get(R);J.outputColorSpace=B.outputColorSpace,J.batching=B.batching,J.batchingColor=B.batchingColor,J.instancing=B.instancing,J.instancingColor=B.instancingColor,J.instancingMorph=B.instancingMorph,J.skinning=B.skinning,J.morphTargets=B.morphTargets,J.morphNormals=B.morphNormals,J.morphColors=B.morphColors,J.morphTargetsCount=B.morphTargetsCount,J.numClippingPlanes=B.numClippingPlanes,J.numIntersection=B.numClipIntersection,J.vertexAlphas=B.vertexAlphas,J.vertexTangents=B.vertexTangents,J.toneMapping=B.toneMapping}function Dx(R,B){if(R.length===0)return null;if(R.length===1)return R[0].texture!==null?R[0]:null;_.setFromMatrixPosition(B.matrixWorld);for(let J=0,W=R.length;J<W;J++){let X=R[J];if(X.texture!==null&&X.boundingBox.containsPoint(_))return X}return null}function Ux(R,B,J,W,X){B.isScene!==!0&&(B=ge),Q.resetTextureUnits();let Ee=B.fog,Pe=W.isMeshStandardMaterial||W.isMeshLambertMaterial||W.isMeshPhongMaterial?B.environment:null,we=oe===null?A.outputColorSpace:oe.isXRRenderTarget===!0?oe.texture.colorSpace:tt.workingColorSpace,Le=W.isMeshStandardMaterial||W.isMeshLambertMaterial&&!W.envMap||W.isMeshPhongMaterial&&!W.envMap,Ue=pe.get(W.envMap||Pe,Le),je=W.vertexColors===!0&&!!J.attributes.color&&J.attributes.color.itemSize===4,ot=!!J.attributes.tangent&&(!!W.normalMap||W.anisotropy>0),Ne=!!J.morphAttributes.position,_t=!!J.morphAttributes.normal,Xt=!!J.morphAttributes.color,Lt=oi;W.toneMapped&&(oe===null||oe.isXRRenderTarget===!0)&&(Lt=A.toneMapping);let Et=J.morphAttributes.position||J.morphAttributes.normal||J.morphAttributes.color,hn=Et!==void 0?Et.length:0,Ce=Y.get(W),vn=M.state.lights;if(F===!0&&(V===!0||R!==te)){let It=R===te&&W.id===K;Be.setState(W,R,It)}let ct=!1;W.version===Ce.__version?(Ce.needsLights&&Ce.lightsStateVersion!==vn.state.version||Ce.outputColorSpace!==we||X.isBatchedMesh&&Ce.batching===!1||!X.isBatchedMesh&&Ce.batching===!0||X.isBatchedMesh&&Ce.batchingColor===!0&&X._colorsTexture===null||X.isBatchedMesh&&Ce.batchingColor===!1&&X._colorsTexture!==null||X.isInstancedMesh&&Ce.instancing===!1||!X.isInstancedMesh&&Ce.instancing===!0||X.isSkinnedMesh&&Ce.skinning===!1||!X.isSkinnedMesh&&Ce.skinning===!0||X.isInstancedMesh&&Ce.instancingColor===!0&&X.instanceColor===null||X.isInstancedMesh&&Ce.instancingColor===!1&&X.instanceColor!==null||X.isInstancedMesh&&Ce.instancingMorph===!0&&X.morphTexture===null||X.isInstancedMesh&&Ce.instancingMorph===!1&&X.morphTexture!==null||Ce.envMap!==Ue||W.fog===!0&&Ce.fog!==Ee||Ce.numClippingPlanes!==void 0&&(Ce.numClippingPlanes!==Be.numPlanes||Ce.numIntersection!==Be.numIntersection)||Ce.vertexAlphas!==je||Ce.vertexTangents!==ot||Ce.morphTargets!==Ne||Ce.morphNormals!==_t||Ce.morphColors!==Xt||Ce.toneMapping!==Lt||Ce.morphTargetsCount!==hn||!!Ce.lightProbeGrid!=M.state.lightProbeGridArray.length>0)&&(ct=!0):(ct=!0,Ce.__version=W.version);let qn=Ce.currentProgram;ct===!0&&(qn=fc(W,B,X),C&&W.isNodeMaterial&&C.onUpdateProgram(W,qn,Ce));let mi=!1,Qi=!1,lr=!1,Mt=qn.getUniforms(),Vt=Ce.uniforms;if(T.useProgram(qn.program)&&(mi=!0,Qi=!0,lr=!0),W.id!==K&&(K=W.id,Qi=!0),Ce.needsLights){let It=Dx(M.state.lightProbeGridArray,X);Ce.lightProbeGrid!==It&&(Ce.lightProbeGrid=It,Qi=!0)}if(mi||te!==R){T.buffers.depth.getReversed()&&R.reversedDepth!==!0&&(R._reversedDepth=!0,R.updateProjectionMatrix()),Mt.setValue(O,"projectionMatrix",R.projectionMatrix),Mt.setValue(O,"viewMatrix",R.matrixWorldInverse);let ts=Mt.map.cameraPosition;ts!==void 0&&ts.setValue(O,ie.setFromMatrixPosition(R.matrixWorld)),N.logarithmicDepthBuffer&&Mt.setValue(O,"logDepthBufFC",2/(Math.log(R.far+1)/Math.LN2)),(W.isMeshPhongMaterial||W.isMeshToonMaterial||W.isMeshLambertMaterial||W.isMeshBasicMaterial||W.isMeshStandardMaterial||W.isShaderMaterial)&&Mt.setValue(O,"isOrthographic",R.isOrthographicCamera===!0),te!==R&&(te=R,Qi=!0,lr=!0)}if(Ce.needsLights&&(vn.state.sunShadowMap.length>0&&Mt.setValue(O,"sunShadowMap",vn.state.sunShadowMap,Q),vn.state.directionalShadowMap.length>0&&Mt.setValue(O,"directionalShadowMap",vn.state.directionalShadowMap,Q),vn.state.spotShadowMap.length>0&&Mt.setValue(O,"spotShadowMap",vn.state.spotShadowMap,Q),vn.state.pointShadowMap.length>0&&Mt.setValue(O,"pointShadowMap",vn.state.pointShadowMap,Q)),X.isSkinnedMesh){Mt.setOptional(O,X,"bindMatrix"),Mt.setOptional(O,X,"bindMatrixInverse");let It=X.skeleton;It&&(It.boneTexture===null&&It.computeBoneTexture(),Mt.setValue(O,"boneTexture",It.boneTexture,Q))}X.isBatchedMesh&&(Mt.setOptional(O,X,"batchingTexture"),Mt.setValue(O,"batchingTexture",X._matricesTexture,Q),Mt.setOptional(O,X,"batchingIdTexture"),Mt.setValue(O,"batchingIdTexture",X._indirectTexture,Q),Mt.setOptional(O,X,"batchingColorTexture"),X._colorsTexture!==null&&Mt.setValue(O,"batchingColorTexture",X._colorsTexture,Q));let es=J.morphAttributes;if((es.position!==void 0||es.normal!==void 0||es.color!==void 0)&&k.update(X,J,qn),(Qi||Ce.receiveShadow!==X.receiveShadow)&&(Ce.receiveShadow=X.receiveShadow,Mt.setValue(O,"receiveShadow",X.receiveShadow)),(W.isMeshStandardMaterial||W.isMeshLambertMaterial||W.isMeshPhongMaterial)&&W.envMap===null&&B.environment!==null&&(Vt.envMapIntensity.value=B.environmentIntensity),Vt.dfgLUT!==void 0&&(Vt.dfgLUT.value=iT()),Qi){if(Mt.setValue(O,"toneMappingExposure",A.toneMappingExposure),Ce.needsLights&&Fx(Vt,lr),Ee&&W.fog===!0&&Oe.refreshFogUniforms(Vt,Ee),Oe.refreshMaterialUniforms(Vt,W,z,$,M.state.transmissionRenderTarget[R.id]),Ce.needsLights&&Ce.lightProbeGrid){let It=Ce.lightProbeGrid;Vt.probesSH.value=It.texture,Vt.probesMin.value.copy(It.boundingBox.min),Vt.probesMax.value.copy(It.boundingBox.max),Vt.probesResolution.value.copy(It.resolution)}ro.upload(O,Op(Ce),Vt,Q)}if(W.isShaderMaterial&&W.uniformsNeedUpdate===!0&&(ro.upload(O,Op(Ce),Vt,Q),W.uniformsNeedUpdate=!1),W.isSpriteMaterial&&Mt.setValue(O,"center",X.center),Mt.setValue(O,"modelViewMatrix",X.modelViewMatrix),Mt.setValue(O,"normalMatrix",X.normalMatrix),Mt.setValue(O,"modelMatrix",X.matrixWorld),W.uniformsGroups!==void 0){let It=W.uniformsGroups;for(let ts=0,ur=It.length;ts<ur;ts++){let kp=It[ts];ue.update(kp,qn),ue.bind(kp,qn)}}return qn}function Fx(R,B){R.ambientLightColor.needsUpdate=B,R.lightProbe.needsUpdate=B,R.sunLights.needsUpdate=B,R.sunLightShadows.needsUpdate=B,R.directionalLights.needsUpdate=B,R.directionalLightShadows.needsUpdate=B,R.pointLights.needsUpdate=B,R.pointLightShadows.needsUpdate=B,R.spotLights.needsUpdate=B,R.spotLightShadows.needsUpdate=B,R.rectAreaLights.needsUpdate=B,R.hemisphereLights.needsUpdate=B}function Ox(R){return R.isMeshLambertMaterial||R.isMeshToonMaterial||R.isMeshPhongMaterial||R.isMeshStandardMaterial||R.isShadowMaterial||R.isShaderMaterial&&R.lights===!0}this.getActiveCubeFace=function(){return G},this.getActiveMipmapLevel=function(){return Z},this.getRenderTarget=function(){return oe},this.setRenderTargetTextures=function(R,B,J){let W=Y.get(R);W.__autoAllocateDepthBuffer=R.resolveDepthBuffer===!1,W.__autoAllocateDepthBuffer===!1&&(W.__useRenderToTexture=!1),Y.get(R.texture).__webglTexture=B,Y.get(R.depthTexture).__webglTexture=W.__autoAllocateDepthBuffer?void 0:J,W.__hasExternalTextures=!0},this.setRenderTargetFramebuffer=function(R,B){let J=Y.get(R);J.__webglFramebuffer=B,J.__useDefaultFramebuffer=B===void 0},this.setRenderTarget=function(R,B=0,J=0){oe=R,G=B,Z=J;let W=null,X=!1,Ee=!1;if(R){let we=Y.get(R);if(we.__useDefaultFramebuffer!==void 0){T.bindFramebuffer(O.FRAMEBUFFER,we.__webglFramebuffer),se.copy(R.viewport),Re.copy(R.scissor),Te=R.scissorTest,T.viewport(se),T.scissor(Re),T.setScissorTest(Te),K=-1;return}else if(we.__webglFramebuffer===void 0)Q.setupRenderTarget(R);else if(we.__hasExternalTextures)Q.rebindTextures(R,Y.get(R.texture).__webglTexture,Y.get(R.depthTexture).__webglTexture);else if(R.depthBuffer){let je=R.depthTexture;if(we.__boundDepthTexture!==je){if(je!==null&&Y.has(je)&&(R.width!==je.image.width||R.height!==je.image.height))throw new Error("THREE.WebGLRenderer: Attached DepthTexture is initialized to the incorrect size.");Q.setupDepthRenderbuffer(R)}}let Le=R.texture;(Le.isData3DTexture||Le.isDataArrayTexture||Le.isCompressedArrayTexture)&&(Ee=!0);let Ue=Y.get(R).__webglFramebuffer;R.isWebGLCubeRenderTarget?(Array.isArray(Ue[B])?W=Ue[B][J]:W=Ue[B],X=!0):R.samples>0&&Q.useMultisampledRTT(R)===!1?W=Y.get(R).__webglMultisampledFramebuffer:Array.isArray(Ue)?W=Ue[J]:W=Ue,se.copy(R.viewport),Re.copy(R.scissor),Te=R.scissorTest}else se.copy(fe).multiplyScalar(z).floor(),Re.copy(de).multiplyScalar(z).floor(),Te=et;if(J!==0&&(W=D),T.bindFramebuffer(O.FRAMEBUFFER,W)&&T.drawBuffers(R,W),T.viewport(se),T.scissor(Re),T.setScissorTest(Te),X){let we=Y.get(R.texture);O.framebufferTexture2D(O.FRAMEBUFFER,O.COLOR_ATTACHMENT0,O.TEXTURE_CUBE_MAP_POSITIVE_X+B,we.__webglTexture,J)}else if(Ee){let we=B;for(let Le=0;Le<R.textures.length;Le++){let Ue=Y.get(R.textures[Le]);O.framebufferTextureLayer(O.FRAMEBUFFER,O.COLOR_ATTACHMENT0+Le,Ue.__webglTexture,J,we)}}else if(R!==null&&J!==0){let we=Y.get(R.texture);O.framebufferTexture2D(O.FRAMEBUFFER,O.COLOR_ATTACHMENT0,O.TEXTURE_2D,we.__webglTexture,J)}K=-1};function zp(R){let B=Y.get(R);return(B.__readFormat!==R.format||B.__readType!==R.type)&&(B.__readFormat=R.format,B.__readType=R.type,B.__formatReadable=N.textureFormatReadable(R.format),B.__typeReadable=N.textureTypeReadable(R.type)),B}this.readRenderTargetPixels=function(R,B,J,W,X,Ee,Pe,we=0){if(!(R&&R.isWebGLRenderTarget)){We("WebGLRenderer.readRenderTargetPixels: renderTarget is not THREE.WebGLRenderTarget.");return}let Le=Y.get(R).__webglFramebuffer;if(R.isWebGLCubeRenderTarget&&Pe!==void 0&&(Le=Le[Pe]),Le){T.bindFramebuffer(O.FRAMEBUFFER,Le);try{let Ue=R.textures[we],je=Ue.format,ot=Ue.type;R.textures.length>1&&O.readBuffer(O.COLOR_ATTACHMENT0+we);let Ne=zp(Ue);if(Ne.__formatReadable===!1){We("WebGLRenderer.readRenderTargetPixels: renderTarget is not in RGBA or implementation defined format.");return}if(Ne.__typeReadable===!1){We("WebGLRenderer.readRenderTargetPixels: renderTarget is not in UnsignedByteType or implementation defined type.");return}B>=0&&B<=R.width-W&&J>=0&&J<=R.height-X&&O.readPixels(B,J,W,X,Se.convert(je),Se.convert(ot),Ee)}finally{let Ue=oe!==null?Y.get(oe).__webglFramebuffer:null;T.bindFramebuffer(O.FRAMEBUFFER,Ue)}}},this.readRenderTargetPixelsAsync=async function(R,B,J,W,X,Ee,Pe,we=0){if(!(R&&R.isWebGLRenderTarget))throw new Error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not THREE.WebGLRenderTarget.");let Le=Y.get(R).__webglFramebuffer;if(R.isWebGLCubeRenderTarget&&Pe!==void 0&&(Le=Le[Pe]),Le)if(B>=0&&B<=R.width-W&&J>=0&&J<=R.height-X){T.bindFramebuffer(O.FRAMEBUFFER,Le);let Ue=R.textures[we],je=Ue.format,ot=Ue.type;R.textures.length>1&&O.readBuffer(O.COLOR_ATTACHMENT0+we);let Ne=zp(Ue);if(Ne.__formatReadable===!1)throw new Error("THREE.WebGLRenderer.readRenderTargetPixelsAsync: renderTarget is not in RGBA or implementation defined format.");if(Ne.__typeReadable===!1)throw new Error("THREE.WebGLRenderer.readRenderTargetPixelsAsync: renderTarget is not in UnsignedByteType or implementation defined type.");let _t=O.createBuffer();O.bindBuffer(O.PIXEL_PACK_BUFFER,_t),O.bufferData(O.PIXEL_PACK_BUFFER,Ee.byteLength,O.STREAM_READ),O.readPixels(B,J,W,X,Se.convert(je),Se.convert(ot),0),O.bindBuffer(O.PIXEL_PACK_BUFFER,null);let Xt=oe!==null?Y.get(oe).__webglFramebuffer:null;T.bindFramebuffer(O.FRAMEBUFFER,Xt);let Lt=O.fenceSync(O.SYNC_GPU_COMMANDS_COMPLETE,0);return O.flush(),await xg(O,Lt,4),O.bindBuffer(O.PIXEL_PACK_BUFFER,_t),O.getBufferSubData(O.PIXEL_PACK_BUFFER,0,Ee),O.bindBuffer(O.PIXEL_PACK_BUFFER,null),O.deleteBuffer(_t),O.deleteSync(Lt),Ee}else throw new Error("THREE.WebGLRenderer.readRenderTargetPixelsAsync: requested read bounds are out of range.")},this.copyFramebufferToTexture=function(R,B=null,J=0){let W=Math.pow(2,-J),X=Math.floor(R.image.width*W),Ee=Math.floor(R.image.height*W),Pe=B!==null?B.x:0,we=B!==null?B.y:0;Q.setTexture2D(R,0),O.copyTexSubImage2D(O.TEXTURE_2D,J,0,0,Pe,we,X,Ee),T.unbindTexture()},this.copyTextureToTexture=function(R,B,J=null,W=null,X=0,Ee=0){let Pe,we,Le,Ue,je,ot,Ne,_t,Xt,Lt=R.isCompressedTexture?R.mipmaps[Ee]:R.image;if(J!==null)Pe=J.max.x-J.min.x,we=J.max.y-J.min.y,Le=J.isBox3?J.max.z-J.min.z:1,Ue=J.min.x,je=J.min.y,ot=J.isBox3?J.min.z:0;else{let Vt=Math.pow(2,-X);Pe=Math.floor(Lt.width*Vt),we=Math.floor(Lt.height*Vt),R.isDataArrayTexture?Le=Lt.depth:R.isData3DTexture?Le=Math.floor(Lt.depth*Vt):Le=1,Ue=0,je=0,ot=0}W!==null?(Ne=W.x,_t=W.y,Xt=W.z):(Ne=0,_t=0,Xt=0);let Et=Se.convert(B.format),hn=Se.convert(B.type),Ce;B.isData3DTexture?(Q.setTexture3D(B,0),Ce=O.TEXTURE_3D):B.isDataArrayTexture||B.isCompressedArrayTexture?(Q.setTexture2DArray(B,0),Ce=O.TEXTURE_2D_ARRAY):(Q.setTexture2D(B,0),Ce=O.TEXTURE_2D),T.activeTexture(O.TEXTURE0),T.pixelStorei(O.UNPACK_FLIP_Y_WEBGL,B.flipY),T.pixelStorei(O.UNPACK_PREMULTIPLY_ALPHA_WEBGL,B.premultiplyAlpha),T.pixelStorei(O.UNPACK_ALIGNMENT,B.unpackAlignment);let vn=T.getParameter(O.UNPACK_ROW_LENGTH),ct=T.getParameter(O.UNPACK_IMAGE_HEIGHT),qn=T.getParameter(O.UNPACK_SKIP_PIXELS),mi=T.getParameter(O.UNPACK_SKIP_ROWS),Qi=T.getParameter(O.UNPACK_SKIP_IMAGES);T.pixelStorei(O.UNPACK_ROW_LENGTH,Lt.width),T.pixelStorei(O.UNPACK_IMAGE_HEIGHT,Lt.height),T.pixelStorei(O.UNPACK_SKIP_PIXELS,Ue),T.pixelStorei(O.UNPACK_SKIP_ROWS,je),T.pixelStorei(O.UNPACK_SKIP_IMAGES,ot);let lr=R.isDataArrayTexture||R.isData3DTexture,Mt=B.isDataArrayTexture||B.isData3DTexture;if(R.isDepthTexture){let Vt=Y.get(R),es=Y.get(B),It=Y.get(Vt.__renderTarget),ts=Y.get(es.__renderTarget);T.bindFramebuffer(O.READ_FRAMEBUFFER,It.__webglFramebuffer),T.bindFramebuffer(O.DRAW_FRAMEBUFFER,ts.__webglFramebuffer);for(let ur=0;ur<Le;ur++)lr&&(O.framebufferTextureLayer(O.READ_FRAMEBUFFER,O.COLOR_ATTACHMENT0,Y.get(R).__webglTexture,X,ot+ur),O.framebufferTextureLayer(O.DRAW_FRAMEBUFFER,O.COLOR_ATTACHMENT0,Y.get(B).__webglTexture,Ee,Xt+ur)),O.blitFramebuffer(Ue,je,Pe,we,Ne,_t,Pe,we,O.DEPTH_BUFFER_BIT,O.NEAREST);T.bindFramebuffer(O.READ_FRAMEBUFFER,null),T.bindFramebuffer(O.DRAW_FRAMEBUFFER,null)}else if(X!==0||R.isRenderTargetTexture||Y.has(R)){let Vt=Y.get(R),es=Y.get(B);T.bindFramebuffer(O.READ_FRAMEBUFFER,L),T.bindFramebuffer(O.DRAW_FRAMEBUFFER,U);for(let It=0;It<Le;It++)lr?O.framebufferTextureLayer(O.READ_FRAMEBUFFER,O.COLOR_ATTACHMENT0,Vt.__webglTexture,X,ot+It):O.framebufferTexture2D(O.READ_FRAMEBUFFER,O.COLOR_ATTACHMENT0,O.TEXTURE_2D,Vt.__webglTexture,X),Mt?O.framebufferTextureLayer(O.DRAW_FRAMEBUFFER,O.COLOR_ATTACHMENT0,es.__webglTexture,Ee,Xt+It):O.framebufferTexture2D(O.DRAW_FRAMEBUFFER,O.COLOR_ATTACHMENT0,O.TEXTURE_2D,es.__webglTexture,Ee),X!==0?O.blitFramebuffer(Ue,je,Pe,we,Ne,_t,Pe,we,O.COLOR_BUFFER_BIT,O.NEAREST):Mt?O.copyTexSubImage3D(Ce,Ee,Ne,_t,Xt+It,Ue,je,Pe,we):O.copyTexSubImage2D(Ce,Ee,Ne,_t,Ue,je,Pe,we);T.bindFramebuffer(O.READ_FRAMEBUFFER,null),T.bindFramebuffer(O.DRAW_FRAMEBUFFER,null)}else Mt?R.isDataTexture||R.isData3DTexture?O.texSubImage3D(Ce,Ee,Ne,_t,Xt,Pe,we,Le,Et,hn,Lt.data):B.isCompressedArrayTexture?O.compressedTexSubImage3D(Ce,Ee,Ne,_t,Xt,Pe,we,Le,Et,Lt.data):O.texSubImage3D(Ce,Ee,Ne,_t,Xt,Pe,we,Le,Et,hn,Lt):R.isDataTexture?O.texSubImage2D(O.TEXTURE_2D,Ee,Ne,_t,Pe,we,Et,hn,Lt.data):R.isCompressedTexture?O.compressedTexSubImage2D(O.TEXTURE_2D,Ee,Ne,_t,Lt.width,Lt.height,Et,Lt.data):O.texSubImage2D(O.TEXTURE_2D,Ee,Ne,_t,Pe,we,Et,hn,Lt);T.pixelStorei(O.UNPACK_ROW_LENGTH,vn),T.pixelStorei(O.UNPACK_IMAGE_HEIGHT,ct),T.pixelStorei(O.UNPACK_SKIP_PIXELS,qn),T.pixelStorei(O.UNPACK_SKIP_ROWS,mi),T.pixelStorei(O.UNPACK_SKIP_IMAGES,Qi),Ee===0&&B.generateMipmaps&&O.generateMipmap(Ce),T.unbindTexture()},this.initRenderTarget=function(R){Y.get(R).__webglFramebuffer===void 0&&Q.setupRenderTarget(R)},this.initTexture=function(R){R.isCubeTexture?Q.setTextureCube(R,0):R.isData3DTexture?Q.setTexture3D(R,0):R.isDataArrayTexture||R.isCompressedArrayTexture?Q.setTexture2DArray(R,0):Q.setTexture2D(R,0),T.unbindTexture()},this.resetState=function(){G=0,Z=0,oe=null,T.reset(),Ae.reset()},typeof __THREE_DEVTOOLS__<"u"&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe",{detail:this}))}get coordinateSystem(){return si}get outputColorSpace(){return this._outputColorSpace}set outputColorSpace(e){this._outputColorSpace=e;let t=this.getContext();t.drawingBufferColorSpace=tt._getDrawingBufferColorSpace(e),t.unpackColorSpace=tt._getUnpackColorSpace()}};var Mu={tsudanuma:{name:"\u6D25\u7530\u6CBC",max:9,url:"https://chibatech.ac.jp/about/institute/campus/tsudanuma.html",plan:"https://chibatech.ac.jp/about/institute/campus/dl53f300000014qt-img/dl53f30000002vv4.png"},narashino:{name:"\u65B0\u7FD2\u5FD7\u91CE",max:13,url:"https://kmsk.is.it-chiba.ac.jp/portal/whole/gakubu/campus_map.pdf",plan:"https://kmsk.is.it-chiba.ac.jp/portal/whole/gakubu/campus_map.pdf"}},sT={1:"\u4E8B\u52D9\u5BA4\u30FB\u7814\u7A76\u5BA4\u306A\u3069",2:"\u5927\u6559\u5BA4\u30FB\u7814\u7A76\u5BA4\u306A\u3069",3:"\u5B66\u751F\u98DF\u5802\u30FB\u8CFC\u8CB7\u306A\u3069",4:"\u8AC7\u8A71\u5BA4\u30FB\u5DE5\u4F5C\u30BB\u30F3\u30BF\u30FC\u30FB\u90E8\u5BA4",5:"\u56F3\u66F8\u9928\u306A\u3069",6:"\u8B1B\u7FA9\u5BA4\u306A\u3069",7:"\u30D1\u30CA\u30BD\u30CB\u30C3\u30AF\u30FB\u5343\u8449\u5DE5\u696D\u5927\u5B66\u7523\u5B66\u9023\u643A\u30BB\u30F3\u30BF\u30FC\u30FB\u30B3\u30F3\u30D4\u30E5\u30FC\u30BF\u6F14\u7FD2\u5BA4\u30FB\u7814\u7A76\u5BA4\u306A\u3069",8:"\u672A\u6765\u30ED\u30DC\u30C3\u30C8\u7814\u7A76\u30BB\u30F3\u30BF\u30FC\u30FB\u60D1\u661F\u63A2\u67FB\u7814\u7A76\u30BB\u30F3\u30BF\u30FC\u306A\u3069",9:"\u5B66\u751F\u5B9F\u9A13\u5BA4"};function rT(i){let e=String(i?.building_id??"");if(!/^\d{1,2}$/.test(e))return null;let t=i.campus==="Shin-Narashino"?"narashino":typeof i.geometry_note=="string"?"tsudanuma":null,n=Number(e);return!t||n<1||n>Mu[t].max?null:{campus:t,number:n,label:`${n}\u53F7\u9928`,key:`${t}:${n}`,source:Mu[t].url,description:t==="tsudanuma"?sT[n]:""}}function oT(i,{width:e,height:t,occupied:n=[],max:s=e<500?8:12}={}){let r=[],o=[...n];for(let a of[...i].sort((c,l)=>c.distance-l.distance)){if(r.length>=s)break;if(a.depth<-1||a.depth>1||a.distance>1800)continue;let c=a.width??62,l=a.height??32,h=(a.landmark?[0,l+8,-l-8]:[0]).map(f=>({x:a.x-c/2,y:a.y-l/2+f,width:c,height:l})).find(f=>f.x>=4&&f.x+f.width<=e-4&&f.y>=4&&f.y+f.height<=t-4&&!o.some(d=>f.x<d.x+d.width+5&&f.x+f.width+5>d.x&&f.y<d.y+d.height+5&&f.y+f.height+5>d.y));h&&(r.push({...a,rect:h}),o.push(h))}return r}function t0({scene:i,camera:e,canvas:t,onOpen:n=()=>{},onOverlay:s=()=>{}}){let r=document.createElement("div");r.id="building-labels",r.setAttribute("aria-label","\u53F7\u9928\u30E9\u30D9\u30EB"),Object.assign(r.style,{position:"fixed",inset:"0",pointerEvents:"none",zIndex:"8"}),document.body.append(r);let o=document.createElement("style");o.textContent=".campus-building-label{position:absolute;min-width:62px;min-height:32px;padding:4px 8px;border:1px solid #547da8;border-radius:14px;background:#fffef2f2;color:#153d61;font:700 13px system-ui;box-shadow:0 2px 5px #18355430;pointer-events:auto;touch-action:manipulation}.campus-building-label:focus-visible{outline:3px solid #ffac35}.campus-building-detail{position:fixed;z-index:2;left:50%;top:50%;transform:translate(-50%,-50%);width:min(310px,82vw);max-height:calc(100% - 24px);overflow:auto;background:#fff;border:2px solid #487ac0;border-radius:18px;padding:16px;color:#193752;box-shadow:0 12px 45px #15294555;pointer-events:auto;font:14px system-ui;line-height:1.5}.campus-building-detail h3{margin:0 40px 0 0;font-size:16px}.campus-building-detail p{margin:12px 0 0;overflow-wrap:anywhere}.campus-building-close{position:absolute;top:6px;right:6px;min-height:44px;min-width:44px;width:44px;height:44px;padding:0;border:0;background:transparent;color:#193752;font:28px system-ui}.campus-building-close:focus-visible{outline:3px solid #1565c0}",document.head.append(o);let a=document.createElement("section");a.className="campus-building-detail",a.id="building-detail",a.hidden=!0,a.setAttribute("role","dialog"),a.setAttribute("aria-label","\u53F7\u9928\u306E\u8A73\u7D30");let c=document.createElement("h3"),l=document.createElement("p"),u=document.createElement("button");u.type="button",u.className="campus-building-close",u.setAttribute("aria-label","\u9589\u3058\u308B"),u.textContent="\xD7",a.append(c,l,u),r.append(a);let h=new Map,f=!0,d=-1/0,m=null,x=null,g=M=>{for(let E=M;E;E=E.parent){if(!E.visible)return!1;if(E===i)return!0}return!1};function p(){return a.hidden?!1:(a.hidden=!0,m=null,s(!1),x?.isConnected&&x.focus({preventScroll:!0}),x=null,!0)}u.addEventListener("click",M=>{M.preventDefault(),M.stopPropagation(),p()});function v(M){x=document.activeElement,n(),m=M.key,c.textContent=`${Mu[M.campus].name}\u30AD\u30E3\u30F3\u30D1\u30B9 ${M.label}`,l.textContent=M.description??"",l.hidden=!l.textContent,a.hidden=!1,s(!0),u.focus({preventScroll:!0})}function b(M,E,y=M.uuid){if(h.has(y))return;let w=document.createElement("button");w.type="button",w.className="campus-building-label",w.textContent=E.label,w.setAttribute("aria-label",`${Mu[E.campus].name} ${E.label}`),w.dataset.campus=E.campus,E.number&&(w.dataset.buildingId=String(E.number)),E.landmark&&(w.dataset.landmark=E.landmark),E.width&&(w.style.width=`${E.width}px`),w.hidden=!0,w.addEventListener("click",A=>{A.preventDefault(),A.stopPropagation(),v(E)}),r.append(w),h.set(y,{...E,object:M,button:w})}function _(M){M-d<500||(d=M,i.traverse(E=>{let y=rT(E.userData);y&&(b(E,y),y.campus==="tsudanuma"&&y.number===7&&b(E,{campus:"tsudanuma",key:"tsudanuma:bus-terminal",label:"\u30D0\u30B9\u30BF\u30FC\u30DF\u30CA\u30EB",landmark:"bus-terminal",description:"7\u53F7\u9928\u3068\u9053\u8DEF\u306E\u9593",width:128},`${E.uuid}:bus-terminal`))}))}function S(){if(!f)return;_(performance.now());let M=t.getBoundingClientRect(),E=M.width,y=M.height,w=[];i.updateMatrixWorld(),e.updateMatrixWorld();for(let P of h.values()){if(P.button.hidden=!0,!g(P.object))continue;let C=new Ke().setFromObject(P.object);if(C.isEmpty())continue;let D=C.getCenter(new I);P.landmark==="bus-terminal"?D.set(C.max.x+4,C.min.y+3,D.z-10):D.y=C.max.y+3;let L=D.distanceTo(e.position),U=D.project(e);w.push({...P,x:(U.x+1)*E/2,y:(1-U.y)*y/2,depth:U.z,distance:L})}let A=[...document.querySelectorAll(".toolbar,.controls,#toolbar,#modes,#race-panel,#pedals,#directions,#sticks,#region-quality,#quality-details,#fullscreen")].filter(P=>!P.hidden&&P.offsetWidth&&P.offsetHeight).map(P=>{let C=P.getBoundingClientRect();return{x:C.x-M.x,y:C.y-M.y,width:C.width,height:C.height}});for(let P of oT(w,{width:E,height:y,occupied:A}))P.button.hidden=!1,P.button.style.left=`${M.x+P.rect.x}px`,P.button.style.top=`${M.y+P.rect.y}px`}return{update:S,closeDetails:p,get open(){return!a.hidden},get state(){return{active:m,open:!a.hidden,buildings:[...h.values()].map(M=>({campus:M.campus,number:M.number,label:M.label,landmark:M.landmark,description:M.description,visible:!M.button.hidden,source:M.source}))}},dispose(){f&&(f=!1,p(),r.remove(),o.remove(),h.clear())}}}var Ut=(i,e,t)=>Math.max(e,Math.min(t,i));function co(i,e,t,n=0){if(t.meshCollision)return t.meshCollision(i,e,n);let s=e==="car"?2.2:5.5,r=e==="car"?.9:1.2;return t.buildings.some(o=>i.x>o.min.x-s&&i.x<o.max.x+s&&i.z>o.min.z-s&&i.z<o.max.z+s&&i.y+r>o.min.y&&i.y-r<o.max.y)}var Tu=class{constructor(e){this.world=e,this.mode="free",this.position={...e.carSpawn},this.yaw=e.carYaw??0,this.speed=0,this.blocked="",this.pitch=0,this.landingCount=0,this.airborne=!1}setMode(e){["free","car","plane","bus"].includes(e)&&(this.mode=e,this.reset())}reset(){this.speed=0,this.blocked="",this.pitch=0,this.airborne=!1,this.position={...this.mode==="plane"?this.world.planeSpawn:this.mode==="bus"?this.world.busSpawn:this.world.carSpawn},this.yaw=this.mode==="plane"?this.world.planeYaw??0:this.mode==="bus"?this.world.busYaw??0:this.world.carYaw??0}stop(){this.speed=0,this.blocked=""}step(e,t){if(this.mode==="free")return;let n=Ut(e,0,.1),s=Math.max(1,Math.ceil(n/.01));for(let r=0;r<s;r++)this._step(n/s,t)}_step(e,t){if(e<=0)return;let n=!1,s=this.airborne,r=this.pitch,o=this.mode==="bus",a=this.mode==="car"||o,c=o?1.4:.8,l=t instanceof Set?Number(t.has("accelerate"))-Number(t.has("brake")):Ut(t.throttle??0,-1,1),u=t instanceof Set?Number(t.has("left"))-Number(t.has("right")):Ut(t.steer??0,-1,1),h=t instanceof Set?Number(t.has("up"))-Number(t.has("down")):Ut(t.lift??0,-1,1),f=o?4:a?7:9;l?this.speed+=l*f*e:a&&(this.speed*=Math.exp(-.8*e)),this.speed=Ut(this.speed,a?o?-3:-4:-8,o?22:a?14:40),Math.abs(this.speed)<.02&&(this.speed=0);let d=this.yaw+u*e*(a?(o?.9:1.1)*Math.min(Math.abs(this.speed)/3,1)*Math.sign(this.speed):.75),m={x:this.position.x-Math.sin(d)*this.speed*e,y:this.position.y+(a?0:h*12*e),z:this.position.z-Math.cos(d)*this.speed*e},x=this.world.terrainHeight(m.x,m.z,a?this.position.y:null,this.mode),g=a?this.world.groundBounds:this.world.flightBounds,p=o?4.2:a?2.2:5.5;if(m.x<g.min.x+p||m.x>g.max.x-p||m.z<g.min.z+p||m.z>g.max.z-p||a&&x==null){this.speed=0,this.blocked="\u7BC4\u56F2\u306E\u7AEF";return}if(a){if(Math.abs(x+c-this.position.y)>.65){this.speed=0,this.blocked="\u6BB5\u5DEE";return}m.y=x+c}else{let v=x??this.world.groundBase;for(let M of this.world.buildings)m.x>M.min.x&&m.x<M.max.x&&m.z>M.min.z&&m.z<M.max.z&&this.position.y>=M.max.y+2.9&&(v=Math.max(v,M.max.y));let b=v+3;m.y=Ut(m.y,b,this.world.maxAltitude),m.y>b+2&&(s=!0),s&&m.y<=b+.001&&h<=0&&(n=!0,s=!1);let _=(m.y-this.position.y)/e,S=m.y<=b+.001?0:Ut(Math.atan2(_,Math.abs(this.speed)+8),-.42,.42);r+=(S-this.pitch)*(1-Math.exp(-e*7))}if(co(m,this.mode,this.world,d)){this.speed=0,this.blocked="\u5EFA\u7269\u306E\u624B\u524D";return}this.airborne=s,this.pitch=r,n&&(this.landingCount++,this.speed*=.45),this.position=m,this.yaw=d,this.blocked=""}};function n0({campus:i,scene:e,world:t}){let n;if(e.traverse(x=>{n||(i==="tsudanuma"&&x.isMesh&&x.material?.name==="sculpture"&&(n=x),i==="narashino"&&String(x.userData?.building_id)==="12"&&(n=x))}),!n)return null;let s=[];e.traverse(x=>{x.isMesh&&s.push({mesh:x,box:new Ke().setFromObject(x)})});let r=new Xs,o=new I;function a(x){return s.some(({mesh:g,box:p})=>!r.ray.intersectBox(p,o)||!p.containsPoint(r.ray.origin)&&o.distanceTo(r.ray.origin)>x?!1:r.intersectObject(g,!1).some(v=>v.distance<x-.3))}function c(x,g,p){let v=g==="car",b=new I(x.x,x.y+(v?.9:0),x.z),_=new I(Math.sin(p)*(v?11:24),v?5:32,Math.cos(p)*(v?11:24)),S=_.length(),M=b.clone().add(_);return r.set(b,_.normalize()),r.far=S,a(S)?!1:(r.set(M,_.negate()),!a(S))}let l=new Ke().setFromObject(n),u=l.getCenter(new I),h=[];if(i==="tsudanuma")for(let x of[9,12,16,22])for(let g=0;g<16;g++){let p=g*Math.PI/8;h.push({x:u.x+Math.sin(p)*x,z:u.z+Math.cos(p)*x})}else for(let x of[8,12,16])for(let g of[.2,.35,.5,.65,.8]){let p=l.min.x+(l.max.x-l.min.x)*g,v=l.min.z+(l.max.z-l.min.z)*g;h.push({x:l.min.x-x,z:v},{x:l.max.x+x,z:v},{x:p,z:l.min.z-x},{x:p,z:l.max.z+x})}function f(x,g,p,v,b){let _=v==="plane"?5.5:2.2,S=t.groundBounds;return x<S.min.x+_||x>S.max.x-_||g<S.min.z+_||g>S.max.z-_||t.buildings.some(M=>x>M.min.x-_&&x<M.max.x+_&&g>M.min.z-_&&g<M.max.z+_)?!1:!co({x,y:p,z:g},v,t,b)}let d=null,m=1/0;for(let x of h){let g=t.terrainHeight(x.x,x.z);if(g==null)continue;let p={...x,y:g+.8},v={...x,y:g+3};for(let b=0;b<16;b++){let _=b*Math.PI/8;if(!f(x.x,x.z,p.y,"car",_)||!f(x.x,x.z,v.y,"plane",_))continue;let S=0;for(let y of[3,6,10,15,20]){let w=x.x-Math.sin(_)*y,A=x.z-Math.cos(_)*y,P=t.terrainHeight(w,A);if(P==null||Math.abs(P-g)>.65||!f(w,A,P+.8,"car",_)||!f(w,A,P+3,"plane",_))break;S=y}if(S<10)continue;let E=(i==="tsudanuma"?Math.hypot(x.x-u.x,x.z-u.z):l.distanceToPoint(new I(x.x,l.min.y,x.z)))-S*.4;E<m&&c(p,"car",_)&&c(v,"plane",_)&&(m=E,d={carSpawn:p,planeSpawn:v,carYaw:_+Math.PI,planeYaw:_+Math.PI})}}return d}function i0(i,e,t){return{lon:t[0]+i/(6378137*Math.cos(t[1]*Math.PI/180))*180/Math.PI,lat:t[1]-e/6378137*180/Math.PI}}function s0(i,e,t){let n=!1;for(let s=0,r=t.length-1;s<t.length;r=s++){let o=t[s],a=t[r];o[1]>e!=a[1]>e&&i<(a[0]-o[0])*(e-o[1])/(a[1]-o[1])+o[0]&&(n=!n)}return n}function $s(i,e,t){let n=(e-i.x)/i.step,s=(t-i.z)/i.step;if(n<0||s<0||n>i.nx-1||s>i.nz-1)return null;let r=Math.min(Math.floor(n),i.nx-2),o=Math.min(Math.floor(s),i.nz-2),a=n-r,c=s-o,l=[o*i.nx+r,o*i.nx+r+1,(o+1)*i.nx+r,(o+1)*i.nx+r+1],u=[(1-a)*(1-c),a*(1-c),(1-a)*c,a*c],h=0,f=0;return l.forEach((d,m)=>{let x=i.heights[d];x!=null&&(h+=x*u[m],f+=u[m])}),f?h/f:null}function Ha(i,e,t,n){let s=n[0]-t[0],r=n[1]-t[1],o=s*s+r*r,a=o?Math.max(0,Math.min(1,((i-t[0])*s+(e-t[1])*r)/o)):0,c=t[0]+s*a,l=t[1]+r*a;return{distance:Math.hypot(i-c,e-l),t:a,x:c,z:l}}var wu=class{constructor(e,t){this.terrain=t,this.cells=new Map,this.segments=[];for(let n of e)if(n.drive)for(let s=1;s<n.points.length;s++){let r=n.points[s-1],o=n.points[s],a={a:r,b:o,road:n};this.segments.push(a);for(let c=Math.floor((Math.min(r[0],o[0])-n.width)/80);c<=Math.floor((Math.max(r[0],o[0])+n.width)/80);c++)for(let l=Math.floor((Math.min(r[1],o[1])-n.width)/80);l<=Math.floor((Math.max(r[1],o[1])+n.width)/80);l++){let u=`${c},${l}`;this.cells.has(u)||this.cells.set(u,[]),this.cells.get(u).push(a)}}}candidates(e,t){return(this.cells.get(`${Math.floor(e/80)},${Math.floor(t/80)}`)??[]).map(n=>({...n,...Ha(e,t,n.a,n.b)})).sort((n,s)=>n.distance-s.distance)}surface(e,t,n=null,s="car"){if($s(this.terrain,e,t)==null)return null;for(let o of this.candidates(e,t)){if(o.distance>Math.max(.3,o.road.width/2-(s==="bus"?1.4:1.15)))continue;let a=o.a[2]+(o.b[2]-o.a[2])*o.t;if(!(n!=null&&Math.abs(a+(s==="bus"?1.4:.8)-n)>.65))return{height:a,road:o.road}}return null}};var wi=(i,e=0)=>new $t({color:i,emissive:e,emissiveIntensity:.35,roughness:.85});function Ti(i,e,t,n){let s=new it(new In(...e),n);return s.position.set(...t),i.add(s),s}function aT(i){i.traverse(e=>{e.geometry?.dispose(),e.material?.map?.dispose(),e.material?.dispose()})}function od(i,e,t,n){let s=[];for(let a=1;a<i.length;a++){let c=i[a-1],l=i[a],u=l[0]-c[0],h=l[1]-c[1],f=Math.hypot(u,h)||1,d=-h/f*e/2,m=u/f*e/2,x=(c[2]??0)+t,g=(l[2]??0)+t;s.push(c[0]+d,x,c[1]+m,c[0]-d,x,c[1]-m,l[0]+d,g,l[1]+m,l[0]+d,g,l[1]+m,c[0]-d,x,c[1]-m,l[0]-d,g,l[1]-m)}let r=new ht;r.setAttribute("position",new lt(s,3)),r.computeVertexNormals();let o=wi(n);return o.side=Dt,new it(r,o)}function Eu(i,e,t,{currentY:n=null,progress:s=null,offset:r=1.4}={}){let o=null,a=0;for(let c=1;c<i.points.length;c++){let l=i.points[c-1],u=i.points[c],h=Math.hypot(u[0]-l[0],u[1]-l[1]),f=a+h,d=Ha(e,t,l,u),m=(l[2]??0)+((u[2]??0)-(l[2]??0))*d.t,x=a+h*d.t;(s==null||f>=s-100&&a<=s+120)&&(n==null||Math.abs(m+r-n)<4)&&(!o||d.distance<o.distance)&&(o={...d,y:m,progress:x,index:c}),a=f}return o}function r0(i,e,t,n,s){let r=wi(16775403),o=wi(s),a=wi(4217202),c=new Bt;if(c.name=e,c.position.set(t,0,n),i.add(c),e==="PopTsudanuma")for(let[l,u]of[62,50,30].entries()){Ti(c,[16,u,18],[l*21-21,u/2,0],r),Ti(c,[17,3,19],[l*21-21,u-4,0],o);for(let h=8;h<u-7;h+=8)Ti(c,[16.2,2,18.2],[l*21-21,h,0],a)}else{for(let l=0;l<5;l++)Ti(c,[20,12+l%2*6,26],[l%3*24-24,6+l%2*3,Math.floor(l/3)*32],r),Ti(c,[21,2,27],[l%3*24-24,13+l%2*6,Math.floor(l/3)*32],o);Ti(c,[60,.1,34],[0,.1,-45],wi(4578481))}return c}async function o0({scene:i,signal:e,reducedMotion:t=!1,onCourse:n=()=>{}}){let s=await fetch("pop_courses.json",{signal:e});if(!s.ok)throw new Error("Game course unavailable");let r=await s.json(),o=null,a=null,c=null,l=0,u=r.courses.map(f=>({...f,id:f.direction,distance:f.length})),h={experience:"game",reducedMotion:t,data:{routes:u,family:"pop",version:2},groundBase:0,maxAltitude:90,buildings:[],collisionTriangles:0,carSpawn:null,busSpawn:null,planeSpawn:null,carYaw:0,busYaw:0,selectedRoute:null,roadDistance(f,d){return Eu(a,f,d)?.distance??1/0},terrainHeight(f,d,m=null,x="bus"){let g=x==="car"?.8:1.4,p=Eu(a,f,d,{currentY:m,progress:m==null?null:l,offset:g});return p&&p.distance<48?(m!=null&&(l=p.progress),p.y):0},meshCollision:()=>!1,cameraDistance:(f,d,m)=>m,description(f){let d=Eu(a,f.x,f.z);return{course:a.id,progress:d?.progress??0,roadDistance:d?.distance??1/0,theme:"fictional game",campusesLoaded:["pop-tsudanuma","pop-narashino"]}},setProgress:f=>l=f,update(){c&&!t&&(c.material.uniforms.phase.value=performance.now()/18e3)},disposeCollision(){o&&(i.remove(o),aT(o),o=null)},get sphere(){return c?{position:c.position.toArray(),radius:38,originalPattern:!0,reducedMotion:t}:null}};return h.roadIndex={surface:(f,d,m=null,x="bus")=>{let g=Eu(a,f,d,{currentY:m,offset:x==="car"?.8:1.4});return g?{height:g.y,road:{name:a.name}}:null}},h.setRoute=f=>{let d=u.find(w=>w.id===f);if(!d)return;h.disposeCollision(),o=new Bt,o.name="OriginalPopGameWorld",i.add(o),a=h.selectedRoute=d,l=0,c=null;let m=d.points.map(w=>w[0]),x=d.points.map(w=>w[1]),g={min:{x:Math.min(...m)-180,z:Math.min(...x)-180},max:{x:Math.max(...m)+180,z:Math.max(...x)+180}};h.groundBounds=h.flightBounds=g;let p=d.points[0],v=d.points[1],b=Math.atan2(-(v[0]-p[0]),-(v[1]-p[1]));h.busSpawn={x:p[0],y:p[2]+1.4,z:p[1]},h.carSpawn={x:p[0],y:p[2]+.8,z:p[1]},h.planeSpawn={x:p[0],y:p[2]+25,z:p[1]},h.carYaw=h.busYaw=b;let _=f==="neon_city";i.background=new Ve(_?1581645:11857151),i.fog=new Jo(i.background,450,1800),Ti(o,[g.max.x-g.min.x,.4,g.max.z-g.min.z],[(g.max.x+g.min.x)/2,-.3,(g.max.z+g.min.z)/2],wi(_?3424867:9690800));let S=[p[0]+Math.sin(b)*28,p[1]+Math.cos(b)*28,p[2]],M=[S,...d.points];o.add(od(M,48,.015,_?4476049:15979931),od(M,24,.04,_?2503257:5399931),od(M,.25,.08,16771771));for(let w=0;w<d.points.length;w+=8){let A=d.points[w],P=d.points[Math.min(w+1,d.points.length-1)],C=Math.atan2(P[0]-A[0],P[1]-A[1]);for(let D of[-1,1]){let L=A[0]+Math.cos(C)*14*D,U=A[1]-Math.sin(C)*14*D,G=Ti(o,[.45,1.4,.45],[L,A[2]+.7,U],wi(w%16?16777215:16755827));_&&G.material.emissive.set(7131135)}}let E=d.points[0],y=d.points.at(-1);r0(o,f==="return"?"PopNarashino":"PopTsudanuma",E[0]-85,E[1]+25,f==="return"?640421:5273582),r0(o,f==="return"?"PopTsudanuma":"PopNarashino",y[0]+90,y[1]-25,f==="return"?5273582:640421);for(let w=0;w<36;w++){let A=d.points[Math.floor(w*d.points.length/36)],P=w*2.399,C=A[0]+Math.cos(P)*75,D=A[1]+Math.sin(P)*75;if(h.roadDistance(C,D)<32)continue;let L=new it(new ks(5,12,6),wi(_?6380689:3716489));L.position.set(C,8,D),o.add(L),Ti(o,[1.5,3,1.5],[C,1.5,D],wi(12885365))}if(_){let w=d.sphere??{x:125,z:-280},A=new ln({uniforms:{phase:{value:0}},vertexShader:"varying vec3 v;void main(){v=position;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}",fragmentShader:"varying vec3 v;uniform float phase;void main(){float k=.5+.5*sin(v.y*.13+v.x*.08+phase);vec3 c=mix(vec3(.2,.82,1.),vec3(.96,.38,.7),k);gl_FragColor=vec4(c,1.);}"});c=new it(new ya(38,40,24),A),c.name="OriginalNeonSphere",c.position.set(w.x,38,w.z),o.add(c);for(let P=0;P<12;P++){let C=d.points[Math.floor(P*d.points.length/12)],D=P%2?1:-1,L=C[0]+D*85;C[1]<0&&C[1]>w.z&&Math.abs(L-w.x*C[1]/w.z)<25||C[0]<30&&C[1]>-1e3&&D>0||Math.hypot(L-w.x,C[1]-w.z)<80||Ti(o,[18,25+P%4*12,20],[L,(25+P%4*12)/2,C[1]],wi(P%2?6910921:12216506,P%2?1976142:4923723))}}return n(d),d},h.setRoute("outward"),h}var Au=class{constructor(e){this.world=e,this.mode="bus",this.reset()}setMode(e){["free","car","bus","plane"].includes(e)&&(this.mode=e,this.reset())}reset(){this.position={...this.mode==="plane"?this.world.planeSpawn:this.mode==="bus"?this.world.busSpawn:this.world.carSpawn},this.yaw=this.world.busYaw??0,this.speed=0,this.steering=0,this.blocked=""}stop(){this.speed=0,this.steering=0,this.blocked=""}step(e,t){if(this.mode==="free")return;let n=Ut(e,0,.1),s=Math.max(1,Math.ceil(n/.01));for(let r=0;r<s;r++)this._step(n/s,t)}_step(e,t){let n=this.mode!=="plane",s=this.mode==="bus",r=!!t.brake||t.throttle<0,o=!r&&(!!t.accelerate||t.throttle>0),a=this.world.roadDistance(this.position.x,this.position.z),c=n?a<=12?22:a<=24?12:6:32;r?this.speed=Math.max(0,this.speed-14*e):o?this.speed=Math.min(c,this.speed+(s?7:9)*e):this.speed=Math.max(0,this.speed-2.2*e),this.speed>c&&(this.speed=Math.max(c,this.speed-12*e)),this.steering+=(Ut(t.steer??0,-1,1)-this.steering)*(1-Math.exp(-e*9)),this.yaw+=this.steering*e*(n?(s?1.3:1.5)*(.45+.55*Math.min(this.speed/5,1)):1);let l={x:this.position.x-Math.sin(this.yaw)*this.speed*e,z:this.position.z-Math.cos(this.yaw)*this.speed*e,y:this.position.y},u=this.world.flightBounds,h=n?3:5,f=l.x,d=l.z;l.x=Ut(l.x,u.min.x+h,u.max.x-h),l.z=Ut(l.z,u.min.z+h,u.max.z-h),this.blocked=f!==l.x||d!==l.z?"\u5883\u754C\u306B\u6CBF\u3063\u3066\u8D70\u884C":n&&a>12?"\u8DEF\u80A9\u30FB\u3086\u3063\u304F\u308A\u8D70\u884C":"";let m=this.world.terrainHeight(l.x,l.z,n?this.position.y:null,this.mode);l.y=n?m+(s?1.4:.8):Ut(l.y+(t.lift??0)*9*e,m+4,90),this.position=l}};var Ru=class{constructor(){this.owners=new Map,this.values=new Set}begin(e,t){return this.owners.has(t)||this.values.has(e)?!1:(this.owners.set(t,e),this.values.add(e),!0)}release(e){let t=this.owners.get(e);this.owners.delete(e),t&&this.values.delete(t)}clear(){this.owners.clear(),this.values.clear()}axes(e){let t=this.values.has("brake"),n=!t&&this.values.has("accelerate");return{brake:t,accelerate:n,throttle:t?-1:n?1:0,steer:Number(this.values.has("left"))-Number(this.values.has("right")),lift:e==="plane"?Number(this.values.has("up"))-Number(this.values.has("down")):0}}};function a0(i,{enabled:e,mode:t,signal:n}){let s=document.querySelector(".controls");s.innerHTML='<div class="drive-buttons" aria-label="\u65B9\u5411"><button data-drive="left" aria-label="\u5DE6\u306B\u66F2\u304C\u308B">\u25C0<small>\u5DE6</small></button><button data-drive="right" aria-label="\u53F3\u306B\u66F2\u304C\u308B">\u25B6<small>\u53F3</small></button><button data-drive="up" class="plane-direction" aria-label="\u4E0A\u6607">\u25B2<small>\u4E0A\u6607</small></button><button data-drive="down" class="plane-direction" aria-label="\u4E0B\u964D">\u25BC<small>\u4E0B\u964D</small></button></div><div class="pedals" aria-label="\u30DA\u30C0\u30EB"><button data-drive="brake" aria-label="\u30D6\u30EC\u30FC\u30AD">\u25A0<small>\u30D6\u30EC\u30FC\u30AD</small></button><button data-drive="accelerate" aria-label="\u30A2\u30AF\u30BB\u30EB">\u25B2<small>\u30A2\u30AF\u30BB\u30EB</small></button></div>';let r=[...s.querySelectorAll("[data-drive]")],o=()=>r.forEach(a=>a.classList.toggle("held",i.values.has(a.dataset.drive)));for(let a of r)a.addEventListener("pointerdown",c=>{if(c.preventDefault(),c.stopPropagation(),!(!e()||!i.begin(a.dataset.drive,c.pointerId))){try{a.setPointerCapture(c.pointerId)}catch{}o()}},{signal:n});window.addEventListener("pointermove",a=>{i.owners.has(a.pointerId)&&(a.preventDefault(),a.stopPropagation())},{signal:n,capture:!0});for(let a of["pointerup","pointercancel"])window.addEventListener(a,c=>{i.owners.has(c.pointerId)&&(c.preventDefault(),c.stopPropagation(),i.release(c.pointerId),o())},{signal:n,capture:!0});for(let a of r)a.addEventListener("lostpointercapture",c=>{i.owners.get(c.pointerId)===a.dataset.drive&&(i.release(c.pointerId),o())},{signal:n});return()=>{for(let[a,c]of i.owners){let l=r.find(u=>u.dataset.drive===c);l?.hasPointerCapture(a)&&l.releasePointerCapture(a)}i.clear(),o()}}function ad(i,e=!1){let t=i[0].index!==null,n=new Set(Object.keys(i[0].attributes)),s=new Set(Object.keys(i[0].morphAttributes)),r={},o={},a=i[0].morphTargetsRelative,c=new ht,l=0;for(let u=0;u<i.length;++u){let h=i[u],f=0;if(t!==(h.index!==null))return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index "+u+". All geometries must have compatible attributes; make sure index attribute exists among all geometries, or in none of them."),null;for(let d in h.attributes){if(!n.has(d))return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index "+u+'. All geometries must have compatible attributes; make sure "'+d+'" attribute exists among all geometries, or in none of them.'),null;r[d]===void 0&&(r[d]=[]),r[d].push(h.attributes[d]),f++}if(f!==n.size)return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index "+u+". Make sure all geometries have the same number of attributes."),null;if(a!==h.morphTargetsRelative)return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index "+u+". .morphTargetsRelative must be consistent throughout all geometries."),null;for(let d in h.morphAttributes){if(!s.has(d))return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index "+u+".  .morphAttributes must be consistent throughout all geometries."),null;o[d]===void 0&&(o[d]=[]),o[d].push(h.morphAttributes[d])}if(e){let d;if(t)d=h.index.count;else if(h.attributes.position!==void 0)d=h.attributes.position.count;else return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index "+u+". The geometry must have either an index or a position attribute"),null;c.addGroup(l,d,u),l+=d}}if(t){let u=0,h=[];for(let f=0;f<i.length;++f){let d=i[f].index;for(let m=0;m<d.count;++m)h.push(d.getX(m)+u);u+=i[f].attributes.position.count}c.setIndex(h)}for(let u in r){let h=c0(r[u]);if(!h)return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed while trying to merge the "+u+" attribute."),null;c.setAttribute(u,h)}for(let u in o){let h=o[u][0].length;if(h!==0){c.morphAttributes=c.morphAttributes||{},c.morphAttributes[u]=[];for(let f=0;f<h;++f){let d=[];for(let x=0;x<o[u].length;++x)d.push(o[u][x][f]);let m=c0(d);if(!m)return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed while trying to merge the "+u+" morphAttribute."),null;c.morphAttributes[u].push(m)}}}return c}function c0(i){let e,t,n,s=-1,r=0;for(let l=0;l<i.length;++l){let u=i[l];if(e===void 0&&(e=u.array.constructor),e!==u.array.constructor)return console.error("THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.array must be of consistent array types across matching attributes."),null;if(t===void 0&&(t=u.itemSize),t!==u.itemSize)return console.error("THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.itemSize must be consistent across matching attributes."),null;if(n===void 0&&(n=u.normalized),n!==u.normalized)return console.error("THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.normalized must be consistent across matching attributes."),null;if(s===-1&&(s=u.gpuType),s!==u.gpuType)return console.error("THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.gpuType must be consistent across matching attributes."),null;r+=u.count*t}let o=new e(r),a=new Tt(o,t,n),c=0;for(let l=0;l<i.length;++l){let u=i[l];if(u.isInterleavedBufferAttribute){let h=c/t;for(let f=0,d=u.count;f<d;f++)for(let m=0;m<t;m++){let x=u.getComponent(f,m);a.setComponent(f+h,m,x)}}else o.set(u.array,c);c+=u.count*t}return s!==void 0&&(a.gpuType=s),a}function cd(i,e){if(e===If)return console.warn("THREE.BufferGeometryUtils.toTrianglesDrawMode(): Geometry already defined as triangles."),i;if(e===no||e===Ba){let t=i.getIndex();if(t===null){let r=[],o=i.getAttribute("position");if(o!==void 0){for(let a=0;a<o.count;a++)r.push(a);i.setIndex(r),t=i.getIndex()}else return console.error("THREE.BufferGeometryUtils.toTrianglesDrawMode(): Undefined position attribute. Processing not possible."),i}let n=t.count-2,s=[];if(e===no)for(let r=1;r<=n;r++)s.push(t.getX(0)),s.push(t.getX(r)),s.push(t.getX(r+1));else for(let r=0;r<n;r++)r%2===0?(s.push(t.getX(r)),s.push(t.getX(r+1)),s.push(t.getX(r+2))):(s.push(t.getX(r+2)),s.push(t.getX(r+1)),s.push(t.getX(r)));return s.length/3!==n&&console.error("THREE.BufferGeometryUtils.toTrianglesDrawMode(): Unable to generate correct amount of triangles."),i.setIndex(s),i.clearGroups(),i}else return console.error("THREE.BufferGeometryUtils.toTrianglesDrawMode(): Unknown draw mode:",e),i}function l0(i){let e=new Map,t=new Map,n=i.clone();return u0(i,n,function(s,r){e.set(r,s),t.set(s,r)}),n.traverse(function(s){if(!s.isSkinnedMesh)return;let r=s,o=e.get(s),a=o.skeleton.bones;r.skeleton=o.skeleton.clone(),r.bindMatrix.copy(o.bindMatrix),r.skeleton.bones=a.map(function(c){return t.get(c)}),r.bind(r.skeleton,r.bindMatrix)}),n}function u0(i,e,t){t(i,e);for(let n=0;n<i.children.length;n++)u0(i.children[n],e.children[n],t)}var uo=class extends vi{constructor(e){super(e),this.dracoLoader=null,this.ktx2Loader=null,this.meshoptDecoder=null,this.pluginCallbacks=[],this.register(function(t){return new md(t)}),this.register(function(t){return new gd(t)}),this.register(function(t){return new wd(t)}),this.register(function(t){return new Ed(t)}),this.register(function(t){return new Ad(t)}),this.register(function(t){return new _d(t)}),this.register(function(t){return new yd(t)}),this.register(function(t){return new vd(t)}),this.register(function(t){return new Sd(t)}),this.register(function(t){return new pd(t)}),this.register(function(t){return new bd(t)}),this.register(function(t){return new xd(t)}),this.register(function(t){return new Td(t)}),this.register(function(t){return new Md(t)}),this.register(function(t){return new fd(t)}),this.register(function(t){return new Cu(t,st.EXT_MESHOPT_COMPRESSION)}),this.register(function(t){return new Cu(t,st.KHR_MESHOPT_COMPRESSION)}),this.register(function(t){return new Rd(t)})}load(e,t,n,s){let r=this,o;if(this.resourcePath!=="")o=this.resourcePath;else if(this.path!==""){let l=Wi.extractUrlBase(e);o=Wi.resolveURL(l,this.path)}else o=Wi.extractUrlBase(e);this.manager.itemStart(e);let a=function(l){s?s(l):console.error(l),r.manager.itemError(e),r.manager.itemEnd(e)},c=new Zr(this.manager);c.setPath(this.path),c.setResponseType("arraybuffer"),c.setRequestHeader(this.requestHeader),c.setWithCredentials(this.withCredentials),c.load(e,function(l){try{r.parse(l,o,function(u){t(u),r.manager.itemEnd(e)},a)}catch(u){a(u)}},n,a)}setDRACOLoader(e){return this.dracoLoader=e,this}setKTX2Loader(e){return this.ktx2Loader=e,this}setMeshoptDecoder(e){return this.meshoptDecoder=e,this}register(e){return this.pluginCallbacks.indexOf(e)===-1&&this.pluginCallbacks.push(e),this}unregister(e){return this.pluginCallbacks.indexOf(e)!==-1&&this.pluginCallbacks.splice(this.pluginCallbacks.indexOf(e),1),this}parse(e,t,n,s){let r,o={},a={},c=new TextDecoder;if(typeof e=="string")r=JSON.parse(e);else if(e instanceof ArrayBuffer)if(c.decode(new Uint8Array(e,0,4))===m0){try{o[st.KHR_BINARY_GLTF]=new Cd(e)}catch(h){s&&s(h);return}r=JSON.parse(o[st.KHR_BINARY_GLTF].content)}else r=JSON.parse(c.decode(e));else r=e;if(r.asset===void 0||r.asset.version[0]<2){s&&s(new Error("THREE.GLTFLoader: Unsupported asset. glTF versions >=2.0 are supported."));return}let l=new Fd(r,{path:t||this.resourcePath||"",crossOrigin:this.crossOrigin,requestHeader:this.requestHeader,manager:this.manager,ktx2Loader:this.ktx2Loader,meshoptDecoder:this.meshoptDecoder});l.fileLoader.setRequestHeader(this.requestHeader);for(let u=0;u<this.pluginCallbacks.length;u++){let h=this.pluginCallbacks[u](l);h.name||console.error("THREE.GLTFLoader: Invalid plugin found: missing name"),a[h.name]=h,o[h.name]=!0}if(r.extensionsUsed)for(let u=0;u<r.extensionsUsed.length;++u){let h=r.extensionsUsed[u],f=r.extensionsRequired||[];switch(h){case st.KHR_MATERIALS_UNLIT:o[h]=new dd;break;case st.KHR_DRACO_MESH_COMPRESSION:o[h]=new Pd(r,this.dracoLoader);break;case st.KHR_TEXTURE_TRANSFORM:o[h]=new Id;break;case st.KHR_MESH_QUANTIZATION:o[h]=new Ld;break;default:f.indexOf(h)>=0&&a[h]===void 0&&console.warn('THREE.GLTFLoader: Unknown extension "'+h+'".')}}l.setExtensions(o),l.setPlugins(a),l.parse(n,s)}parseAsync(e,t){let n=this;return new Promise(function(s,r){n.parse(e,t,s,r)})}};function cT(){let i={};return{get:function(e){return i[e]},add:function(e,t){i[e]=t},remove:function(e){delete i[e]},removeAll:function(){i={}}}}function Wt(i,e,t){let n=i.json.materials[e];return n.extensions&&n.extensions[t]?n.extensions[t]:null}var st={KHR_BINARY_GLTF:"KHR_binary_glTF",KHR_DRACO_MESH_COMPRESSION:"KHR_draco_mesh_compression",KHR_LIGHTS_PUNCTUAL:"KHR_lights_punctual",KHR_MATERIALS_CLEARCOAT:"KHR_materials_clearcoat",KHR_MATERIALS_DISPERSION:"KHR_materials_dispersion",KHR_MATERIALS_IOR:"KHR_materials_ior",KHR_MATERIALS_SHEEN:"KHR_materials_sheen",KHR_MATERIALS_SPECULAR:"KHR_materials_specular",KHR_MATERIALS_TRANSMISSION:"KHR_materials_transmission",KHR_MATERIALS_IRIDESCENCE:"KHR_materials_iridescence",KHR_MATERIALS_ANISOTROPY:"KHR_materials_anisotropy",KHR_MATERIALS_UNLIT:"KHR_materials_unlit",KHR_MATERIALS_VOLUME:"KHR_materials_volume",KHR_TEXTURE_BASISU:"KHR_texture_basisu",KHR_TEXTURE_TRANSFORM:"KHR_texture_transform",KHR_MESH_QUANTIZATION:"KHR_mesh_quantization",KHR_MATERIALS_EMISSIVE_STRENGTH:"KHR_materials_emissive_strength",EXT_MATERIALS_BUMP:"EXT_materials_bump",EXT_TEXTURE_WEBP:"EXT_texture_webp",EXT_TEXTURE_AVIF:"EXT_texture_avif",EXT_MESHOPT_COMPRESSION:"EXT_meshopt_compression",KHR_MESHOPT_COMPRESSION:"KHR_meshopt_compression",EXT_MESH_GPU_INSTANCING:"EXT_mesh_gpu_instancing"},fd=class{constructor(e){this.parser=e,this.name=st.KHR_LIGHTS_PUNCTUAL,this.cache={refs:{},uses:{}}}_markDefs(){let e=this.parser,t=this.parser.json.nodes||[];for(let n=0,s=t.length;n<s;n++){let r=t[n];r.extensions&&r.extensions[this.name]&&r.extensions[this.name].light!==void 0&&e._addNodeRef(this.cache,r.extensions[this.name].light)}}_loadLight(e){let t=this.parser,n="light:"+e,s=t.cache.get(n);if(s)return s;let r=t.json,c=((r.extensions&&r.extensions[this.name]||{}).lights||[])[e],l,u=new Ve(16777215);c.color!==void 0&&u.setRGB(c.color[0],c.color[1],c.color[2],bn);let h=c.range!==void 0?c.range:0;switch(c.type){case"directional":l=new Ws(u),l.target.position.set(0,0,-1),l.add(l.target);break;case"point":l=new Ea(u),l.distance=h;break;case"spot":l=new wa(u),l.distance=h,c.spot=c.spot||{},c.spot.innerConeAngle=c.spot.innerConeAngle!==void 0?c.spot.innerConeAngle:0,c.spot.outerConeAngle=c.spot.outerConeAngle!==void 0?c.spot.outerConeAngle:Math.PI/4,l.angle=c.spot.outerConeAngle,l.penumbra=1-c.spot.innerConeAngle/c.spot.outerConeAngle,l.target.position.set(0,0,-1),l.add(l.target);break;default:throw new Error("THREE.GLTFLoader: Unexpected light type: "+c.type)}return l.position.set(0,0,0),Ei(l,c),c.intensity!==void 0&&(l.intensity=c.intensity),l.name=t.createUniqueName(c.name||"light_"+e),s=Promise.resolve(l),t.cache.add(n,s),s}getDependency(e,t){if(e==="light")return this._loadLight(t)}createNodeAttachment(e){let t=this,n=this.parser,r=n.json.nodes[e],a=(r.extensions&&r.extensions[this.name]||{}).light;return a===void 0?null:this._loadLight(a).then(function(c){return n._getNodeRef(t.cache,a,c)})}},dd=class{constructor(){this.name=st.KHR_MATERIALS_UNLIT}getMaterialType(){return Bn}extendParams(e,t,n){let s=[];e.color=new Ve(1,1,1),e.opacity=1;let r=t.pbrMetallicRoughness;if(r){if(Array.isArray(r.baseColorFactor)){let o=r.baseColorFactor;e.color.setRGB(o[0],o[1],o[2],bn),e.opacity=o[3]}r.baseColorTexture!==void 0&&s.push(n.assignTexture(e,"map",r.baseColorTexture,Ft))}return Promise.all(s)}},pd=class{constructor(e){this.parser=e,this.name=st.KHR_MATERIALS_EMISSIVE_STRENGTH}extendMaterialParams(e,t){let n=Wt(this.parser,e,this.name);return n===null||n.emissiveStrength!==void 0&&(t.emissiveIntensity=n.emissiveStrength),Promise.resolve()}},md=class{constructor(e){this.parser=e,this.name=st.KHR_MATERIALS_CLEARCOAT}getMaterialType(e){return Wt(this.parser,e,this.name)!==null?Ln:null}extendMaterialParams(e,t){let n=Wt(this.parser,e,this.name);if(n===null)return Promise.resolve();let s=[];if(n.clearcoatFactor!==void 0&&(t.clearcoat=n.clearcoatFactor),n.clearcoatTexture!==void 0&&s.push(this.parser.assignTexture(t,"clearcoatMap",n.clearcoatTexture)),n.clearcoatRoughnessFactor!==void 0&&(t.clearcoatRoughness=n.clearcoatRoughnessFactor),n.clearcoatRoughnessTexture!==void 0&&s.push(this.parser.assignTexture(t,"clearcoatRoughnessMap",n.clearcoatRoughnessTexture)),n.clearcoatNormalTexture!==void 0&&(s.push(this.parser.assignTexture(t,"clearcoatNormalMap",n.clearcoatNormalTexture)),n.clearcoatNormalTexture.scale!==void 0)){let r=n.clearcoatNormalTexture.scale;t.clearcoatNormalScale=new ce(r,r)}return Promise.all(s)}},gd=class{constructor(e){this.parser=e,this.name=st.KHR_MATERIALS_DISPERSION}getMaterialType(e){return Wt(this.parser,e,this.name)!==null?Ln:null}extendMaterialParams(e,t){let n=Wt(this.parser,e,this.name);return n===null||(t.dispersion=n.dispersion!==void 0?n.dispersion:0),Promise.resolve()}},xd=class{constructor(e){this.parser=e,this.name=st.KHR_MATERIALS_IRIDESCENCE}getMaterialType(e){return Wt(this.parser,e,this.name)!==null?Ln:null}extendMaterialParams(e,t){let n=Wt(this.parser,e,this.name);if(n===null)return Promise.resolve();let s=[];return n.iridescenceFactor!==void 0&&(t.iridescence=n.iridescenceFactor),n.iridescenceTexture!==void 0&&s.push(this.parser.assignTexture(t,"iridescenceMap",n.iridescenceTexture)),n.iridescenceIor!==void 0&&(t.iridescenceIOR=n.iridescenceIor),t.iridescenceThicknessRange===void 0&&(t.iridescenceThicknessRange=[100,400]),n.iridescenceThicknessMinimum!==void 0&&(t.iridescenceThicknessRange[0]=n.iridescenceThicknessMinimum),n.iridescenceThicknessMaximum!==void 0&&(t.iridescenceThicknessRange[1]=n.iridescenceThicknessMaximum),n.iridescenceThicknessTexture!==void 0&&s.push(this.parser.assignTexture(t,"iridescenceThicknessMap",n.iridescenceThicknessTexture)),Promise.all(s)}},_d=class{constructor(e){this.parser=e,this.name=st.KHR_MATERIALS_SHEEN}getMaterialType(e){return Wt(this.parser,e,this.name)!==null?Ln:null}extendMaterialParams(e,t){let n=Wt(this.parser,e,this.name);if(n===null)return Promise.resolve();let s=[];if(t.sheenColor=new Ve(0,0,0),t.sheenRoughness=0,t.sheen=1,n.sheenColorFactor!==void 0){let r=n.sheenColorFactor;t.sheenColor.setRGB(r[0],r[1],r[2],bn)}return n.sheenRoughnessFactor!==void 0&&(t.sheenRoughness=n.sheenRoughnessFactor),n.sheenColorTexture!==void 0&&s.push(this.parser.assignTexture(t,"sheenColorMap",n.sheenColorTexture,Ft)),n.sheenRoughnessTexture!==void 0&&s.push(this.parser.assignTexture(t,"sheenRoughnessMap",n.sheenRoughnessTexture)),Promise.all(s)}},yd=class{constructor(e){this.parser=e,this.name=st.KHR_MATERIALS_TRANSMISSION}getMaterialType(e){return Wt(this.parser,e,this.name)!==null?Ln:null}extendMaterialParams(e,t){let n=Wt(this.parser,e,this.name);if(n===null)return Promise.resolve();let s=[];return n.transmissionFactor!==void 0&&(t.transmission=n.transmissionFactor),n.transmissionTexture!==void 0&&s.push(this.parser.assignTexture(t,"transmissionMap",n.transmissionTexture)),Promise.all(s)}},vd=class{constructor(e){this.parser=e,this.name=st.KHR_MATERIALS_VOLUME}getMaterialType(e){return Wt(this.parser,e,this.name)!==null?Ln:null}extendMaterialParams(e,t){let n=Wt(this.parser,e,this.name);if(n===null)return Promise.resolve();let s=[];t.thickness=n.thicknessFactor!==void 0?n.thicknessFactor:0,n.thicknessTexture!==void 0&&s.push(this.parser.assignTexture(t,"thicknessMap",n.thicknessTexture)),t.attenuationDistance=n.attenuationDistance||1/0;let r=n.attenuationColor||[1,1,1];return t.attenuationColor=new Ve().setRGB(r[0],r[1],r[2],bn),Promise.all(s)}},Sd=class{constructor(e){this.parser=e,this.name=st.KHR_MATERIALS_IOR}getMaterialType(e){return Wt(this.parser,e,this.name)!==null?Ln:null}extendMaterialParams(e,t){let n=Wt(this.parser,e,this.name);return n===null||(t.ior=n.ior!==void 0?n.ior:1.5,t.ior===0&&(t.ior=1e3)),Promise.resolve()}},bd=class{constructor(e){this.parser=e,this.name=st.KHR_MATERIALS_SPECULAR}getMaterialType(e){return Wt(this.parser,e,this.name)!==null?Ln:null}extendMaterialParams(e,t){let n=Wt(this.parser,e,this.name);if(n===null)return Promise.resolve();let s=[];t.specularIntensity=n.specularFactor!==void 0?n.specularFactor:1,n.specularTexture!==void 0&&s.push(this.parser.assignTexture(t,"specularIntensityMap",n.specularTexture));let r=n.specularColorFactor||[1,1,1];return t.specularColor=new Ve().setRGB(r[0],r[1],r[2],bn),n.specularColorTexture!==void 0&&s.push(this.parser.assignTexture(t,"specularColorMap",n.specularColorTexture,Ft)),Promise.all(s)}},Md=class{constructor(e){this.parser=e,this.name=st.EXT_MATERIALS_BUMP}getMaterialType(e){return Wt(this.parser,e,this.name)!==null?Ln:null}extendMaterialParams(e,t){let n=Wt(this.parser,e,this.name);if(n===null)return Promise.resolve();let s=[];return t.bumpScale=n.bumpFactor!==void 0?n.bumpFactor:1,n.bumpTexture!==void 0&&s.push(this.parser.assignTexture(t,"bumpMap",n.bumpTexture)),Promise.all(s)}},Td=class{constructor(e){this.parser=e,this.name=st.KHR_MATERIALS_ANISOTROPY}getMaterialType(e){return Wt(this.parser,e,this.name)!==null?Ln:null}extendMaterialParams(e,t){let n=Wt(this.parser,e,this.name);if(n===null)return Promise.resolve();let s=[];return n.anisotropyStrength!==void 0&&(t.anisotropy=n.anisotropyStrength),n.anisotropyRotation!==void 0&&(t.anisotropyRotation=n.anisotropyRotation),n.anisotropyTexture!==void 0&&s.push(this.parser.assignTexture(t,"anisotropyMap",n.anisotropyTexture)),Promise.all(s)}},wd=class{constructor(e){this.parser=e,this.name=st.KHR_TEXTURE_BASISU}loadTexture(e){let t=this.parser,n=t.json,s=n.textures[e];if(!s.extensions||!s.extensions[this.name])return null;let r=s.extensions[this.name],o=t.options.ktx2Loader;if(!o){if(n.extensionsRequired&&n.extensionsRequired.indexOf(this.name)>=0)throw new Error("THREE.GLTFLoader: setKTX2Loader must be called before loading KTX2 textures");return null}return t.loadTextureImage(e,r.source,o)}},Ed=class{constructor(e){this.parser=e,this.name=st.EXT_TEXTURE_WEBP}loadTexture(e){let t=this.name,n=this.parser,s=n.json,r=s.textures[e];if(!r.extensions||!r.extensions[t])return null;let o=r.extensions[t],a=s.images[o.source],c=n.textureLoader;if(a.uri){let l=n.options.manager.getHandler(a.uri);l!==null&&(c=l)}return n.loadTextureImage(e,o.source,c)}},Ad=class{constructor(e){this.parser=e,this.name=st.EXT_TEXTURE_AVIF}loadTexture(e){let t=this.name,n=this.parser,s=n.json,r=s.textures[e];if(!r.extensions||!r.extensions[t])return null;let o=r.extensions[t],a=s.images[o.source],c=n.textureLoader;if(a.uri){let l=n.options.manager.getHandler(a.uri);l!==null&&(c=l)}return n.loadTextureImage(e,o.source,c)}},Cu=class{constructor(e,t){this.name=t,this.parser=e}loadBufferView(e){let t=this.parser.json,n=t.bufferViews[e];if(n.extensions&&n.extensions[this.name]){let s=n.extensions[this.name],r=this.parser.getDependency("buffer",s.buffer),o=this.parser.options.meshoptDecoder;if(!o||!o.supported){if(t.extensionsRequired&&t.extensionsRequired.indexOf(this.name)>=0)throw new Error("THREE.GLTFLoader: setMeshoptDecoder must be called before loading compressed files");return null}return r.then(function(a){let c=s.byteOffset||0,l=s.byteLength||0,u=s.count,h=s.byteStride,f=new Uint8Array(a,c,l);return o.decodeGltfBufferAsync?o.decodeGltfBufferAsync(u,h,f,s.mode,s.filter).then(function(d){return d.buffer}):o.ready.then(function(){let d=new ArrayBuffer(u*h);return o.decodeGltfBuffer(new Uint8Array(d),u,h,f,s.mode,s.filter),d})})}else return null}},Rd=class{constructor(e){this.name=st.EXT_MESH_GPU_INSTANCING,this.parser=e}createNodeMesh(e){let t=this.parser.json,n=t.nodes[e];if(!n.extensions||!n.extensions[this.name]||n.mesh===void 0)return null;let s=t.meshes[n.mesh];for(let l of s.primitives)if(l.mode!==Jn.TRIANGLES&&l.mode!==Jn.TRIANGLE_STRIP&&l.mode!==Jn.TRIANGLE_FAN&&l.mode!==void 0)return null;let o=n.extensions[this.name].attributes,a=[],c={};for(let l in o)a.push(this.parser.getDependency("accessor",o[l]).then(u=>(c[l]=u,c[l])));return a.length<1?null:(a.push(this.parser.createNodeMesh(e)),Promise.all(a).then(l=>{let u=l.pop(),h=u.isGroup?u.children:[u],f=l[0].count,d=[];for(let m of h){let x=new Ie,g=new I,p=new pn,v=new I(1,1,1),b=new na(m.geometry,m.material,f);for(let S=0;S<f;S++)c.TRANSLATION&&g.fromBufferAttribute(c.TRANSLATION,S),c.ROTATION&&p.fromBufferAttribute(c.ROTATION,S),c.SCALE&&v.fromBufferAttribute(c.SCALE,S),b.setMatrixAt(S,x.compose(g,p,v));let _=null;for(let S in c)if(S==="_COLOR_0"){let M=c[S];b.instanceColor=new Bi(M.array,M.itemSize,M.normalized)}else if(S!=="TRANSLATION"&&S!=="ROTATION"&&S!=="SCALE"){if(_===null){let E=b.geometry;_=new ht,_.name=E.name;for(let y in E.attributes)_.setAttribute(y,E.attributes[y]);for(let y in E.morphAttributes)_.morphAttributes[y]=E.morphAttributes[y];E.index!==null&&_.setIndex(E.index),_.morphTargetsRelative=E.morphTargetsRelative;for(let y of E.groups)_.addGroup(y.start,y.count,y.materialIndex);E.boundingBox!==null&&(_.boundingBox=E.boundingBox.clone()),E.boundingSphere!==null&&(_.boundingSphere=E.boundingSphere.clone()),_.drawRange.start=E.drawRange.start,_.drawRange.count=E.drawRange.count,_.userData=Object.assign({},E.userData),b.geometry=_}let M=c[S];_.setAttribute(S,new Bi(M.array,M.itemSize,M.normalized))}Nt.prototype.copy.call(b,m),this.parser.assignFinalMaterial(b),d.push(b)}return u.isGroup?(u.clear(),u.add(...d),u):d[0]}))}},m0="glTF",Ga=12,h0={JSON:1313821514,BIN:5130562},Cd=class{constructor(e){this.name=st.KHR_BINARY_GLTF,this.content=null,this.body=null;let t=new DataView(e,0,Ga),n=new TextDecoder;if(this.header={magic:n.decode(new Uint8Array(e.slice(0,4))),version:t.getUint32(4,!0),length:t.getUint32(8,!0)},this.header.magic!==m0)throw new Error("THREE.GLTFLoader: Unsupported glTF-Binary header.");if(this.header.version<2)throw new Error("THREE.GLTFLoader: Legacy binary file detected.");let s=this.header.length-Ga,r=new DataView(e,Ga),o=0;for(;o<s;){let a=r.getUint32(o,!0);o+=4;let c=r.getUint32(o,!0);if(o+=4,c===h0.JSON){let l=new Uint8Array(e,Ga+o,a);this.content=n.decode(l)}else if(c===h0.BIN){let l=Ga+o;this.body=e.slice(l,l+a)}o+=a}if(this.content===null)throw new Error("THREE.GLTFLoader: JSON content not found.")}},Pd=class{constructor(e,t){if(!t)throw new Error("THREE.GLTFLoader: No DRACOLoader instance provided.");this.name=st.KHR_DRACO_MESH_COMPRESSION,this.json=e,this.dracoLoader=t,this.dracoLoader.preload()}decodePrimitive(e,t){let n=this.json,s=this.dracoLoader,r=e.extensions[this.name].bufferView,o=e.extensions[this.name].attributes,a={},c={},l={};for(let u in o){let h=Dd[u]||u.toLowerCase();a[h]=o[u]}for(let u in e.attributes){let h=Dd[u]||u.toLowerCase();if(o[u]!==void 0){let f=n.accessors[e.attributes[u]],d=lo[f.componentType];l[h]=d.name,c[h]=f.normalized===!0}}return t.getDependency("bufferView",r).then(function(u){return new Promise(function(h,f){s.decodeDracoFile(u,function(d){for(let m in d.attributes){let x=d.attributes[m],g=c[m];g!==void 0&&(x.normalized=g)}h(d)},a,l,bn,f)})})}},Id=class{constructor(){this.name=st.KHR_TEXTURE_TRANSFORM}extendTexture(e,t){if((t.texCoord===void 0||t.texCoord===e.channel)&&t.offset===void 0&&t.rotation===void 0&&t.scale===void 0)return e;if(e=e.clone(),t.texCoord!==void 0&&(e.channel=t.texCoord),t.offset!==void 0&&e.offset.fromArray(t.offset),t.rotation!==void 0&&(e.rotation=t.rotation),t.scale!==void 0&&e.repeat.fromArray(t.scale),t.rotation!==void 0){let n=Math.cos(e.rotation),s=Math.sin(e.rotation);e.matrix.set(e.repeat.x*n,e.repeat.y*s,e.offset.x,-e.repeat.x*s,e.repeat.y*n,e.offset.y,0,0,1),e.matrixAutoUpdate=!1}return e.needsUpdate=!0,e}},Ld=class{constructor(){this.name=st.KHR_MESH_QUANTIZATION}},Pu=class extends yi{constructor(e,t,n,s){super(e,t,n,s)}copySampleValue_(e){let t=this.resultBuffer,n=this.sampleValues,s=this.valueSize,r=e*s*3+s;for(let o=0;o!==s;o++)t[o]=n[r+o];return t}interpolate_(e,t,n,s){let r=this.resultBuffer,o=this.sampleValues,a=this.valueSize,c=a*2,l=a*3,u=s-t,h=(n-t)/u,f=h*h,d=f*h,m=e*l,x=m-l,g=-2*d+3*f,p=d-f,v=1-g,b=p-f+h;for(let _=0;_!==a;_++){let S=o[x+_+a],M=o[x+_+c]*u,E=o[m+_+a],y=o[m+_]*u;r[_]=v*S+b*M+g*E+p*y}return r}},lT=new pn,Nd=class extends Pu{interpolate_(e,t,n,s){let r=super.interpolate_(e,t,n,s);return lT.fromArray(r).normalize().toArray(r),r}},Jn={FLOAT:5126,FLOAT_MAT3:35675,FLOAT_MAT4:35676,FLOAT_VEC2:35664,FLOAT_VEC3:35665,FLOAT_VEC4:35666,LINEAR:9729,REPEAT:10497,SAMPLER_2D:35678,POINTS:0,LINES:1,LINE_LOOP:2,LINE_STRIP:3,TRIANGLES:4,TRIANGLE_STRIP:5,TRIANGLE_FAN:6,UNSIGNED_BYTE:5121,UNSIGNED_SHORT:5123},lo={5120:Int8Array,5121:Uint8Array,5122:Int16Array,5123:Uint16Array,5125:Uint32Array,5126:Float32Array},f0={9728:Ht,9729:Gt,9984:Rl,9985:Qr,9986:Zs,9987:ai},d0={33071:Zn,33648:Nr,10497:cs},ld={SCALAR:1,VEC2:2,VEC3:3,VEC4:4,MAT2:4,MAT3:9,MAT4:16},Dd={POSITION:"position",NORMAL:"normal",TANGENT:"tangent",TEXCOORD_0:"uv",TEXCOORD_1:"uv1",TEXCOORD_2:"uv2",TEXCOORD_3:"uv3",COLOR_0:"color",WEIGHTS_0:"skinWeight",JOINTS_0:"skinIndex"},vs={scale:"scale",translation:"position",rotation:"quaternion",weights:"morphTargetInfluences"},uT={CUBICSPLINE:void 0,LINEAR:Fs,STEP:Us},ud={OPAQUE:"OPAQUE",MASK:"MASK",BLEND:"BLEND"};function hT(i){return i.DefaultMaterial===void 0&&(i.DefaultMaterial=new $t({color:16777215,emissive:0,metalness:1,roughness:1,transparent:!1,depthTest:!0,side:kn})),i.DefaultMaterial}function js(i,e,t){for(let n in t.extensions)i[n]===void 0&&(e.userData.gltfExtensions=e.userData.gltfExtensions||{},e.userData.gltfExtensions[n]=t.extensions[n])}function Ei(i,e){e.extras!==void 0&&(typeof e.extras=="object"?Object.assign(i.userData,e.extras):console.warn("THREE.GLTFLoader: Ignoring primitive type .extras, "+e.extras))}function fT(i,e,t){let n=!1,s=!1,r=!1;for(let l=0,u=e.length;l<u;l++){let h=e[l];if(h.POSITION!==void 0&&(n=!0),h.NORMAL!==void 0&&(s=!0),h.COLOR_0!==void 0&&(r=!0),n&&s&&r)break}if(!n&&!s&&!r)return Promise.resolve(i);let o=[],a=[],c=[];for(let l=0,u=e.length;l<u;l++){let h=e[l];if(n){let f=h.POSITION!==void 0?t.getDependency("accessor",h.POSITION):i.attributes.position;o.push(f)}if(s){let f=h.NORMAL!==void 0?t.getDependency("accessor",h.NORMAL):i.attributes.normal;a.push(f)}if(r){let f=h.COLOR_0!==void 0?t.getDependency("accessor",h.COLOR_0):i.attributes.color;c.push(f)}}return Promise.all([Promise.all(o),Promise.all(a),Promise.all(c)]).then(function(l){let u=l[0],h=l[1],f=l[2];return n&&(i.morphAttributes.position=u),s&&(i.morphAttributes.normal=h),r&&(i.morphAttributes.color=f),i.morphTargetsRelative=!0,i})}function dT(i,e){if(i.updateMorphTargets(),e.weights!==void 0)for(let t=0,n=e.weights.length;t<n;t++)i.morphTargetInfluences[t]=e.weights[t];if(e.extras&&Array.isArray(e.extras.targetNames)){let t=e.extras.targetNames;if(i.morphTargetInfluences.length===t.length){i.morphTargetDictionary={};for(let n=0,s=t.length;n<s;n++)i.morphTargetDictionary[t[n]]=n}else console.warn("THREE.GLTFLoader: Invalid extras.targetNames length. Ignoring names.")}}function pT(i){let e,t=i.extensions&&i.extensions[st.KHR_DRACO_MESH_COMPRESSION];if(t?e="draco:"+t.bufferView+":"+t.indices+":"+hd(t.attributes):e=i.indices+":"+hd(i.attributes)+":"+i.mode,i.targets!==void 0)for(let n=0,s=i.targets.length;n<s;n++)e+=":"+hd(i.targets[n]);return e}function hd(i){let e="",t=Object.keys(i).sort();for(let n=0,s=t.length;n<s;n++)e+=t[n]+":"+i[t[n]]+";";return e}function Ud(i){switch(i){case Int8Array:return 1/127;case Uint8Array:return 1/255;case Int16Array:return 1/32767;case Uint16Array:return 1/65535;default:throw new Error("THREE.GLTFLoader: Unsupported normalized accessor component type.")}}function mT(i){return i.search(/\.jpe?g($|\?)/i)>0||i.search(/^data\:image\/jpeg/)===0?"image/jpeg":i.search(/\.webp($|\?)/i)>0||i.search(/^data\:image\/webp/)===0?"image/webp":i.search(/\.ktx2($|\?)/i)>0||i.search(/^data\:image\/ktx2/)===0?"image/ktx2":"image/png"}var gT=new Ie,Fd=class{constructor(e={},t={}){this.json=e,this.extensions={},this.plugins={},this.options=t,this.cache=new cT,this.associations=new Map,this.primitiveCache={},this.nodeCache={},this.meshCache={refs:{},uses:{}},this.cameraCache={refs:{},uses:{}},this.lightCache={refs:{},uses:{}},this.sourceCache={},this.textureCache={},this.nodeNamesUsed={};let n=!1,s=-1,r=!1,o=-1;if(typeof navigator<"u"&&typeof navigator.userAgent<"u"){let a=navigator.userAgent;n=/^((?!chrome|android).)*safari/i.test(a)===!0;let c=a.match(/Version\/(\d+)/);s=n&&c?parseInt(c[1],10):-1,r=a.indexOf("Firefox")>-1,o=r?a.match(/Firefox\/([0-9]+)\./)[1]:-1}typeof createImageBitmap>"u"||n&&s<17||r&&o<98?this.textureLoader=new Hs(this.options.manager):this.textureLoader=new Aa(this.options.manager),this.textureLoader.setCrossOrigin(this.options.crossOrigin),this.textureLoader.setRequestHeader(this.options.requestHeader),this.fileLoader=new Zr(this.options.manager),this.fileLoader.setResponseType("arraybuffer"),this.options.crossOrigin==="use-credentials"&&this.fileLoader.setWithCredentials(!0)}setExtensions(e){this.extensions=e}setPlugins(e){this.plugins=e}parse(e,t){let n=this,s=this.json,r=this.extensions;this.cache.removeAll(),this.nodeCache={},this._invokeAll(function(o){return o._markDefs&&o._markDefs()}),Promise.all(this._invokeAll(function(o){return o.beforeRoot&&o.beforeRoot()})).then(function(){return Promise.all([n.getDependencies("scene"),n.getDependencies("animation"),n.getDependencies("camera")])}).then(function(o){let a={scene:o[0][s.scene||0],scenes:o[0],animations:o[1],cameras:o[2],asset:s.asset,parser:n,userData:{}};return js(r,a,s),Ei(a,s),Promise.all(n._invokeAll(function(c){return c.afterRoot&&c.afterRoot(a)})).then(function(){for(let c of a.scenes)c.updateMatrixWorld();e(a)})}).catch(t)}_markDefs(){let e=this.json.nodes||[],t=this.json.skins||[],n=this.json.meshes||[];for(let s=0,r=t.length;s<r;s++){let o=t[s].joints;for(let a=0,c=o.length;a<c;a++)e[o[a]].isBone=!0}for(let s=0,r=e.length;s<r;s++){let o=e[s];o.mesh!==void 0&&(this._addNodeRef(this.meshCache,o.mesh),o.skin!==void 0&&(n[o.mesh].isSkinnedMesh=!0)),o.camera!==void 0&&this._addNodeRef(this.cameraCache,o.camera)}}_addNodeRef(e,t){t!==void 0&&(e.refs[t]===void 0&&(e.refs[t]=e.uses[t]=0),e.refs[t]++)}_getNodeRef(e,t,n){if(e.refs[t]<=1)return n;let s=n.clone(),r=(o,a)=>{let c=this.associations.get(o);c!=null&&this.associations.set(a,c);for(let[l,u]of o.children.entries())r(u,a.children[l])};return r(n,s),s.name+="_instance_"+e.uses[t]++,s}_invokeOne(e){let t=Object.values(this.plugins);t.push(this);for(let n=0;n<t.length;n++){let s=e(t[n]);if(s)return s}return null}_invokeAll(e){let t=Object.values(this.plugins);t.unshift(this);let n=[];for(let s=0;s<t.length;s++){let r=e(t[s]);r&&n.push(r)}return n}getDependency(e,t){let n=e+":"+t,s=this.cache.get(n);if(!s){switch(e){case"scene":s=this.loadScene(t);break;case"node":s=this._invokeOne(function(r){return r.loadNode&&r.loadNode(t)});break;case"mesh":s=this._invokeOne(function(r){return r.loadMesh&&r.loadMesh(t)});break;case"accessor":s=this.loadAccessor(t);break;case"bufferView":s=this._invokeOne(function(r){return r.loadBufferView&&r.loadBufferView(t)});break;case"buffer":s=this.loadBuffer(t);break;case"material":s=this._invokeOne(function(r){return r.loadMaterial&&r.loadMaterial(t)});break;case"texture":s=this._invokeOne(function(r){return r.loadTexture&&r.loadTexture(t)});break;case"skin":s=this.loadSkin(t);break;case"animation":s=this._invokeOne(function(r){return r.loadAnimation&&r.loadAnimation(t)});break;case"camera":s=this.loadCamera(t);break;default:if(s=this._invokeOne(function(r){return r!=this&&r.getDependency&&r.getDependency(e,t)}),!s)throw new Error("Unknown type: "+e);break}this.cache.add(n,s)}return s}getDependencies(e){let t=this.cache.get(e);if(!t){let n=this,s=this.json[e+(e==="mesh"?"es":"s")]||[];t=Promise.all(s.map(function(r,o){return n.getDependency(e,o)})),this.cache.add(e,t)}return t}loadBuffer(e){let t=this.json.buffers[e],n=this.fileLoader;if(t.type&&t.type!=="arraybuffer")throw new Error("THREE.GLTFLoader: "+t.type+" buffer type is not supported.");if(t.uri===void 0&&e===0)return Promise.resolve(this.extensions[st.KHR_BINARY_GLTF].body);let s=this.options;return new Promise(function(r,o){n.load(Wi.resolveURL(t.uri,s.path),r,void 0,function(){o(new Error('THREE.GLTFLoader: Failed to load buffer "'+t.uri+'".'))})})}loadBufferView(e){let t=this.json.bufferViews[e];return this.getDependency("buffer",t.buffer).then(function(n){let s=t.byteLength||0,r=t.byteOffset||0;return n.slice(r,r+s)})}loadAccessor(e){let t=this,n=this.json,s=this.json.accessors[e];if(s.bufferView===void 0&&s.sparse===void 0){let o=ld[s.type],a=lo[s.componentType],c=s.normalized===!0,l=new a(s.count*o);return Promise.resolve(new Tt(l,o,c))}let r=[];return s.bufferView!==void 0?r.push(this.getDependency("bufferView",s.bufferView)):r.push(null),s.sparse!==void 0&&(r.push(this.getDependency("bufferView",s.sparse.indices.bufferView)),r.push(this.getDependency("bufferView",s.sparse.values.bufferView))),Promise.all(r).then(function(o){let a=o[0],c=ld[s.type],l=lo[s.componentType],u=l.BYTES_PER_ELEMENT,h=u*c,f=s.byteOffset||0,d=s.bufferView!==void 0?n.bufferViews[s.bufferView].byteStride:void 0,m=s.normalized===!0,x,g;if(d&&d!==h){let p=Math.floor(f/d),v="InterleavedBuffer:"+s.bufferView+":"+s.componentType+":"+p+":"+s.count,b=t.cache.get(v);b||(x=new l(a,p*d,s.count*d/u),b=new zs(x,d/u),t.cache.add(v,b)),g=new ls(b,c,f%d/u,m)}else a===null?x=new l(s.count*c):x=new l(a,f,s.count*c),g=new Tt(x,c,m);if(s.sparse!==void 0){let p=ld.SCALAR,v=lo[s.sparse.indices.componentType],b=s.sparse.indices.byteOffset||0,_=s.sparse.values.byteOffset||0,S=new v(o[1],b,s.sparse.count*p),M=new l(o[2],_,s.sparse.count*c);a!==null&&(g=new Tt(g.array.slice(),g.itemSize,g.normalized)),g.normalized=!1;for(let E=0,y=S.length;E<y;E++){let w=S[E];if(g.setX(w,M[E*c]),c>=2&&g.setY(w,M[E*c+1]),c>=3&&g.setZ(w,M[E*c+2]),c>=4&&g.setW(w,M[E*c+3]),c>=5)throw new Error("THREE.GLTFLoader: Unsupported itemSize in sparse BufferAttribute.")}g.normalized=m}return g})}loadTexture(e){let t=this.json,n=this.options,r=t.textures[e].source,o=t.images[r],a=this.textureLoader;if(o.uri){let c=n.manager.getHandler(o.uri);c!==null&&(a=c)}return this.loadTextureImage(e,r,a)}loadTextureImage(e,t,n){let s=this,r=this.json,o=r.textures[e],a=r.images[t],c=(a.uri||a.bufferView)+":"+o.sampler;if(this.textureCache[c])return this.textureCache[c];let l=this.loadImageSource(t,n).then(function(u){u.flipY=!1,u.name=o.name||a.name||"",u.name===""&&typeof a.uri=="string"&&a.uri.startsWith("data:image/")===!1&&(u.name=a.uri);let f=(r.samplers||{})[o.sampler]||{};return u.magFilter=f0[f.magFilter]||Gt,u.minFilter=f0[f.minFilter]||ai,u.wrapS=d0[f.wrapS]||cs,u.wrapT=d0[f.wrapT]||cs,u.generateMipmaps=!u.isCompressedTexture&&u.minFilter!==Ht&&u.minFilter!==Gt,s.associations.set(u,{textures:e}),u}).catch(function(){return null});return this.textureCache[c]=l,l}loadImageSource(e,t){let n=this,s=this.json,r=this.options;if(this.sourceCache[e]!==void 0)return this.sourceCache[e].then(h=>h.clone());let o=s.images[e],a=self.URL||self.webkitURL,c=o.uri||"",l=!1;if(o.bufferView!==void 0)c=n.getDependency("bufferView",o.bufferView).then(function(h){l=!0;let f=new Blob([h],{type:o.mimeType});return c=a.createObjectURL(f),c});else if(o.uri===void 0)throw new Error("THREE.GLTFLoader: Image "+e+" is missing URI and bufferView");let u=Promise.resolve(c).then(function(h){return new Promise(function(f,d){let m=f;t.isImageBitmapLoader===!0&&(m=function(x){let g=new Jt(x);g.needsUpdate=!0,f(g)}),t.load(Wi.resolveURL(h,r.path),m,void 0,d)})}).then(function(h){return l===!0&&a.revokeObjectURL(c),Ei(h,o),h.userData.mimeType=o.mimeType||mT(o.uri),h}).catch(function(h){throw console.error("THREE.GLTFLoader: Couldn't load texture",c),h});return this.sourceCache[e]=u,u}assignTexture(e,t,n,s){let r=this;return this.getDependency("texture",n.index).then(function(o){if(!o)return null;if(n.texCoord!==void 0&&n.texCoord>0&&(o=o.clone(),o.channel=n.texCoord),r.extensions[st.KHR_TEXTURE_TRANSFORM]){let a=n.extensions!==void 0?n.extensions[st.KHR_TEXTURE_TRANSFORM]:void 0;if(a){let c=r.associations.get(o);o=r.extensions[st.KHR_TEXTURE_TRANSFORM].extendTexture(o,a),r.associations.set(o,c)}}return s!==void 0&&(o.colorSpace=s),e[t]=o,o})}assignFinalMaterial(e){let t=e.geometry,n=e.material,s=t.attributes.tangent===void 0,r=t.attributes.color!==void 0,o=t.attributes.normal===void 0;if(e.isPoints){let a="PointsMaterial:"+n.uuid,c=this.cache.get(a);c||(c=new Wr,Mn.prototype.copy.call(c,n),c.color.copy(n.color),c.map=n.map,c.sizeAttenuation=!1,this.cache.add(a,c)),n=c}else if(e.isLine){let a="LineBasicMaterial:"+n.uuid,c=this.cache.get(a);c||(c=new us,Mn.prototype.copy.call(c,n),c.color.copy(n.color),c.map=n.map,this.cache.add(a,c)),n=c}if(s||r||o){let a="ClonedMaterial:"+n.uuid+":";s&&(a+="derivative-tangents:"),r&&(a+="vertex-colors:"),o&&(a+="flat-shading:");let c=this.cache.get(a);c||(c=n.clone(),r&&(c.vertexColors=!0),o&&(c.flatShading=!0),s&&(c.normalScale&&(c.normalScale.y*=-1),c.clearcoatNormalScale&&(c.clearcoatNormalScale.y*=-1)),this.cache.add(a,c),this.associations.set(c,this.associations.get(n))),n=c}e.material=n}getMaterialType(){return $t}loadMaterial(e){let t=this,n=this.json,s=this.extensions,r=n.materials[e],o,a={},c=r.extensions||{},l=[];if(c[st.KHR_MATERIALS_UNLIT]){let h=s[st.KHR_MATERIALS_UNLIT];o=h.getMaterialType(),l.push(h.extendParams(a,r,t))}else{let h=r.pbrMetallicRoughness||{};if(a.color=new Ve(1,1,1),a.opacity=1,Array.isArray(h.baseColorFactor)){let f=h.baseColorFactor;a.color.setRGB(f[0],f[1],f[2],bn),a.opacity=f[3]}h.baseColorTexture!==void 0&&l.push(t.assignTexture(a,"map",h.baseColorTexture,Ft)),a.metalness=h.metallicFactor!==void 0?h.metallicFactor:1,a.roughness=h.roughnessFactor!==void 0?h.roughnessFactor:1,h.metallicRoughnessTexture!==void 0&&(l.push(t.assignTexture(a,"metalnessMap",h.metallicRoughnessTexture)),l.push(t.assignTexture(a,"roughnessMap",h.metallicRoughnessTexture))),o=this._invokeOne(function(f){return f.getMaterialType&&f.getMaterialType(e)}),l.push(Promise.all(this._invokeAll(function(f){return f.extendMaterialParams&&f.extendMaterialParams(e,a)})))}r.doubleSided===!0&&(a.side=Dt);let u=r.alphaMode||ud.OPAQUE;if(u===ud.BLEND?(a.transparent=!0,a.depthWrite=!1):(a.transparent=!1,u===ud.MASK&&(a.alphaTest=r.alphaCutoff!==void 0?r.alphaCutoff:.5)),r.normalTexture!==void 0&&o!==Bn&&(l.push(t.assignTexture(a,"normalMap",r.normalTexture)),a.normalScale=new ce(1,1),r.normalTexture.scale!==void 0)){let h=r.normalTexture.scale;a.normalScale.set(h,h)}if(r.occlusionTexture!==void 0&&o!==Bn&&(l.push(t.assignTexture(a,"aoMap",r.occlusionTexture)),r.occlusionTexture.strength!==void 0&&(a.aoMapIntensity=r.occlusionTexture.strength)),r.emissiveFactor!==void 0&&o!==Bn){let h=r.emissiveFactor;a.emissive=new Ve().setRGB(h[0],h[1],h[2],bn)}return r.emissiveTexture!==void 0&&o!==Bn&&l.push(t.assignTexture(a,"emissiveMap",r.emissiveTexture,Ft)),Promise.all(l).then(function(){let h=new o(a);return r.name&&(h.name=r.name),Ei(h,r),t.associations.set(h,{materials:e}),r.extensions&&js(s,h,r),h})}createUniqueName(e){let t=At.sanitizeNodeName(e||"");return t in this.nodeNamesUsed?t+"_"+ ++this.nodeNamesUsed[t]:(this.nodeNamesUsed[t]=0,t)}loadGeometries(e){let t=this,n=this.extensions,s=this.primitiveCache;function r(a){return n[st.KHR_DRACO_MESH_COMPRESSION].decodePrimitive(a,t).then(function(c){return p0(c,a,t)})}let o=[];for(let a=0,c=e.length;a<c;a++){let l=e[a],u=pT(l),h=s[u];if(h)o.push(h.promise);else{let f;l.extensions&&l.extensions[st.KHR_DRACO_MESH_COMPRESSION]?f=r(l):f=p0(new ht,l,t),l.mode===Jn.TRIANGLE_STRIP?f=f.then(d=>cd(d,Ba)):l.mode===Jn.TRIANGLE_FAN&&(f=f.then(d=>cd(d,no))),s[u]={primitive:l,promise:f},o.push(f)}}return Promise.all(o)}loadMesh(e){let t=this,n=this.json,s=this.extensions,r=n.meshes[e],o=r.primitives,a=[];for(let c=0,l=o.length;c<l;c++){let u=o[c].material===void 0?hT(this.cache):this.getDependency("material",o[c].material);a.push(u)}return a.push(t.loadGeometries(o)),Promise.all(a).then(async function(c){let l=c.slice(0,c.length-1),u=c[c.length-1],h=[];for(let d=0,m=u.length;d<m;d++){let x=u[d],g=o[d],p,v=l[d];if(g.mode===Jn.TRIANGLES||g.mode===Jn.TRIANGLE_STRIP||g.mode===Jn.TRIANGLE_FAN||g.mode===void 0){let b=r.isSkinnedMesh===!0,_=x.hasAttribute("skinIndex")&&x.hasAttribute("skinWeight");b&&_===!1&&console.warn("THREE.GLTFLoader: Missing skinIndex or skinWeight attributes. Skinning disabled."),p=b&&_?new ea(x,v):new it(x,v),p.isSkinnedMesh===!0&&p.normalizeSkinWeights()}else if(g.mode===Jn.LINES)p=new ia(x,v);else if(g.mode===Jn.LINE_STRIP)p=new zi(x,v);else if(g.mode===Jn.LINE_LOOP)p=new sa(x,v);else if(g.mode===Jn.POINTS)p=new ra(x,v);else throw new Error("THREE.GLTFLoader: Primitive mode unsupported: "+g.mode);Object.keys(p.geometry.morphAttributes).length>0&&dT(p,r),p.name=t.createUniqueName(r.name||"mesh_"+e),Ei(p,r),g.extensions&&js(s,p,g),t.assignFinalMaterial(p),h.push(p)}for(let d=0,m=h.length;d<m;d++)t.associations.set(h[d],{meshes:e,primitives:d});if(h.length===1)return r.extensions&&js(s,h[0],r),h[0];let f=new Bt;r.extensions&&js(s,f,r),t.associations.set(f,{meshes:e});for(let d=0,m=h.length;d<m;d++)f.add(h[d]);return f})}loadCamera(e){let t,n=this.json.cameras[e],s=n[n.type];if(!s){console.warn("THREE.GLTFLoader: Missing camera parameters.");return}return n.type==="perspective"?t=new Yt(qi.radToDeg(s.yfov),s.aspectRatio||1,s.znear||1,s.zfar||2e6):n.type==="orthographic"&&(t=new ps(-s.xmag,s.xmag,s.ymag,-s.ymag,s.znear,s.zfar)),n.name&&(t.name=this.createUniqueName(n.name)),Ei(t,n),Promise.resolve(t)}loadSkin(e){let t=this.json.skins[e],n=[];for(let s=0,r=t.joints.length;s<r;s++)n.push(this._loadNodeShallow(t.joints[s]));return t.inverseBindMatrices!==void 0?n.push(this.getDependency("accessor",t.inverseBindMatrices)):n.push(null),Promise.all(n).then(function(s){let r=s.pop(),o=s,a=[],c=[];for(let l=0,u=o.length;l<u;l++){let h=o[l];if(h){a.push(h);let f=new Ie;r!==null&&f.fromArray(r.array,l*16),c.push(f)}else console.warn('THREE.GLTFLoader: Joint "%s" could not be found.',t.joints[l])}return new ta(a,c)})}loadAnimation(e){let t=this.json,n=this,s=t.animations[e],r=s.name?s.name:"animation_"+e,o=[],a=[],c=[],l=[],u=[];for(let h=0,f=s.channels.length;h<f;h++){let d=s.channels[h],m=s.samplers[d.sampler],x=d.target,g=x.node,p=s.parameters!==void 0?s.parameters[m.input]:m.input,v=s.parameters!==void 0?s.parameters[m.output]:m.output;x.node!==void 0&&(o.push(this.getDependency("node",g)),a.push(this.getDependency("accessor",p)),c.push(this.getDependency("accessor",v)),l.push(m),u.push(x))}return Promise.all([Promise.all(o),Promise.all(a),Promise.all(c),Promise.all(l),Promise.all(u)]).then(function(h){let f=h[0],d=h[1],m=h[2],x=h[3],g=h[4],p=[];for(let b=0,_=f.length;b<_;b++){let S=f[b],M=d[b],E=m[b],y=x[b],w=g[b];if(S===void 0)continue;S.updateMatrix&&S.updateMatrix();let A=n._createAnimationTracks(S,M,E,y,w);if(A)for(let P=0;P<A.length;P++)p.push(A[P])}let v=new ba(r,void 0,p);return Ei(v,s),v})}createNodeMesh(e){let t=this.json,n=this,s=t.nodes[e];return s.mesh===void 0?null:n.getDependency("mesh",s.mesh).then(function(r){let o=n._getNodeRef(n.meshCache,s.mesh,r);return s.weights!==void 0&&o.traverse(function(a){if(a.isMesh)for(let c=0,l=s.weights.length;c<l;c++)a.morphTargetInfluences[c]=s.weights[c]}),o})}loadNode(e){let t=this.json,n=this,s=t.nodes[e],r=n._loadNodeShallow(e),o=[],a=s.children||[];for(let l=0,u=a.length;l<u;l++)o.push(n.getDependency("node",a[l]));let c=s.skin===void 0?Promise.resolve(null):n.getDependency("skin",s.skin);return Promise.all([r,Promise.all(o),c]).then(function(l){let u=l[0],h=l[1],f=l[2];f!==null&&u.traverse(function(d){d.isSkinnedMesh&&d.bind(f,gT)});for(let d=0,m=h.length;d<m;d++)u.add(h[d]);if(u.userData.pivot!==void 0&&h.length>0){let d=u.userData.pivot,m=h[0];u.pivot=new I().fromArray(d),u.position.x-=d[0],u.position.y-=d[1],u.position.z-=d[2],m.position.set(0,0,0),delete u.userData.pivot}return u})}_loadNodeShallow(e){let t=this.json,n=this.extensions,s=this;if(this.nodeCache[e]!==void 0)return this.nodeCache[e];let r=t.nodes[e],o=r.name?s.createUniqueName(r.name):"",a=[],c=s._invokeOne(function(l){return l.createNodeMesh&&l.createNodeMesh(e)});return c&&a.push(c),r.camera!==void 0&&a.push(s.getDependency("camera",r.camera).then(function(l){return s._getNodeRef(s.cameraCache,r.camera,l)})),s._invokeAll(function(l){return l.createNodeAttachment&&l.createNodeAttachment(e)}).forEach(function(l){a.push(l)}),this.nodeCache[e]=Promise.all(a).then(function(l){let u;if(r.isBone===!0?u=new Vr:l.length>1?u=new Bt:l.length===1?u=l[0]:u=new Nt,u!==l[0])for(let h=0,f=l.length;h<f;h++)u.add(l[h]);if(r.name&&(u.userData.name=r.name,u.name=o),Ei(u,r),r.extensions&&js(n,u,r),r.matrix!==void 0){let h=new Ie;h.fromArray(r.matrix),u.applyMatrix4(h)}else r.translation!==void 0&&u.position.fromArray(r.translation),r.rotation!==void 0&&u.quaternion.fromArray(r.rotation),r.scale!==void 0&&u.scale.fromArray(r.scale);if(!s.associations.has(u))s.associations.set(u,{});else if(r.mesh!==void 0&&s.meshCache.refs[r.mesh]>1){let h=s.associations.get(u);s.associations.set(u,{...h})}return s.associations.get(u).nodes=e,u}),this.nodeCache[e]}loadScene(e){let t=this.extensions,n=this.json.scenes[e],s=this,r=new Bt;n.name&&(r.name=s.createUniqueName(n.name)),Ei(r,n),n.extensions&&js(t,r,n);let o=n.nodes||[],a=[];for(let c=0,l=o.length;c<l;c++)a.push(s.getDependency("node",o[c]));return Promise.all(a).then(function(c){for(let u=0,h=c.length;u<h;u++){let f=c[u];f.parent!==null?r.add(l0(f)):r.add(f)}let l=u=>{let h=new Map;for(let[f,d]of s.associations)(f instanceof Mn||f instanceof Jt)&&h.set(f,d);return u.traverse(f=>{let d=s.associations.get(f);d!=null&&h.set(f,d)}),h};return s.associations=l(r),r})}_createAnimationTracks(e,t,n,s,r){let o=[],a=e.name?e.name:e.uuid,c=[];function l(d){d.morphTargetInfluences&&c.push(d.name?d.name:d.uuid)}vs[r.path]===vs.weights?(l(e),e.isGroup&&e.children.forEach(l)):c.push(a);let u;switch(vs[r.path]){case vs.weights:u=Vi;break;case vs.rotation:u=Hi;break;case vs.translation:case vs.scale:u=ds;break;default:n.itemSize===1?u=Vi:u=ds;break}let h=s.interpolation!==void 0?uT[s.interpolation]:Fs,f=this._getArrayFromAccessor(n);for(let d=0,m=c.length;d<m;d++){let x=new u(c[d]+"."+vs[r.path],t.array,f,h);s.interpolation==="CUBICSPLINE"&&this._createCubicSplineTrackInterpolant(x),o.push(x)}return o}_getArrayFromAccessor(e){let t=e.array;if(e.normalized){let n=Ud(t.constructor),s=new Float32Array(t.length);for(let r=0,o=t.length;r<o;r++)s[r]=t[r]*n;t=s}return t}_createCubicSplineTrackInterpolant(e){e.createInterpolant=function(n){let s=this instanceof Hi?Nd:Pu;return new s(this.times,this.values,this.getValueSize()/3,n)},e.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline=!0}};function xT(i,e,t){let n=e.attributes,s=new Ke;if(n.POSITION!==void 0){let a=t.json.accessors[n.POSITION],c=a.min,l=a.max;if(c!==void 0&&l!==void 0){if(s.set(new I(c[0],c[1],c[2]),new I(l[0],l[1],l[2])),a.normalized){let u=Ud(lo[a.componentType]);s.min.multiplyScalar(u),s.max.multiplyScalar(u)}}else{console.warn("THREE.GLTFLoader: Missing min/max properties for accessor POSITION.");return}}else return;let r=e.targets;if(r!==void 0){let a=new I,c=new I;for(let l=0,u=r.length;l<u;l++){let h=r[l];if(h.POSITION!==void 0){let f=t.json.accessors[h.POSITION],d=f.min,m=f.max;if(d!==void 0&&m!==void 0){if(c.setX(Math.max(Math.abs(d[0]),Math.abs(m[0]))),c.setY(Math.max(Math.abs(d[1]),Math.abs(m[1]))),c.setZ(Math.max(Math.abs(d[2]),Math.abs(m[2]))),f.normalized){let x=Ud(lo[f.componentType]);c.multiplyScalar(x)}a.max(c)}else console.warn("THREE.GLTFLoader: Missing min/max properties for accessor POSITION.")}}s.expandByVector(a)}i.boundingBox=s;let o=new Cn;s.getCenter(o.center),o.radius=s.min.distanceTo(s.max)/2,i.boundingSphere=o}function p0(i,e,t){let n=e.attributes,s=[];function r(o,a){return t.getDependency("accessor",o).then(function(c){i.setAttribute(a,c)})}for(let o in n){let a=Dd[o]||o.toLowerCase();a in i.attributes||s.push(r(n[o],a))}if(e.indices!==void 0&&!i.index){let o=t.getDependency("accessor",e.indices).then(function(a){i.setIndex(a)});s.push(o)}return tt.workingColorSpace!==bn&&"COLOR_0"in n&&console.warn(`THREE.GLTFLoader: Converting vertex colors from "srgb-linear" to "${tt.workingColorSpace}" not supported.`),Ei(i,e),xT(i,e,t),Promise.all(s).then(function(){return e.targets!==void 0?fT(i,e.targets,t):i})}var g0={type:"change"},Bd={type:"start"},_0={type:"end"},Iu=new Pn,x0=new an,_T=Math.cos(70*qi.DEG2RAD),tn=new I,Un=2*Math.PI,bt={NONE:-1,ROTATE:0,DOLLY:1,PAN:2,TOUCH_ROTATE:3,TOUCH_PAN:4,TOUCH_DOLLY_PAN:5,TOUCH_DOLLY_ROTATE:6},Od=1e-6,Lu=class extends Ra{constructor(e,t=null){super(e,t),this.state=bt.NONE,this.target=new I,this.cursor=new I,this.minDistance=0,this.maxDistance=1/0,this.minZoom=0,this.maxZoom=1/0,this.minTargetRadius=0,this.maxTargetRadius=1/0,this.minPolarAngle=0,this.maxPolarAngle=Math.PI,this.minAzimuthAngle=-1/0,this.maxAzimuthAngle=1/0,this.enableDamping=!1,this.dampingFactor=.05,this.enableZoom=!0,this.zoomSpeed=1,this.enableRotate=!0,this.rotateSpeed=1,this.keyRotateSpeed=1,this.enablePan=!0,this.panSpeed=1,this.screenSpacePanning=!0,this.keyPanSpeed=7,this.zoomToCursor=!1,this.autoRotate=!1,this.autoRotateSpeed=2,this.keys={LEFT:"ArrowLeft",UP:"ArrowUp",RIGHT:"ArrowRight",BOTTOM:"ArrowDown"},this.mouseButtons={LEFT:ms.ROTATE,MIDDLE:ms.DOLLY,RIGHT:ms.PAN},this.touches={ONE:gs.ROTATE,TWO:gs.DOLLY_PAN},this.target0=this.target.clone(),this.position0=this.object.position.clone(),this.zoom0=this.object.zoom,this._cursorStyle="auto",this._domElementKeyEvents=null,this._lastPosition=new I,this._lastQuaternion=new pn,this._lastTargetPosition=new I,this._quat=new pn().setFromUnitVectors(e.up,new I(0,1,0)),this._quatInverse=this._quat.clone().invert(),this._spherical=new Jr,this._sphericalDelta=new Jr,this._scale=1,this._panOffset=new I,this._rotateStart=new ce,this._rotateEnd=new ce,this._rotateDelta=new ce,this._panStart=new ce,this._panEnd=new ce,this._panDelta=new ce,this._dollyStart=new ce,this._dollyEnd=new ce,this._dollyDelta=new ce,this._dollyDirection=new I,this._mouse=new ce,this._performCursorZoom=!1,this._pointers=[],this._pointerPositions={},this._controlActive=!1,this._onPointerMove=vT.bind(this),this._onPointerDown=yT.bind(this),this._onPointerUp=ST.bind(this),this._onContextMenu=RT.bind(this),this._onMouseWheel=TT.bind(this),this._onKeyDown=wT.bind(this),this._onTouchStart=ET.bind(this),this._onTouchMove=AT.bind(this),this._onMouseDown=bT.bind(this),this._onMouseMove=MT.bind(this),this._interceptControlDown=CT.bind(this),this._interceptControlUp=PT.bind(this),this.domElement!==null&&this.connect(this.domElement),this.update()}set cursorStyle(e){this._cursorStyle=e,e==="grab"?this.domElement.style.cursor="grab":this.domElement.style.cursor="auto"}get cursorStyle(){return this._cursorStyle}connect(e){super.connect(e),this.domElement.addEventListener("pointerdown",this._onPointerDown),this.domElement.addEventListener("pointercancel",this._onPointerUp),this.domElement.addEventListener("contextmenu",this._onContextMenu),this.domElement.addEventListener("wheel",this._onMouseWheel,{passive:!1}),this.domElement.getRootNode().addEventListener("keydown",this._interceptControlDown,{passive:!0,capture:!0}),this.domElement.style.touchAction="none"}disconnect(){this.state=bt.NONE,this.domElement.removeEventListener("pointerdown",this._onPointerDown),this.domElement.ownerDocument.removeEventListener("pointermove",this._onPointerMove),this.domElement.ownerDocument.removeEventListener("pointerup",this._onPointerUp),this.domElement.removeEventListener("pointercancel",this._onPointerUp),this.domElement.removeEventListener("wheel",this._onMouseWheel),this.domElement.removeEventListener("contextmenu",this._onContextMenu),this.stopListenToKeyEvents();let e=this.domElement.getRootNode();e.removeEventListener("keydown",this._interceptControlDown,{capture:!0}),e.removeEventListener("keyup",this._interceptControlUp,{capture:!0}),this._controlActive=!1,this._pointers.length=0,this._pointerPositions={},this.domElement.style.touchAction="",this.domElement.style.cursor="auto"}dispose(){this.disconnect()}getPolarAngle(){return this._spherical.phi}getAzimuthalAngle(){return this._spherical.theta}getDistance(){return this.object.position.distanceTo(this.target)}listenToKeyEvents(e){e.addEventListener("keydown",this._onKeyDown),this._domElementKeyEvents=e}stopListenToKeyEvents(){this._domElementKeyEvents!==null&&(this._domElementKeyEvents.removeEventListener("keydown",this._onKeyDown),this._domElementKeyEvents=null)}saveState(){this.target0.copy(this.target),this.position0.copy(this.object.position),this.zoom0=this.object.zoom}reset(){this.target.copy(this.target0),this.object.position.copy(this.position0),this.object.zoom=this.zoom0,this.object.updateProjectionMatrix(),this.dispatchEvent(g0),this.update(),this.state=bt.NONE}pan(e,t){this._pan(e,t),this.update()}dollyIn(e){this._dollyIn(e),this.update()}dollyOut(e){this._dollyOut(e),this.update()}rotateLeft(e){this._rotateLeft(e),this.update()}rotateUp(e){this._rotateUp(e),this.update()}update(e=null){let t=this.object.position;tn.copy(t).sub(this.target),tn.applyQuaternion(this._quat),this._spherical.setFromVector3(tn),this.autoRotate&&this.state===bt.NONE&&this._rotateLeft(this._getAutoRotationAngle(e)),this.enableDamping?(this._spherical.theta+=this._sphericalDelta.theta*this.dampingFactor,this._spherical.phi+=this._sphericalDelta.phi*this.dampingFactor):(this._spherical.theta+=this._sphericalDelta.theta,this._spherical.phi+=this._sphericalDelta.phi);let n=this.minAzimuthAngle,s=this.maxAzimuthAngle;isFinite(n)&&isFinite(s)&&(n<-Math.PI?n+=Un:n>Math.PI&&(n-=Un),s<-Math.PI?s+=Un:s>Math.PI&&(s-=Un),n<=s?this._spherical.theta=Math.max(n,Math.min(s,this._spherical.theta)):this._spherical.theta=this._spherical.theta>(n+s)/2?Math.max(n,this._spherical.theta):Math.min(s,this._spherical.theta)),this._spherical.phi=Math.max(this.minPolarAngle,Math.min(this.maxPolarAngle,this._spherical.phi)),this._spherical.makeSafe(),this.enableDamping===!0?this.target.addScaledVector(this._panOffset,this.dampingFactor):this.target.add(this._panOffset),this.target.sub(this.cursor),this.target.clampLength(this.minTargetRadius,this.maxTargetRadius),this.target.add(this.cursor);let r=!1;if(this.zoomToCursor&&this._performCursorZoom||this.object.isOrthographicCamera)this._spherical.radius=this._clampDistance(this._spherical.radius);else{let o=this._spherical.radius;this._spherical.radius=this._clampDistance(this._spherical.radius*this._scale),r=o!=this._spherical.radius}if(tn.setFromSpherical(this._spherical),tn.applyQuaternion(this._quatInverse),t.copy(this.target).add(tn),this.object.lookAt(this.target),this.enableDamping===!0?(this._sphericalDelta.theta*=1-this.dampingFactor,this._sphericalDelta.phi*=1-this.dampingFactor,this._panOffset.multiplyScalar(1-this.dampingFactor)):(this._sphericalDelta.set(0,0,0),this._panOffset.set(0,0,0)),this.zoomToCursor&&this._performCursorZoom){let o=null;if(this.object.isPerspectiveCamera){let a=tn.length();o=this._clampDistance(a*this._scale);let c=a-o;this.object.position.addScaledVector(this._dollyDirection,c),this.object.updateMatrixWorld(),r=!!c}else if(this.object.isOrthographicCamera){let a=new I(this._mouse.x,this._mouse.y,0);a.unproject(this.object);let c=this.object.zoom;this.object.zoom=Math.max(this.minZoom,Math.min(this.maxZoom,this.object.zoom/this._scale)),this.object.updateProjectionMatrix(),r=c!==this.object.zoom;let l=new I(this._mouse.x,this._mouse.y,0);l.unproject(this.object),this.object.position.sub(l).add(a),this.object.updateMatrixWorld(),o=tn.length()}else console.warn("WARNING: OrbitControls.js encountered an unknown camera type - zoom to cursor disabled."),this.zoomToCursor=!1;o!==null&&(this.screenSpacePanning?this.target.set(0,0,-1).transformDirection(this.object.matrix).multiplyScalar(o).add(this.object.position):(Iu.origin.copy(this.object.position),Iu.direction.set(0,0,-1).transformDirection(this.object.matrix),Math.abs(this.object.up.dot(Iu.direction))<_T?this.object.lookAt(this.target):(x0.setFromNormalAndCoplanarPoint(this.object.up,this.target),Iu.intersectPlane(x0,this.target))))}else if(this.object.isOrthographicCamera){let o=this.object.zoom;this.object.zoom=Math.max(this.minZoom,Math.min(this.maxZoom,this.object.zoom/this._scale)),o!==this.object.zoom&&(this.object.updateProjectionMatrix(),r=!0)}return this._scale=1,this._performCursorZoom=!1,r||this._lastPosition.distanceToSquared(this.object.position)>Od||8*(1-this._lastQuaternion.dot(this.object.quaternion))>Od||this._lastTargetPosition.distanceToSquared(this.target)>Od?(this.dispatchEvent(g0),this._lastPosition.copy(this.object.position),this._lastQuaternion.copy(this.object.quaternion),this._lastTargetPosition.copy(this.target),!0):!1}_getAutoRotationAngle(e){return e!==null?Un/60*this.autoRotateSpeed*e:Un/60/60*this.autoRotateSpeed}_getZoomScale(e){let t=Math.abs(e*.01);return Math.pow(.95,this.zoomSpeed*t)}_rotateLeft(e){this._sphericalDelta.theta-=e}_rotateUp(e){this._sphericalDelta.phi-=e}_panLeft(e,t){tn.setFromMatrixColumn(t,0),tn.multiplyScalar(-e),this._panOffset.add(tn)}_panUp(e,t){this.screenSpacePanning===!0?tn.setFromMatrixColumn(t,1):(tn.setFromMatrixColumn(t,0),tn.crossVectors(this.object.up,tn)),tn.multiplyScalar(e),this._panOffset.add(tn)}_pan(e,t){let n=this.domElement;if(this.object.isPerspectiveCamera){let s=this.object.position;tn.copy(s).sub(this.target);let r=tn.length();r*=Math.tan(this.object.fov/2*Math.PI/180),this._panLeft(2*e*r/n.clientHeight,this.object.matrix),this._panUp(2*t*r/n.clientHeight,this.object.matrix)}else this.object.isOrthographicCamera?(this._panLeft(e*(this.object.right-this.object.left)/this.object.zoom/n.clientWidth,this.object.matrix),this._panUp(t*(this.object.top-this.object.bottom)/this.object.zoom/n.clientHeight,this.object.matrix)):(console.warn("WARNING: OrbitControls.js encountered an unknown camera type - pan disabled."),this.enablePan=!1)}_dollyOut(e){this.object.isPerspectiveCamera||this.object.isOrthographicCamera?this._scale/=e:(console.warn("WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled."),this.enableZoom=!1)}_dollyIn(e){this.object.isPerspectiveCamera||this.object.isOrthographicCamera?this._scale*=e:(console.warn("WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled."),this.enableZoom=!1)}_updateZoomParameters(e,t){if(!this.zoomToCursor)return;this._performCursorZoom=!0;let n=this.domElement.getBoundingClientRect(),s=e-n.left,r=t-n.top,o=n.width,a=n.height;this._mouse.x=s/o*2-1,this._mouse.y=-(r/a)*2+1,this._dollyDirection.set(this._mouse.x,this._mouse.y,1).unproject(this.object).sub(this.object.position).normalize()}_clampDistance(e){return Math.max(this.minDistance,Math.min(this.maxDistance,e))}_handleMouseDownRotate(e){this._rotateStart.set(e.clientX,e.clientY)}_handleMouseDownDolly(e){this._updateZoomParameters(e.clientX,e.clientX),this._dollyStart.set(e.clientX,e.clientY)}_handleMouseDownPan(e){this._panStart.set(e.clientX,e.clientY)}_handleMouseMoveRotate(e){this._rotateEnd.set(e.clientX,e.clientY),this._rotateDelta.subVectors(this._rotateEnd,this._rotateStart).multiplyScalar(this.rotateSpeed);let t=this.domElement;this._rotateLeft(Un*this._rotateDelta.x/t.clientHeight),this._rotateUp(Un*this._rotateDelta.y/t.clientHeight),this._rotateStart.copy(this._rotateEnd),this.update()}_handleMouseMoveDolly(e){this._dollyEnd.set(e.clientX,e.clientY),this._dollyDelta.subVectors(this._dollyEnd,this._dollyStart),this._dollyDelta.y>0?this._dollyOut(this._getZoomScale(this._dollyDelta.y)):this._dollyDelta.y<0&&this._dollyIn(this._getZoomScale(this._dollyDelta.y)),this._dollyStart.copy(this._dollyEnd),this.update()}_handleMouseMovePan(e){this._panEnd.set(e.clientX,e.clientY),this._panDelta.subVectors(this._panEnd,this._panStart).multiplyScalar(this.panSpeed),this._pan(this._panDelta.x,this._panDelta.y),this._panStart.copy(this._panEnd),this.update()}_handleMouseWheel(e){this._updateZoomParameters(e.clientX,e.clientY),e.deltaY<0?this._dollyIn(this._getZoomScale(e.deltaY)):e.deltaY>0&&this._dollyOut(this._getZoomScale(e.deltaY)),this.update()}_handleKeyDown(e){let t=!1;switch(e.code){case this.keys.UP:e.ctrlKey||e.metaKey||e.shiftKey?this.enableRotate&&this._rotateUp(Un*this.keyRotateSpeed/this.domElement.clientHeight):this.enablePan&&this._pan(0,this.keyPanSpeed),t=!0;break;case this.keys.BOTTOM:e.ctrlKey||e.metaKey||e.shiftKey?this.enableRotate&&this._rotateUp(-Un*this.keyRotateSpeed/this.domElement.clientHeight):this.enablePan&&this._pan(0,-this.keyPanSpeed),t=!0;break;case this.keys.LEFT:e.ctrlKey||e.metaKey||e.shiftKey?this.enableRotate&&this._rotateLeft(Un*this.keyRotateSpeed/this.domElement.clientHeight):this.enablePan&&this._pan(this.keyPanSpeed,0),t=!0;break;case this.keys.RIGHT:e.ctrlKey||e.metaKey||e.shiftKey?this.enableRotate&&this._rotateLeft(-Un*this.keyRotateSpeed/this.domElement.clientHeight):this.enablePan&&this._pan(-this.keyPanSpeed,0),t=!0;break}t&&(e.preventDefault(),this.update())}_handleTouchStartRotate(e){if(this._pointers.length===1)this._rotateStart.set(e.pageX,e.pageY);else{let t=this._getSecondPointerPosition(e),n=.5*(e.pageX+t.x),s=.5*(e.pageY+t.y);this._rotateStart.set(n,s)}}_handleTouchStartPan(e){if(this._pointers.length===1)this._panStart.set(e.pageX,e.pageY);else{let t=this._getSecondPointerPosition(e),n=.5*(e.pageX+t.x),s=.5*(e.pageY+t.y);this._panStart.set(n,s)}}_handleTouchStartDolly(e){let t=this._getSecondPointerPosition(e),n=e.pageX-t.x,s=e.pageY-t.y,r=Math.sqrt(n*n+s*s);this._dollyStart.set(0,r)}_handleTouchStartDollyPan(e){this.enableZoom&&this._handleTouchStartDolly(e),this.enablePan&&this._handleTouchStartPan(e)}_handleTouchStartDollyRotate(e){this.enableZoom&&this._handleTouchStartDolly(e),this.enableRotate&&this._handleTouchStartRotate(e)}_handleTouchMoveRotate(e){if(this._pointers.length==1)this._rotateEnd.set(e.pageX,e.pageY);else{let n=this._getSecondPointerPosition(e),s=.5*(e.pageX+n.x),r=.5*(e.pageY+n.y);this._rotateEnd.set(s,r)}this._rotateDelta.subVectors(this._rotateEnd,this._rotateStart).multiplyScalar(this.rotateSpeed);let t=this.domElement;this._rotateLeft(Un*this._rotateDelta.x/t.clientHeight),this._rotateUp(Un*this._rotateDelta.y/t.clientHeight),this._rotateStart.copy(this._rotateEnd)}_handleTouchMovePan(e){if(this._pointers.length===1)this._panEnd.set(e.pageX,e.pageY);else{let t=this._getSecondPointerPosition(e),n=.5*(e.pageX+t.x),s=.5*(e.pageY+t.y);this._panEnd.set(n,s)}this._panDelta.subVectors(this._panEnd,this._panStart).multiplyScalar(this.panSpeed),this._pan(this._panDelta.x,this._panDelta.y),this._panStart.copy(this._panEnd)}_handleTouchMoveDolly(e){let t=this._getSecondPointerPosition(e),n=e.pageX-t.x,s=e.pageY-t.y,r=Math.sqrt(n*n+s*s);this._dollyEnd.set(0,r),this._dollyDelta.set(0,Math.pow(this._dollyEnd.y/this._dollyStart.y,this.zoomSpeed)),this._dollyOut(this._dollyDelta.y),this._dollyStart.copy(this._dollyEnd);let o=(e.pageX+t.x)*.5,a=(e.pageY+t.y)*.5;this._updateZoomParameters(o,a)}_handleTouchMoveDollyPan(e){this.enableZoom&&this._handleTouchMoveDolly(e),this.enablePan&&this._handleTouchMovePan(e)}_handleTouchMoveDollyRotate(e){this.enableZoom&&this._handleTouchMoveDolly(e),this.enableRotate&&this._handleTouchMoveRotate(e)}_addPointer(e){this._pointers.push(e.pointerId)}_removePointer(e){delete this._pointerPositions[e.pointerId];for(let t=0;t<this._pointers.length;t++)if(this._pointers[t]==e.pointerId){this._pointers.splice(t,1);return}}_isTrackingPointer(e){for(let t=0;t<this._pointers.length;t++)if(this._pointers[t]==e.pointerId)return!0;return!1}_trackPointer(e){let t=this._pointerPositions[e.pointerId];t===void 0&&(t=new ce,this._pointerPositions[e.pointerId]=t),t.set(e.pageX,e.pageY)}_getSecondPointerPosition(e){let t=e.pointerId===this._pointers[0]?this._pointers[1]:this._pointers[0];return this._pointerPositions[t]}_customWheelEvent(e){let t=e.deltaMode,n={clientX:e.clientX,clientY:e.clientY,deltaY:e.deltaY};switch(t){case 1:n.deltaY*=16;break;case 2:n.deltaY*=100;break}return e.ctrlKey&&!this._controlActive&&(n.deltaY*=10),n}};function yT(i){this.enabled!==!1&&(this._pointers.length===0&&(this.domElement.setPointerCapture(i.pointerId),this.domElement.ownerDocument.addEventListener("pointermove",this._onPointerMove),this.domElement.ownerDocument.addEventListener("pointerup",this._onPointerUp)),!this._isTrackingPointer(i)&&(this._addPointer(i),i.pointerType==="touch"?this._onTouchStart(i):this._onMouseDown(i),this._cursorStyle==="grab"&&(this.domElement.style.cursor="grabbing")))}function vT(i){this.enabled!==!1&&(i.pointerType==="touch"?this._onTouchMove(i):this._onMouseMove(i))}function ST(i){switch(this._removePointer(i),this._pointers.length){case 0:this.domElement.releasePointerCapture(i.pointerId),this.domElement.ownerDocument.removeEventListener("pointermove",this._onPointerMove),this.domElement.ownerDocument.removeEventListener("pointerup",this._onPointerUp),this.dispatchEvent(_0),this.state=bt.NONE,this._cursorStyle==="grab"&&(this.domElement.style.cursor="grab");break;case 1:let e=this._pointers[0],t=this._pointerPositions[e];this._onTouchStart({pointerId:e,pageX:t.x,pageY:t.y});break}}function bT(i){let e;switch(i.button){case 0:e=this.mouseButtons.LEFT;break;case 1:e=this.mouseButtons.MIDDLE;break;case 2:e=this.mouseButtons.RIGHT;break;default:e=-1}switch(e){case ms.DOLLY:if(this.enableZoom===!1)return;this._handleMouseDownDolly(i),this.state=bt.DOLLY;break;case ms.ROTATE:if(i.ctrlKey||i.metaKey||i.shiftKey){if(this.enablePan===!1)return;this._handleMouseDownPan(i),this.state=bt.PAN}else{if(this.enableRotate===!1)return;this._handleMouseDownRotate(i),this.state=bt.ROTATE}break;case ms.PAN:if(i.ctrlKey||i.metaKey||i.shiftKey){if(this.enableRotate===!1)return;this._handleMouseDownRotate(i),this.state=bt.ROTATE}else{if(this.enablePan===!1)return;this._handleMouseDownPan(i),this.state=bt.PAN}break;default:this.state=bt.NONE}this.state!==bt.NONE&&this.dispatchEvent(Bd)}function MT(i){switch(this.state){case bt.ROTATE:if(this.enableRotate===!1)return;this._handleMouseMoveRotate(i);break;case bt.DOLLY:if(this.enableZoom===!1)return;this._handleMouseMoveDolly(i);break;case bt.PAN:if(this.enablePan===!1)return;this._handleMouseMovePan(i);break}}function TT(i){this.enabled===!1||this.enableZoom===!1||this.state!==bt.NONE||(i.preventDefault(),this.dispatchEvent(Bd),this._handleMouseWheel(this._customWheelEvent(i)),this.dispatchEvent(_0))}function wT(i){this.enabled!==!1&&this._handleKeyDown(i)}function ET(i){switch(this._trackPointer(i),this._pointers.length){case 1:switch(this.touches.ONE){case gs.ROTATE:if(this.enableRotate===!1)return;this._handleTouchStartRotate(i),this.state=bt.TOUCH_ROTATE;break;case gs.PAN:if(this.enablePan===!1)return;this._handleTouchStartPan(i),this.state=bt.TOUCH_PAN;break;default:this.state=bt.NONE}break;case 2:switch(this.touches.TWO){case gs.DOLLY_PAN:if(this.enableZoom===!1&&this.enablePan===!1)return;this._handleTouchStartDollyPan(i),this.state=bt.TOUCH_DOLLY_PAN;break;case gs.DOLLY_ROTATE:if(this.enableZoom===!1&&this.enableRotate===!1)return;this._handleTouchStartDollyRotate(i),this.state=bt.TOUCH_DOLLY_ROTATE;break;default:this.state=bt.NONE}break;default:this.state=bt.NONE}this.state!==bt.NONE&&this.dispatchEvent(Bd)}function AT(i){switch(this._trackPointer(i),this.state){case bt.TOUCH_ROTATE:if(this.enableRotate===!1)return;this._handleTouchMoveRotate(i),this.update();break;case bt.TOUCH_PAN:if(this.enablePan===!1)return;this._handleTouchMovePan(i),this.update();break;case bt.TOUCH_DOLLY_PAN:if(this.enableZoom===!1&&this.enablePan===!1)return;this._handleTouchMoveDollyPan(i),this.update();break;case bt.TOUCH_DOLLY_ROTATE:if(this.enableZoom===!1&&this.enableRotate===!1)return;this._handleTouchMoveDollyRotate(i),this.update();break;default:this.state=bt.NONE}}function RT(i){this.enabled!==!1&&i.preventDefault()}function CT(i){i.key==="Control"&&(this._controlActive=!0,this.domElement.getRootNode().addEventListener("keyup",this._interceptControlUp,{passive:!0,capture:!0}))}function PT(i){i.key==="Control"&&(this._controlActive=!1,this.domElement.getRootNode().removeEventListener("keyup",this._interceptControlUp,{passive:!0,capture:!0}))}var Gn=i=>new $t({color:i,roughness:.6,metalness:.15}),nn=(i,e,t,n)=>{let s=new it(new In(...e),n);return s.position.set(...t),i.add(s),s};function Wa(){let i=new Bt;i.name="OriginalCampusBus";let e=Gn(16120056),t=Gn(556222),n=Gn(1388100),s=Gn(1451569),r=Gn(16777166),o=Gn(14364728);nn(i,[2.45,2.55,7.8],[0,1.7,0],e),nn(i,[2.48,.5,7.82],[0,1.05,0],t),nn(i,[2.2,.2,7.4],[0,3.05,0],t);for(let c of[-1.235,1.235])for(let l of[-2.8,-1.4,0,1.4,2.8])nn(i,[.035,.85,1.12],[c,2.2,l],n);nn(i,[2.12,1.05,.035],[0,2.16,-3.915],n),nn(i,[1.8,.18,.04],[0,2.88,-3.92],n),nn(i,[1.8,.8,.035],[0,2.2,3.915],n),nn(i,[2.48,.13,.12],[0,.6,3.96],s);for(let c of[-.85,.85])nn(i,[.27,.32,.06],[c,.9,3.95],o);for(let c of[-.85,.85])nn(i,[.38,.22,.06],[c,.9,-3.95],r);let a=[];for(let c of[-1.25,1.25])for(let l of[-2.65,2.4]){let u=new it(new fs(.5,.5,.2,12),s);u.rotation.z=Math.PI/2,u.position.set(c,.5,l),i.add(u),a.push(u)}return i.userData.wheels=a,i}function zd(){let i=new Bt;i.name="CampusCar";let e=Gn(1207244),t=Gn(2375512),n=Gn(1517365),s=Gn(16185074);nn(i,[1.85,.6,3.8],[0,.75,0],e),nn(i,[1.5,.65,1.9],[0,1.35,.15],t),nn(i,[1.55,.1,2],[0,1.72,.15],e);for(let o of[-.64,.64])nn(i,[.38,.2,.12],[o,.8,-1.93],s);let r=[];for(let o of[-1,1])for(let a of[-1.2,1.2]){let c=new it(new fs(.43,.43,.22,12),n);c.rotation.z=Math.PI/2,c.position.set(o,.43,a),i.add(c),r.push(c)}return i.userData.wheels=r,i}function kd(){let i=new Bt;i.name="CampusPlane";let e=Gn(16775400),t=Gn(15431716),n=Gn(1589095),s=new it(new fs(.58,.58,5.8,12),e);s.rotation.x=Math.PI/2,i.add(s);let r=new it(new ks(.58,1.4,12),t);r.rotation.x=-Math.PI/2,r.position.z=-3.6,i.add(r),nn(i,[10.8,.16,1.6],[0,0,0],t),nn(i,[3.8,.14,.8],[0,.1,2.5],t),nn(i,[.18,1.6,1.1],[0,.85,2.4],t),nn(i,[.75,.42,1.25],[0,.5,-1.65],n);let o=new Bt;return o.position.z=-4.32,nn(o,[2.7,.15,.1],[0,0,0],n),i.add(o),i.userData.propeller=o,i}var ho=Math.pow(2,-24),Xa=Symbol("SKIP_GENERATION"),Nu={strategy:0,maxDepth:40,targetLeafSize:10,useSharedArrayBuffer:!1,setBoundingBox:!0,onProgress:null,indirect:!1,verbose:!0,range:null,[Xa]:!1};function Rt(i,e,t){return t.min.x=e[i],t.min.y=e[i+1],t.min.z=e[i+2],t.max.x=e[i+3],t.max.y=e[i+4],t.max.z=e[i+5],t}function qa(i){let e=-1,t=-1/0;for(let n=0;n<3;n++){let s=i[n+3]-i[n];s>t&&(t=s,e=n)}return e}function Vd(i,e){e.set(i)}function Hd(i,e,t){let n,s;for(let r=0;r<3;r++){let o=r+3;n=i[r],s=e[r],t[r]=n<s?n:s,n=i[o],s=e[o],t[o]=n>s?n:s}}function Ya(i,e,t){for(let n=0;n<3;n++){let s=e[i+2*n],r=e[i+2*n+1],o=s-r,a=s+r;o<t[n]&&(t[n]=o),a>t[n+3]&&(t[n+3]=a)}}function fo(i){let e=i[3]-i[0],t=i[4]-i[1],n=i[5]-i[2];return 2*(e*t+t*n+n*e)}function at(i,e){return e[i+15]===65535}function vt(i,e){return e[i+6]}function wt(i,e){return e[i+14]}function dt(i){return i+8}function pt(i,e){let t=e[i+6];return i+t*8}function po(i,e){return e[i+7]}function Du(i,e,t,n,s){let r=1/0,o=1/0,a=1/0,c=-1/0,l=-1/0,u=-1/0,h=1/0,f=1/0,d=1/0,m=-1/0,x=-1/0,g=-1/0,p=i.offset||0;for(let v=(e-p)*6,b=(e+t-p)*6;v<b;v+=6){let _=i[v+0],S=i[v+1],M=_-S,E=_+S;M<r&&(r=M),E>c&&(c=E),_<h&&(h=_),_>m&&(m=_);let y=i[v+2],w=i[v+3],A=y-w,P=y+w;A<o&&(o=A),P>l&&(l=P),y<f&&(f=y),y>x&&(x=y);let C=i[v+4],D=i[v+5],L=C-D,U=C+D;L<a&&(a=L),U>u&&(u=U),C<d&&(d=C),C>g&&(g=C)}n[0]=r,n[1]=o,n[2]=a,n[3]=c,n[4]=l,n[5]=u,s[0]=h,s[1]=f,s[2]=d,s[3]=m,s[4]=x,s[5]=g}var Zi=32,NT=(i,e)=>i.candidate-e.candidate,Ss=new Array(Zi).fill().map(()=>({count:0,bounds:new Float32Array(6),rightCacheBounds:new Float32Array(6),leftCacheBounds:new Float32Array(6),candidate:0})),Uu=new Float32Array(6);function v0(i,e,t,n,s,r){let o=-1,a=0;if(r===0)o=qa(e),o!==-1&&(a=(e[o]+e[o+3])/2);else if(r===1)o=qa(i),o!==-1&&(a=DT(t,n,s,o));else if(r===2){let c=fo(i),l=1.25*s,u=t.offset||0,h=(n-u)*6,f=(n+s-u)*6;for(let d=0;d<3;d++){let m=e[d],p=(e[d+3]-m)/Zi;if(s<Zi/4){let v=[...Ss];v.length=s;let b=0;for(let S=h;S<f;S+=6,b++){let M=v[b];M.candidate=t[S+2*d],M.count=0;let{bounds:E,leftCacheBounds:y,rightCacheBounds:w}=M;for(let A=0;A<3;A++)w[A]=1/0,w[A+3]=-1/0,y[A]=1/0,y[A+3]=-1/0,E[A]=1/0,E[A+3]=-1/0;Ya(S,t,E)}v.sort(NT);let _=s;for(let S=0;S<_;S++){let M=v[S];for(;S+1<_&&v[S+1].candidate===M.candidate;)v.splice(S+1,1),_--}for(let S=h;S<f;S+=6){let M=t[S+2*d];for(let E=0;E<_;E++){let y=v[E];M>=y.candidate?Ya(S,t,y.rightCacheBounds):(Ya(S,t,y.leftCacheBounds),y.count++)}}for(let S=0;S<_;S++){let M=v[S],E=M.count,y=s-M.count,w=M.leftCacheBounds,A=M.rightCacheBounds,P=0;E!==0&&(P=fo(w)/c);let C=0;y!==0&&(C=fo(A)/c);let D=1+1.25*(P*E+C*y);D<l&&(o=d,l=D,a=M.candidate)}}else{for(let _=0;_<Zi;_++){let S=Ss[_];S.count=0,S.candidate=m+p+_*p;let M=S.bounds;for(let E=0;E<3;E++)M[E]=1/0,M[E+3]=-1/0}for(let _=h;_<f;_+=6){let E=~~((t[_+2*d]-m)/p);E>=Zi&&(E=Zi-1);let y=Ss[E];y.count++,Ya(_,t,y.bounds)}let v=Ss[Zi-1];Vd(v.bounds,v.rightCacheBounds);for(let _=Zi-2;_>=0;_--){let S=Ss[_],M=Ss[_+1];Hd(S.bounds,M.rightCacheBounds,S.rightCacheBounds)}let b=0;for(let _=0;_<Zi-1;_++){let S=Ss[_],M=S.count,E=S.bounds,w=Ss[_+1].rightCacheBounds;M!==0&&(b===0?Vd(E,Uu):Hd(E,Uu,Uu)),b+=M;let A=0,P=0;b!==0&&(A=fo(Uu)/c);let C=s-b;C!==0&&(P=fo(w)/c);let D=1+1.25*(A*b+P*C);D<l&&(o=d,l=D,a=S.candidate)}}}}else console.warn(`BVH: Invalid build strategy value ${r} used.`);return{axis:o,pos:a}}function DT(i,e,t,n){let s=0,r=i.offset;for(let o=e,a=e+t;o<a;o++)s+=i[(o-r)*6+n*2];return s/t}var mo=class{constructor(){this.boundingData=new Float32Array(6)}};function S0(i,e,t,n,s,r){let o=n,a=n+s-1,c=r.pos,l=r.axis*2,u=t.offset||0;for(;;){for(;o<=a&&t[(o-u)*6+l]<c;)o++;for(;o<=a&&t[(a-u)*6+l]>=c;)a--;if(o<a){for(let h=0;h<e;h++){let f=i[o*e+h];i[o*e+h]=i[a*e+h],i[a*e+h]=f}for(let h=0;h<6;h++){let f=o-u,d=a-u,m=t[f*6+h];t[f*6+h]=t[d*6+h],t[d*6+h]=m}o++,a--}else return o}}var b0,Fu,Gd,M0,UT=Math.pow(2,32);function Ou(i){return"count"in i?1:1+Ou(i.left)+Ou(i.right)}function T0(i,e,t){return b0=new Float32Array(t),Fu=new Uint32Array(t),Gd=new Uint16Array(t),M0=new Uint8Array(t),Wd(i,e)}function Wd(i,e){let t=i/4,n=i/2,s="count"in e,r=e.boundingData;for(let o=0;o<6;o++)b0[t+o]=r[o];if(s)return e.buffer?(M0.set(new Uint8Array(e.buffer),i),i+e.buffer.byteLength):(Fu[t+6]=e.offset,Gd[n+14]=e.count,Gd[n+15]=65535,i+32);{let{left:o,right:a,splitAxis:c}=e,l=i+32,u=Wd(l,o),h=i/32,d=u/32-h;if(d>UT)throw new Error("MeshBVH: Cannot store relative child node offset greater than 32 bits.");return Fu[t+6]=d,Fu[t+7]=c,Wd(u,a)}}function FT(i,e,t,n,s,r){let{maxDepth:o,verbose:a,targetLeafSize:c,_strictLeafSize:l=1/0,strategy:u,onProgress:h}=s,f=i.primitiveBuffer,d=i.primitiveBufferStride,m=new Float32Array(6),x=!1,g=new mo;return Du(e,t,n,g.boundingData,m),v(g,t,n,m),g;function p(b){h&&h((b-r.offset)/r.count)}function v(b,_,S,M=null,E=0){!x&&E>=o&&(x=!0,a&&console.warn(`BVH: Max depth of ${o} reached when generating BVH. Consider increasing maxDepth.`));let y=S>l;if(S<=c&&!y||E>=o)return p(_+S),b.offset=_,b.count=S,b;let w=v0(b.boundingData,M,e,_,S,u),A=w.axis===-1?-1:S0(f,d,e,_,S,w);if(w.axis===-1||A===_||A===_+S){if(!y)return p(_+S),b.offset=_,b.count=S,b;w.axis=Math.max(0,qa(b.boundingData)),A=_+Math.max(1,Math.floor(S/2))}b.splitAxis=w.axis;let P=new mo,C=_,D=A-_;b.left=P,Du(e,C,D,P.boundingData,m),v(P,C,D,m,E+1);let L=new mo,U=A,G=S-D;return b.right=L,Du(e,U,G,L.boundingData,m),v(L,U,G,m,E+1),b}}function w0(i,e){let t=e.useSharedArrayBuffer?SharedArrayBuffer:ArrayBuffer,n=i.getRootRanges(e.range),s=n[0],r=n[n.length-1],o={offset:s.offset,count:r.offset+r.count-s.offset},a=new Float32Array(6*o.count);a.offset=o.offset,i.computePrimitiveBounds(o.offset,o.count,a),i._roots=n.map(c=>{let l=FT(i,a,c.offset,c.count,e,o),u=Ou(l),h=new t(32*u);return T0(0,l,h),h})}var bs=class{constructor(e){this._getNewPrimitive=e,this._primitives=[]}getPrimitive(){let e=this._primitives;return e.length===0?this._getNewPrimitive():e.pop()}releasePrimitive(e){this._primitives.push(e)}};var Xd=class{constructor(){this.float32Array=null,this.uint16Array=null,this.uint32Array=null;let e=[],t=null;this.setBuffer=n=>{t&&e.push(t),t=n,this.float32Array=new Float32Array(n),this.uint16Array=new Uint16Array(n),this.uint32Array=new Uint32Array(n)},this.clearBuffer=()=>{t=null,this.float32Array=null,this.uint16Array=null,this.uint32Array=null,e.length!==0&&this.setBuffer(e.pop())}}},ft=new Xd;var Ms,xo,go=[],Bu=new bs(()=>new Ke);function E0(i,e,t,n,s,r){Ms=Bu.getPrimitive(),xo=Bu.getPrimitive(),go.push(Ms,xo),ft.setBuffer(i._roots[e]);let o=qd(0,i.geometry,t,n,s,r);ft.clearBuffer(),Bu.releasePrimitive(Ms),Bu.releasePrimitive(xo),go.pop(),go.pop();let a=go.length;return a>0&&(xo=go[a-1],Ms=go[a-2]),o}function qd(i,e,t,n,s=null,r=0,o=0){let{float32Array:a,uint16Array:c,uint32Array:l}=ft,u=i*2;if(at(u,c)){let f=vt(i,l),d=wt(u,c);return Rt(i,a,Ms),n(f,d,!1,o,r+i/8,Ms)}else{let A=function(C){let{uint16Array:D,uint32Array:L}=ft,U=C*2;for(;!at(U,D);)C=dt(C),U=C*2;return vt(C,L)},P=function(C){let{uint16Array:D,uint32Array:L}=ft,U=C*2;for(;!at(U,D);)C=pt(C,L),U=C*2;return vt(C,L)+wt(U,D)},f=dt(i),d=pt(i,l),m=f,x=d,g,p,v,b;if(s&&(v=Ms,b=xo,Rt(m,a,v),Rt(x,a,b),g=s(v),p=s(b),p<g)){m=d,x=f;let C=g;g=p,p=C,v=b}v||(v=Ms,Rt(m,a,v));let _=at(m*2,c),S=t(v,_,g,o+1,r+m/8),M;if(S===2){let C=A(m),L=P(m)-C;M=n(C,L,!0,o+1,r+m/8,v)}else M=S&&qd(m,e,t,n,s,r,o+1);if(M)return!0;b=xo,Rt(x,a,b);let E=at(x*2,c),y=t(b,E,p,o+1,r+x/8),w;if(y===2){let C=A(x),L=P(x)-C;w=n(C,L,!0,o+1,r+x/8,b)}else w=y&&qd(x,e,t,n,s,r,o+1);return!!w}}var Za=new ft.constructor,zu=new ft.constructor,Ts=new bs(()=>new Ke),_o=new Ke,yo=new Ke,Zd=new Ke,Kd=new Ke,Jd=!1;function A0(i,e,t,n){if(Jd)throw new Error("MeshBVH: Recursive calls to bvhcast not supported.");Jd=!0;let s=i._roots,r=e._roots,o,a=0,c=0,l=new Ie().copy(t).invert();for(let u=0,h=s.length;u<h;u++){Za.setBuffer(s[u]),c=0;let f=Ts.getPrimitive();Rt(0,Za.float32Array,f),f.applyMatrix4(l);for(let d=0,m=r.length;d<m&&(zu.setBuffer(r[d]),o=ui(0,0,t,l,n,a,c,0,0,f),zu.clearBuffer(),c+=r[d].byteLength/32,!o);d++);if(Ts.releasePrimitive(f),Za.clearBuffer(),a+=s[u].byteLength/32,o)break}return Jd=!1,o}function ui(i,e,t,n,s,r=0,o=0,a=0,c=0,l=null,u=!1){let h,f;u?(h=zu,f=Za):(h=Za,f=zu);let d=h.float32Array,m=h.uint32Array,x=h.uint16Array,g=f.float32Array,p=f.uint32Array,v=f.uint16Array,b=i*2,_=e*2,S=at(b,x),M=at(_,v),E=!1;if(M&&S)u?E=s(vt(e,p),wt(e*2,v),vt(i,m),wt(i*2,x),c,o+e/8,a,r+i/8):E=s(vt(i,m),wt(i*2,x),vt(e,p),wt(e*2,v),a,r+i/8,c,o+e/8);else if(M){let y=Ts.getPrimitive();Rt(e,g,y),y.applyMatrix4(t);let w=dt(i),A=pt(i,m);Rt(w,d,_o),Rt(A,d,yo);let P=y.intersectsBox(_o),C=y.intersectsBox(yo);E=P&&ui(e,w,n,t,s,o,r,c,a+1,y,!u)||C&&ui(e,A,n,t,s,o,r,c,a+1,y,!u),Ts.releasePrimitive(y)}else{let y=dt(e),w=pt(e,p);Rt(y,g,Zd),Rt(w,g,Kd);let A=l.intersectsBox(Zd),P=l.intersectsBox(Kd);if(A&&P)E=ui(i,y,t,n,s,r,o,a,c+1,l,u)||ui(i,w,t,n,s,r,o,a,c+1,l,u);else if(A)if(S)E=ui(i,y,t,n,s,r,o,a,c+1,l,u);else{let C=Ts.getPrimitive();C.copy(Zd).applyMatrix4(t);let D=dt(i),L=pt(i,m);Rt(D,d,_o),Rt(L,d,yo);let U=C.intersectsBox(_o),G=C.intersectsBox(yo);E=U&&ui(y,D,n,t,s,o,r,c,a+1,C,!u)||G&&ui(y,L,n,t,s,o,r,c,a+1,C,!u),Ts.releasePrimitive(C)}else if(P)if(S)E=ui(i,w,t,n,s,r,o,a,c+1,l,u);else{let C=Ts.getPrimitive();C.copy(Kd).applyMatrix4(t);let D=dt(i),L=pt(i,m);Rt(D,d,_o),Rt(L,d,yo);let U=C.intersectsBox(_o),G=C.intersectsBox(yo);E=U&&ui(w,D,n,t,s,o,r,c,a+1,C,!u)||G&&ui(w,L,n,t,s,o,r,c,a+1,C,!u),Ts.releasePrimitive(C)}}return E}var ku=new class{constructor(){let i=null,e=null,t=null,n=!1;this.root=null,this.buffer=null,this.uint32Array=null,this.uint16Array=null,this.setBVH=(r,o)=>{if(n)throw new Error("BVHTraversalHelper: cannot call setBVH during an active traversal.");this.root=o,this.buffer=i=r._roots[o],this.uint16Array=t=new Uint16Array(i),this.uint32Array=e=new Uint32Array(i)},this.reset=()=>{this.root=null,this.buffer=i=null,this.uint16Array=t=null,this.uint32Array=e=null},this.getRangeStart=r=>{let o=r*2;for(;!at(o,t);)r=dt(r),o=r*2;return vt(r,e)},this.getRangeEnd=r=>{let o=r*2;for(;!at(o,t);)r=pt(r,e),o=r*2;return vt(r,e)+wt(o,t)};let s=(r,o,a)=>{let c=o*2,l=at(c,t);if(!r(a,l,o)&&!l){let h=dt(o),f=pt(o,e);s(r,h,a+1),s(r,f,a+1)}};this.traverseBuffer=r=>{if(n)throw new Error("BVHTraversalHelper: cannot start a traversal during an active traversal.");n=!0;try{s(r,0,0)}finally{n=!1}},this.traverse=r=>{this.traverseBuffer((o,a,c)=>{if(a){let l=c*2,u=e[c+6],h=t[l+14];return r(o,a,new Float32Array(i,c*4,6),u,h)}else{let l=po(c,e);return r(o,a,new Float32Array(i,c*4,6),l)}})}}};var R0=new Ke,vo=new Float32Array(6),Vu=class{constructor(){this._roots=null,this.primitiveBuffer=null,this.primitiveBufferStride=null}init(e){e={...Nu,...e},"maxLeafSize"in e&&(console.warn('BVH: "maxLeafSize" option has been deprecated. Use "targetLeafSize", instead.'),e={...e,targetLeafSize:e.maxLeafSize}),w0(this,e)}getRootRanges(){throw new Error("BVH: getRootRanges() not implemented")}writePrimitiveBounds(){throw new Error("BVH: writePrimitiveBounds() not implemented")}writePrimitiveRangeBounds(e,t,n,s){let r=1/0,o=1/0,a=1/0,c=-1/0,l=-1/0,u=-1/0;for(let h=e,f=e+t;h<f;h++){this.writePrimitiveBounds(h,vo,0);let[d,m,x,g,p,v]=vo;d<r&&(r=d),g>c&&(c=g),m<o&&(o=m),p>l&&(l=p),x<a&&(a=x),v>u&&(u=v)}return n[s+0]=r,n[s+1]=o,n[s+2]=a,n[s+3]=c,n[s+4]=l,n[s+5]=u,n}computePrimitiveBounds(e,t,n){let s=n.offset||0;for(let r=e,o=e+t;r<o;r++){this.writePrimitiveBounds(r,vo,0);let[a,c,l,u,h,f]=vo,d=(a+u)/2,m=(c+h)/2,x=(l+f)/2,g=(u-a)/2,p=(h-c)/2,v=(f-l)/2,b=(r-s)*6;n[b+0]=d,n[b+1]=g+(Math.abs(d)+g)*ho,n[b+2]=m,n[b+3]=p+(Math.abs(m)+p)*ho,n[b+4]=x,n[b+5]=v+(Math.abs(x)+v)*ho}return n}shiftPrimitiveOffsets(e){let t=this._indirectBuffer;if(t)for(let n=0,s=t.length;n<s;n++)t[n]+=e;else{let n=this._roots;for(let s=0;s<n.length;s++){let r=n[s],o=new Uint32Array(r),a=new Uint16Array(r),c=r.byteLength/32;for(let l=0;l<c;l++){let u=8*l,h=2*u;at(h,a)&&(o[u+6]+=e)}}}}traverse(e,t=0){ku.setBVH(this,t),ku.traverse(e),ku.reset()}refit(){let e=this._roots;for(let t=0,n=e.length;t<n;t++){let s=e[t],r=new Uint32Array(s),o=new Uint16Array(s),a=new Float32Array(s),c=s.byteLength/32;for(let l=c-1;l>=0;l--){let u=l*8,h=u*2;if(at(h,o)){let d=vt(u,r),m=wt(h,o);this.writePrimitiveRangeBounds(d,m,vo,0),a.set(vo,u)}else{let d=dt(u),m=pt(u,r);for(let x=0;x<3;x++){let g=a[d+x],p=a[d+x+3],v=a[m+x],b=a[m+x+3];a[u+x]=g<v?g:v,a[u+x+3]=p>b?p:b}}}}}getBoundingBox(e){return e.makeEmpty(),this._roots.forEach(n=>{Rt(0,new Float32Array(n),R0),e.union(R0)}),e}shapecast(e){let{boundsTraverseOrder:t,intersectsBounds:n,intersectsRange:s,intersectsPrimitive:r,scratchPrimitive:o,iterate:a}=e;if(s&&r){let h=s;s=(f,d,m,x,g)=>h(f,d,m,x,g)?!0:a(f,d,this,r,m,x,o)}else s||(r?s=(h,f,d,m)=>a(h,f,this,r,d,m,o):s=(h,f,d)=>d);let c=!1,l=0,u=this._roots;for(let h=0,f=u.length;h<f;h++){let d=u[h];if(c=E0(this,h,n,s,t,l),c)break;l+=d.byteLength/32}return c}bvhcast(e,t,n){let{intersectsRanges:s}=n;return A0(this,e,t,s)}};function C0(){return typeof SharedArrayBuffer<"u"}function $d(i){return i.index?i.index.count:i.attributes.position.count}function ws(i){return $d(i)/3}function BT(i,e=ArrayBuffer){return i>65535?new Uint32Array(new e(4*i)):new Uint16Array(new e(2*i))}function P0(i,e){if(!i.index){let t=i.attributes.position.count,n=e.useSharedArrayBuffer?SharedArrayBuffer:ArrayBuffer,s=BT(t,n);i.setIndex(new Tt(s,1));for(let r=0;r<t;r++)s[r]=r}}function zT(i,e,t){let n=$d(i)/t,s=e||i.drawRange,r=s.start/t,o=(s.start+s.count)/t,a=Math.max(0,r),c=Math.min(n,o)-a;return{offset:Math.floor(a),count:Math.floor(c)}}function kT(i,e){return i.groups.map(t=>({offset:t.start/e,count:t.count/e}))}function jd(i,e,t){let n=zT(i,e,t),s=kT(i,t);if(!s.length)return[n];let r=[],o=n.offset,a=n.offset+n.count,c=$d(i)/t,l=[];for(let f of s){let{offset:d,count:m}=f,x=d,g=isFinite(m)?m:c-d,p=d+g;x<a&&p>o&&(l.push({pos:Math.max(o,x),isStart:!0}),l.push({pos:Math.min(a,p),isStart:!1}))}l.sort((f,d)=>f.pos!==d.pos?f.pos-d.pos:f.type==="end"?-1:1);let u=0,h=null;for(let f of l){let d=f.pos;u!==0&&d!==h&&r.push({offset:h,count:d-h}),u+=f.isStart?1:-1,h=d}return r}function VT(i,e){let t=i[i.length-1],n=t.offset+t.count>2**16,s=i.reduce((l,u)=>l+u.count,0),r=n?4:2,o=e?new SharedArrayBuffer(s*r):new ArrayBuffer(s*r),a=n?new Uint32Array(o):new Uint16Array(o),c=0;for(let l=0;l<i.length;l++){let{offset:u,count:h}=i[l];for(let f=0;f<h;f++)a[c+f]=u+f;c+=h}return a}var Hu=class extends Vu{get indirect(){return!!this._indirectBuffer}get primitiveStride(){return null}get primitiveBufferStride(){return this.indirect?1:this.primitiveStride}set primitiveBufferStride(e){}get primitiveBuffer(){return this.indirect?this._indirectBuffer:this.geometry.index.array}set primitiveBuffer(e){}constructor(e,t={}){if(e.isBufferGeometry){if(e.index&&e.index.isInterleavedBufferAttribute)throw new Error("BVH: InterleavedBufferAttribute is not supported for the index attribute.")}else throw new Error("BVH: Only BufferGeometries are supported.");if(t.useSharedArrayBuffer&&!C0())throw new Error("BVH: SharedArrayBuffer is not available.");super(),this.geometry=e,this.resolvePrimitiveIndex=t.indirect?n=>this._indirectBuffer[n]:n=>n,this.primitiveBuffer=null,this.primitiveBufferStride=null,this._indirectBuffer=null,t={...Nu,...t},t[Xa]||this.init(t)}init(e){let{geometry:t,primitiveStride:n}=this;if(e.indirect){let s=jd(t,e.range,n),r=VT(s,e.useSharedArrayBuffer);this._indirectBuffer=r}else P0(t,e);super.init(e),!t.boundingBox&&e.setBoundingBox&&(t.boundingBox=this.getBoundingBox(new Ke))}getRootRanges(e){return this.indirect?[{offset:0,count:this._indirectBuffer.length}]:jd(this.geometry,e,this.primitiveStride)}raycastObject3D(){throw new Error("BVH: raycastObject3D() not implemented")}};var Wn=class{constructor(){this.min=1/0,this.max=-1/0}setFromPointsField(e,t){let n=1/0,s=-1/0;for(let r=0,o=e.length;r<o;r++){let c=e[r][t];n=c<n?c:n,s=c>s?c:s}this.min=n,this.max=s}setFromPoints(e,t){let n=1/0,s=-1/0;for(let r=0,o=t.length;r<o;r++){let a=t[r],c=e.dot(a);n=c<n?c:n,s=c>s?c:s}this.min=n,this.max=s}isSeparated(e){return this.min>e.max||e.min>this.max}};Wn.prototype.setFromBox=(function(){let i=new I;return function(t,n){let s=n.min,r=n.max,o=1/0,a=-1/0;for(let c=0;c<=1;c++)for(let l=0;l<=1;l++)for(let u=0;u<=1;u++){i.x=s.x*c+r.x*(1-c),i.y=s.y*l+r.y*(1-l),i.z=s.z*u+r.z*(1-u);let h=t.dot(i);o=Math.min(h,o),a=Math.max(h,a)}this.min=o,this.max=a}})();var HT=(function(){let i=new I,e=new I,t=new I;return function(s,r,o){let a=s.start,c=i,l=r.start,u=e;t.subVectors(a,l),i.subVectors(s.end,s.start),e.subVectors(r.end,r.start);let h=t.dot(u),f=u.dot(c),d=u.dot(u),m=t.dot(c),g=c.dot(c)*d-f*f,p,v;g!==0?p=(h*f-m*d)/g:p=0,v=(h+p*f)/d,o.x=p,o.y=v}})(),Ka=(function(){let i=new ce,e=new I,t=new I;return function(s,r,o,a){HT(s,r,i);let c=i.x,l=i.y;if(c>=0&&c<=1&&l>=0&&l<=1){s.at(c,o),r.at(l,a);return}else if(c>=0&&c<=1){l<0?r.at(0,a):r.at(1,a),s.closestPointToPoint(a,!0,o);return}else if(l>=0&&l<=1){c<0?s.at(0,o):s.at(1,o),r.closestPointToPoint(o,!0,a);return}else{let u;c<0?u=s.start:u=s.end;let h;l<0?h=r.start:h=r.end;let f=e,d=t;if(s.closestPointToPoint(h,!0,e),r.closestPointToPoint(u,!0,t),f.distanceToSquared(h)<=d.distanceToSquared(u)){o.copy(f),a.copy(h);return}else{o.copy(u),a.copy(d);return}}}})(),I0=(function(){let i=new I,e=new I,t=new an,n=new Tn;return function(r,o){let{radius:a,center:c}=r,{a:l,b:u,c:h}=o;if(n.start=l,n.end=u,n.closestPointToPoint(c,!0,i).distanceTo(c)<=a||(n.start=l,n.end=h,n.closestPointToPoint(c,!0,i).distanceTo(c)<=a)||(n.start=u,n.end=h,n.closestPointToPoint(c,!0,i).distanceTo(c)<=a))return!0;let x=o.getPlane(t);if(Math.abs(x.distanceToPoint(c))<=a){let p=x.projectPoint(c,e);if(o.containsPoint(p))return!0}return!1}})();var GT=["x","y","z"],Ki=1e-15,L0=Ki*Ki;function $n(i){return Math.abs(i)<Ki}var un=class extends cn{constructor(...e){super(...e),this.isExtendedTriangle=!0,this.satAxes=new Array(4).fill().map(()=>new I),this.satBounds=new Array(4).fill().map(()=>new Wn),this.points=[this.a,this.b,this.c],this.plane=new an,this.isDegenerateIntoSegment=!1,this.isDegenerateIntoPoint=!1,this.degenerateSegment=new Tn,this.needsUpdate=!0}intersectsSphere(e){return I0(e,this)}update(){let e=this.a,t=this.b,n=this.c,s=this.points,r=this.satAxes,o=this.satBounds,a=r[0],c=o[0];this.getNormal(a),c.setFromPoints(a,s);let l=r[1],u=o[1];l.subVectors(e,t),u.setFromPoints(l,s);let h=r[2],f=o[2];h.subVectors(t,n),f.setFromPoints(h,s);let d=r[3],m=o[3];d.subVectors(n,e),m.setFromPoints(d,s);let x=l.length(),g=h.length(),p=d.length();this.isDegenerateIntoPoint=!1,this.isDegenerateIntoSegment=!1,x<Ki?g<Ki||p<Ki?this.isDegenerateIntoPoint=!0:(this.isDegenerateIntoSegment=!0,this.degenerateSegment.start.copy(e),this.degenerateSegment.end.copy(n)):g<Ki?p<Ki?this.isDegenerateIntoPoint=!0:(this.isDegenerateIntoSegment=!0,this.degenerateSegment.start.copy(t),this.degenerateSegment.end.copy(e)):p<Ki&&(this.isDegenerateIntoSegment=!0,this.degenerateSegment.start.copy(n),this.degenerateSegment.end.copy(t)),this.plane.setFromNormalAndCoplanarPoint(a,e),this.needsUpdate=!1}};un.prototype.closestPointToSegment=(function(){let i=new I,e=new I,t=new Tn;return function(s,r=null,o=null){let{start:a,end:c}=s,l=this.points,u,h=1/0;for(let f=0;f<3;f++){let d=(f+1)%3;t.start.copy(l[f]),t.end.copy(l[d]),Ka(t,s,i,e),u=i.distanceToSquared(e),u<h&&(h=u,r&&r.copy(i),o&&o.copy(e))}return this.closestPointToPoint(a,i),u=a.distanceToSquared(i),u<h&&(h=u,r&&r.copy(i),o&&o.copy(a)),this.closestPointToPoint(c,i),u=c.distanceToSquared(i),u<h&&(h=u,r&&r.copy(i),o&&o.copy(c)),Math.sqrt(h)}})();un.prototype.intersectsTriangle=(function(){let i=new un,e=new Wn,t=new Wn,n=new I,s=new I,r=new I,o=new I,a=new Tn,c=new Tn,l=new I,u=new ce,h=new ce;function f(b,_,S,M){let E=n;!b.isDegenerateIntoPoint&&!b.isDegenerateIntoSegment?E.copy(b.plane.normal):E.copy(_.plane.normal);let y=b.satBounds,w=b.satAxes;for(let C=1;C<4;C++){let D=y[C],L=w[C];if(e.setFromPoints(L,_.points),D.isSeparated(e)||(o.copy(E).cross(L),e.setFromPoints(o,b.points),t.setFromPoints(o,_.points),e.isSeparated(t)))return!1}let A=_.satBounds,P=_.satAxes;for(let C=1;C<4;C++){let D=A[C],L=P[C];if(e.setFromPoints(L,b.points),D.isSeparated(e)||(o.crossVectors(E,L),e.setFromPoints(o,b.points),t.setFromPoints(o,_.points),e.isSeparated(t)))return!1}return S&&(M||console.warn("ExtendedTriangle.intersectsTriangle: Triangles are coplanar which does not support an output edge. Setting edge to 0, 0, 0."),S.start.set(0,0,0),S.end.set(0,0,0)),!0}function d(b,_,S,M,E,y,w,A,P,C,D){let L=w/(w-A);C.x=M+(E-M)*L,D.start.subVectors(_,b).multiplyScalar(L).add(b),L=w/(w-P),C.y=M+(y-M)*L,D.end.subVectors(S,b).multiplyScalar(L).add(b)}function m(b,_,S,M,E,y,w,A,P,C,D){if(E>0)d(b.c,b.a,b.b,M,_,S,P,w,A,C,D);else if(y>0)d(b.b,b.a,b.c,S,_,M,A,w,P,C,D);else if(A*P>0||w!=0)d(b.a,b.b,b.c,_,S,M,w,A,P,C,D);else if(A!=0)d(b.b,b.a,b.c,S,_,M,A,w,P,C,D);else if(P!=0)d(b.c,b.a,b.b,M,_,S,P,w,A,C,D);else return!0;return!1}function x(b,_,S,M){let E=_.degenerateSegment,y=b.plane.distanceToPoint(E.start),w=b.plane.distanceToPoint(E.end);return $n(y)?$n(w)?f(b,_,S,M):(S&&(S.start.copy(E.start),S.end.copy(E.start)),b.containsPoint(E.start)):$n(w)?(S&&(S.start.copy(E.end),S.end.copy(E.end)),b.containsPoint(E.end)):b.plane.intersectLine(E,n)!=null?(S&&(S.start.copy(n),S.end.copy(n)),b.containsPoint(n)):!1}function g(b,_,S){let M=_.a;return $n(b.plane.distanceToPoint(M))&&b.containsPoint(M)?(S&&(S.start.copy(M),S.end.copy(M)),!0):!1}function p(b,_,S){let M=b.degenerateSegment,E=_.a;return M.closestPointToPoint(E,!0,n),E.distanceToSquared(n)<L0?(S&&(S.start.copy(E),S.end.copy(E)),!0):!1}function v(b,_,S,M){if(b.isDegenerateIntoSegment)if(_.isDegenerateIntoSegment){let E=b.degenerateSegment,y=_.degenerateSegment,w=s,A=r;E.delta(w),y.delta(A);let P=n.subVectors(y.start,E.start),C=w.x*A.y-w.y*A.x;if($n(C))return!1;let D=(P.x*A.y-P.y*A.x)/C,L=-(w.x*P.y-w.y*P.x)/C;if(D<0||D>1||L<0||L>1)return!1;let U=E.start.z+w.z*D,G=y.start.z+A.z*L;return $n(U-G)?(S&&(S.start.copy(E.start).addScaledVector(w,D),S.end.copy(E.start).addScaledVector(w,D)),!0):!1}else return _.isDegenerateIntoPoint?p(b,_,S):x(_,b,S,M);else{if(b.isDegenerateIntoPoint)return _.isDegenerateIntoPoint?_.a.distanceToSquared(b.a)<L0?(S&&(S.start.copy(b.a),S.end.copy(b.a)),!0):!1:_.isDegenerateIntoSegment?p(_,b,S):g(_,b,S);if(_.isDegenerateIntoPoint)return g(b,_,S);if(_.isDegenerateIntoSegment)return x(b,_,S,M)}}return function(_,S=null,M=!1){this.needsUpdate&&this.update(),_.isExtendedTriangle?_.needsUpdate&&_.update():(i.copy(_),i.update(),_=i);let E=v(this,_,S,M);if(E!==void 0)return E;let y=this.plane,w=_.plane,A=w.distanceToPoint(this.a),P=w.distanceToPoint(this.b),C=w.distanceToPoint(this.c);$n(A)&&(A=0),$n(P)&&(P=0),$n(C)&&(C=0);let D=A*P,L=A*C;if(D>0&&L>0)return!1;let U=y.distanceToPoint(_.a),G=y.distanceToPoint(_.b),Z=y.distanceToPoint(_.c);$n(U)&&(U=0),$n(G)&&(G=0),$n(Z)&&(Z=0);let oe=U*G,K=U*Z;if(oe>0&&K>0)return!1;s.copy(y.normal),r.copy(w.normal);let te=s.cross(r),se=0,Re=Math.abs(te.x),Te=Math.abs(te.y);Te>Re&&(Re=Te,se=1),Math.abs(te.z)>Re&&(se=2);let He=GT[se],$e=this.a[He],$=this.b[He],z=this.c[He],j=_.a[He],me=_.b[He],fe=_.c[He];if(m(this,$e,$,z,D,L,A,P,C,u,a))return f(this,_,S,M);if(m(_,j,me,fe,oe,K,U,G,Z,h,c))return f(this,_,S,M);if(u.y<u.x){let de=u.y;u.y=u.x,u.x=de,l.copy(a.start),a.start.copy(a.end),a.end.copy(l)}if(h.y<h.x){let de=h.y;h.y=h.x,h.x=de,l.copy(c.start),c.start.copy(c.end),c.end.copy(l)}return u.y<h.x||h.y<u.x?!1:(S&&(h.x>u.x?S.start.copy(c.start):S.start.copy(a.start),h.y<u.y?S.end.copy(c.end):S.end.copy(a.end)),!0)}})();un.prototype.distanceToPoint=(function(){let i=new I;return function(t){return this.closestPointToPoint(t,i),t.distanceTo(i)}})();un.prototype.distanceToTriangle=(function(){let i=new I,e=new I,t=["a","b","c"],n=new Tn,s=new Tn;return function(o,a=null,c=null){let l=a||c?n:null;if(this.intersectsTriangle(o,l,!0))return(a||c)&&(a&&l.getCenter(a),c&&l.getCenter(c)),0;let u=1/0;for(let h=0;h<3;h++){let f,d=t[h],m=o[d];this.closestPointToPoint(m,i),f=m.distanceToSquared(i),f<u&&(u=f,a&&a.copy(i),c&&c.copy(m));let x=this[d];o.closestPointToPoint(x,i),f=x.distanceToSquared(i),f<u&&(u=f,a&&a.copy(x),c&&c.copy(i))}for(let h=0;h<3;h++){let f=t[h],d=t[(h+1)%3];n.set(this[f],this[d]);for(let m=0;m<3;m++){let x=t[m],g=t[(m+1)%3];s.set(o[x],o[g]),Ka(n,s,i,e);let p=i.distanceToSquared(e);p<u&&(u=p,a&&a.copy(i),c&&c.copy(e))}}return Math.sqrt(u)}})();var kt=class{constructor(e,t,n){this.isOrientedBox=!0,this.min=new I,this.max=new I,this.matrix=new Ie,this.invMatrix=new Ie,this.points=new Array(8).fill().map(()=>new I),this.satAxes=new Array(3).fill().map(()=>new I),this.satBounds=new Array(3).fill().map(()=>new Wn),this.alignedSatBounds=new Array(3).fill().map(()=>new Wn),this.needsUpdate=!1,e&&this.min.copy(e),t&&this.max.copy(t),n&&this.matrix.copy(n)}set(e,t,n){this.min.copy(e),this.max.copy(t),this.matrix.copy(n),this.needsUpdate=!0}copy(e){this.min.copy(e.min),this.max.copy(e.max),this.matrix.copy(e.matrix),this.needsUpdate=!0}};kt.prototype.update=(function(){return function(){let e=this.matrix,t=this.min,n=this.max,s=this.points;for(let l=0;l<=1;l++)for(let u=0;u<=1;u++)for(let h=0;h<=1;h++){let f=1*l|2*u|4*h,d=s[f];d.x=l?n.x:t.x,d.y=u?n.y:t.y,d.z=h?n.z:t.z,d.applyMatrix4(e)}let r=this.satBounds,o=this.satAxes,a=s[0];for(let l=0;l<3;l++){let u=o[l],h=r[l],f=1<<l,d=s[f];u.subVectors(a,d),h.setFromPoints(u,s)}let c=this.alignedSatBounds;c[0].setFromPointsField(s,"x"),c[1].setFromPointsField(s,"y"),c[2].setFromPointsField(s,"z"),this.invMatrix.copy(this.matrix).invert(),this.needsUpdate=!1}})();kt.prototype.intersectsBox=(function(){let i=new Wn;return function(t){this.needsUpdate&&this.update();let n=t.min,s=t.max,r=this.satBounds,o=this.satAxes,a=this.alignedSatBounds;if(i.min=n.x,i.max=s.x,a[0].isSeparated(i)||(i.min=n.y,i.max=s.y,a[1].isSeparated(i))||(i.min=n.z,i.max=s.z,a[2].isSeparated(i)))return!1;for(let c=0;c<3;c++){let l=o[c],u=r[c];if(i.setFromBox(l,t),u.isSeparated(i))return!1}return!0}})();kt.prototype.intersectsTriangle=(function(){let i=new un,e=new Array(3),t=new Wn,n=new Wn,s=new I;return function(o){this.needsUpdate&&this.update(),o.isExtendedTriangle?o.needsUpdate&&o.update():(i.copy(o),i.update(),o=i);let a=this.satBounds,c=this.satAxes;e[0]=o.a,e[1]=o.b,e[2]=o.c;for(let f=0;f<3;f++){let d=a[f],m=c[f];if(t.setFromPoints(m,e),d.isSeparated(t))return!1}let l=o.satBounds,u=o.satAxes,h=this.points;for(let f=0;f<3;f++){let d=l[f],m=u[f];if(t.setFromPoints(m,h),d.isSeparated(t))return!1}for(let f=0;f<3;f++){let d=c[f];for(let m=0;m<4;m++){let x=u[m];if(s.crossVectors(d,x),t.setFromPoints(s,e),n.setFromPoints(s,h),t.isSeparated(n))return!1}}return!0}})();kt.prototype.closestPointToPoint=(function(){return function(e,t){return this.needsUpdate&&this.update(),t.copy(e).applyMatrix4(this.invMatrix).clamp(this.min,this.max).applyMatrix4(this.matrix),t}})();kt.prototype.distanceToPoint=(function(){let i=new I;return function(t){return this.closestPointToPoint(t,i),t.distanceTo(i)}})();kt.prototype.distanceToBox=(function(){let i=["x","y","z"],e=new Array(12).fill().map(()=>new Tn),t=new Array(12).fill().map(()=>new Tn),n=new I,s=new I;return function(o,a=0,c=null,l=null){if(this.needsUpdate&&this.update(),this.intersectsBox(o))return(c||l)&&(o.getCenter(s),this.closestPointToPoint(s,n),o.closestPointToPoint(n,s),c&&c.copy(n),l&&l.copy(s)),0;let u=a*a,h=o.min,f=o.max,d=this.points,m=1/0;for(let g=0;g<8;g++){let p=d[g];s.copy(p).clamp(h,f);let v=p.distanceToSquared(s);if(v<m&&(m=v,c&&c.copy(p),l&&l.copy(s),v<u))return Math.sqrt(v)}let x=0;for(let g=0;g<3;g++)for(let p=0;p<=1;p++)for(let v=0;v<=1;v++){let b=(g+1)%3,_=(g+2)%3,S=p<<b|v<<_,M=1<<g|p<<b|v<<_,E=d[S],y=d[M];e[x].set(E,y);let A=i[g],P=i[b],C=i[_],D=t[x],L=D.start,U=D.end;L[A]=h[A],L[P]=p?h[P]:f[P],L[C]=v?h[C]:f[P],U[A]=f[A],U[P]=p?h[P]:f[P],U[C]=v?h[C]:f[P],x++}for(let g=0;g<=1;g++)for(let p=0;p<=1;p++)for(let v=0;v<=1;v++){s.x=g?f.x:h.x,s.y=p?f.y:h.y,s.z=v?f.z:h.z,this.closestPointToPoint(s,n);let b=s.distanceToSquared(n);if(b<m&&(m=b,c&&c.copy(n),l&&l.copy(s),b<u))return Math.sqrt(b)}for(let g=0;g<12;g++){let p=e[g];for(let v=0;v<12;v++){let b=t[v];Ka(p,b,n,s);let _=n.distanceToSquared(s);if(_<m&&(m=_,c&&c.copy(n),l&&l.copy(s),_<u))return Math.sqrt(_)}}return Math.sqrt(m)}})();var Qd=class extends bs{constructor(){super(()=>new un)}},wn=new Qd;var Ja=new I,ep=new I;function N0(i,e,t={},n=0,s=1/0){let r=n*n,o=s*s,a=1/0,c=null;if(i.shapecast({boundsTraverseOrder:u=>(Ja.copy(e).clamp(u.min,u.max),Ja.distanceToSquared(e)),intersectsBounds:(u,h,f)=>f<a&&f<o,intersectsTriangle:(u,h)=>{u.closestPointToPoint(e,Ja);let f=e.distanceToSquared(Ja);return f<a&&(ep.copy(Ja),a=f,c=h),f<r}}),a===1/0)return null;let l=Math.sqrt(a);return t.point?t.point.copy(ep):t.point=ep.clone(),t.distance=l,t.faceIndex=c,t}var Gu=parseInt("186")>=169,WT=parseInt("186")<=161,Qs=new I,er=new I,tr=new I,Wu=new ce,Xu=new ce,qu=new ce,D0=new I,U0=new I,F0=new I,$a=new I;function XT(i,e,t,n,s,r,o,a){let c;if(r===jt?c=i.intersectTriangle(n,t,e,!0,s):c=i.intersectTriangle(e,t,n,r!==Dt,s),c===null)return null;let l=i.origin.distanceTo(s);return l<o||l>a?null:{distance:l,point:s.clone()}}function O0(i,e,t,n,s,r,o,a,c,l,u){Qs.fromBufferAttribute(e,r),er.fromBufferAttribute(e,o),tr.fromBufferAttribute(e,a);let h=XT(i,Qs,er,tr,$a,c,l,u);if(h){if(n){Wu.fromBufferAttribute(n,r),Xu.fromBufferAttribute(n,o),qu.fromBufferAttribute(n,a),h.uv=new ce;let d=cn.getInterpolation($a,Qs,er,tr,Wu,Xu,qu,h.uv);Gu||(h.uv=d)}if(s){Wu.fromBufferAttribute(s,r),Xu.fromBufferAttribute(s,o),qu.fromBufferAttribute(s,a),h.uv1=new ce;let d=cn.getInterpolation($a,Qs,er,tr,Wu,Xu,qu,h.uv1);Gu||(h.uv1=d),WT&&(h.uv2=h.uv1)}if(t){D0.fromBufferAttribute(t,r),U0.fromBufferAttribute(t,o),F0.fromBufferAttribute(t,a),h.normal=new I;let d=cn.getInterpolation($a,Qs,er,tr,D0,U0,F0,h.normal);h.normal.dot(i.direction)>0&&h.normal.multiplyScalar(-1),Gu||(h.normal=d)}let f={a:r,b:o,c:a,normal:new I,materialIndex:0};if(cn.getNormal(Qs,er,tr,f.normal),h.face=f,h.faceIndex=r,Gu){let d=new I;cn.getBarycoord($a,Qs,er,tr,d),h.barycoord=d}}return h}function B0(i){return i&&i.isMaterial?i.side:i}function So(i,e,t,n,s,r,o){let a=n*3,c=a+0,l=a+1,u=a+2,{index:h,groups:f}=i;i.index&&(c=h.getX(c),l=h.getX(l),u=h.getX(u));let{position:d,normal:m,uv:x,uv1:g}=i.attributes;if(Array.isArray(e)){let p=n*3;for(let v=0,b=f.length;v<b;v++){let{start:_,count:S,materialIndex:M}=f[v];if(p>=_&&p<_+S){let E=B0(e[M]),y=O0(t,d,m,x,g,c,l,u,E,r,o);if(y)if(y.faceIndex=n,y.face.materialIndex=M,s)s.push(y);else return y}}}else{let p=B0(e),v=O0(t,d,m,x,g,c,l,u,p,r,o);if(v)if(v.faceIndex=n,v.face.materialIndex=0,s)s.push(v);else return v}return null}function Ct(i,e,t,n){let s=i.a,r=i.b,o=i.c,a=e,c=e+1,l=e+2;t&&(a=t.getX(a),c=t.getX(c),l=t.getX(l)),s.x=n.getX(a),s.y=n.getY(a),s.z=n.getZ(a),r.x=n.getX(c),r.y=n.getY(c),r.z=n.getZ(c),o.x=n.getX(l),o.y=n.getY(l),o.z=n.getZ(l)}function z0(i,e,t,n,s,r,o,a){let{geometry:c,_indirectBuffer:l}=i;for(let u=n,h=n+s;u<h;u++)So(c,e,t,u,r,o,a)}function k0(i,e,t,n,s,r,o){let{geometry:a,_indirectBuffer:c}=i,l=1/0,u=null;for(let h=n,f=n+s;h<f;h++){let d;d=So(a,e,t,h,null,r,o),d&&d.distance<l&&(u=d,l=d.distance)}return u}function V0(i,e,t,n,s,r,o){let{geometry:a}=t,{index:c}=a,l=a.attributes.position;for(let u=i,h=e+i;u<h;u++){let f;if(f=u,Ct(o,f*3,c,l),o.needsUpdate=!0,n(o,f,s,r))return!0}return!1}function H0(i,e=null){e&&Array.isArray(e)&&(e=new Set(e));let t=i.geometry,n=t.index?t.index.array:null,s=t.attributes.position,r,o,a,c,l=0,u=i._roots;for(let f=0,d=u.length;f<d;f++)r=u[f],o=new Uint32Array(r),a=new Uint16Array(r),c=new Float32Array(r),h(0,l),l+=r.byteLength;function h(f,d,m=!1){let x=f*2;if(at(x,a)){let g=vt(f,o),p=wt(x,a),v=1/0,b=1/0,_=1/0,S=-1/0,M=-1/0,E=-1/0;for(let y=3*g,w=3*(g+p);y<w;y++){let A=n[y],P=s.getX(A),C=s.getY(A),D=s.getZ(A);P<v&&(v=P),P>S&&(S=P),C<b&&(b=C),C>M&&(M=C),D<_&&(_=D),D>E&&(E=D)}return c[f+0]!==v||c[f+1]!==b||c[f+2]!==_||c[f+3]!==S||c[f+4]!==M||c[f+5]!==E?(c[f+0]=v,c[f+1]=b,c[f+2]=_,c[f+3]=S,c[f+4]=M,c[f+5]=E,!0):!1}else{let g=dt(f),p=pt(f,o),v=m,b=!1,_=!1;if(e){if(!v){let A=g/8+d/32,P=p/8+d/32;b=e.has(A),_=e.has(P),v=!b&&!_}}else b=!0,_=!0;let S=v||b,M=v||_,E=!1;S&&(E=h(g,d,v));let y=!1;M&&(y=h(p,d,v));let w=E||y;if(w)for(let A=0;A<3;A++){let P=g+A,C=p+A,D=c[P],L=c[P+3],U=c[C],G=c[C+3];c[f+A]=D<U?D:U,c[f+A+3]=L>G?L:G}return w}}}function jn(i,e,t,n,s){let r,o,a,c,l,u,h=1/t.direction.x,f=1/t.direction.y,d=1/t.direction.z,m=t.origin.x,x=t.origin.y,g=t.origin.z,p=e[i],v=e[i+3],b=e[i+1],_=e[i+3+1],S=e[i+2],M=e[i+3+2];return h>=0?(r=(p-m)*h,o=(v-m)*h):(r=(v-m)*h,o=(p-m)*h),f>=0?(a=(b-x)*f,c=(_-x)*f):(a=(_-x)*f,c=(b-x)*f),r>c||a>o||((a>r||isNaN(r))&&(r=a),(c<o||isNaN(o))&&(o=c),d>=0?(l=(S-g)*d,u=(M-g)*d):(l=(M-g)*d,u=(S-g)*d),r>u||l>o)?!1:((l>r||r!==r)&&(r=l),(u<o||o!==o)&&(o=u),r<=s&&o>=n)}function G0(i,e,t,n,s,r,o,a){let{geometry:c,_indirectBuffer:l}=i;for(let u=n,h=n+s;u<h;u++){let f=l?l[u]:u;So(c,e,t,f,r,o,a)}}function W0(i,e,t,n,s,r,o){let{geometry:a,_indirectBuffer:c}=i,l=1/0,u=null;for(let h=n,f=n+s;h<f;h++){let d;d=So(a,e,t,c?c[h]:h,null,r,o),d&&d.distance<l&&(u=d,l=d.distance)}return u}function X0(i,e,t,n,s,r,o){let{geometry:a}=t,{index:c}=a,l=a.attributes.position;for(let u=i,h=e+i;u<h;u++){let f;if(f=t.resolveTriangleIndex(u),Ct(o,f*3,c,l),o.needsUpdate=!0,n(o,f,s,r))return!0}return!1}function q0(i,e,t,n,s,r,o){ft.setBuffer(i._roots[e]),tp(0,i,t,n,s,r,o),ft.clearBuffer()}function tp(i,e,t,n,s,r,o){let{float32Array:a,uint16Array:c,uint32Array:l}=ft,u=i*2;if(at(u,c)){let f=vt(i,l),d=wt(u,c);z0(e,t,n,f,d,s,r,o)}else{let f=dt(i);jn(f,a,n,r,o)&&tp(f,e,t,n,s,r,o);let d=pt(i,l);jn(d,a,n,r,o)&&tp(d,e,t,n,s,r,o)}}var qT=["x","y","z"];function Y0(i,e,t,n,s,r){ft.setBuffer(i._roots[e]);let o=np(0,i,t,n,s,r);return ft.clearBuffer(),o}function np(i,e,t,n,s,r){let{float32Array:o,uint16Array:a,uint32Array:c}=ft,l=i*2;if(at(l,a)){let h=vt(i,c),f=wt(l,a);return k0(e,t,n,h,f,s,r)}else{let h=po(i,c),f=qT[h],m=n.direction[f]>=0,x,g;m?(x=dt(i),g=pt(i,c)):(x=pt(i,c),g=dt(i));let v=jn(x,o,n,s,r)?np(x,e,t,n,s,r):null;if(v){let S=v.point[f];if(m?S<=o[g+h]:S>=o[g+h+3])return v}let _=jn(g,o,n,s,r)?np(g,e,t,n,s,r):null;return v&&_?v.distance<=_.distance?v:_:v||_||null}}var Yu=new Ke,bo=new un,Mo=new un,ja=new Ie,Z0=new kt,Zu=new kt;function K0(i,e,t,n){ft.setBuffer(i._roots[e]);let s=ip(0,i,t,n);return ft.clearBuffer(),s}function ip(i,e,t,n,s=null){let{float32Array:r,uint16Array:o,uint32Array:a}=ft,c=i*2;if(s===null&&(t.boundingBox||t.computeBoundingBox(),Z0.set(t.boundingBox.min,t.boundingBox.max,n),s=Z0),at(c,o)){let u=e.geometry,h=u.index,f=u.attributes.position,d=t.index,m=t.attributes.position,x=vt(i,a),g=wt(c,o);if(ja.copy(n).invert(),t.boundsTree)return Rt(i,r,Zu),Zu.matrix.copy(ja),Zu.needsUpdate=!0,t.boundsTree.shapecast({intersectsBounds:v=>Zu.intersectsBox(v),intersectsTriangle:v=>{v.a.applyMatrix4(n),v.b.applyMatrix4(n),v.c.applyMatrix4(n),v.needsUpdate=!0;for(let b=x*3,_=(g+x)*3;b<_;b+=3)if(Ct(Mo,b,h,f),Mo.needsUpdate=!0,v.intersectsTriangle(Mo))return!0;return!1}});{let p=ws(t);for(let v=x*3,b=(g+x)*3;v<b;v+=3){Ct(bo,v,h,f),bo.a.applyMatrix4(ja),bo.b.applyMatrix4(ja),bo.c.applyMatrix4(ja),bo.needsUpdate=!0;for(let _=0,S=p*3;_<S;_+=3)if(Ct(Mo,_,d,m),Mo.needsUpdate=!0,bo.intersectsTriangle(Mo))return!0}}}else{let u=dt(i),h=pt(i,a);return Rt(u,r,Yu),!!(s.intersectsBox(Yu)&&ip(u,e,t,n,s)||(Rt(h,r,Yu),s.intersectsBox(Yu)&&ip(h,e,t,n,s)))}}var Ku=new Ie,sp=new kt,Qa=new kt,YT=new I,ZT=new I,KT=new I,JT=new I;function J0(i,e,t,n={},s={},r=0,o=1/0){e.boundingBox||e.computeBoundingBox(),sp.set(e.boundingBox.min,e.boundingBox.max,t),sp.needsUpdate=!0;let a=i.geometry,c=a.attributes.position,l=a.index,u=e.attributes.position,h=e.index,f=wn.getPrimitive(),d=wn.getPrimitive(),m=YT,x=ZT,g=null,p=null;s&&(g=KT,p=JT);let v=1/0,b=null,_=null;return Ku.copy(t).invert(),Qa.matrix.copy(Ku),i.shapecast({boundsTraverseOrder:S=>sp.distanceToBox(S),intersectsBounds:(S,M,E)=>E<v&&E<o?(M&&(Qa.min.copy(S.min),Qa.max.copy(S.max),Qa.needsUpdate=!0),!0):!1,intersectsRange:(S,M)=>{if(e.boundsTree)return e.boundsTree.shapecast({boundsTraverseOrder:y=>Qa.distanceToBox(y),intersectsBounds:(y,w,A)=>A<v&&A<o,intersectsRange:(y,w)=>{for(let A=y,P=y+w;A<P;A++){Ct(d,3*A,h,u),d.a.applyMatrix4(t),d.b.applyMatrix4(t),d.c.applyMatrix4(t),d.needsUpdate=!0;for(let C=S,D=S+M;C<D;C++){Ct(f,3*C,l,c),f.needsUpdate=!0;let L=f.distanceToTriangle(d,m,g);if(L<v&&(x.copy(m),p&&p.copy(g),v=L,b=C,_=A),L<r)return!0}}}});{let E=ws(e);for(let y=0,w=E;y<w;y++){Ct(d,3*y,h,u),d.a.applyMatrix4(t),d.b.applyMatrix4(t),d.c.applyMatrix4(t),d.needsUpdate=!0;for(let A=S,P=S+M;A<P;A++){Ct(f,3*A,l,c),f.needsUpdate=!0;let C=f.distanceToTriangle(d,m,g);if(C<v&&(x.copy(m),p&&p.copy(g),v=C,b=A,_=y),C<r)return!0}}}}}),wn.releasePrimitive(f),wn.releasePrimitive(d),v===1/0?null:(n.point?n.point.copy(x):n.point=x.clone(),n.distance=v,n.faceIndex=b,s&&(s.point?s.point.copy(p):s.point=p.clone(),s.point.applyMatrix4(Ku),x.applyMatrix4(Ku),s.distance=x.sub(s.point).length(),s.faceIndex=_),n)}function $0(i,e=null){e&&Array.isArray(e)&&(e=new Set(e));let t=i.geometry,n=t.index?t.index.array:null,s=t.attributes.position,r,o,a,c,l=0,u=i._roots;for(let f=0,d=u.length;f<d;f++)r=u[f],o=new Uint32Array(r),a=new Uint16Array(r),c=new Float32Array(r),h(0,l),l+=r.byteLength;function h(f,d,m=!1){let x=f*2;if(at(x,a)){let g=vt(f,o),p=wt(x,a),v=1/0,b=1/0,_=1/0,S=-1/0,M=-1/0,E=-1/0;for(let y=g,w=g+p;y<w;y++){let A=3*i.resolveTriangleIndex(y);for(let P=0;P<3;P++){let C=A+P;C=n?n[C]:C;let D=s.getX(C),L=s.getY(C),U=s.getZ(C);D<v&&(v=D),D>S&&(S=D),L<b&&(b=L),L>M&&(M=L),U<_&&(_=U),U>E&&(E=U)}}return c[f+0]!==v||c[f+1]!==b||c[f+2]!==_||c[f+3]!==S||c[f+4]!==M||c[f+5]!==E?(c[f+0]=v,c[f+1]=b,c[f+2]=_,c[f+3]=S,c[f+4]=M,c[f+5]=E,!0):!1}else{let g=dt(f),p=pt(f,o),v=m,b=!1,_=!1;if(e){if(!v){let A=g/8+d/32,P=p/8+d/32;b=e.has(A),_=e.has(P),v=!b&&!_}}else b=!0,_=!0;let S=v||b,M=v||_,E=!1;S&&(E=h(g,d,v));let y=!1;M&&(y=h(p,d,v));let w=E||y;if(w)for(let A=0;A<3;A++){let P=g+A,C=p+A,D=c[P],L=c[P+3],U=c[C],G=c[C+3];c[f+A]=D<U?D:U,c[f+A+3]=L>G?L:G}return w}}}function j0(i,e,t,n,s,r,o){ft.setBuffer(i._roots[e]),rp(0,i,t,n,s,r,o),ft.clearBuffer()}function rp(i,e,t,n,s,r,o){let{float32Array:a,uint16Array:c,uint32Array:l}=ft,u=i*2;if(at(u,c)){let f=vt(i,l),d=wt(u,c);G0(e,t,n,f,d,s,r,o)}else{let f=dt(i);jn(f,a,n,r,o)&&rp(f,e,t,n,s,r,o);let d=pt(i,l);jn(d,a,n,r,o)&&rp(d,e,t,n,s,r,o)}}var $T=["x","y","z"];function Q0(i,e,t,n,s,r){ft.setBuffer(i._roots[e]);let o=op(0,i,t,n,s,r);return ft.clearBuffer(),o}function op(i,e,t,n,s,r){let{float32Array:o,uint16Array:a,uint32Array:c}=ft,l=i*2;if(at(l,a)){let h=vt(i,c),f=wt(l,a);return W0(e,t,n,h,f,s,r)}else{let h=po(i,c),f=$T[h],m=n.direction[f]>=0,x,g;m?(x=dt(i),g=pt(i,c)):(x=pt(i,c),g=dt(i));let v=jn(x,o,n,s,r)?op(x,e,t,n,s,r):null;if(v){let S=v.point[f];if(m?S<=o[g+h]:S>=o[g+h+3])return v}let _=jn(g,o,n,s,r)?op(g,e,t,n,s,r):null;return v&&_?v.distance<=_.distance?v:_:v||_||null}}var Ju=new Ke,To=new un,wo=new un,ec=new Ie,ex=new kt,$u=new kt;function tx(i,e,t,n){ft.setBuffer(i._roots[e]);let s=ap(0,i,t,n);return ft.clearBuffer(),s}function ap(i,e,t,n,s=null){let{float32Array:r,uint16Array:o,uint32Array:a}=ft,c=i*2;if(s===null&&(t.boundingBox||t.computeBoundingBox(),ex.set(t.boundingBox.min,t.boundingBox.max,n),s=ex),at(c,o)){let u=e.geometry,h=u.index,f=u.attributes.position,d=t.index,m=t.attributes.position,x=vt(i,a),g=wt(c,o);if(ec.copy(n).invert(),t.boundsTree)return Rt(i,r,$u),$u.matrix.copy(ec),$u.needsUpdate=!0,t.boundsTree.shapecast({intersectsBounds:v=>$u.intersectsBox(v),intersectsTriangle:v=>{v.a.applyMatrix4(n),v.b.applyMatrix4(n),v.c.applyMatrix4(n),v.needsUpdate=!0;for(let b=x,_=g+x;b<_;b++)if(Ct(wo,3*e.resolveTriangleIndex(b),h,f),wo.needsUpdate=!0,v.intersectsTriangle(wo))return!0;return!1}});{let p=ws(t);for(let v=x,b=g+x;v<b;v++){let _=e.resolveTriangleIndex(v);Ct(To,3*_,h,f),To.a.applyMatrix4(ec),To.b.applyMatrix4(ec),To.c.applyMatrix4(ec),To.needsUpdate=!0;for(let S=0,M=p*3;S<M;S+=3)if(Ct(wo,S,d,m),wo.needsUpdate=!0,To.intersectsTriangle(wo))return!0}}}else{let u=dt(i),h=pt(i,a);return Rt(u,r,Ju),!!(s.intersectsBox(Ju)&&ap(u,e,t,n,s)||(Rt(h,r,Ju),s.intersectsBox(Ju)&&ap(h,e,t,n,s)))}}var ju=new Ie,cp=new kt,tc=new kt,jT=new I,QT=new I,ew=new I,tw=new I;function nx(i,e,t,n={},s={},r=0,o=1/0){e.boundingBox||e.computeBoundingBox(),cp.set(e.boundingBox.min,e.boundingBox.max,t),cp.needsUpdate=!0;let a=i.geometry,c=a.attributes.position,l=a.index,u=e.attributes.position,h=e.index,f=wn.getPrimitive(),d=wn.getPrimitive(),m=jT,x=QT,g=null,p=null;s&&(g=ew,p=tw);let v=1/0,b=null,_=null;return ju.copy(t).invert(),tc.matrix.copy(ju),i.shapecast({boundsTraverseOrder:S=>cp.distanceToBox(S),intersectsBounds:(S,M,E)=>E<v&&E<o?(M&&(tc.min.copy(S.min),tc.max.copy(S.max),tc.needsUpdate=!0),!0):!1,intersectsRange:(S,M)=>{if(e.boundsTree){let E=e.boundsTree;return E.shapecast({boundsTraverseOrder:y=>tc.distanceToBox(y),intersectsBounds:(y,w,A)=>A<v&&A<o,intersectsRange:(y,w)=>{for(let A=y,P=y+w;A<P;A++){let C=E.resolveTriangleIndex(A);Ct(d,3*C,h,u),d.a.applyMatrix4(t),d.b.applyMatrix4(t),d.c.applyMatrix4(t),d.needsUpdate=!0;for(let D=S,L=S+M;D<L;D++){let U=i.resolveTriangleIndex(D);Ct(f,3*U,l,c),f.needsUpdate=!0;let G=f.distanceToTriangle(d,m,g);if(G<v&&(x.copy(m),p&&p.copy(g),v=G,b=D,_=A),G<r)return!0}}}})}else{let E=ws(e);for(let y=0,w=E;y<w;y++){Ct(d,3*y,h,u),d.a.applyMatrix4(t),d.b.applyMatrix4(t),d.c.applyMatrix4(t),d.needsUpdate=!0;for(let A=S,P=S+M;A<P;A++){let C=i.resolveTriangleIndex(A);Ct(f,3*C,l,c),f.needsUpdate=!0;let D=f.distanceToTriangle(d,m,g);if(D<v&&(x.copy(m),p&&p.copy(g),v=D,b=A,_=y),D<r)return!0}}}}}),wn.releasePrimitive(f),wn.releasePrimitive(d),v===1/0?null:(n.point?n.point.copy(x):n.point=x.clone(),n.distance=v,n.faceIndex=b,s&&(s.point?s.point.copy(p):s.point=p.clone(),s.point.applyMatrix4(ju),x.applyMatrix4(ju),s.distance=x.sub(s.point).length(),s.faceIndex=_),n)}function lp(i,e,t){return i===null?null:(i.point.applyMatrix4(e.matrixWorld),i.distance=i.point.distanceTo(t.ray.origin),i.object=e,i)}var Qu=new kt,eh=new Pn,ix=new I,sx=new Ie,rx=new I,up=["getX","getY","getZ"],th=class i extends Hu{static serialize(e,t={}){t={cloneBuffers:!0,...t};let n=e.geometry,s=e._roots,r=e._indirectBuffer,o=n.getIndex(),a={version:1,roots:null,index:null,indirectBuffer:null};return t.cloneBuffers?(a.roots=s.map(c=>c.slice()),a.index=o?o.array.slice():null,a.indirectBuffer=r?r.slice():null):(a.roots=s,a.index=o?o.array:null,a.indirectBuffer=r),a}static deserialize(e,t,n={}){n={setIndex:!0,indirect:!!e.indirectBuffer,...n};let{index:s,roots:r,indirectBuffer:o}=e;e.version||(console.warn("MeshBVH.deserialize: Serialization format has been changed and will be fixed up. It is recommended to regenerate any stored serialized data."),c(r));let a=new i(t,{...n,[Xa]:!0});if(a._roots=r,a._indirectBuffer=o||null,n.setIndex){let l=t.getIndex();if(l===null){let u=new Tt(e.index,1,!1);t.setIndex(u)}else l.array!==s&&(l.array.set(s),l.needsUpdate=!0)}return a;function c(l){for(let u=0;u<l.length;u++){let h=l[u],f=new Uint32Array(h),d=new Uint16Array(h);for(let m=0,x=h.byteLength/32;m<x;m++){let g=8*m,p=2*g;at(p,d)||(f[g+6]=f[g+6]/8-m)}}}}get primitiveStride(){return 3}get resolveTriangleIndex(){return this.resolvePrimitiveIndex}constructor(e,t={}){t.maxLeafTris&&(console.warn('MeshBVH: "maxLeafTris" option has been deprecated. Use "targetLeafSize", instead.'),t={...t,targetLeafSize:t.maxLeafTris}),super(e,t)}shiftTriangleOffsets(e){return super.shiftPrimitiveOffsets(e)}writePrimitiveBounds(e,t,n){let s=this.geometry,r=this._indirectBuffer,o=s.attributes.position,a=s.index?s.index.array:null,l=(r?r[e]:e)*3,u=l+0,h=l+1,f=l+2;a&&(u=a[u],h=a[h],f=a[f]);for(let d=0;d<3;d++){let m=o[up[d]](u),x=o[up[d]](h),g=o[up[d]](f),p=m;x<p&&(p=x),g<p&&(p=g);let v=m;x>v&&(v=x),g>v&&(v=g),t[n+d]=p,t[n+d+3]=v}return t}computePrimitiveBounds(e,t,n){let s=this.geometry,r=this._indirectBuffer,o=s.attributes.position,a=s.index?s.index.array:null,c=o.normalized;if(e<0||t+e-n.offset>n.length/6)throw new Error("MeshBVH: compute triangle bounds range is invalid.");let l=o.array,u=o.offset||0,h=3;o.isInterleavedBufferAttribute&&(h=o.data.stride);let f=["getX","getY","getZ"],d=n.offset;for(let m=e,x=e+t;m<x;m++){let p=(r?r[m]:m)*3,v=(m-d)*6,b=p+0,_=p+1,S=p+2;a&&(b=a[b],_=a[_],S=a[S]),c||(b=b*h+u,_=_*h+u,S=S*h+u);for(let M=0;M<3;M++){let E,y,w;c?(E=o[f[M]](b),y=o[f[M]](_),w=o[f[M]](S)):(E=l[b+M],y=l[_+M],w=l[S+M]);let A=E;y<A&&(A=y),w<A&&(A=w);let P=E;y>P&&(P=y),w>P&&(P=w);let C=(P-A)/2,D=M*2;n[v+D+0]=A+C,n[v+D+1]=C+(Math.abs(A)+C)*ho}}return n}raycastObject3D(e,t,n=[]){let{material:s}=e;if(s===void 0)return;sx.copy(e.matrixWorld).invert(),eh.copy(t.ray).applyMatrix4(sx),rx.setFromMatrixScale(e.matrixWorld),ix.copy(eh.direction).multiply(rx);let r=ix.length(),o=t.near/r,a=t.far/r;if(t.firstHitOnly===!0){let c=this.raycastFirst(eh,s,o,a);c=lp(c,e,t),c&&n.push(c)}else{let c=this.raycast(eh,s,o,a);for(let l=0,u=c.length;l<u;l++){let h=lp(c[l],e,t);h&&n.push(h)}}return n}refit(e=null){return(this.indirect?$0:H0)(this,e)}raycast(e,t=kn,n=0,s=1/0){let r=this._roots,o=[],a=this.indirect?j0:q0;for(let c=0,l=r.length;c<l;c++)a(this,c,t,e,o,n,s);return o}raycastFirst(e,t=kn,n=0,s=1/0){let r=this._roots,o=null,a=this.indirect?Q0:Y0;for(let c=0,l=r.length;c<l;c++){let u=a(this,c,t,e,n,s);u!=null&&(o==null||u.distance<o.distance)&&(o=u)}return o}intersectsGeometry(e,t){let n=!1,s=this._roots,r=this.indirect?tx:K0;for(let o=0,a=s.length;o<a&&(n=r(this,o,e,t),!n);o++);return n}shapecast(e){let t=wn.getPrimitive(),n=super.shapecast({...e,intersectsPrimitive:e.intersectsTriangle,scratchPrimitive:t,iterate:this.indirect?X0:V0});return wn.releasePrimitive(t),n}bvhcast(e,t,n){let{intersectsRanges:s,intersectsTriangles:r}=n,o=wn.getPrimitive(),a=this.geometry.index,c=this.geometry.attributes.position,l=this.indirect?m=>{let x=this.resolveTriangleIndex(m);Ct(o,x*3,a,c)}:m=>{Ct(o,m*3,a,c)},u=wn.getPrimitive(),h=e.geometry.index,f=e.geometry.attributes.position,d=e.indirect?m=>{let x=e.resolveTriangleIndex(m);Ct(u,x*3,h,f)}:m=>{Ct(u,m*3,h,f)};if(r){if(!(e instanceof i))throw new Error('MeshBVH: "intersectsTriangles" callback can only be used with another MeshBVH.');let m=(x,g,p,v,b,_,S,M)=>{for(let E=p,y=p+v;E<y;E++){d(E),u.a.applyMatrix4(t),u.b.applyMatrix4(t),u.c.applyMatrix4(t),u.needsUpdate=!0;for(let w=x,A=x+g;w<A;w++)if(l(w),o.needsUpdate=!0,r(o,u,w,E,b,_,S,M))return!0}return!1};if(s){let x=s;s=function(g,p,v,b,_,S,M,E){return x(g,p,v,b,_,S,M,E)?!0:m(g,p,v,b,_,S,M,E)}}else s=m}return super.bvhcast(e,t,{intersectsRanges:s})}intersectsBox(e,t){return Qu.set(e.min,e.max,t),Qu.needsUpdate=!0,this.shapecast({intersectsBounds:n=>Qu.intersectsBox(n),intersectsTriangle:n=>Qu.intersectsTriangle(n)})}intersectsSphere(e){return this.shapecast({intersectsBounds:t=>e.intersectsBox(t),intersectsTriangle:t=>t.intersectsSphere(e)})}closestPointToGeometry(e,t,n={},s={},r=0,o=1/0){return(this.indirect?nx:J0)(this,e,t,n,s,r,o)}closestPointToPoint(e,t={},n=0,s=1/0){return N0(this,e,t,n,s)}};var nr=new I,ir=new I,sr=new I,ox=new ut,nh=new I,hp=new I,ax=new ut,cx=new ut,ih=new Ie,lx=new Ie;function nc(i,e){if(!i&&!e)return;let t=i.count===e.count,n=i.normalized===e.normalized,s=i.array.constructor===e.array.constructor,r=i.itemSize===e.itemSize;if(!t||!n||!s||!r)throw new Error}function ic(i,e=null){let t=i.array.constructor,n=i.normalized,s=i.itemSize,r=e===null?i.count:e;return new Tt(new t(s*r),s,n)}function hx(i,e,t=0){if(i.isInterleavedBufferAttribute){let n=i.itemSize;for(let s=0,r=i.count;s<r;s++){let o=s+t;e.setX(o,i.getX(s)),n>=2&&e.setY(o,i.getY(s)),n>=3&&e.setZ(o,i.getZ(s)),n>=4&&e.setW(o,i.getW(s))}}else{let n=e.array,s=n.constructor,r=n.BYTES_PER_ELEMENT*i.itemSize*t;new s(n.buffer,r,i.array.length).set(i.array)}}function nw(i,e,t){let n=i.elements,s=e.elements;for(let r=0,o=s.length;r<o;r++)n[r]+=s[r]*t}function ux(i,e,t){let n=i.skeleton,s=i.geometry,r=n.bones,o=n.boneInverses;ax.fromBufferAttribute(s.attributes.skinIndex,e),cx.fromBufferAttribute(s.attributes.skinWeight,e),ih.elements.fill(0);for(let a=0;a<4;a++){let c=cx.getComponent(a);if(c!==0){let l=ax.getComponent(a);lx.multiplyMatrices(r[l].matrixWorld,o[l]),nw(ih,lx,c)}}return ih.multiply(i.bindMatrix).premultiply(i.bindMatrixInverse),t.transformDirection(ih),t}function fp(i,e,t,n,s){nh.set(0,0,0);for(let r=0,o=i.length;r<o;r++){let a=e[r],c=i[r];a!==0&&(hp.fromBufferAttribute(c,n),t?nh.addScaledVector(hp,a):nh.addScaledVector(hp.sub(s),a))}s.add(nh)}function iw(i,e={useGroups:!1,updateIndex:!1,skipAttributes:[]},t=new ht){let n=i[0].index!==null,{useGroups:s=!1,updateIndex:r=!1,skipAttributes:o=[]}=e,a=new Set(Object.keys(i[0].attributes)),c={},l=0;t.clearGroups();for(let u=0;u<i.length;++u){let h=i[u],f=0;if(n!==(h.index!==null))throw new Error("StaticGeometryGenerator: All geometries must have compatible attributes; make sure index attribute exists among all geometries, or in none of them.");for(let d in h.attributes){if(!a.has(d))throw new Error('StaticGeometryGenerator: All geometries must have compatible attributes; make sure "'+d+'" attribute exists among all geometries, or in none of them.');c[d]===void 0&&(c[d]=[]),c[d].push(h.attributes[d]),f++}if(f!==a.size)throw new Error("StaticGeometryGenerator: Make sure all geometries have the same number of attributes.");if(s){let d;if(n)d=h.index.count;else if(h.attributes.position!==void 0)d=h.attributes.position.count;else throw new Error("StaticGeometryGenerator: The geometry must have either an index or a position attribute");t.addGroup(l,d,u),l+=d}}if(n){let u=!1;if(!t.index){let h=0;for(let f=0;f<i.length;++f)h+=i[f].index.count;t.setIndex(new Tt(new Uint32Array(h),1,!1)),u=!0}if(r||u){let h=t.index,f=0,d=0;for(let m=0;m<i.length;++m){let x=i[m],g=x.index;if(o[m]!==!0)for(let p=0;p<g.count;++p)h.setX(f,g.getX(p)+d),f++;d+=x.attributes.position.count}}}for(let u in c){let h=c[u];if(!(u in t.attributes)){let m=0;for(let x in h)m+=h[x].count;t.setAttribute(u,ic(c[u][0],m))}let f=t.attributes[u],d=0;for(let m=0,x=h.length;m<x;m++){let g=h[m];o[m]!==!0&&hx(g,f,d),d+=g.count}}return t}function sw(i,e){if(i===null||e===null)return i===e;if(i.length!==e.length)return!1;for(let t=0,n=i.length;t<n;t++)if(i[t]!==e[t])return!1;return!0}function rw(i){let{index:e,attributes:t}=i;if(e)for(let n=0,s=e.count;n<s;n+=3){let r=e.getX(n),o=e.getX(n+2);e.setX(n,o),e.setX(n+2,r)}else for(let n in t){let s=t[n],r=s.itemSize;for(let o=0,a=s.count;o<a;o+=3)for(let c=0;c<r;c++){let l=s.getComponent(o,c),u=s.getComponent(o+2,c);s.setComponent(o,c,u),s.setComponent(o+2,c,l)}}return i}var dp=class{constructor(e){this.matrixWorld=new Ie,this.geometryHash=null,this.boneMatrices=null,this.primitiveCount=-1,this.mesh=e,this.update()}update(){let e=this.mesh,t=e.geometry,n=e.skeleton,s=(t.index?t.index.count:t.attributes.position.count)/3;if(this.matrixWorld.copy(e.matrixWorld),this.geometryHash=t.attributes.position.version,this.primitiveCount=s,n){n.boneTexture||n.computeBoneTexture(),n.update();let r=n.boneMatrices;!this.boneMatrices||this.boneMatrices.length!==r.length?this.boneMatrices=r.slice():this.boneMatrices.set(r)}else this.boneMatrices=null}didChange(){let e=this.mesh,t=e.geometry,n=(t.index?t.index.count:t.attributes.position.count)/3;return!(this.matrixWorld.equals(e.matrixWorld)&&this.geometryHash===t.attributes.position.version&&sw(e.skeleton&&e.skeleton.boneMatrices||null,this.boneMatrices)&&this.primitiveCount===n)}},sh=class{constructor(e){Array.isArray(e)||(e=[e]);let t=[];e.forEach(n=>{n.traverseVisible(s=>{s.isMesh&&t.push(s)})}),this.meshes=t,this.useGroups=!0,this.applyWorldTransforms=!0,this.attributes=["position","normal","color","tangent","uv","uv2"],this._intermediateGeometry=new Array(t.length).fill().map(()=>new ht),this._diffMap=new WeakMap}getMaterials(){let e=[];return this.meshes.forEach(t=>{Array.isArray(t.material)?e.push(...t.material):e.push(t.material)}),e}generate(e=new ht){let t=[],{meshes:n,useGroups:s,_intermediateGeometry:r,_diffMap:o}=this;for(let a=0,c=n.length;a<c;a++){let l=n[a],u=r[a],h=o.get(l);!h||h.didChange(l)?(this._convertToStaticGeometry(l,u),t.push(!1),h?h.update():o.set(l,new dp(l))):t.push(!0)}if(r.length===0){e.setIndex(null);let a=e.attributes;for(let c in a)e.deleteAttribute(c);for(let c in this.attributes)e.setAttribute(this.attributes[c],new Tt(new Float32Array(0),4,!1))}else iw(r,{useGroups:s,skipAttributes:t},e);for(let a in e.attributes)e.attributes[a].needsUpdate=!0;return e}_convertToStaticGeometry(e,t=new ht){let n=e.geometry,s=this.applyWorldTransforms,r=this.attributes.includes("normal"),o=this.attributes.includes("tangent"),a=n.attributes,c=t.attributes;!t.index&&n.index&&(t.index=n.index.clone()),c.position||t.setAttribute("position",ic(a.position)),r&&!c.normal&&a.normal&&t.setAttribute("normal",ic(a.normal)),o&&!c.tangent&&a.tangent&&t.setAttribute("tangent",ic(a.tangent)),nc(n.index,t.index),nc(a.position,c.position),r&&nc(a.normal,c.normal),o&&nc(a.tangent,c.tangent);let l=a.position,u=r?a.normal:null,h=o?a.tangent:null,f=n.morphAttributes.position,d=n.morphAttributes.normal,m=n.morphAttributes.tangent,x=n.morphTargetsRelative,g=e.morphTargetInfluences,p=new Ye;p.getNormalMatrix(e.matrixWorld),n.index&&t.index.array.set(n.index.array);for(let v=0,b=a.position.count;v<b;v++)nr.fromBufferAttribute(l,v),u&&ir.fromBufferAttribute(u,v),h&&(ox.fromBufferAttribute(h,v),sr.fromBufferAttribute(h,v)),g&&(f&&fp(f,g,x,v,nr),d&&fp(d,g,x,v,ir),m&&fp(m,g,x,v,sr)),e.isSkinnedMesh&&(e.applyBoneTransform(v,nr),u&&ux(e,v,ir),h&&ux(e,v,sr)),s&&nr.applyMatrix4(e.matrixWorld),c.position.setXYZ(v,nr.x,nr.y,nr.z),u&&(s&&ir.applyNormalMatrix(p),c.normal.setXYZ(v,ir.x,ir.y,ir.z)),h&&(s&&sr.transformDirection(e.matrixWorld),c.tangent.setXYZW(v,sr.x,sr.y,sr.z,ox.w));for(let v in this.attributes){let b=this.attributes[v];b==="position"||b==="tangent"||b==="normal"||!(b in a)||(c[b]||t.setAttribute(b,ic(a[b])),nc(a[b],c[b]),hx(a[b],c[b]))}return e.matrixWorld.determinant()<0&&rw(t),t}};var sc=(i,e)=>new Ke(new I(...i),new I(...e)),fx={bus:[sc([-1.38,-1.28,-4.16],[1.38,1.87,4.16])],car:[sc([-1.16,-.79,-2.08],[1.16,1.08,2.08])],plane:[sc([-.78,-.95,-4.48],[.78,1.02,3.1]),sc([-5.6,-1.28,-.98],[5.6,1.28,.98]),sc([-2.1,-.8,1.85],[2.1,1.85,3.3])]};function rc(i){let e=[],t=new Set;for(let l of i)l.traverse(u=>{u.isMesh&&!t.has(u.uuid)&&(e.push(u),t.add(u.uuid))});let n=new sh(e);n.attributes=["position"],n.useGroups=!1,n.applyWorldTransforms=!0;let s=n.generate(),r=new th(s,{targetLeafSize:12}),o=new Ie;return{collides:(l,u,h=0)=>(o.makeRotationY(h),o.setPosition(l.x,l.y,l.z),(fx[u]??fx.car).some(f=>r.intersectsBox(f,o))),cameraDistance:(l,u,h)=>{let f=r.raycastFirst(new Pn(l,u),Dt);return f&&f.distance<h?Math.max(2,f.distance-.8):h},triangleCount:s.index?s.index.count/3:s.attributes.position.count/3,dispose:()=>s.dispose()}}var dx=(i,e,t)=>Math.max(e,Math.min(t,i));function px(i,e,t,n=!1){let s=i/t,r=n?0:e/t,o=Math.hypot(s,r);return o<.12?{x:0,y:0}:(o>1&&(s/=o,r/=o),{x:s,y:r})}var rh=class{constructor(){this.values={left:{x:0,y:0},right:{x:0,y:0}},this.pointers=new Map}begin(e,t){return this.pointers.has(t)||[...this.pointers.values()].includes(e)?!1:(this.pointers.set(t,e),!0)}move(e,t,n){let s=this.pointers.get(e);return s?(this.values[s]={x:dx(t,-1,1),y:dx(n,-1,1)},!0):!1}release(e){let t=this.pointers.get(e);t&&(this.values[t]={x:0,y:0}),this.pointers.delete(e)}clear(){this.pointers.clear(),this.values={left:{x:0,y:0},right:{x:0,y:0}}}axes(e){return{throttle:-this.values.left.y||0,steer:-this.values.right.x||0,lift:["car","bus"].includes(e)?0:-this.values.right.y||0}}};function mx(i,{mode:e,enabled:t,signal:n}){let s=[...document.querySelectorAll("[data-stick]")],r={signal:n},o=new Map,a=()=>s.forEach(l=>{let u=i.values[l.dataset.stick],h=l.clientWidth*.28;l.querySelector(".knob").style.transform=`translate(${u.x*h}px,${u.y*h}px)`,l.classList.toggle("active",Math.hypot(u.x,u.y)>.01)}),c=(l,u)=>{i.pointers.get(u)===l.dataset.stick&&(i.release(u),l.hasPointerCapture(u)&&l.releasePointerCapture(u),a())};for(let l of s){let u=h=>{if(i.pointers.get(h.pointerId)!==l.dataset.stick)return;h.preventDefault(),h.stopPropagation();let f=l.getBoundingClientRect(),d=px(h.clientX-(f.left+f.width/2),h.clientY-(f.top+f.height/2),f.width*.3,l.dataset.stick==="left"||["car","bus"].includes(e()));if(l.dataset.stick==="left"){let m=px(0,h.clientY-(f.top+f.height/2),f.height*.3);d.x=0,d.y=m.y}i.move(h.pointerId,d.x,d.y),a()};l.addEventListener("pointerdown",h=>{if(h.preventDefault(),h.stopPropagation(),!(!t()||!i.begin(l.dataset.stick,h.pointerId))){try{l.setPointerCapture(h.pointerId)}catch{}u(h)}},r),o.set(l.dataset.stick,u),["pointerup","pointercancel","lostpointercapture"].forEach(h=>l.addEventListener(h,f=>c(l,f.pointerId),r))}window.addEventListener("pointermove",l=>o.get(i.pointers.get(l.pointerId))?.(l),{signal:n,capture:!0});for(let l of["pointerup","pointercancel"])window.addEventListener(l,u=>{let h=i.pointers.get(u.pointerId);h&&(u.preventDefault(),u.stopPropagation(),c(s.find(f=>f.dataset.stick===h),u.pointerId))},{signal:n,capture:!0});return()=>{for(let l of s)for(let[u,h]of i.pointers)h===l.dataset.stick&&l.hasPointerCapture(u)&&l.releasePointerCapture(u);i.clear(),a()}}function gx(i,e,t){let n=(e-i.x)/i.step,s=(t-i.z)/i.step;if(n<0||s<0||n>i.nx-1||s>i.nz-1)return{terrainEstimated:!0,sourceMasks:0,terrainSourceLabel:"\u7BC4\u56F2\u5916"};let r=Math.min(Math.floor(n),i.nx-2),o=Math.min(Math.floor(s),i.nz-2),a=n-r,c=s-o,l=[o*i.nx+r,o*i.nx+r+1,(o+1)*i.nx+r,(o+1)*i.nx+r+1],u=[(1-a)*(1-c),a*(1-c),(1-a)*c,a*c],h=!1,f=0;l.forEach((m,x)=>{u[x]<=1e-10||(i.known[m]||(h=!0),f|=i.sampleSources?.[m]??(i.known[m]?1:0))});let d=[];return f&1&&d.push("DEM5A"),f&2&&d.push("DEM5B"),f&4&&d.push("DEM10B"),{terrainEstimated:h,sourceMasks:f,terrainSourceLabel:h?"\u88DC\u9593\u542B\u3080":d.join("+")||"\u88DC\u9593",sourceDerivedPercent:i.sourceDerivedPercent,interpolatedPercent:i.interpolatedPercent}}var oc=class i extends it{constructor(){let e=i.SkyShader,t=new ln({name:e.name,uniforms:mu.clone(e.uniforms),vertexShader:e.vertexShader,fragmentShader:e.fragmentShader,side:jt,depthWrite:!1});super(new In(1,1,1),t),this.isSky=!0}};oc.SkyShader={name:"SkyShader",uniforms:{turbidity:{value:2},rayleigh:{value:1},mieCoefficient:{value:.005},mieDirectionalG:{value:.8},sunPosition:{value:new I},cloudScale:{value:2e-4},cloudSpeed:{value:2e-5},cloudCoverage:{value:.4},cloudDensity:{value:.4},cloudElevation:{value:.5},showSunDisc:{value:1},time:{value:0}},vertexShader:`
		uniform vec3 sunPosition;
		uniform float rayleigh;
		uniform float turbidity;
		uniform float mieCoefficient;

		varying vec3 vWorldPosition;
		varying vec3 vSunDirection;
		varying float vSunfade;
		varying vec3 vBetaR;
		varying vec3 vBetaM;
		varying float vSunE;

		// constants for atmospheric scattering
		const float e = 2.71828182845904523536028747135266249775724709369995957;
		const float pi = 3.141592653589793238462643383279502884197169;

		// wavelength of used primaries, according to preetham
		const vec3 lambda = vec3( 680E-9, 550E-9, 450E-9 );
		// this pre-calculation replaces older TotalRayleigh(vec3 lambda) function:
		// (8.0 * pow(pi, 3.0) * pow(pow(n, 2.0) - 1.0, 2.0) * (6.0 + 3.0 * pn)) / (3.0 * N * pow(lambda, vec3(4.0)) * (6.0 - 7.0 * pn))
		const vec3 totalRayleigh = vec3( 5.804542996261093E-6, 1.3562911419845635E-5, 3.0265902468824876E-5 );

		// mie stuff
		// K coefficient for the primaries
		const float v = 4.0;
		const vec3 K = vec3( 0.686, 0.678, 0.666 );
		// MieConst = pi * pow( ( 2.0 * pi ) / lambda, vec3( v - 2.0 ) ) * K
		const vec3 MieConst = vec3( 1.8399918514433978E14, 2.7798023919660528E14, 4.0790479543861094E14 );

		// earth shadow hack
		// cutoffAngle = pi / 1.95;
		const float cutoffAngle = 1.6110731556870734;
		const float steepness = 1.5;
		const float EE = 1000.0;

		float sunIntensity( float zenithAngleCos ) {
			zenithAngleCos = clamp( zenithAngleCos, -1.0, 1.0 );
			return EE * max( 0.0, 1.0 - pow( e, -( ( cutoffAngle - acos( zenithAngleCos ) ) / steepness ) ) );
		}

		vec3 totalMie( float T ) {
			float c = ( 0.2 * T ) * 10E-18;
			return 0.434 * c * MieConst;
		}

		void main() {

			vec4 worldPosition = modelMatrix * vec4( position, 1.0 );
			vWorldPosition = worldPosition.xyz;

			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
			gl_Position.z = gl_Position.w; // set z to camera.far

			vSunDirection = normalize( sunPosition );

			vSunE = sunIntensity( vSunDirection.y );

			vSunfade = 1.0 - clamp( 1.0 - exp( ( sunPosition.y / 450000.0 ) ), 0.0, 1.0 );

			float rayleighCoefficient = rayleigh - ( 1.0 * ( 1.0 - vSunfade ) );

			// extinction (absorption + out scattering)
			// rayleigh coefficients
			vBetaR = totalRayleigh * rayleighCoefficient;

			// mie coefficients
			vBetaM = totalMie( turbidity ) * mieCoefficient;

		}`,fragmentShader:`
		varying vec3 vWorldPosition;
		varying vec3 vSunDirection;
		varying vec3 vBetaR;
		varying vec3 vBetaM;
		varying float vSunE;

		uniform float mieDirectionalG;
		uniform float cloudScale;
		uniform float cloudSpeed;
		uniform float cloudCoverage;
		uniform float cloudDensity;
		uniform float cloudElevation;
		uniform float showSunDisc;
		uniform float time;

		// gradient at a lattice corner; sinless hash so every GPU produces the same clouds
		vec2 gradient( vec2 i ) {
			vec3 p = fract( i.xyx * vec3( 0.1031, 0.1030, 0.0973 ) );
			p += dot( p, p.yzx + 33.33 );
			return fract( ( p.xx + p.yz ) * p.zy ) * 2.0 - 1.0;
		}

		// 2D gradient noise: isotropic lobes like Perlin at value-noise cost
		float noise( vec2 p ) {
			vec2 i = floor( p );
			vec2 f = fract( p );
			vec2 u = f * f * f * ( f * ( f * 6.0 - 15.0 ) + 10.0 ); // quintic fade
			float a = dot( gradient( i ), f );
			float b = dot( gradient( i + vec2( 1.0, 0.0 ) ), f - vec2( 1.0, 0.0 ) );
			float c = dot( gradient( i + vec2( 0.0, 1.0 ) ), f - vec2( 0.0, 1.0 ) );
			float d = dot( gradient( i + vec2( 1.0, 1.0 ) ), f - vec2( 1.0, 1.0 ) );
			return mix( mix( a, b, u.x ), mix( c, d, u.x ), u.y ) * 1.6; // ~[-1,1]
		}

		// fbm; per-octave drift makes clouds billow instead of scrolling as a rigid stamp
		float fbm( vec2 p, float drift ) {
			float result = 0.0;
			float amplitude = 1.0;
			for ( int i = 0; i < 4; i ++ ) {
				result += amplitude * noise( p );
				amplitude *= 0.5;
				p = p * 2.0 + drift;
			}
			return result;
		}

		// constants for atmospheric scattering
		const float pi = 3.141592653589793238462643383279502884197169;

		const float n = 1.0003; // refractive index of air
		const float N = 2.545E25; // number of molecules per unit volume for air at 288.15K and 1013mb (sea level -45 celsius)

		// optical length at zenith for molecules
		const float rayleighZenithLength = 8.4E3;
		const float mieZenithLength = 1.25E3;
		// 66 arc seconds -> degrees, and the cosine of that
		const float sunAngularDiameterCos = 0.999956676946448443553574619906976478926848692873900859324;

		// 3.0 / ( 16.0 * pi )
		const float THREE_OVER_SIXTEENPI = 0.05968310365946075;
		// 1.0 / ( 4.0 * pi )
		const float ONE_OVER_FOURPI = 0.07957747154594767;

		float rayleighPhase( float cosTheta ) {
			return THREE_OVER_SIXTEENPI * ( 1.0 + pow( cosTheta, 2.0 ) );
		}

		float hgPhase( float cosTheta, float g ) {
			float g2 = pow( g, 2.0 );
			float inverse = 1.0 / pow( 1.0 - 2.0 * g * cosTheta + g2, 1.5 );
			return ONE_OVER_FOURPI * ( ( 1.0 - g2 ) * inverse );
		}

		void main() {

			vec3 direction = normalize( vWorldPosition - cameraPosition );

			// optical length
			// cutoff angle at 90 to avoid singularity in next formula.
			float zenithAngle = acos( max( 0.0, direction.y ) );
			float inverse = 1.0 / ( cos( zenithAngle ) + 0.15 * pow( 93.885 - ( ( zenithAngle * 180.0 ) / pi ), -1.253 ) );
			float sR = rayleighZenithLength * inverse;
			float sM = mieZenithLength * inverse;

			// combined extinction factor
			vec3 Fex = exp( -( vBetaR * sR + vBetaM * sM ) );

			// in scattering
			float cosTheta = dot( direction, vSunDirection );

			float rPhase = rayleighPhase( cosTheta * 0.5 + 0.5 );
			vec3 betaRTheta = vBetaR * rPhase;

			float mPhase = hgPhase( cosTheta, mieDirectionalG );
			vec3 betaMTheta = vBetaM * mPhase;

			vec3 Lin = pow( vSunE * ( ( betaRTheta + betaMTheta ) / ( vBetaR + vBetaM ) ) * ( 1.0 - Fex ), vec3( 1.5 ) );
			Lin *= mix( vec3( 1.0 ), pow( vSunE * ( ( betaRTheta + betaMTheta ) / ( vBetaR + vBetaM ) ) * Fex, vec3( 1.0 / 2.0 ) ), clamp( pow( 1.0 - vSunDirection.y, 5.0 ), 0.0, 1.0 ) );

			// nightsky
			float theta = acos( direction.y ); // elevation --> y-axis, [-pi/2, pi/2]
			float phi = atan( direction.z, direction.x ); // azimuth --> x-axis [-pi/2, pi/2]
			vec2 uv = vec2( phi, theta ) / vec2( 2.0 * pi, pi ) + vec2( 0.5, 0.0 );
			vec3 L0 = vec3( 0.1 ) * Fex;

			// composition + solar disc
			float sundisc = clamp( ( cosTheta - sunAngularDiameterCos ) * 50000.0, 0.0, 1.0 ) * showSunDisc;
			vec3 sundiscColor = ( 760.0 * sundisc ) * min( vSunE * Fex, 80.0 );

			vec3 texColor = ( Lin + L0 ) * 0.04 + sundiscColor + vec3( 0.0, 0.0003, 0.00075 );

			// Clouds
			if ( direction.y > 0.0 && cloudCoverage > 0.0 ) {

				// Project to cloud plane (higher elevation = clouds appear lower/closer)
				float elevation = mix( 1.0, 0.1, cloudElevation );
				vec2 cloudUV = direction.xz / ( direction.y * elevation );
				cloudUV *= cloudScale;
				cloudUV += time * cloudSpeed;

				// Cloud density field
				float evolve = time * cloudSpeed * 300.0;
				float cloudNoise = clamp( fbm( cloudUV * 1000.0, evolve ) * 0.7 + 0.5, 0.0, 1.0 );

				// Large-scale coverage variation: clear gaps next to dense banks
				float region = noise( cloudUV * 300.0 ) * 0.37 + 0.5;
				float cov = clamp( cloudCoverage + ( region - 0.5 ) * 0.6, 0.0, 1.0 );

				// Carve clouds where noise rises above the coverage level
				float threshold = 1.0 - cov;
				float cloudMask = smoothstep( threshold, threshold + 0.3, cloudNoise );

				// Fade clouds near horizon (adjusted by elevation)
				float horizonFade = smoothstep( 0.0, 0.03 + 0.06 * cloudElevation, direction.y );
				cloudMask *= horizonFade;

				// Cloud lighting from the sky's own radiance
				float dayFactor = smoothstep( -0.08, 0.3, vSunDirection.y );
				vec3 sunColor = vSunE * Fex * 0.22 * 0.04; // 0.22 ~ albedo/pi, 0.04 = exposure; the aerial composite adds the eye-leg extinction
				vec3 skyAmbient = Lin * 0.04 + vec3( 0.0, 0.0003, 0.00075 );

				// Beer-powder self-shadow from the sampled density
				float depth = max( 0.0, cloudNoise - threshold );
				float beer = exp( depth * -4.0 );
				float powder = 1.0 - beer * beer; // beer*beer == exp(-8*depth)
				float shade = mix( 0.45, 1.0, clamp( beer * powder * 2.6, 0.0, 1.0 ) ); // 2.6 = 1/0.385, normalizes beer*powder peak to 1

				// Henyey-Greenstein forward lobe ( g = 0.7 ): silver lining on rims toward the sun
				float silver = clamp( 0.51 / pow( 1.49 - cosTheta * 1.4, 1.5 ), 0.0, 3.0 ); // 0.51=1-g^2, 1.49=1+g^2, 1.4=2g
				float edge = cloudMask * ( 1.0 - cloudMask ) * 4.0;

				vec3 cloudColor = skyAmbient + sunColor * shade;
				cloudColor += sunColor * silver * edge * 0.6;
				cloudColor *= max( dayFactor, 0.03 );

				// Cloud opacity via Beer's law: density sets how solid the clouds get
				float alpha = ( 1.0 - exp( depth * cloudDensity * -12.0 ) ) * horizonFade;

				// Occlude the sun disc/glow behind opaque cloud
				texColor -= L0 * 0.04 * alpha;

				// Composite through the atmosphere so distant clouds dissolve into haze
				vec3 cloudAerial = mix( texColor, cloudColor, Fex );
				texColor = mix( texColor, cloudAerial, alpha );

			}

			gl_FragColor = vec4( texColor, 1.0 );

			#include <tonemapping_fragment>
			#include <colorspace_fragment>

		}`};function xx(i,e){let t=new oc;t.scale.setScalar(45e4),t.material.uniforms.turbidity.value=3.5,t.material.uniforms.rayleigh.value=2,t.material.uniforms.mieCoefficient.value=.005,t.material.uniforms.mieDirectionalG.value=.8,t.material.uniforms.sunPosition.value.set(-.45,.75,.4).normalize();let n=new Bs;n.add(t);let s=new oo(i),r=s.fromScene(n,.05);e.environment=r.texture,e.environmentIntensity=.08,i.toneMappingExposure=.9,s.dispose(),t.geometry.dispose(),t.material.dispose(),i.shadowMap.enabled=!0,i.shadowMap.type=wl;let o=e.children.find(a=>a.isDirectionalLight);return o.castShadow=!0,o.shadow.mapSize.set(512,512),o.shadow.camera.left=o.shadow.camera.bottom=-140,o.shadow.camera.right=o.shadow.camera.top=140,o.shadow.camera.near=.5,o.shadow.camera.far=650,o.shadow.bias=-5e-4,o.shadow.normalBias=.3,e.add(o.target),o.intensity=2.5,e.children.find(a=>a.isHemisphereLight).intensity=1.6,{follow:a=>{o.position.set(a.x-150,a.y+250,a.z+100),o.target.position.set(a.x,a.y,a.z),o.target.updateMatrixWorld()},dispose:()=>{r.dispose(),o.shadow.map?.dispose()}}}function ac(i){i.traverse(e=>{if(!e.isMesh)return;e.receiveShadow=!0;let t=e,n=!1;for(;t;){if(t.userData.building_id||/^Building_|^Dorm_|^Campus_Annex/.test(t.name)){n=!0;break}t=t.parent}e.castShadow=n;for(let s of Array.isArray(e.material)?e.material:[e.material])s?.isMeshStandardMaterial&&(s.envMapIntensity=/glass|spandrel|solar/.test(s.name)?.85:.35,/glass/.test(s.name)&&(s.roughness=Math.min(s.roughness,.22)),s.needsUpdate=!0)})}var _x=i=>i.userData.building_id||/^(Building_|Campus_Annex_|Dorm_Common)/.test(i.name),ow=/^(Site_Base|Landscape_Ground|Campus_Ground|Landscape_Paving|Sports_Fields)$/,pp=i=>i?.traverse(e=>{e.geometry?.dispose();for(let t of Array.isArray(e.material)?e.material:[e.material])t?.map?.dispose(),t?.dispose()});function aw(i,e){let t=[];for(let s=1;s<i.length;s++){let r=i[s-1],o=i[s],a=o[0]-r[0],c=o[1]-r[1],l=Math.hypot(a,c);if(!l)continue;let u=-c/l*e/2,h=a/l*e/2,f=[r[0]+u,r[2],r[1]+h],d=[r[0]-u,r[2],r[1]-h],m=[o[0]+u,o[2],o[1]+h],x=[o[0]-u,o[2],o[1]-h];t.push(...f,...m,...d,...d,...m,...x)}let n=new ht;return n.setAttribute("position",new lt(t,3)),n.computeVertexNormals(),n}function cw(i){let e=new Map,t=new Map,n=new Map,s=[];for(let r of i.roads){r.points.forEach((o,a)=>{e.set(r.nodes[a],o),t.has(r.nodes[a])||t.set(r.nodes[a],[])});for(let o=1;o<r.nodes.length;o++){let a=r.nodes[o-1],c=r.nodes[o],l=Math.hypot(r.points[o][0]-r.points[o-1][0],r.points[o][1]-r.points[o-1][1]);t.get(a).push([c,l]),t.get(c).push([a,l])}if(r.tags.bridge==="yes"||r.tags.bridge==="viaduct"){let o=Math.max(3,4.5*Math.max(1,Number(r.tags.layer)||1));r.nodes.forEach(a=>{n.set(a,Math.max(n.get(a)||0,o)),s.push(a)})}}for(let r=0;r<s.length;r++){let o=s[r],a=n.get(o);for(let[c,l]of t.get(o)??[]){let u=a-l*.075;u>0&&u>(n.get(c)||0)+.001&&(n.set(c,u),s.push(c))}}for(let r of i.roads){let o=r.points,a=[];for(let l=1;l<o.length;l++){let u=o[l-1],h=o[l],f=Math.max(1,Math.ceil(Math.hypot(h[0]-u[0],h[1]-u[1])/8));for(let d=0;d<f;d++){let m=d/f,x=u[0]+(h[0]-u[0])*m,g=u[1]+(h[1]-u[1])*m,p=(n.get(r.nodes[l-1])||0)*(1-m)+(n.get(r.nodes[l])||0)*m;a.push([x,g,($s(i.terrain,x,g)??0)+.12+p])}}let c=o.at(-1);c&&a.push([c[0],c[1],($s(i.terrain,c[0],c[1])??0)+.12+(n.get(r.nodes.at(-1))||0)]),r.points=a}return i.roads}function yx(i,e,t){let n=[],s=[],r=[],o=e.min,a=e.max;for(let l=0;l<=t;l++)for(let u=0;u<=t;u++){let h=o[0]+(a[0]-o[0])*u/t,f=o[1]+(a[1]-o[1])*l/t;n.push(h,($s(i.terrain,h,f)??0)+(e.z===18?.025:.005),f),s.push(u/t,1-l/t)}for(let l=0;l<t;l++)for(let u=0;u<t;u++){let h=l*(t+1)+u,f=h+1,d=h+t+1,m=d+1;r.push(h,d,f,f,d,m)}let c=new ht;return c.setAttribute("position",new lt(n,3)),c.setAttribute("uv",new lt(s,2)),c.setIndex(r),c.computeVertexNormals(),c}function lw(i){let e=new Map,t=[],n=new $t({color:12367788,roughness:.9});for(let s of i.buildings){let r=s.points;if(r.length<4)continue;let o=r.reduce((h,f)=>h+f[0],0)/r.length,a=r.reduce((h,f)=>h+f[1],0)/r.length,c=new qr(r.map(h=>new ce(h[0]-o,-(h[1]-a)))),l=new xa(c,{depth:s.height,bevelEnabled:!1,steps:1});l.rotateX(-Math.PI/2),l.translate(o,$s(i.terrain,o,a)??0,a);let u=`${Math.floor(o/300)},${Math.floor(a/300)}`;e.has(u)||e.set(u,[]),e.get(u).push(l)}for(let[s,r]of e){let o=ad(r,!1);r.forEach(c=>c.dispose());let a=new it(o,n);a.castShadow=!0,a.userData.cell=s.split(",").map(Number),a.receiveShadow=!0,t.push(a)}return t}async function vx({scene:i,currentCampus:e,currentScene:t,currentWorld:n,currentMotion:s,camera:r,controls:o,signal:a,onProgress:c,isDisposed:l,preloadedCampuses:u=[]}){c("\u9053\u8DEF\u30FB\u5730\u5F62\u3092\u6E96\u5099\u4E2D\u2026");let h=await fetch("region.json",{signal:a});if(!h.ok)throw Error("Region asset unavailable");let f=await h.json();if(l())throw Error("Disposed");let d=new Bt;d.name="ConnectedRegion";let m=(z,j)=>$s(f.terrain,z,j),x=cw(f),g=new wu(x,f.terrain),p=lw(f);p.forEach(z=>d.add(z));let v=rc(p),b={road:new $t({color:4278091,roughness:.95,side:Dt}),private:new $t({color:7633008,roughness:.95,side:Dt}),walk:new $t({color:12169120,roughness:1,side:Dt})},_={road:[],private:[],walk:[]};for(let z of x){if(z.points.length<2)continue;let j=z.drive?z.private?"private":"road":z.highway.startsWith("motorway")?"road":"walk";_[j].push(aw(z.points,z.width))}for(let[z,j]of Object.entries(_)){if(!j.length)continue;let me=ad(j);j.forEach(de=>de.dispose());let fe=new it(me,b[z]);fe.receiveShadow=!0,d.add(fe)}let S={min:[f.terrain.x,f.terrain.z],max:[f.terrain.x+(f.terrain.nx-1)*f.terrain.step,f.terrain.z+(f.terrain.nz-1)*f.terrain.step],z:0},M=new it(yx(f,S,128),new $t({color:9279357,roughness:1,side:Dt}));M.receiveShadow=!0,d.add(M);let E=f.photos.map(z=>({photo:z,mesh:null,loading:!1,failed:!1,center:new I((z.min[0]+z.max[0])/2,0,(z.min[1]+z.max[1])/2)})),y=0,w=!0,A=new Hs,P=z=>{if(!(typeof document>"u"))for(let j of E){let me=Math.hypot(z.x-j.center.x,z.z-j.center.z),fe=j.photo.z===18?500:1600;if(j.mesh){j.mesh.visible=me<fe;continue}!w||j.failed||j.loading||me>fe||y>=3||(j.loading=!0,y++,A.load(`region/${j.photo.file}`,de=>{if(y--,!w){de.dispose();return}de.colorSpace=Ft,de.anisotropy=4;let et=new it(yx(f,j.photo,j.photo.z===18?12:24),new $t({map:de,roughness:1,side:Dt}));et.receiveShadow=!0,j.mesh=et,d.add(et)},void 0,()=>{y--,j.failed=!0}))}},C=new Map,D=!1,L=(f.gates??[]).filter(z=>z.motorcarNo||z.locked),U=new $t({color:12666429,roughness:.8});for(let z of L){let j=new it(new In(3,.18,.18),U);j.position.set(z.point[0],(m(...z.point)??0)+.75,z.point[1]),d.add(j)}function G(z,j){let me=f.campuses.find(ne=>ne.id===z),fe=me.offset;j.position.x=fe[0],j.position.z=fe[1],j.updateMatrixWorld(!0);for(let ne of j.children)if(_x(ne)){let F=new Ke().setFromObject(ne),V=F.getCenter(new I);ne.position.y+=m(V.x,V.z)??me.altitude??0}else ne.traverse(F=>{if(!F.isMesh)return;if(ow.test(ne.name)){F.visible=!1;return}let V=F.geometry.attributes.position;for(let q=0;q<V.count;q++)V.setY(q,V.getY(q)+(m(V.getX(q)+fe[0],V.getZ(q)+fe[1])??me.altitude??0));V.needsUpdate=!0,F.geometry.computeVertexNormals(),F.geometry.computeBoundingBox(),F.geometry.computeBoundingSphere()});j.updateMatrixWorld(!0);let de=j.children.filter(_x),et=rc(de);C.set(z,{root:j,collision:et,definition:me})}G(e,t);for(let z of u)i.add(z.scene),ac(z.scene),G(z.id,z.scene);let Z=f.campuses.find(z=>z.id===e),oe=Z.offset,K=new I(oe[0],0,oe[1]);r.position.add(K),o.target.add(K),s.position.x+=oe[0],s.position.z+=oe[1],s.position.y+=m(s.position.x,s.position.z)??Z.altitude??0;let te={x:n.carSpawn.x+oe[0],z:n.carSpawn.z+oe[1]};te.y=(m(te.x,te.z)??Z.altitude??0)+.8;let se=400,Re={min:{x:S.min[0],z:S.min[1]},max:{x:S.max[0],z:S.max[1]}},Te={x:oe[0],y:(Z.altitude??0)+140,z:oe[1]},nt=()=>[v,...[...C.values()].map(z=>z.collision)],He={carSpawn:te,carYaw:n.carYaw,planeSpawn:Te,groundBounds:Re,flightBounds:Re,groundBase:0,maxAltitude:se,buildings:n.buildings,collisionTriangles:v.triangleCount+C.get(e).collision.triangleCount,terrainHeight:(z,j,me=null,fe="car")=>{let de=m(z,j);return me==null||f.campuses.some(et=>s0(z,j,et.boundary))?de:g.surface(z,j,me,fe)?.height??null},meshCollision:(z,j,me)=>["car","bus"].includes(j)&&L.some(fe=>Math.hypot(z.x-fe.point[0],z.z-fe.point[1])<2.5)||nt().some(fe=>fe.collides(z,j,me)),cameraDistance:(z,j,me)=>nt().reduce((fe,de)=>Math.min(fe,de.cameraDistance(z,j,me)),me),disposeCollision:()=>{w=!1,nt().forEach(z=>z.dispose()),pp(d);for(let z of C.values())z.root!==t&&(i.remove(z.root),pp(z.root));i.remove(d)},update:z=>{P(z),p.forEach(j=>{let[me,fe]=j.userData.cell;j.visible=Math.hypot(z.x-(me+.5)*300,z.z-(fe+.5)*300)<1800});for(let j of C.values())j.root.visible=Math.hypot(z.x-j.definition.offset[0],z.z-j.definition.offset[1])<1400;if(!D&&C.size<2){let j=f.campuses.find(me=>me.id!==e);Math.hypot(z.x-j.offset[0],z.z-j.offset[1])<1e3&&(D=!0,c("\u5230\u7740\u5148\u306E\u5EFA\u7269\u3092\u8AAD\u307F\u8FBC\u307F\u4E2D\u2026"),new uo().loadAsync(j.id==="narashino"?"shinnarashino-campus.glb":"tsudanuma-campus.glb").then(me=>{if(!w){pp(me.scene);return}ac(me.scene),i.add(me.scene),G(j.id,me.scene),c("")}).catch(()=>{D=!1,c("\u5230\u7740\u5148\u30E2\u30C7\u30EB\u3092\u8AAD\u307F\u8FBC\u3081\u307E\u305B\u3093\u3067\u3057\u305F")}))}},description:z=>({...i0(z.x,z.z,f.origin),elevation:m(z.x,z.z),...gx(f.terrain,z.x,z.z),campusesLoaded:[...C.keys()],road:g.surface(z.x,z.z)?.road.name??""}),data:f,roadIndex:g,group:d},$e=new us({color:556238,transparent:!0,opacity:.9,depthTest:!1}),$;return He.setRoute=z=>{$&&(d.remove($),$.geometry.dispose());let j=f.routes.find(de=>de.id===z);if(!j)return;let me=j.points.flatMap(de=>[de[0],(g.surface(de[0],de[1])?.height??m(de[0],de[1])??0)+.35,de[1]]),fe=new ht;fe.setAttribute("position",new lt(me,3)),$=new zi(fe,$e),$.renderOrder=5,d.add($),He.selectedRoute=j},He.setRoute(e==="tsudanuma"?"outward":"return"),i.add(d),P(s.position),c(""),He}function Sx({isDisposed:i,isLoaded:e,getGame:t,isRegionLoading:n,enterRegion:s,closeOverlay:r,clock:o=()=>performance.now()}){let a=[];function c(u){if(i())return;if(typeof u=="string")try{u=JSON.parse(u)}catch{return}if(u?.type==="campus-close-overlay"){r();return}if(u?.type==="campus-game-session"&&!u.data||u?.type==="campus-game-leave"){a.length=0,t()?.gameOnline(u);return}let h=u?.type==="campus-game-session"?u.data:u?.session?.room??u?.session??u?.room,f=u?.challenge??(u?.action==="challenge"&&u?.ok?u.data:null),d=Array.isArray(h?.players)||!!f?.challengeId;!t()&&!d||(a.push({event:u,received:o()}),a.length>32&&a.shift(),l())}function l(){if(i()||!e()||!a.length)return;let u=t();if(!u){n()||s();return}for(let h of a.splice(0)){let f=structuredClone(h.event),d=o()-h.received;for(let m of[f?.data,f?.challenge,f?.session,f?.room])m&&Number.isFinite(m.serverNow)&&(m.serverNow+=d);u.gameOnline(f)}}return{receive:c,drain:l,clear(){a.length=0},get size(){return a.length}}}function bx({data:i,signal:e,onOpen:t=()=>{},onClose:n=()=>{}}){let s=document.querySelector("#quality-dialog"),r=document.querySelector("#quality-details"),o=document.querySelector("#quality-tiles"),a=document.querySelector("#quality-summary");r.hidden=!1;let c=i.terrain;a.textContent=`\u6A19\u9AD8\u306FDEM\u7531\u6765\u306E20m\u683C\u5B50\u3067\u3059\u3002\u5168\u4F53 DEM\u7531\u6765 ${Number(c.sourceDerivedPercent).toFixed(2)}% / \u88DC\u9593 ${Number(c.interpolatedPercent).toFixed(2)}%\u3002\u6E2C\u91CF\u7CBE\u5EA6\u3092\u793A\u3059\u3082\u306E\u3067\u306F\u3042\u308A\u307E\u305B\u3093\u3002`;let l=Array.isArray(c.coverageByTile)?c.coverageByTile:Object.entries(c.coverageByTile??{}).map(([h,f])=>({tile:h,...f}));for(let h of l){let f=document.createElement("tr"),d=h.tile??h.key??[h.z??14,h.x,h.y].join("/");for(let m of[d,`${Number(h.sourceDerivedPercent??(h.total?h.sourceDerived/h.total*100:0)).toFixed(2)}%`,`${Number(h.interpolatedPercent??(h.total?h.interpolated/h.total*100:0)).toFixed(2)}%`]){let x=document.createElement("td");x.textContent=String(m),f.append(x)}o.append(f)}let u=()=>{s.hasAttribute("open")&&(typeof s.close=="function"?s.close():(s.removeAttribute("open"),n()))};return s.addEventListener("close",n,{signal:e}),r.addEventListener("click",()=>{t(),typeof s.showModal=="function"?s.showModal():s.setAttribute("open","")},{signal:e}),document.querySelector("#quality-close").addEventListener("click",()=>{u(),r.focus()},{signal:e}),s.addEventListener("click",h=>{if(h.target===s){let f=s.getBoundingClientRect();(h.clientX<f.left||h.clientX>f.right||h.clientY<f.top||h.clientY>f.bottom)&&u()}},{signal:e}),u}var oh=class{constructor({limit:e=32,cadenceMs:t=750,maxAgeMs:n=22e3}={}){this.limit=e,this.cadenceMs=t,this.maxAgeMs=n,this.reset()}reset({baselineT:e=0,now:t=null}={}){this.samples=[],this.lastT=e,this.lastCapturedAt=t}clearPending(){this.samples=[]}capture(e,t,n,{force:s=!1,layerAware:r=!1}={}){if(this.lastCapturedAt!==null&&!s&&e-this.lastCapturedAt<this.cadenceMs)return!1;let o=Math.max(1,Math.round(e-t));if(o<=this.lastT)return!1;if(!Number.isFinite(o)||!Number.isFinite(n.x)||!Number.isFinite(n.z)||r&&!Number.isFinite(n.y))throw new Error("\u8D70\u884C\u4F4D\u7F6E\u3092\u78BA\u8A8D\u3067\u304D\u307E\u305B\u3093\u3002\u5FA9\u5E30\u3057\u3066\u304F\u3060\u3055\u3044\u3002");if(this.lastCapturedAt!==null&&e-this.lastCapturedAt>5e3)throw new Error("\u4F4D\u7F6E\u8A18\u9332\u306E\u9593\u9694\u304C\u7A7A\u304D\u307E\u3057\u305F\u3002\u5FA9\u5E30\u3057\u3066\u304F\u3060\u3055\u3044\u3002");if(this.samples.length>=this.limit)throw new Error("\u9001\u4FE1\u5F85\u3061\u306E\u8A18\u9332\u304C\u4E0A\u9650\u306B\u9054\u3057\u307E\u3057\u305F\u3002\u5FA9\u5E30\u3057\u3066\u304F\u3060\u3055\u3044\u3002");return this.samples.push({t:o,x:n.x,z:n.z,...r?{y:n.y}:{},capturedAt:e}),this.lastT=o,this.lastCapturedAt=e,!0}take(e){if(this.samples.length&&e-this.samples[0].capturedAt>this.maxAgeMs)throw new Error("\u9001\u4FE1\u5F85\u3061\u306E\u8A18\u9332\u304C\u53E4\u304F\u306A\u308A\u307E\u3057\u305F\u3002\u5FA9\u5E30\u3057\u3066\u304F\u3060\u3055\u3044\u3002");return this.samples.splice(0,32).map(({capturedAt:t,...n})=>n)}get size(){return this.samples.length}};function mp(i){let e=[],t=[],n=i.points;if(!Array.isArray(n)||n.length<2)throw new Error("Invalid course");let s=0;for(let a=1;a<n.length;a++){let c=n[a-1],l=n[a],u=Math.hypot(l[0]-c[0],l[1]-c[1]);u&&(e.push({a:c,b:l,start:s,end:s+u}),s+=u)}if(!e.length)throw new Error("Empty course");let r=a=>{let c=e.find(u=>u.end>=a)??e.at(-1),l=Math.max(0,Math.min(1,(a-c.start)/(c.end-c.start)));return{x:c.a[0]+(c.b[0]-c.a[0])*l,z:c.a[1]+(c.b[1]-c.a[1])*l,y:(c.a[2]??0)+((c.b[2]??0)-(c.a[2]??0))*l,progress:a}};for(let a=150;a<s-25;a+=150)t.push(r(a));t.push(r(s));let o=2166136261;for(let a of JSON.stringify(n.map(c=>c.map(l=>Math.round(l*100)))))o^=a.charCodeAt(0),o=Math.imul(o,16777619);return{id:i.id,length:s,segments:e,checkpoints:t,start:r(0),goal:r(s),family:i.family??"campus",corridor:i.corridor??7,layerAware:i.layerAware??!1,pointAt:r,key:i.key??`cit_bus_best_v1_${i.id}_${(o>>>0).toString(16).padStart(8,"0")}`}}var ah=class{constructor({clock:e=()=>performance.now(),onFinish:t=()=>{}}={}){this.clock=e,this.onFinish=t,this.phase="idle",this.reason="",this.course=null,this.elapsed=0,this.nextCheckpoint=0,this.progress=0,this.lastTime=null,this.lastPosition=null,this.penaltyMs=0}arm(e,t,n=this.clock()+3e3){this.course=e,this.phase="countdown",this.reason="",this.elapsed=0,this.nextCheckpoint=0,this.progress=0,this.penaltyMs=0,this.startTime=n,this.lastTime=this.clock(),this.lastPosition={...t}}cancel(e="\u4E2D\u65AD"){(this.phase==="countdown"||this.phase==="running")&&(this.phase="invalid",this.reason=e)}get countdown(){return this.phase==="countdown"?Math.max(1,Math.ceil((this.startTime-this.clock())/1e3)):0}tick(e,{mode:t="bus",onCourse:n=!0,foreground:s=!0}={}){if(!["countdown","running"].includes(this.phase))return;let r=this.clock();if(!Number.isFinite(r)||r<this.lastTime){this.cancel("\u6642\u8A08\u304C\u5909\u66F4\u3055\u308C\u307E\u3057\u305F");return}if(t!=="bus"&&!(this.course.family==="pop"&&t==="car")||!s){this.cancel("\u8D70\u884C\u304C\u4E2D\u65AD\u3055\u308C\u307E\u3057\u305F");return}let o=Math.hypot(e.x-this.lastPosition.x,e.z-this.lastPosition.z),a=Math.abs(e.y-this.lastPosition.y),c=r-this.lastTime;if(this.phase==="countdown"){if(o>.1||a>.1){this.cancel("\u30B9\u30BF\u30FC\u30C8\u524D\u306B\u79FB\u52D5\u3057\u307E\u3057\u305F");return}if(r<this.startTime){this.lastTime=r;return}this.phase="running",this.lastTime=this.startTime}if(r-this.startTime>36e5){this.cancel("\u5236\u9650\u6642\u9593\uFF0860\u5206\uFF09\u3092\u8D85\u3048\u307E\u3057\u305F");return}if(r-this.lastTime>1500){this.cancel("\u51E6\u7406\u304C\u9577\u304F\u6B62\u307E\u308A\u307E\u3057\u305F");return}if(o>22*Math.max(c,0)/1e3+.8||a>4+8*Math.max(c,0)/1e3){this.cancel("\u4F4D\u7F6E\u304C\u98DB\u3073\u307E\u3057\u305F");return}if(!n){this.cancel("\u30B3\u30FC\u30B9\u5916\u3078\u51FA\u307E\u3057\u305F");return}let l=o*1.5+6,u=null;for(let f of this.course.segments){if(f.end<this.progress-35||f.start>this.progress+l+25)continue;let d=Ha(e.x,e.z,f.a,f.b);if(this.course.layerAware&&Math.abs(e.y-1.4-((f.a[2]??0)+((f.b[2]??0)-(f.a[2]??0))*d.t))>5)continue;let m=f.start+(f.end-f.start)*d.t;(!u||d.distance<u.distance)&&(u={...d,progress:m})}if(!u||u.distance>this.course.corridor){this.cancel("\u30B3\u30FC\u30B9\u304B\u3089\u5916\u308C\u307E\u3057\u305F");return}if(u.progress>this.progress+l){this.cancel("\u30C1\u30A7\u30C3\u30AF\u30DD\u30A4\u30F3\u30C8\u3092\u98DB\u3070\u3057\u307E\u3057\u305F");return}let h=this.course.checkpoints[this.nextCheckpoint];if(h&&u.progress>h.progress+18){this.cancel("\u30C1\u30A7\u30C3\u30AF\u30DD\u30A4\u30F3\u30C8\u672A\u901A\u904E");return}if(h&&u.progress>=h.progress-14&&Math.hypot(e.x-h.x,e.z-h.z)<=14&&this.nextCheckpoint++,this.progress=Math.max(this.progress,u.progress),this.elapsed=r-this.startTime+this.penaltyMs,this.lastTime=r,this.lastPosition={...e},this.nextCheckpoint===this.course.checkpoints.length&&Math.hypot(e.x-this.course.goal.x,e.z-this.course.goal.z)<=8&&this.progress>=this.course.length-8){if(this.elapsed<this.course.length/22*1e3-1e3){this.cancel("\u8A08\u6E2C\u3092\u78BA\u8A8D\u3067\u304D\u307E\u305B\u3093");return}this.phase="finished",this.onFinish({key:this.course.key,milliseconds:Math.round(this.elapsed),routeId:this.course.id})}}recover(e,t,n){return this.course?.family!=="pop"||!["running","invalid"].includes(this.phase)||!Number.isFinite(t)||t<0||t>this.course.length||!Number.isFinite(n)||n<this.penaltyMs?!1:(this.phase="running",this.reason="",this.progress=t,this.penaltyMs=n,this.nextCheckpoint=this.course.checkpoints.findIndex(s=>s.progress>t+.01),this.nextCheckpoint<0&&(this.nextCheckpoint=this.course.checkpoints.length),this.lastPosition={...e},this.lastTime=this.clock(),this.elapsed=this.lastTime-this.startTime+this.penaltyMs,!0)}get state(){return{penaltyMs:this.penaltyMs,phase:this.phase,reason:this.reason,elapsed:this.elapsed,countdown:this.countdown,progress:this.progress,nextCheckpoint:this.nextCheckpoint,checkpointCount:this.course?.checkpoints.length??0,routeId:this.course?.id??null,key:this.course?.key??null}}};function Eo(i){return typeof i=="number"&&Number.isFinite(i)&&i>0&&i<=36e5}function cc(i){if(!Eo(i))return"\u2014";let e=Math.floor(i/10),t=Math.floor(e/6e3),n=Math.floor(e/100)%60,s=e%100;return`${t}:${String(n).padStart(2,"0")}.${String(s).padStart(2,"0")}`}function gp({world:i,motion:e,scene:t,stop:n,setMode:s,notifyHost:r,onActor:o}){let a=document.querySelector("#race-panel"),c=document.querySelector("#race-time"),l=document.querySelector("#race-info"),u=document.querySelector("#race-best"),h=new Map,f=new Map,d=[],m=new Map,x=new Set,g=0,p=null,v=0,b=!0,_="",S="",M="",E,y=null,w=!1,A=!1,P=!1,C=!1,D=!1,L=-1/0,U=new ah({onFinish:F=>{n();let V=h.get(F.key);if(Po((!Eo(V)||F.milliseconds<V?"\u81EA\u5DF1\u30D9\u30B9\u30C8\u66F4\u65B0\uFF01":"\u30B4\u30FC\u30EB\uFF01 \u30CA\u30A4\u30B9\u30E9\u30F3\uFF01")+`
`+cc(F.milliseconds),{goal:!0,reducedMotion:i().reducedMotion===!0}),!Eo(V)||F.milliseconds<V){h.set(F.key,F.milliseconds),S="";try{localStorage.setItem(F.key,String(F.milliseconds))}catch{S="\u7AEF\u672B\u3078\u306E\u4FDD\u5B58\u4E0D\u53EF"}r(JSON.stringify({type:"campus-bus-best",...F}))}p&&$(!0),de()}});function G(){return mp(i().selectedRoute)}function Z(F,V={}){return new Promise((q,ie)=>{let le=`bus-${++g}`,ge=performance.now(),he=setTimeout(()=>{f.delete(le),ie(new Error("\u901A\u4FE1\u304C\u30BF\u30A4\u30E0\u30A2\u30A6\u30C8\u3057\u307E\u3057\u305F"))},12e3);f.set(le,{resolve:q,reject:ie,timeout:he,sentAt:ge}),r(JSON.stringify({type:"campus-game",requestId:le,action:F,payload:V}))})}function oe(){for(let F of m.values())t.remove(F.actor),F.actor.traverse(V=>{V.geometry?.dispose(),V.material?.map?.dispose(),V.material?.dispose()});m.clear()}function K(F="\u8D70\u884C\u3092\u4E2D\u65AD\u3057\u307E\u3057\u305F"){if(D=!1,C=!1,oe(),U.cancel(F),A=!1,p){p.buffer.clearPending();let V=p.challengeId;p=null,Z("cancelChallenge",{challengeId:V}).catch(()=>{})}de()}function te(){E&&(t.remove(E),E.traverse(F=>{F.geometry?.dispose(),F.material?.map?.dispose(),F.material?.dispose()}),E=null)}function se(F){te(),E=new Bt;for(let[V,q]of F.checkpoints.entries()){let ie=new it(new va(V===F.checkpoints.length-1?8:5,.12,4,24),new Bn({color:V===F.checkpoints.length-1?1614952:16758302}));ie.rotation.x=Math.PI/2,ie.position.set(q.x,(F.layerAware?q.y:i().roadIndex?.surface(q.x,q.z,null,"bus")?.height??i().terrainHeight(q.x,q.z)??0)+.4,q.z),E.add(ie)}t.add(E)}function Re(F){C=!1,K("\u65B0\u3057\u3044\u8D70\u884C\u3092\u958B\u59CB"),i().setRoute(F);let V=G(),q=V.segments[0],ie=i().roadIndex?.surface(V.start.x,V.start.z,null,"bus")?.height??i().terrainHeight(V.start.x,V.start.z);if(ie==null)throw new Error("\u30B9\u30BF\u30FC\u30C8\u5730\u70B9\u3092\u8AAD\u307F\u8FBC\u3081\u307E\u305B\u3093");return i().busSpawn={x:V.start.x,y:ie+1.4,z:V.start.z},i().busYaw=Math.atan2(-(q.b[0]-q.a[0]),-(q.b[1]-q.a[1])),s("bus"),e().reset(),o(),se(V),V}function Te(F=i().selectedRoute.id,V=null){let q=Re(F),ie=performance.now()+3e3;if(V){if(V.courseKey!==q.key||!Number.isFinite(V.startAt)||!Number.isFinite(V.serverNow))throw new Error("\u30B3\u30FC\u30B9\u306E\u7248\u304C\u4E00\u81F4\u3057\u307E\u305B\u3093");if(ie=performance.now()+V.startAt-V.serverNow-(V.rtt??0)/2,ie<performance.now()-250)throw new Error("\u958B\u59CB\u6642\u523B\u3092\u904E\u304E\u307E\u3057\u305F");x.add(V.challengeId),p={challengeId:V.challengeId,roomId:V.roomId,serverStart:V.startAt,localStart:ie,lastSampleT:0,buffer:new oh}}U.arm(q,{...e().position},ie),D=!0,v=performance.now(),_="",de()}function nt(F){n(),K("\u30B3\u30FC\u30B9\u3092\u5909\u66F4\u3057\u307E\u3057\u305F"),i().setRoute(F),i().experience==="game"&&(e().reset(),o()),te(),de()}function He(F){p&&(p.buffer.clearPending(),i().experience==="game"?(C=!0,D=!0,U.phase==="finished"&&(U.phase="invalid"),A=!1,n(),_=`\u30B5\u30FC\u30D0\u30FC\u78BA\u8A8D\u3092\u505C\u6B62\uFF1A${F.message}\u3002\u5FA9\u5E30\u3067\u518D\u958B\u3067\u304D\u307E\u3059\u3002`):(_=F.message,K(F.message)),de())}function $e(F=!1){if(!p||P||C||!["running","finished"].includes(U.phase))return;let V=e().position;try{p.buffer.capture(performance.now(),p.localStart,{x:V.x,z:V.z,y:V.y+(e().mode==="car"?.6:0)},{force:F,layerAware:G().layerAware})}catch(q){He(q)}}async function $(F=!1,V=!1){if(!p||C||P&&!V||(F&&(A=!0),$e(F),!p||C||w||performance.now()-v<300)||(A&&$e(!0),C))return;let q=p,ie=q.challengeId,le;try{le=q.buffer.take(performance.now())}catch(he){He(he);return}if(!le.length)return;let ge=A&&q.buffer.size===0;w=!0,v=performance.now(),p.lastSampleT=le.at(-1).t;try{let he=await Z("trace",{challengeId:ie,samples:le,...ge?{finish:!0}:{}});if(p!==q)return;he.room&&me(he.room),ge&&(_=he.finished?`\u30B5\u30FC\u30D0\u30FC\u78BA\u8A8D\u6E08\u307F ${cc(he.elapsedMs)} \u30FB \u516C\u958B\u8A2D\u5B9A\u306B\u5F93\u3046`:"\u30B5\u30FC\u30D0\u30FC\u3067\u5B8C\u8D70\u3092\u78BA\u8A8D\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F",A=!1,p=null)}catch(he){p===q&&He(he)}finally{v=performance.now(),w=!1;for(let he of d.splice(0))he()}de(),b&&p&&!P&&!C&&$()}async function z(){if(i().experience!=="game"||!D||P||!["running","invalid"].includes(U.phase)||performance.now()-L<2e3)return!1;P=!0,n(),A=!1,de();let F=p?.challengeId;try{if(w&&(_="\u8D70\u884C\u306E\u78BA\u8A8D\u5B8C\u4E86\u3092\u5F85\u3063\u3066\u5FA9\u5E30\u3057\u3066\u3044\u307E\u3059\u2026",de(),await new Promise(he=>d.push(he))),!b||!D||!["running","invalid"].includes(U.phase)||F&&p?.challengeId!==F)return!1;for(;p&&p.challengeId===F&&p.buffer.size&&!C;){let he=Math.max(0,300-(performance.now()-v));if(he&&await new Promise(ze=>setTimeout(ze,he)),!b||!D||p?.challengeId!==F)return!1;await $(!1,!0)}if(!b||!D||!["running","invalid"].includes(U.phase)||F&&p?.challengeId!==F)return!1;p?.buffer.clearPending();let V,q,ie,le,ge=!1;if(p){let he=await Z("recover",{challengeId:F});if(p?.challengeId!==F)return!1;V=he.progress,q={x:he.position.x,z:he.position.z,y:he.position.y+1.4},ie=he.yaw+Math.PI,le=he.penaltyMs,p.lastSampleT=he.t,ge=Math.round(performance.now()-p.localStart)-he.t>5e3,p.buffer.reset({baselineT:he.t,now:performance.now()}),v=performance.now(),he.room&&me(he.room)}else{V=Math.floor(U.progress/150)*150;let he=G(),ze=he.pointAt(V),O=he.pointAt(Math.min(he.length,V+1));q={x:ze.x,z:ze.z,y:ze.y+1.4},ie=Math.atan2(-(O.x-ze.x),-(O.z-ze.z)),le=U.penaltyMs+5e3}return i().setProgress?.(V),e().position={...q,y:q.y-(e().mode==="car"?.6:0)},e().yaw=ie,e().stop(),U.recover(q,V,le),C=!1,L=performance.now(),ge?(C=!0,U.cancel("\u5FA9\u5E30\u306E\u5FDC\u7B54\u304C5\u79D2\u4EE5\u4E0A\u9045\u308C\u305F\u305F\u3081\u518D\u958B\u3092\u505C\u6B62\u3057\u307E\u3057\u305F"),_=`\u5FA9\u5E30\u6599\u91D1\u306F\u9069\u7528\u6E08\u307F\uFF08\u5408\u8A08 ${le/1e3}\u79D2\uFF09\u3002\u518D\u5EA6\u5FA9\u5E30\u3057\u3066\u304F\u3060\u3055\u3044\u3002`,o(),!1):(p&&p.buffer.capture(performance.now(),p.localStart,{x:e().position.x,z:e().position.z,y:e().position.y+(e().mode==="car"?.6:0)},{force:!0,layerAware:G().layerAware}),_=`\u30B3\u30FC\u30B9\u3078\u5FA9\u5E30 +5\u79D2\uFF08\u5408\u8A08 ${le/1e3}\u79D2\uFF09`,o(),!0)}catch(V){return _=`\u5FA9\u5E30\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F\uFF1A${V.message}`,!1}finally{P=!1,de()}}function j(F,V){let q=String(V??"Player");if(F.nickname===q)return;if(F.nickname=q,!F.nameTexture&&document.createElement){let le=document.createElement("canvas");le.width=256,le.height=48;let ge=le.getContext("2d");if(ge){F.nameContext=ge,F.nameTexture=new aa(le);let he=new Qo(new kr({map:F.nameTexture,transparent:!0,depthTest:!1}));he.scale.set(6,1.13,1),he.position.y=4,F.actor.add(he)}}let ie=F.nameContext;ie&&(ie.clearRect(0,0,256,48),ie.fillStyle="#14324ddd",ie.fillRect(0,0,256,48),ie.fillStyle="white",ie.font="24px system-ui",ie.textAlign="center",ie.fillText(q,128,33,240),F.nameTexture.needsUpdate=!0)}function me(F,V=0){if(!F)return;y=F,document.querySelector("#race-online").textContent=F.status==="finished"?"\u5BFE\u6226\u7D50\u679C":"\u30E9\u30F3\u30AD\u30F3\u30B0\u30FB\u5BFE\u6226";let q=F.players?.find(le=>le.self||le.challengeId);if(q?.status==="left"||U.phase==="invalid"&&x.has(q?.challengeId)&&(i().experience!=="game"||!p)){oe();return}if(F.status==="racing"&&q?.challengeId&&q.status==="racing"&&!x.has(q.challengeId)){x.add(q.challengeId);try{Te(F.direction,{...F,challengeId:q.challengeId,roomId:F.roomId,rtt:V})}catch(le){_=le.message,K(le.message)}}let ie=new Set;for(let le of F.players??[]){if(le.challengeId||le.status==="left"||!le.position||!Number.isFinite(le.position.x)||!Number.isFinite(le.position.z))continue;ie.add(le.playerId);let ge=m.get(le.playerId);if(!ge){let ze=Wa();ze.traverse(O=>{O.material&&(O.material=O.material.clone(),O.material.transparent=!0,O.material.opacity=.45)}),t.add(ze),ge={actor:ze,target:new I,yaw:0},m.set(le.playerId,ge)}j(ge,le.nickname);let he=le.position;ge.target.set(he.x,i().experience==="game"&&Number.isFinite(he.y)?he.y-1.4:i().roadIndex?.surface(he.x,he.z,null,"bus")?.height??i().terrainHeight(he.x,he.z)??0,he.z),ge.initialized||(ge.actor.position.copy(ge.target),ge.initialized=!0),ge.yaw=Number.isFinite(le.yaw)?le.yaw+Math.PI:ge.yaw}for(let[le,ge]of m)ie.has(le)||(t.remove(ge.actor),ge.actor.traverse(he=>{he.geometry?.dispose(),he.material?.map?.dispose(),he.material?.dispose()}),m.delete(le))}function fe(F){if(typeof F=="string")try{F=JSON.parse(F)}catch{return}if(F?.type==="campus-best-save"){F.key===U.course?.key&&(S=F.ok?"":"\u7AEF\u672B\u3078\u306E\u4FDD\u5B58\u5931\u6557\uFF08\u3053\u306E\u753B\u9762\u5185\u306E\u8A18\u9332\u306E\u307F\uFF09",de());return}let V=f.get(F?.requestId);if(V){f.delete(F.requestId),clearTimeout(V.timeout),F.error?V.reject(new Error(F.error.message??F.error)):V.resolve(F.result??F.data??F.response??{});return}let q=F?.type==="campus-game-session"?F.data:F?.session?.room??F?.session??F?.room;if(q?.players&&me(q,F.rtt??0),F?.type==="campus-game-session"&&!F.data){y=null,document.querySelector("#race-online").textContent="\u30E9\u30F3\u30AD\u30F3\u30B0\u30FB\u5BFE\u6226",K("\u30EB\u30FC\u30E0\u3092\u9000\u51FA\u3057\u307E\u3057\u305F");for(let le of m.values())t.remove(le.actor),le.actor.traverse(ge=>{ge.geometry?.dispose(),ge.material?.map?.dispose(),ge.material?.dispose()});m.clear()}let ie=F?.challenge??(F?.action==="challenge"&&F?.ok?F.data:null);if(ie&&!x.has(ie.challengeId)){x.add(ie.challengeId);try{Te(F.direction??i().selectedRoute.id,ie)}catch(le){_=le.message,de()}}F?.type==="campus-game-leave"&&K("\u30EB\u30FC\u30E0\u3092\u9000\u51FA\u3057\u307E\u3057\u305F")}function de(){let F=document.querySelector("#race-speed"),V=document.querySelector("#race-progress");F&&(F.textContent=Math.round(Math.abs(e()?.speed??0)*3.6)+" km/h"),V&&(V.value=U.course?.length?Math.min(100,U.progress/U.course.length*100):0),a.hidden=e()?.mode!=="bus"&&!(i().experience==="game"&&e()?.mode==="car");let q=i()?.selectedRoute?G():null;if(!q)return;let ie=h.get(q.key);c.textContent=U.phase==="countdown"?`${U.countdown}\u2026`:cc(U.elapsed),l.textContent=U.phase==="running"?`CP ${U.nextCheckpoint}/${U.course.checkpoints.length}`:U.phase==="finished"?"\u30B4\u30FC\u30EB\uFF01":U.phase==="invalid"?U.reason:"\u7DF4\u7FD2\u30FB\u7AEF\u672B\u8A18\u9332",u.textContent=`\u81EA\u5DF1\u30D9\u30B9\u30C8 ${cc(ie)}${[_,S].filter(Boolean).length?" \xB7 "+[_,S].filter(Boolean).join(" / "):""}`;let le=document.querySelector("#race-recover");le&&(le.hidden=i().experience!=="game",le.disabled=!D||P||!["running","invalid"].includes(U.phase)||performance.now()-L<2e3),C&&(l.textContent="\u5FA9\u5E30\u3067\u30B5\u30FC\u30D0\u30FC\u78BA\u8A8D\u3092\u518D\u958B"),P&&(l.textContent="\u78BA\u8A8D\u5B8C\u4E86\u3092\u5F85\u3063\u3066\u5FA9\u5E30\u3057\u3066\u3044\u307E\u3059\u2026"),document.querySelector("#race-start").disabled=U.phase==="countdown"||U.phase==="running"}function et(F){if(!b)return;let V=U.phase,q=U.nextCheckpoint;U.tick({...e().position,y:e().position.y+(i().experience==="game"&&e().mode==="car"?.6:0)},{mode:e().mode,foreground:!document.hidden,onCourse:i().terrainHeight(e().position.x,e().position.z,e().position.y,"bus")!=null});let ie=Vp(V,U.phase,q,U.nextCheckpoint);ie&&Po(ie,{reducedMotion:i().reducedMotion===!0}),(U.phase==="running"||U.phase==="finished"&&p)&&($e(),$()),V!==U.phase&&U.phase==="invalid"&&(i().experience==="game"?(C=!!p,n()):K(U.reason));for(let le of m.values())le.actor.position.lerp(le.target,1-Math.exp(-F*6)),le.actor.rotation.y=le.yaw;de(),M=U.phase}function ne(F){for(let[V,q]of Object.entries(F??{}))/^(cit_bus_best_v1_(outward|return)|cit_bus_best_v2_pop_(outward|return|s_bay|neon_city))_[0-9a-f]{8}$/.test(V)&&Eo(q)&&h.set(V,q);de()}for(let F of i().data.routes){let V=mp(F).key;try{let q=Number(localStorage.getItem(V));Eo(q)&&h.set(V,q)}catch{}}return document.querySelector("#race-recover")?.addEventListener("click",()=>z()),document.querySelector("#race-start").addEventListener("click",()=>Te()),document.querySelector("#race-cancel").addEventListener("click",()=>K("\u4E2D\u65AD\u3057\u307E\u3057\u305F")),document.querySelector("#race-online").addEventListener("click",()=>r(JSON.stringify({type:"campus-game-open",direction:i().selectedRoute.id}))),{start:Te,select:nt,cancel:K,recover:z,tick:et,gameOnline:fe,setRaceBests:ne,get state(){return{...U.state,best:h.get(U.course?.key),online:!!p,pendingSamples:p?.buffer.size??0,roomStatus:y?.status??null,opponents:[...m].map(([F,V])=>({playerId:F,nickname:V.nickname,position:V.actor.position.toArray(),target:V.target.toArray()}))}},get frozen(){return U.phase==="countdown"||P||C},dispose(){b=!1,K("\u753B\u9762\u3092\u9589\u3058\u307E\u3057\u305F"),te();for(let F of f.values())clearTimeout(F.timeout),F.reject(new Error("\u753B\u9762\u3092\u9589\u3058\u307E\u3057\u305F"));f.clear();for(let F of m.values())t.remove(F.actor),F.actor.traverse(V=>{V.geometry?.dispose(),V.material?.map?.dispose(),V.material?.dispose()});m.clear()}}}var Ex=new URLSearchParams(location.search),An=Ex.get("experience")==="game",Ax=Ex.get("reducedMotion")==="1";document.body.dataset.experience=An?"game":"map";var Sp=new Ru,rr,Ai=new URLSearchParams(location.search).get("campus")==="narashino"?"narashino":"tsudanuma",uw=Ai==="narashino"?"shinnarashino-campus.glb":"tsudanuma-campus.glb",fi=document.querySelector("#scene"),Ao=document.querySelector("#message"),Rx=document.querySelector("#status"),Mx=document.querySelector("#help"),cr=new AbortController,sn={signal:cr.signal},on=new Set,bp=new Set,Mp=new rh,Ri,mt,Ze,Xe,En,zt,Ji,xn,Es,Kt,Tp={},Xn=!1,_n=!1,ji=!1,Ci=0,ch=0,Tx="",or,wx=0,Cx,As=!1,lc=!1,Ro,xp=1,fh=0,uc=0,hi=null,lh=new Set,wp=Sx({isDisposed:()=>_n,isLoaded:()=>Xn,getGame:()=>Kt,isRegionLoading:()=>lc,enterRegion:Pp,closeOverlay:()=>$i.closeOverlay()}),hw=i=>{if(i?.type==="campus-reset-view"){Co();return}return wp.receive(i)},_p=()=>wp.drain(),dh=()=>{let i=An?Sp.axes(Xe?.mode??"free"):Mp.axes(Xe?.mode??"free");if(An){let e=i.brake||on.has("brake");return{...i,brake:e,accelerate:!e&&(i.accelerate||on.has("accelerate")),throttle:e?-1:i.accelerate||on.has("accelerate")?1:0,steer:Ut(i.steer+Number(on.has("left"))-Number(on.has("right")),-1,1),lift:Ut(i.lift+Number(on.has("up"))-Number(on.has("down")),-1,1)}}return{throttle:Ut(i.throttle+Number(on.has("accelerate"))-Number(on.has("brake")),-1,1),steer:Ut(i.steer+Number(on.has("left"))-Number(on.has("right")),-1,1),lift:Ut(i.lift+Number(on.has("up"))-Number(on.has("down")),-1,1)}},fw={mode:()=>Xe?.mode??"free",enabled:()=>Xn&&!ji&&!_n&&Xe?.mode!=="free"&&!$i.overlayOpen,signal:cr.signal},dw=An?a0(Sp,fw):mx(Mp,{mode:()=>Xe?.mode??"free",enabled:()=>Xn&&!ji&&!_n&&Xe?.mode!=="free"&&!document.querySelector("#quality-dialog").hasAttribute("open"),signal:cr.signal}),pw=()=>{on.forEach(i=>bp.add(i)),on.clear(),dw(),hi=null;for(let i of[...lh])fi.dispatchEvent(new PointerEvent("pointercancel",{pointerId:i})),fi.hasPointerCapture(i)&&fi.releasePointerCapture(i);lh.clear()};fi.addEventListener("pointerdown",i=>{lh.add(i.pointerId),!(!Xn||ji||Xe.mode==="free"||hi)&&(i.preventDefault(),fi.setPointerCapture(i.pointerId),hi={id:i.pointerId,x:i.clientX,y:i.clientY})},sn);fi.addEventListener("pointermove",i=>{!hi||hi.id!==i.pointerId||(i.preventDefault(),fh-=(i.clientX-hi.x)*.006,uc=Ut(uc+(i.clientY-hi.y)*.005,-.7,.7),hi.x=i.clientX,hi.y=i.clientY)},sn);for(let i of["pointerup","pointercancel","lostpointercapture"])fi.addEventListener(i,e=>{lh.delete(e.pointerId),hi?.id===e.pointerId&&(hi=null)},sn);var yn=()=>{pw(),Xe?.stop()},Ep=i=>{i&&Kt?.cancel("\u30D0\u30C3\u30AF\u30B0\u30E9\u30A6\u30F3\u30C9\u306B\u79FB\u52D5\u3057\u307E\u3057\u305F"),ji=i,yn(),ch=0,!i&&!_n&&!Ci&&(Ci=requestAnimationFrame(hh))};function Px(i){i?.traverse(e=>{e.geometry?.dispose(),(Array.isArray(e.material)?e.material:[e.material]).forEach(n=>{if(n){for(let s of Object.values(n))s?.isTexture&&s.dispose();n.dispose()}})})}function Ap(){_n||(_n=!0,Cp?.(),rr?.dispose(),wp.clear(),Kt?.dispose(),yn(),cancelAnimationFrame(Ci),Ci=0,cr.abort(),yp?.disconnect(),mt?.dispose(),Rp?.dispose(),Ze?.disposeCollision(),Px(En),Ri?.dispose(),Ri?.forceContextLoss(),Xn=!1)}var yp,Rp,Cp,$i={stop:yn,pause:Ep,dispose:Ap,closeOverlay:()=>rr?.open?(rr.closeDetails(),!0):document.querySelector("#quality-dialog").hasAttribute("open")?(Cp?.(),!0):!1,get overlayOpen(){return rr?.open||document.querySelector("#quality-dialog").hasAttribute("open")},gameOnline:hw,setRaceBests:i=>{Tp=i,Kt?.setRaceBests(i)},startRace:i=>Kt?.start(i),cancelRace:()=>Kt?.cancel(),recoverRace:()=>Kt?.recover(),get race(){return Kt?.state??null},setFullscreen:vp,enterRegion:Pp,viewLandmark:mw,setMode:i=>ar(i),reset:()=>Co(),get state(){return{experience:An?"game":"map",sphere:Ze?.sphere,buildingLabels:rr?.state,course:Ze?.selectedRoute?.id,campus:Ai,loaded:Xn,regionMode:As,regionLoading:lc,region:As?Ze?.description(Xe.mode==="free"?mt.target:Xe.position):null,mode:Xe?.mode??"free",speed:Xe?.speed??0,yaw:Xe?.yaw??0,position:Xe?{...Xe.position}:null,pressed:[...on,...Mp.pointers.values(),...Sp.values],axes:dh(),cameraOrbit:{yaw:fh,pitch:uc},paused:ji,disposed:_n,blocked:Xe?.blocked??"",carVisible:Ji?.visible??!1,planeVisible:xn?.visible??!1,busVisible:Es?.visible??!1,camera:zt?.position.toArray(),target:mt?.target.toArray(),triangles:Ri?.info.render.triangles??0}},get worldSummary(){return Ze?{carSpawn:Ze.carSpawn,carYaw:Ze.carYaw,planeSpawn:Ze.planeSpawn,groundBounds:Ze.groundBounds,flightBounds:Ze.flightBounds,maxAltitude:Ze.maxAltitude,groundBase:Ze.groundBase,buildings:Ze.buildings,collisionTriangles:Ze.collisionTriangles}:null}};window.campusExplorer=$i;document.querySelectorAll("button[data-mode]").forEach(i=>i.addEventListener("click",()=>ar(i.dataset.mode),sn));var ph=!1;function mw(){if(!An||!Ze.sphere)return!1;ar("free");let[i,e,t]=Ze.sphere.position;return mt.target.set(i,e,t),zt.position.set(i-100,e+30,t+190),mt.update(),!0}async function Pp(){if(!Xn||_n||lc||As)return;yn(),lc=!0,document.querySelector("#city").disabled=!0;let i=e=>{document.querySelector("#region-message").textContent=e};try{let e=Ze,t=await vx({scene:En,currentCampus:Ai,currentScene:Cx,currentWorld:Ze,currentMotion:Xe,camera:zt,controls:mt,signal:cr.signal,onProgress:i,isDisposed:()=>_n});if(_n){t.disposeCollision();return}e.disposeCollision(),Ze=t,Xe.world=t,As=!0,Kt=gp({world:()=>Ze,motion:()=>Xe,scene:En,stop:yn,setMode:ar,notifyHost:di,onActor:()=>mh(0,!0)}),Kt.setRaceBests(Tp),Cp=bx({data:Ze.data,signal:cr.signal,onOpen:()=>{yn(),di(JSON.stringify({type:"campus-overlay",open:!0}))},onClose:()=>di(JSON.stringify({type:"campus-overlay",open:!1}))}),or.position.add(new I(t.data.campuses.find(n=>n.id===Ai).offset[0],t.data.campuses.find(n=>n.id===Ai).altitude??0,t.data.campuses.find(n=>n.id===Ai).offset[1])),or.target.add(new I(t.data.campuses.find(n=>n.id===Ai).offset[0],t.data.campuses.find(n=>n.id===Ai).altitude??0,t.data.campuses.find(n=>n.id===Ai).offset[1])),mt.maxDistance=6e3,document.querySelector("#city").textContent="\u6821\u5185",document.querySelector("#city").setAttribute("aria-label","\u30AD\u30E3\u30F3\u30D1\u30B9\u8868\u793A\u306B\u623B\u308B"),document.querySelector("#region-bar").hidden=!1}catch(e){_n||(console.error(e),i("\u5468\u8FBA\u30C7\u30FC\u30BF\u3092\u8AAD\u307F\u8FBC\u3081\u307E\u305B\u3093\u3002\u4E0A\u90E8\u306E\u30EA\u30BB\u30C3\u30C8\u3067\u518D\u8A66\u884C\u3057\u3066\u304F\u3060\u3055\u3044\u3002"))}finally{lc=!1,_n||(document.querySelector("#city").disabled=!1,Kt&&_p())}}document.querySelectorAll(".sources a").forEach(i=>i.addEventListener("click",e=>{window.CampusHost&&(e.preventDefault(),di(i.href.includes("openstreetmap")?"campus-source:osm":"campus-source:gsi"))},sn));document.querySelector("#city").addEventListener("click",()=>{An?Co():As?di("campus-reset-viewer"):Pp()},sn);document.querySelectorAll("[data-route]").forEach(i=>i.addEventListener("click",()=>Kt?Kt.select(i.dataset.route):Ze?.setRoute?.(i.dataset.route),sn));function di(i){window.CampusHost?window.CampusHost.postMessage(i):window.parent.postMessage(i,location.origin)}function vp(i){ph=i;let e=document.querySelector("#fullscreen");e.textContent=i?"\u2922":"\u26F6",e.setAttribute("aria-label",i?"\u5168\u753B\u9762\u3092\u89E3\u9664":"\u5168\u753B\u9762\u306B\u3059\u308B"),e.title=e.getAttribute("aria-label"),!i&&document.fullscreenElement&&document.exitFullscreen().catch(()=>{})}document.querySelector("#fullscreen").addEventListener("click",()=>{yn(),!ph&&window.parent!==window&&document.documentElement.requestFullscreen&&document.documentElement.requestFullscreen().catch(()=>{}),di("campus-fullscreen-toggle")},sn);document.addEventListener("fullscreenchange",()=>{!document.fullscreenElement&&ph&&di("campus-fullscreen-exit")},sn);document.querySelector("#stop").addEventListener("click",yn,sn);document.querySelector("#reset").addEventListener("click",()=>Co(),sn);var uh={ArrowUp:"accelerate",ArrowDown:"brake",ArrowLeft:"left",ArrowRight:"right",w:"accelerate",s:"brake",a:"left",d:"right",r:"up",f:"down",PageUp:"up",PageDown:"down"};window.addEventListener("keydown",i=>{if(i.key==="Escape"&&$i.overlayOpen){i.preventDefault(),$i.closeOverlay();return}if(i.key==="Escape"&&ph){i.preventDefault(),di("campus-fullscreen-exit");return}if(!Xn||ji||$i.overlayOpen)return;if(i.code==="Space"){i.preventDefault(),yn();return}let e=uh[i.key]??uh[i.key.toLowerCase()];e&&(i.preventDefault(),bp.has(e)||on.add(e))},sn);window.addEventListener("keyup",i=>{let e=uh[i.key]??uh[i.key.toLowerCase()];on.delete(e),bp.delete(e)},sn);window.addEventListener("blur",yn,sn);window.addEventListener("pagehide",Ap,sn);window.addEventListener("message",i=>{i.origin===location.origin&&i.source===window.parent&&(i.data?.type==="campus-reset-view"&&Co(),i.data?.type==="campus-close-overlay"&&$i.closeOverlay(),i.data?.type==="campus-best-save"&&$i.gameOnline(i.data),(i.data?.type==="campus-game-response"||i.data?.type==="campus-game-session"||i.data?.type==="campus-game-challenge"||i.data?.type==="campus-game-leave")&&$i.gameOnline(i.data),i.data==="campus-dispose"&&Ap(),i.data==="campus-stop"&&yn(),i.data==="campus-fullscreen:1"&&vp(!0),i.data==="campus-fullscreen:0"&&vp(!1))},sn);document.addEventListener("visibilitychange",()=>Ep(document.hidden),sn);fi.addEventListener("webglcontextlost",i=>{i.preventDefault(),Ep(!0),Ao.hidden=!1,Ao.textContent="3D\u63CF\u753B\u304C\u4E2D\u65AD\u3057\u307E\u3057\u305F\u3002"},sn);function ar(i){if(!(An&&i!=="bus")&&!(!Xn||_n||!["free","car","plane","bus"].includes(i)||i==="car"&&!Ze.carSpawn||i==="bus"&&!As)){if(Kt?.cancel("\u30E2\u30FC\u30C9\u3092\u5909\u66F4\u3057\u307E\u3057\u305F"),yn(),i==="bus"&&!Ze.busSpawn){let e=Ze.selectedRoute,t=e.points[0],n=e.points[1];Ze.busSpawn={x:t[0],y:(Ze.roadIndex.surface(t[0],t[1],null,"bus")?.height??Ze.terrainHeight(t[0],t[1])??0)+1.4,z:t[1]},Ze.busYaw=Math.atan2(-(n[0]-t[0]),-(n[1]-t[1]))}Xe.setMode(i),An&&(zt.fov=["bus","car"].includes(i)?65:50,zt.updateProjectionMatrix()),mt.enabled=i==="free",Ji.visible=i==="car",xn.visible=i==="plane",Es.visible=i==="bus",document.body.dataset.mode=i,document.querySelectorAll("button[data-mode]").forEach(e=>e.setAttribute("aria-pressed",String(e.dataset.mode===i))),An||(document.querySelector("#right-label").textContent=["car","bus"].includes(i)?"\u5DE6\u53F3\u3067\u64CD\u8235":"\u4E0A\u4E0B\u5DE6\u53F3\u3067\u64CD\u7E26"),Mx.textContent=i==="free"?"\u30C9\u30E9\u30C3\u30B0\u3067\u56DE\u8EE2\u30FB\u30D4\u30F3\u30C1\u3067\u62E1\u5927\u30FB2\u672C\u6307\u3067\u79FB\u52D5":"\u5DE6\uFF1A\u52A0\u6E1B\u901F\uFF0F\u53F3\uFF1A"+(["car","bus"].includes(i)?"\u5DE6\u53F3\u306E\u64CD\u8235":"\u4E0A\u4E0B\u5DE6\u53F3\u306E\u64CD\u7E26")+"\uFF0F\u7A7A\u3044\u3066\u3044\u308B\u753B\u9762\u3092\u30B9\u30EF\u30A4\u30D7\u3067\u8996\u70B9\u79FB\u52D5",Co(),An&&(Mx.textContent="\u5DE6\uFF1A\u5DE6\u53F3\u30DC\u30BF\u30F3\uFF0F\u53F3\uFF1A\u30A2\u30AF\u30BB\u30EB\u30FB\u30D6\u30EC\u30FC\u30AD\u3002\u753B\u9762\u30C9\u30E9\u30C3\u30B0\u3067\u8996\u70B9\u79FB\u52D5\u3002")}}function Co(){if(!(!Xn||_n))if(Kt?.cancel("\u30EA\u30BB\u30C3\u30C8\u3057\u307E\u3057\u305F"),yn(),Xe.reset(),fh=uc=0,xn.rotation.x=xn.rotation.z=0,Xe.mode==="free"){if(An){let i=Ze.flightBounds,e=new I((i.min.x+i.max.x)/2,0,(i.min.z+i.max.z)/2),t=Math.max(i.max.x-i.min.x,i.max.z-i.min.z)/Math.tan(qi.degToRad(zt.fov/2))*.6;or={position:e.clone().add(new I(0,t*.85,t*.55)),target:e}}zt.position.copy(or.position),mt.target.copy(or.target),mt.update()}else mh(0,!0)}function mh(i,e=!1){let t=Xe.mode==="bus",n=Xe.mode==="car"||t,s=t?Es:n?Ji:xn,r=Xe.position;s.position.set(r.x,r.y-(t?1.4:n?.8:0),r.z),s.rotation.y=Xe.yaw;let o=dh();n?s.userData.wheels.forEach(g=>g.rotateY(Xe.speed*i/.43)):(xn.rotation.z=qi.lerp(xn.rotation.z,o.steer*.18,Math.min(1,i*6)),xn.rotation.order="YXZ",xn.rotation.x=Xe.pitch??0,(Xe.landingCount??0)>wx&&(wx=Xe.landingCount,Po("\u30CA\u30A4\u30B9\u30E9\u30F3\u30C7\u30A3\u30F3\u30B0\uFF01",{reducedMotion:Ax,goal:!0})),xn.userData.propeller.rotation.z+=i*(8+Math.abs(Xe.speed)));let a=new I(r.x,r.y+(n?.9:0),r.z),c=Ut((An&&n?.12:n?Math.atan2(5,11):Math.atan2(32,24))+uc,.12,1.45),l=t?19:n?Math.hypot(11,5):40,u=Xe.yaw+fh,h=a.clone().add(new I(Math.sin(u)*Math.cos(c)*l,Math.sin(c)*l,Math.cos(u)*Math.cos(c)*l)),f=Ze.terrainHeight(h.x,h.z);f!=null&&(h.y=Math.max(h.y,f+1.5));let d=h.clone().sub(a),m=d.length();d.normalize();let x=Ze.cameraDistance(a,d,m);h.copy(a).addScaledVector(d,x),e?zt.position.copy(h):zt.position.lerp(h,1-Math.exp(-i*8)),zt.lookAt(a),mt.target.copy(a)}function gw(i){let e=dh();if(!e.throttle&&!e.steer&&!e.lift)return;let t=new I;zt.getWorldDirection(t),t.y=0,t.normalize();let n=new I().crossVectors(t,new I(0,1,0)),s=new I().addScaledVector(t,e.throttle).addScaledVector(n,-e.steer);if(s.y=e.lift,!s.lengthSq())return;s.normalize().multiplyScalar(xp*.15*i);let r=mt.target.clone();mt.target.add(s),mt.target.x=Ut(mt.target.x,Ze.flightBounds.min.x,Ze.flightBounds.max.x),mt.target.z=Ut(mt.target.z,Ze.flightBounds.min.z,Ze.flightBounds.max.z),mt.target.y=Ut(mt.target.y,Ze.groundBase,Ze.maxAltitude),zt.position.add(mt.target.clone().sub(r))}function hh(i){if(Ci=0,_n||ji)return;let e=Math.min((i-(ch||i))/1e3,.05);if(ch=i,Xn){if(Xe.mode==="free"?(gw(e),mt.update()):(Kt?.frozen||Xe.step(e,dh()),mh(e)),rr?.update(),As&&(Ze.update(Xe.mode==="free"?zt.position:Xe.position),!An)){let n=Ze.description(Xe.mode==="free"?mt.target:Xe.position);document.querySelector("#region-quality").textContent=`DEM\u7531\u676520m ${Number(n.sourceDerivedPercent??0).toFixed(2)}% / \u88DC\u9593 ${Number(n.interpolatedPercent??0).toFixed(2)}% \xB7 \u73FE\u5728 ${n.terrainSourceLabel??"\u78BA\u8A8D\u4E2D"} \xB7 \u5916\u89B3\u306B\u63A8\u5B9A\u3092\u542B\u3080`}Kt?.tick(e),Rp?.follow(Xe.mode==="free"?mt.target:Xe.position);let t=Xe.mode==="free"?"\u81EA\u7531\u8996\u70B9":`${Xe.mode==="bus"?"\u30D0\u30B9":Xe.mode==="car"?"\u8ECA":"\u98DB\u884C\u6A5F"} ${Math.round(Math.abs(Xe.speed)*3.6)} km/h${Xe.mode==="plane"?` \xB7 \u9AD8\u3055 ${Math.round(Xe.position.y-Ze.groundBase)} m`:""}${Xe.blocked?` \xB7 ${Xe.blocked}`:""}`;t!==Tx&&(Rx.textContent=t,Tx=t)}Ri.render(En,zt),Ci=requestAnimationFrame(hh)}function xw(i){let e=[],t=[],n=[],s=p=>p.userData.building_id||/^(Building_|Campus_Annex_|Dorm_Common)/.test(p.name);if(i.traverse(p=>{if(/^(Site_Base|Landscape_Ground|Campus_Ground|Landscape_Paving|Sports_Fields)$/.test(p.name)&&e.push(p),s(p)){for(let b=p.parent;b&&b!==i;b=b.parent)if(s(b))return;let v=new Ke().setFromObject(p);v.isEmpty()||(t.push({name:p.name,id:p.userData.building_id??p.name,min:{...v.min},max:{...v.max}}),n.push(p))}}),!e.length)throw Error("Ground meshes not found");let r=new Ke;e.forEach(p=>r.union(new Ke().setFromObject(p)));let o=r.getSize(new I),a=r.getCenter(new I),c=Math.max(o.x,o.z),l=new I(0,-1,0),u=new Xs,h=(p,v)=>{u.set(new I(p,Ro.max.y+50,v),l);let b=u.intersectObjects(e,!0);return b.length?b[0].point.y:null},f=e.find(p=>/^(Site_Base|Campus_Ground)$/.test(p.name))??e[0],d={terrainHeight:h,groundBounds:{min:{...r.min},max:{...r.max}},flightBounds:{min:{x:r.min.x-c*.4,z:r.min.z-c*.4},max:{x:r.max.x+c*.4,z:r.max.z+c*.4}},groundBase:new Ke().setFromObject(f).max.y,maxAltitude:Ro.max.y+250,buildings:t,carSpawn:null,carYaw:0,planeSpawn:{x:a.x,y:Ro.max.y+25,z:a.z}},m=rc(n);d.meshCollision=m.collides,d.cameraDistance=m.cameraDistance,d.collisionTriangles=m.triangleCount,d.disposeCollision=m.dispose;let x=n0({campus:Ai,scene:i,world:d});x&&Object.assign(d,x);let g=1/0;if(!x)for(let p=1;p<24;p++)for(let v=1;v<24;v++){let b=r.min.x+o.x*p/24,_=r.min.z+o.z*v/24,S=h(b,_);if(S==null)continue;let M={x:b,y:S+.8,z:_};if(co(M,"car",d))continue;let E=0,y=0;for(let A=0;A<8;A++){let P=A*Math.PI/4,C=0;for(let D of[3,6,10,15]){let L={x:b-Math.sin(P)*D,y:M.y,z:_-Math.cos(P)*D},U=h(L.x,L.z);if(U==null||Math.abs(U-S)>.65||co(L,"car",d))break;C=D}C>E&&(E=C,y=P)}let w=(b-a.x)**2+(_-a.z)**2-E*80;w<g&&(g=w,d.carSpawn=M,d.carYaw=y)}return d.carSpawn||(document.querySelector("[data-mode=car]").disabled=!0,d.carSpawn={x:a.x,y:r.max.y+.8,z:a.z}),d}async function _w(){try{Ri=new yu({canvas:fi,antialias:!0,alpha:!1,powerPreference:"high-performance"}),Ri.setPixelRatio(Math.min(devicePixelRatio,1.5)),Ri.outputColorSpace=Ft,Ri.toneMapping=Pa,En=new Bs,En.background=new Ve(15265522),zt=new Yt(50,1,.2,1e4),En.add(new Ma(16777215,7902580,2.4));let i=new Ws(16775660,3);i.position.set(-150,250,100),En.add(i),Rp=xx(Ri,En),mt=new Lu(zt,fi),mt.enableDamping=!1,mt.minDistance=2,mt.maxPolarAngle=Math.PI*.49;let e=0,t=0,n=()=>{let c=document.body.clientWidth,l=document.body.clientHeight;!c||!l||(e&&(c!==e||l!==t)&&yn(),e=c,t=l,zt.aspect=c/l,zt.updateProjectionMatrix(),Ri.setSize(c,l,!1))};if(yp=new ResizeObserver(n),yp.observe(document.body),n(),An){document.body.dataset.experience="game",document.querySelector("#scene").setAttribute("aria-label","\u30DD\u30C3\u30D7\u30C9\u30E9\u30A4\u30D6"),document.querySelector(".toolbar").remove(),document.querySelector("#region-bar").innerHTML='<select id="game-course" aria-label="\u30B3\u30FC\u30B9\u9078\u629E"><option value="outward">\u30AD\u30E3\u30F3\u30D1\u30B9\u5F80\u8DEF</option><option value="return">\u30AD\u30E3\u30F3\u30D1\u30B9\u5FA9\u8DEF</option><option value="s_bay">S\u5B57\u30D9\u30A4\uFF08\u975E\u516C\u5F0F\uFF09</option><option value="neon_city">\u30CD\u30AA\u30F3\u30B9\u30C8\u30EA\u30FC\u30C8\uFF08\u975E\u516C\u5F0F\uFF09</option></select><span id="region-quality">\u30AA\u30EA\u30B8\u30CA\u30EB\u30B2\u30FC\u30E0\u30B3\u30FC\u30B9</span>',Ze=await o0({scene:En,signal:cr.signal,reducedMotion:Ax,onCourse:c=>{di(JSON.stringify({type:"campus-course",direction:c.id})),document.querySelector("#game-course").value=c.id;let l=document.querySelector("#sphere-view");l&&(l.hidden=c.id!=="neon_city")}}),Xe=new Au(Ze),As=!0,Ji=zd(),xn=kd(),Es=Wa(),En.add(Ji,xn,Es),Ji.visible=xn.visible=!1,or={position:new I(0,110,110),target:new I},xp=300,mt.maxDistance=2e3,Xn=!0,ar("bus"),Kt=gp({world:()=>Ze,motion:()=>Xe,scene:En,stop:yn,setMode:ar,notifyHost:di,onActor:()=>mh(0,!0)}),Kt.setRaceBests(Tp),document.querySelector("#game-course").addEventListener("change",c=>Kt.select(c.target.value),sn),document.querySelector("#region-bar").hidden=!1,document.querySelector(".sources").innerHTML="\u30AA\u30EA\u30B8\u30CA\u30EB\u30B3\u30FC\u30B9<br>\u5B9F\u969B\u306E\u9053\u8DEF\u3067\u306F\u3042\u308A\u307E\u305B\u3093",Ao.hidden=!0,document.body.dataset.ready="true",_p(),!ji&&!Ci&&(Ci=requestAnimationFrame(hh));return}rr=t0({scene:En,camera:zt,canvas:fi,onOpen:yn,onOverlay:c=>di(JSON.stringify({type:"campus-overlay",open:c}))});let s=await new uo().loadAsync(uw);if(_n){Px(s.scene);return}ac(s.scene),Cx=s.scene,En.add(s.scene),s.scene.updateMatrixWorld(!0),Ro=new Ke().setFromObject(s.scene);let r=Ro.getSize(new I),o=Ro.getCenter(new I);xp=Math.max(r.x,r.z),Ze=xw(s.scene),Xe=new Tu(Ze),Ji=zd(),xn=kd(),Es=Wa(),En.add(Ji,xn,Es),Ji.visible=xn.visible=Es.visible=!1;let a=Math.max(r.x/zt.aspect,r.z,r.y)*.68/Math.tan(qi.degToRad(zt.fov/2));zt.position.copy(o).add(new I(0,.8,1).normalize().multiplyScalar(a)),mt.target.copy(o),mt.maxDistance=a*3,mt.update(),or={position:zt.position.clone(),target:o.clone()},Xn=!0,Ao.hidden=!0,document.body.dataset.ready="true",ar("free"),ch=0,_p(),!ji&&!Ci&&(Ci=requestAnimationFrame(hh))}catch(i){console.error(i),Ao.hidden=!1,Ao.textContent="3D\u30E2\u30C7\u30EB\u3092\u8868\u793A\u3067\u304D\u307E\u305B\u3093\u3002",Rx.textContent="\u8AAD\u307F\u8FBC\u307F\u5931\u6557"}}_w();})();
