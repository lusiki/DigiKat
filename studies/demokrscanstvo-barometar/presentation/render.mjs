// Native Chrome rendering and focused accessibility/layout checks for the deck.
import {createServer} from 'node:http';
import {spawn} from 'node:child_process';
import {readFile,writeFile,mkdtemp,mkdir} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
import {tmpdir} from 'node:os';
const root=process.cwd(),out=resolve(root,'output/demokrscanstvo-presentation');
const qa=resolve(root,'tmp/pdfs/demokrscanstvo-presentation');await mkdir(qa,{recursive:true});
const mime={'.html':'text/html; charset=utf-8','.js':'application/javascript','.css':'text/css'};
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
  await send('Emulation.setDeviceMetricsOverride',{width:1280,height:850,deviceScaleFactor:1,mobile:false});
  await send('Page.navigate',{url:`http://127.0.0.1:${server.address().port}/output/demokrscanstvo-presentation/demokrscanstvo-12-nalaza.html`});
  await sleep(500);await evaluate('document.fonts.ready.then(()=>true)');
  const geometry=await evaluate(`Array.from(document.querySelectorAll('.slide')).map(s=>({id:s.id,title:s.querySelector('h1,h2').textContent,contentBottom:s.querySelector('.content').getBoundingClientRect().bottom-s.getBoundingClientRect().top,footerTop:s.querySelector('footer').getBoundingClientRect().top-s.getBoundingClientRect().top,width:s.scrollWidth,height:s.scrollHeight}))`);
  if(geometry.length!==15)throw Error('Unexpected page: '+await evaluate('document.documentElement.outerHTML'));
  if(geometry.some(s=>s.contentBottom>s.footerTop-8||s.width>1200||s.height>675))throw Error('Slide clipping: '+JSON.stringify(geometry));
  await evaluate(await readFile(resolve(root,'node_modules/axe-core/axe.min.js'),'utf-8'));
  const a11y=await evaluate(`axe.run(document,{runOnly:{type:'tag',values:['wcag2a','wcag2aa','wcag21aa']}}).then(r=>r.violations.map(v=>({id:v.id,impact:v.impact,nodes:v.nodes.map(n=>({html:n.html,summary:n.failureSummary}))})))`);
  if(a11y.length)throw Error('Accessibility: '+JSON.stringify(a11y));
  const print=await send('Page.printToPDF',{printBackground:true,preferCSSPageSize:true,displayHeaderFooter:false,generateTaggedPDF:true,generateDocumentOutline:true});
  await writeFile(resolve(out,'demokrscanstvo-12-nalaza.pdf'),Buffer.from(print.data,'base64'));
  const first=await evaluate(`(()=>{const r=document.querySelector('.slide').getBoundingClientRect();return {x:r.x,y:r.y+scrollY,width:r.width,height:r.height,scale:1}})()`);
  const cover=await send('Page.captureScreenshot',{format:'png',captureBeyondViewport:true,clip:first});await writeFile(resolve(qa,'cover.png'),Buffer.from(cover.data,'base64'));
  await evaluate(`document.querySelector('#mode').click();true`);
  await send('Input.dispatchKeyEvent',{type:'keyDown',key:'ArrowRight',code:'ArrowRight',windowsVirtualKeyCode:39});
  let keyboard=await evaluate(`document.querySelector('#slajd-2').classList.contains('active')&&document.activeElement.id==='slajd-2'`);
  await send('Input.dispatchKeyEvent',{type:'keyDown',key:'Escape',code:'Escape',windowsVirtualKeyCode:27});
  keyboard=keyboard&&await evaluate(`!document.body.classList.contains('present')&&document.activeElement.id==='mode'`);
  if(!keyboard)throw Error('Keyboard check failed');
  const mobile=[];
  for(const width of [320,390,768]){
    await send('Emulation.setDeviceMetricsOverride',{width,height:844,deviceScaleFactor:1,mobile:false});
    const layout=await evaluate(`({width:innerWidth,scrollWidth:document.documentElement.scrollWidth,clipping:Array.from(document.querySelectorAll('.slide')).filter(s=>s.querySelector('.content').getBoundingClientRect().bottom>s.querySelector('footer').getBoundingClientRect().top-8).map(s=>s.id)})`);
    mobile.push(layout);if(layout.scrollWidth>width||layout.clipping.length)throw Error('Mobile clipping: '+JSON.stringify(layout));
  }
  const result={status:'PASS',slides:geometry.length,geometry,accessibility:a11y,keyboard,mobile,errors};
  if(errors.length)throw Error('Browser exception');
  await writeFile(resolve(out,'browser-verification.json'),JSON.stringify(result,null,2));
  console.log(JSON.stringify({status:'PASS',slides:geometry.length,accessibilityViolations:0,keyboard,mobile}));
}finally{if(socket)socket.close();chrome.kill();server.close();}
