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
 for(const campus of ['tsudanuma','narashino']){
  if(campus==='narashino'){await page.locator('[aria-label="新習志野"]').click();await page.waitForTimeout(600);await ready();}
  await frame.locator('#city').click();await frame.waitForFunction(()=>window.campusExplorer.state.regionMode,null,{timeout:60000});await page.waitForTimeout(1000);result[campus]={};
  for(const [orientation,size]of [['portrait',{width:390,height:844}],['landscape',{width:844,height:390}]]){
   await page.setViewportSize(size);await page.waitForTimeout(300);
   for(const mode of ['car','plane']){await frame.locator(`button[data-mode=${mode}]`).click();await page.waitForTimeout(450);assert((await state()).triangles>10000);await page.screenshot({path:path.join(out,`${campus}-${orientation}-${mode}.png`)});result[campus][`${orientation}-${mode}`]={triangles:(await state()).triangles,region:(await state()).region};}
  }
  await page.setViewportSize({width:390,height:844});await page.getByRole('button',{name:'全画面にする',exact:true}).click();await frame.waitForFunction(()=>document.querySelector('#fullscreen').getAttribute('aria-label')==='全画面を解除');await page.waitForTimeout(400);await page.screenshot({path:path.join(out,`${campus}-fullscreen-plane.png`)});
  await frame.locator('#city').click();await page.waitForTimeout(600);await ready();assert.equal((await state()).regionMode,false);await frame.waitForFunction(()=>document.querySelector('#fullscreen').getAttribute('aria-label')==='全画面を解除');result[campus].exitRegionRetainsFullscreen=true;
  await frame.locator('#fullscreen').click();await page.getByRole('button',{name:'全画面にする',exact:true}).waitFor();
 }
 assert.equal(errors.length,0);result.pageErrors=errors;console.log(JSON.stringify(result,null,2));
}catch(e){result.failure=e.stack;result.pageErrors=errors;console.error(JSON.stringify(result,null,2));await page.screenshot({path:path.join(out,'failure.png')});process.exitCode=1;}
finally{fs.writeFileSync(path.join(out,'region-final-render-validation.json'),JSON.stringify(result,null,2));await browser.close();server.close();}})();
