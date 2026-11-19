const fs=require('fs'),path=require('path'),http=require('http'),assert=require('assert/strict');
const {chromium}=require('playwright-core');
const root=path.resolve(process.env.CAMPUS_3D_QA_WEB||'build/campus_3d_qa'),out=path.resolve('docs/campus_3d');fs.mkdirSync(out,{recursive:true});
const server=http.createServer((req,res)=>{const f=path.resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname==='/'?'/index.html':new URL(req.url,'http://localhost').pathname));if(!f.startsWith(root+path.sep)||!fs.existsSync(f)){res.writeHead(404);res.end();return;}res.setHeader('Content-Type',({'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.glb':'model/gltf-binary','.json':'application/json'})[path.extname(f)]??'application/octet-stream');fs.createReadStream(f).pipe(res);});
(async()=>{await new Promise(r=>server.listen(0,'127.0.0.1',r));const browser=await chromium.launch({executablePath:process.env.CHROME_PATH||'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader']});const page=await browser.newPage({viewport:{width:390,height:844},hasTouch:true,isMobile:true});const errors=[],result={};page.on('pageerror',e=>errors.push(e.message));let frame;
const ready=async()=>{const handle=await page.locator('iframe').elementHandle();frame=await handle.contentFrame();await frame.waitForFunction(()=>window.campusExplorer?.state.loaded,null,{timeout:60000});await page.waitForTimeout(250);};
const state=()=>frame.evaluate(()=>window.campusExplorer.state);const cdp=await page.context().newCDPSession(page);
const touch=async(type,points)=>{await cdp.send('Input.dispatchTouchEvent',{type,touchPoints:points.map(([id,x,y])=>({id,x,y,radiusX:2,radiusY:2,force:1}))});await page.waitForTimeout(60);};
const point=async selector=>{const b=await frame.locator(selector).boundingBox();return {x:b.x+b.width/2,y:b.y+b.height/2,r:b.width*.25,b};};
const neutral=async()=>{await frame.waitForFunction(()=>window.campusExplorer.state.pressed.length===0,null,{timeout:5000});const s=await state();assert.deepEqual(s.pressed,[]);assert.equal(s.axes.throttle,0);assert.equal(s.axes.steer,0);assert.equal(s.axes.lift,0);};
try{
 await page.goto(`http://127.0.0.1:${server.address().port}/`);await page.locator('flt-semantics-placeholder').waitFor({state:'attached',timeout:60000});await page.locator('flt-semantics-placeholder').evaluate(e=>e.click());await page.getByRole('button',{name:'3Dマップを開く',exact:true}).click();await ready();

 await frame.locator('button[data-mode=car]').click();const beforeFull=await state();const frameUrl=frame.url();
 await page.getByRole('button',{name:'全画面にする',exact:true}).click();await frame.waitForFunction(()=>document.querySelector('#fullscreen').getAttribute('aria-label')==='全画面を解除');
 assert.equal(frame.url(),frameUrl);assert.deepEqual((await state()).position,beforeFull.position);assert.equal((await state()).mode,'car');result.fullscreenPreservesScene=true;
 await page.screenshot({path:path.join(out,'fullscreen-car.png')});
 await frame.locator('#fullscreen').click();await page.getByRole('button',{name:'全画面にする',exact:true}).waitFor();result.fullscreenExit=true;
 await frame.locator('#fullscreen').click();await frame.waitForFunction(()=>document.querySelector('#fullscreen').getAttribute('aria-label')==='全画面を解除');
 await page.screenshot({path:path.join(out,'fullscreen-native.png')});
 await frame.locator('#scene').focus();await page.keyboard.press('Escape');await page.getByRole('button',{name:'全画面にする',exact:true}).waitFor();result.fullscreenEscape=true;
 await frame.locator('button[data-mode=free]').click();
 for(const campus of ['tsudanuma','narashino']){
  if(campus==='narashino'){await page.locator('[aria-label="新習志野"]').click();await page.waitForTimeout(600);await ready();}

  result[campus]={};await frame.locator('#city').click();await frame.waitForFunction(()=>window.campusExplorer?.state.regionMode,null,{timeout:60000});await page.waitForTimeout(1500);const region=(await state()).region;assert(region.campusesLoaded.includes(campus));assert(Number.isFinite(region.elevation));result[campus].regionLoaded=region;
  assert((await state()).triangles>10000);

  const world=await frame.evaluate(()=>window.campusExplorer.worldSummary);assert(world.collisionTriangles>1000);result[campus].collisionTriangles=world.collisionTriangles;
  for(const [orientation,size] of [['portrait',{width:390,height:844}],['landscape',{width:844,height:390}]]){
   await page.setViewportSize(size);await page.waitForTimeout(400);await neutral();
   for(const mode of ['car','plane']){
    await frame.locator(`button[data-mode=${mode}]`).click();await page.waitForTimeout(250);const r=result[campus][`${orientation}-${mode}`]={};
    const l=await point('[data-stick=left]'),right=await point('[data-stick=right]'),canvas=await point('#scene');
    assert(l.b.y>=canvas.b.y&&l.b.y+l.b.height<=canvas.b.y+canvas.b.height);assert(right.b.x>l.b.x+l.b.width);r.controlsFit=true;
    const initial=await state();
    const left=[1,l.x,l.y-l.r],rp=[2,right.x-right.r*.6,right.y-(mode==='plane'?right.r*.6:0)];
    await touch('touchStart',[left,rp]);await frame.waitForFunction(([yaw,mode,y])=>{const s=window.campusExplorer.state;return s.speed>0&&s.yaw>yaw+.01&&(mode!=='plane'||s.position.y>y+1);},[initial.yaw,mode,initial.position.y],{timeout:10000});let s=await state();assert(s.speed>0);assert(s.yaw>initial.yaw+.01);if(mode==='plane')assert(s.position.y>initial.position.y+1);else assert.equal(s.axes.lift,0);r.simultaneousSticks=true;
    const beforeSwipe=s.cameraOrbit.yaw;const cx=canvas.x,cy=canvas.y;
    await touch('touchStart',[left,rp,[3,cx,cy]]);await touch('touchMove',[left,rp,[3,cx+40,cy+12]]);s=await state();assert(Math.abs(s.cameraOrbit.yaw-beforeSwipe)>.1);assert(s.axes.throttle>0&&s.axes.steer>0);r.thirdFingerCamera=true;
    // Both owners survive border crossings and retain clamped axes until actual release.
    const heldCamera=(await state()).cameraOrbit;await touch('touchMove',[[1,l.x,l.b.y-30],[2,right.b.x-30,right.y],[3,cx+40,cy+12]]);await frame.waitForFunction(()=>window.campusExplorer.state.axes.throttle===1&&window.campusExplorer.state.axes.steer===1,null,{timeout:8000});s=await state();assert.equal(s.pressed.filter(x=>x==='left'||x==='right').length,2);assert.deepEqual(s.cameraOrbit,heldCamera);await touch('touchMove',[left,rp,[3,cx+40,cy+12]]);await frame.waitForFunction(()=>window.campusExplorer.state.axes.throttle>0&&window.campusExplorer.state.axes.throttle<1,null,{timeout:8000});r.outsideBothHeldAndReturn=true;
    await touch('touchCancel',[]);await neutral();r.cancelNeutral=true;
    await frame.locator('#stop').click();assert.equal((await state()).speed,0);
    // Second pointer cannot steal a stick from its owner.
    await touch('touchStart',[left,[4,l.x,l.y+l.r],rp]);assert((await state()).axes.throttle>0);await touch('touchEnd',[]);await neutral();r.extraFingerIgnored=true;
    await touch('touchStart',[left,rp]);await page.waitForTimeout(150);await frame.locator('#reset').evaluate(e=>e.click());await neutral();assert.equal((await state()).speed,0);await touch('touchEnd',[]);r.resetHeld=true;
    await page.screenshot({path:path.join(out,`${campus}-${orientation}-${mode}.png`)});
   }
  }
  await frame.locator('button[data-mode=plane]').click();const l=await point('[data-stick=left]'),rr=await point('[data-stick=right]');await touch('touchStart',[[1,l.x,l.y-l.r],[2,rr.x,rr.y-rr.r]]);await page.setViewportSize({width:390,height:844});await page.waitForTimeout(300);await neutral();assert.equal((await state()).speed,0);await touch('touchEnd',[]);result[campus].rotationClearsInput=true;
  await touch('touchStart',[[1,(await point('[data-stick=left]')).x,(await point('[data-stick=left]')).y-20]]);await frame.locator('button[data-mode=car]').evaluate(e=>e.click());await neutral();assert.equal((await state()).speed,0);await touch('touchEnd',[]);result[campus].heldModeClears=true;
  await frame.locator('[data-route=return]').click();await frame.locator('[data-route=outward]').click();result[campus].routeSelection=true;await frame.locator('button[data-mode=free]').click();const c=await point('#scene'),before=(await state()).camera;await page.mouse.move(c.x,c.y);await page.mouse.down();await page.mouse.move(c.x+60,c.y+10,{steps:8});await page.mouse.up();assert(Math.hypot(...(await state()).camera.map((n,i)=>n-before[i]))>1);result[campus].freeSwipe=true;
 }
 await frame.locator('button[data-mode=car]').click();const l=await point('[data-stick=left]');await touch('touchStart',[[1,l.x,l.y-l.r]]);await frame.evaluate(()=>window.campusExplorer.pause(true));await neutral();assert.equal((await state()).speed,0);await touch('touchEnd',[]);await frame.evaluate(()=>window.campusExplorer.pause(false));result.pauseNeutral=true;
 await touch('touchStart',[[1,l.x,l.y-l.r]]);await page.getByRole('button',{name:'視点をリセット',exact:true}).click();await page.waitForTimeout(600);await touch('touchEnd',[]);await ready();await neutral();result.heldFlutterResetClears=true;
 await frame.locator('button[data-mode=car]').click();const last=await point('[data-stick=left]');await touch('touchStart',[[1,last.x,last.y-last.r]]);await page.getByRole('button',{name:'Back',exact:true}).click();await touch('touchEnd',[]);await page.locator('iframe').waitFor({state:'detached',timeout:5000});assert.equal(await page.locator('iframe').count(),0);result.heldBackRemovesViewer=true;assert.equal(errors.length,0);result.pageErrors=errors;console.log(JSON.stringify(result,null,2));
}catch(e){result.failure=e.stack;result.pageErrors=errors;console.error(JSON.stringify(result,null,2));await page.screenshot({path:path.join(out,'failure.png')});process.exitCode=1;}
finally{fs.writeFileSync(path.join(out,'stick-render-validation.json'),JSON.stringify(result,null,2));await browser.close();server.close();}})();
