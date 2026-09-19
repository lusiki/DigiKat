// Native Chrome rendering and focused accessibility/layout checks for the deck.
import {createServer} from 'node:http';
import {spawn} from 'node:child_process';
import {readFile,writeFile,mkdtemp,mkdir} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
import {tmpdir} from 'node:os';
const root=process.cwd(),out=resolve(root,'output/demokrscanstvo-presentation');
const qa=resolve(root,'tmp/pdfs/demokrscanstvo-presentation');await mkdir(qa,{recursive:true});
const mime={'.html':'text/html; charset=utf-8','.js':'application/javascript','.css':'text/css','.svg':'image/svg+xml','.png':'image/png','.webp':'image/webp','.woff2':'font/woff2','.woff':'font/woff','.ico':'image/x-icon'};
const server=createServer(async(req,res)=>{try{const p=resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname));if(!p.startsWith(root+sep))throw Error('path');res.setHeader('Content-Type',mime[extname(p)]||'application/octet-stream');res.end(await readFile(p));}catch{res.writeHead(404).end();}});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const profile=await mkdtemp(resolve(tmpdir(),'digikat-slides-'));
const chrome=spawn('C:/Program Files/Google/Chrome/Application/chrome.exe',['--headless=new','--disable-gpu','--no-first-run','--no-default-browser-check','--disable-background-networking','--remote-debugging-port=9325',`--user-data-dir=${profile}`,'about:blank'],{stdio:'ignore'});
const sleep=ms=>new Promise(r=>setTimeout(r,ms));let socket;
try{
  let tabs;for(let i=0;i<100;i++){try{tabs=await(await fetch('http://127.0.0.1:9325/json')).json();break;}catch{await sleep(100);}}
  const tab=tabs.find(t=>t.type==='page'&&t.url==='about:blank');if(!tab)throw Error(JSON.stringify(tabs));
  socket=new WebSocket(tab.webSocketDebuggerUrl);await new Promise(r=>socket.addEventListener('open',r,{once:true}));
  let id=0;const pending=new Map(),errors=[];
  socket.addEventListener('message',e=>{const m=JSON.parse(e.data);if(m.id){const p=pending.get(m.id);pending.delete(m.id);if(m.error)p.reject(Error(m.error.message));else p.resolve(m.result);}else if(m.method==='Runtime.exceptionThrown')errors.push(m.params);});
  const send=(method,params={})=>new Promise((resolve,reject)=>{const n=++id;pending.set(n,{resolve,reject});socket.send(JSON.stringify({id:n,method,params}));});
  const evaluate=async expression=>{const r=await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(JSON.stringify(r.exceptionDetails));return r.result.value;};
  await send('Page.enable');await send('Runtime.enable');

  const results=[];
  for(const page of ['pages/demokrscanstvo/index.html','assets/izvjestaji/demokrscanstvo-od-rijeci-do-argumenta.html','assets/izvjestaji/demokrscanstvo-12-nalaza.html']){
    await send('Page.navigate',{url:`http://127.0.0.1:${server.address().port}/docs/${page}`});await sleep(650);await evaluate('document.fonts.ready.then(()=>true)');
    await evaluate(`Promise.all(Array.from(document.images).map(i=>{i.loading='eager';return i.decode().then(()=>true).catch(()=>{throw new Error(i.src)})}))`);
    await evaluate(await readFile(resolve(root,'node_modules/axe-core/axe.min.js'),'utf-8'));
    for(const width of [390,1366]){
      await send('Emulation.setDeviceMetricsOverride',{width,height:900,deviceScaleFactor:1,mobile:false});await sleep(120);
      const violations=await evaluate(`axe.run(document,{runOnly:{type:'tag',values:['wcag2a','wcag2aa','wcag21aa']}}).then(r=>r.violations.map(v=>({id:v.id,impact:v.impact,nodes:v.nodes.map(n=>n.html)})))`);
      const layout=await evaluate(`({width:innerWidth,scrollWidth:document.documentElement.scrollWidth})`);
      if(violations.length||layout.scrollWidth>width)throw Error(JSON.stringify({page,width,violations,layout}));
      results.push({page,width,violations,layout});
      if(page.startsWith('pages/'))for(const section of ['nalazi','izvjestaj']){
        const clip=await evaluate(`(()=>{const el=document.querySelector('#${section}');const r=el.getBoundingClientRect();return {x:r.x,y:r.y+scrollY,width:r.width,height:r.height,scale:1}})()`);
        const image=await send('Page.captureScreenshot',{format:'png',captureBeyondViewport:true,clip});await writeFile(resolve(qa,`${section}-${width}.png`),Buffer.from(image.data,'base64'));
      }
    }
  }
  await writeFile(resolve(out,'web-verification.json'),JSON.stringify({status:'PASS',results,errors},null,2));console.log(JSON.stringify({status:'PASS',pages:3,widths:[390,1366],accessibilityViolations:0}));
}finally{if(socket)socket.close();chrome.kill();server.close();}
