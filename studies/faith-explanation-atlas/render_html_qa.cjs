/* Isolated local-artifact renderer. Never attaches to an existing browser.
 * Usage: node render_html_qa.cjs study/output/.../report.html output/private/qa-new [width]
 * A fresh headless profile and loopback-only debugging endpoint are closed at exit.
 * HTTP(S) resources are blocked: the study HTML must be self-contained.
 */
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {spawn} = require('node:child_process');
const {pathToFileURL} = require('node:url');
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
const sha = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');

async function main() {
  const source = fs.realpathSync(process.argv[2]);
  const destination = path.resolve(process.argv[3]);
  const width = Number(process.argv[4] || 1440), height = width < 600 ? 844 : 1100;
  const outputRoot = path.join(__dirname, 'output') + path.sep;
  const privateRoot = path.join(__dirname, 'output', 'private') + path.sep;
  if (!source.startsWith(outputRoot) || path.extname(source) !== '.html')
    throw Error('Only generated study HTML is allowed');
  if (!destination.startsWith(privateRoot) || fs.existsSync(destination))
    throw Error('Use a new study-private QA directory');
  if (!Number.isInteger(width) || width < 320 || width > 2000)
    throw Error('Unsupported viewport width');
  fs.mkdirSync(destination, {recursive:true});
  const profile = path.join(destination, 'isolated-profile');
  const before = sha(source);
  let phase='starting';
  const stage=name=>{phase=name;fs.appendFileSync(path.join(destination,'stages.jsonl'),JSON.stringify({at:new Date().toISOString(),phase})+'\n');};
  const stderr = fs.openSync(path.join(destination, 'renderer.stderr.log'), 'wx');
  const child = spawn('C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe', [
    '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
    '--disable-background-networking', '--disable-component-update', '--disable-sync',
    '--disable-extensions', '--remote-debugging-address=127.0.0.1', '--remote-debugging-port=0',
    `--user-data-dir=${profile}`, 'about:blank'
  ], {windowsHide:true, stdio:['ignore','ignore',stderr]});
  let socket, rpc, launchError;
  child.on('error', error => { launchError = error; });
  try {
    const portFile = path.join(profile, 'DevToolsActivePort');
    for (let i=0; i<100 && !fs.existsSync(portFile); i++) {
      if (launchError) throw launchError;
      if (child.exitCode !== null) throw Error('Isolated renderer exited during startup');
      await delay(100);
    }
    const port = Number(fs.readFileSync(portFile,'utf8').split(/\r?\n/)[0]);
    if (!Number.isInteger(port) || port < 1) throw Error('Invalid isolated renderer port');
    const endpoint = `http://127.0.0.1:${port}`;
    const protocol = await (await fetch(endpoint+'/json/protocol')).json();
    const capture = protocol.domains.find(d=>d.domain==='Page').commands.find(c=>c.name==='captureScreenshot');
    if (!capture.parameters.some(p=>p.name==='captureBeyondViewport'))
      throw Error('Renderer does not support full-page artifact capture');
    const targets = (await (await fetch(endpoint+'/json/list')).json()).filter(t=>t.type==='page');
    if (targets.length!==1 || targets[0].url!=='about:blank') throw Error('Unexpected isolated target');
    socket = new WebSocket(targets[0].webSocketDebuggerUrl);
    await new Promise((resolve,reject)=>{socket.addEventListener('open',resolve,{once:true});socket.addEventListener('error',reject,{once:true});});
    let sequence=0;
    const pending=new Map(), exceptions=[], loadingFailures=[];
    socket.addEventListener('message',event=>{
      const message=JSON.parse(event.data);
      if (message.id && pending.has(message.id)) {
        const request=pending.get(message.id);pending.delete(message.id);clearTimeout(request.timer);
        message.error ? request.reject(Error(JSON.stringify(message.error))) : request.resolve(message.result);
      } else if (message.method==='Runtime.exceptionThrown') exceptions.push(message.params.exceptionDetails.text);
      else if (message.method==='Network.loadingFailed') loadingFailures.push(message.params.errorText);
    });
    socket.addEventListener('close',()=>{
      for (const request of pending.values()) {clearTimeout(request.timer);request.reject(Error('Renderer connection closed'));}
      pending.clear();
    });
    rpc=(method,params={})=>new Promise((resolve,reject)=>{
      const id=++sequence;
      const timer=setTimeout(()=>{pending.delete(id);reject(Error('Renderer timed out: '+method));},30000);
      pending.set(id,{resolve,reject,timer});socket.send(JSON.stringify({id,method,params}));
    });
    const version=await rpc('Browser.getVersion');
    await rpc('Page.enable');await rpc('Runtime.enable');await rpc('Network.enable');
    await rpc('Network.setBlockedURLs',{urls:['http://*','https://*']});
    await rpc('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});
    stage('navigate');
    const sourceUrl=pathToFileURL(source).href;
    const navigation=await rpc('Page.navigate',{url:sourceUrl});
    if (navigation.errorText) throw Error(navigation.errorText);
    for (let i=0; i<100; i++) {
      const state=await rpc('Runtime.evaluate',{expression:'({state:document.readyState,url:location.href})',returnByValue:true});
      if (state.result.value.state==='complete' && state.result.value.url===sourceUrl) break;
      if(i===99)throw Error('HTML did not finish loading');
      await delay(100);
    }
    stage('load_fonts_and_all_figures');
    const ready=await rpc('Runtime.evaluate',{expression:`(async()=>{
      const timeout=()=>new Promise(resolve=>setTimeout(()=>resolve(false),5000));
      const fontsReady=await Promise.race([document.fonts.ready.then(()=>true),timeout()]);
      for(const image of document.images)image.loading='eager';
      await Promise.race([Promise.all(Array.from(document.images).map(image=>image.decode().catch(()=>null))),timeout()]);
      return {title:document.title,url:location.href,lang:document.documentElement.lang,fontsReady,
        clientWidth:document.documentElement.clientWidth,scrollWidth:document.documentElement.scrollWidth,
        scrollHeight:document.documentElement.scrollHeight,
        tableScrollRegions:Array.from(document.querySelectorAll('.report-table-scroll')).map(e=>{
          const previous=e.scrollLeft;
          e.scrollLeft=e.scrollWidth;
          const reached=e.scrollLeft;
          e.scrollLeft=previous;
          return {clientWidth:e.clientWidth,scrollWidth:e.scrollWidth,reachableScroll:reached,
            focusable:e.tabIndex===0,accessibleLabel:e.getAttribute('aria-label')};
        }),
        overflowingElements:Array.from(document.body.querySelectorAll('*')).filter(e=>{
          const r=e.getBoundingClientRect();
          return r.width>0 && (r.right>document.documentElement.clientWidth+1 || r.left < -1) && !e.closest('.report-table-scroll');
        }).slice(0,40).map(e=>({tag:e.tagName,id:e.id,class:e.className,
          text:e.textContent.trim().slice(0,120),left:e.getBoundingClientRect().left,right:e.getBoundingClientRect().right})),
        headings:Array.from(document.querySelectorAll('h1,h2')).map(h=>({level:h.tagName,text:h.textContent.trim(),id:h.id})),
        images:Array.from(document.images).map(i=>({complete:i.complete,width:i.naturalWidth,height:i.naturalHeight})),
        missingTocTargets:Array.from(document.querySelectorAll('nav a[href^="#"]')).filter(a=>!document.getElementById(decodeURIComponent(a.hash.slice(1)))).map(a=>a.hash)};
    })()`,awaitPromise:true,returnByValue:true});
    if (ready.exceptionDetails) throw Error('HTML readiness inspection failed');
    const layout=ready.result.value;
    stage('capture');
    const metrics=await rpc('Page.getLayoutMetrics');
    const content=metrics.cssContentSize;
    const top=await rpc('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});
    fs.writeFileSync(path.join(destination,'viewport.png'),Buffer.from(top.data,'base64'));
    const full=await rpc('Page.captureScreenshot',{format:'png',captureBeyondViewport:true,
      clip:{x:0,y:0,width:content.width,height:content.height,scale:1}});
    fs.writeFileSync(path.join(destination,'full.png'),Buffer.from(full.data,'base64'));
    if (sha(source)!==before)throw Error('HTML changed during visual capture');
    const result={created_utc:new Date().toISOString(),scope:'Isolated local HTML rendering; human/agent visual inspection still required',
      source,source_sha256:before,renderer_code_sha256:sha(__filename),browser:version,
      viewport:{width,height},content,layout,exceptions,loadingFailures,
      external_http_resources_blocked:true,existing_browser_profiles_accessed:false,
      lazy_images_loaded_for_capture:true,
      viewport_png_sha256:sha(path.join(destination,'viewport.png')),full_png_sha256:sha(path.join(destination,'full.png'))};
    fs.writeFileSync(path.join(destination,'render_evidence.json'),JSON.stringify(result,null,2)+'\n');
    console.log(JSON.stringify({directory:destination,source_sha256:before,viewport:result.viewport,content,
      images:layout.images.length,missingImages:layout.images.filter(i=>!i.complete||!i.width).length,
      pageOverflow:layout.scrollWidth>layout.clientWidth,exceptions,loadingFailures}));
    if(!layout.fontsReady||layout.images.some(i=>!i.complete||!i.width)||exceptions.length||loadingFailures.length||
       layout.missingTocTargets.length||layout.scrollWidth>layout.clientWidth||
       layout.tableScrollRegions.some(t=>!t.focusable||!t.accessibleLabel||t.scrollWidth-t.clientWidth>t.reachableScroll+1))
      throw Error('HTML has resource, navigation, overflow or table-access problems; inspect evidence');
    stage('complete');
  } catch(error) {
    fs.writeFileSync(path.join(destination,'failure.json'),JSON.stringify({phase,error:String(error),source_sha256:before},null,2)+'\n');
    throw error;
  } finally {
    if(rpc && socket?.readyState===WebSocket.OPEN)await rpc('Browser.close').catch(()=>{});
    socket?.close();
    if(child.exitCode===null)child.kill();
    fs.closeSync(stderr);
  }
}
main().catch(error=>{console.error(error.stack);process.exitCode=1;});
