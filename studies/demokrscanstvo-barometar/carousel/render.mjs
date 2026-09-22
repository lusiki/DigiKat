// Render the same semantic HTML to PDF and check its reading/presentation modes.
import {createServer} from 'node:http';
import {spawn} from 'node:child_process';
import {readFile,writeFile,mkdtemp,mkdir} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
import {tmpdir} from 'node:os';
const root=process.cwd(),out=resolve(root,process.argv[2]||'output/demokrscanstvo-carousel');
const stem=process.argv[3]||'demokrscanske-vrijednosti-karusel';
const qa=resolve(root,process.argv[4]||'tmp/pdfs/demokrscanstvo-carousel');await mkdir(qa,{recursive:true});
const mime={'.html':'text/html; charset=utf-8','.js':'application/javascript','.css':'text/css'};
const server=createServer(async(req,res)=>{try{const p=resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname));if(!p.startsWith(root+sep))throw Error('path');res.setHeader('Content-Type',mime[extname(p)]||'application/octet-stream');res.end(await readFile(p));}catch{res.writeHead(404).end();}});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const profile=await mkdtemp(resolve(tmpdir(),'digikat-carousel-'));
const chrome=spawn(process.env.CHROME_PATH||'C:/Program Files/Google/Chrome/Application/chrome.exe',['--headless=new','--disable-gpu','--no-first-run','--no-default-browser-check','--disable-background-networking','--remote-debugging-port=9338',`--user-data-dir=${profile}`,'about:blank'],{stdio:'ignore',windowsHide:true});
const sleep=ms=>new Promise(r=>setTimeout(r,ms));let socket;
try{
  let tabs;for(let i=0;i<100;i++){try{tabs=await(await fetch('http://127.0.0.1:9338/json')).json();break;}catch{await sleep(100);}}
  const tab=tabs?.find(t=>t.type==='page'&&t.url==='about:blank');if(!tab)throw Error('Cannot start headless Chrome');
  socket=new WebSocket(tab.webSocketDebuggerUrl);await new Promise(r=>socket.addEventListener('open',r,{once:true}));
  let id=0;const pending=new Map(),errors=[];
  socket.addEventListener('message',e=>{const m=JSON.parse(e.data);if(m.id){const p=pending.get(m.id);pending.delete(m.id);if(m.error)p.reject(Error(m.error.message));else p.resolve(m.result);}else if(m.method==='Runtime.exceptionThrown')errors.push(m.params);});
  const send=(method,params={})=>new Promise((resolve,reject)=>{const n=++id;pending.set(n,{resolve,reject});socket.send(JSON.stringify({id:n,method,params}));});
  const evaluate=async expression=>{const r=await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(JSON.stringify(r.exceptionDetails));return r.result.value;};
  await send('Page.enable');await send('Runtime.enable');
  await send('Emulation.setDeviceMetricsOverride',{width:1600,height:1000,deviceScaleFactor:1,mobile:false});
  const outputPath=out.slice(root.length).split(sep).join('/');
  await send('Page.navigate',{url:`http://127.0.0.1:${server.address().port}${outputPath}/${stem}.html`});
  for(let i=0;i<100;i++){if(await evaluate(`document.querySelectorAll('.slide').length===18`))break;await sleep(100);}
  await evaluate('document.fonts.ready.then(()=>true)');
  const geometry=await evaluate(`Array.from(document.querySelectorAll('.slide')).map(s=>({id:s.id,title:(s.querySelector('h1,h2')||s).textContent,contentBottom:s.querySelector('.content').getBoundingClientRect().bottom-s.getBoundingClientRect().top,footerTop:s.querySelector('footer').getBoundingClientRect().top-s.getBoundingClientRect().top,width:s.scrollWidth,height:s.scrollHeight}))`);
  await writeFile(resolve(out,'geometry.json'),JSON.stringify(geometry,null,2));
  if(geometry.length!==18)throw Error('Unexpected slide count');
  const clipping=geometry.filter(s=>s.contentBottom>s.footerTop-12||s.width>1440||s.height>810);
  // Save the draft even if a check fails so the defect can be inspected.
  const print=await send('Page.printToPDF',{printBackground:true,preferCSSPageSize:true,displayHeaderFooter:false,generateTaggedPDF:true,generateDocumentOutline:true});
  await writeFile(resolve(out,stem+'.pdf'),Buffer.from(print.data,'base64'));
  for(let i=1;i<=18;i++){
    const clip=await evaluate(`(()=>{const r=document.querySelector('#slajd-${i}').getBoundingClientRect();return {x:r.x,y:r.y+scrollY,width:r.width,height:r.height,scale:1}})()`);
    const png=await send('Page.captureScreenshot',{format:'png',captureBeyondViewport:true,clip});
    await writeFile(resolve(qa,`browser-${String(i).padStart(2,'0')}.png`),Buffer.from(png.data,'base64'));
  }
  if(clipping.length)throw Error('Slide clipping: '+JSON.stringify(clipping));
  await evaluate(await readFile(resolve(root,'node_modules/axe-core/axe.min.js'),'utf-8'));
  const a11y=await evaluate(`axe.run(document,{runOnly:{type:'tag',values:['wcag2a','wcag2aa','wcag21aa']}}).then(r=>r.violations.map(v=>({id:v.id,impact:v.impact,nodes:v.nodes.map(n=>({html:n.html,summary:n.failureSummary}))})))`);
  if(a11y.length)throw Error('Accessibility: '+JSON.stringify(a11y));
  await evaluate(`document.querySelector('#mode').click();true`);
  await send('Input.dispatchKeyEvent',{type:'keyDown',key:'ArrowRight',code:'ArrowRight',windowsVirtualKeyCode:39});
  let keyboard=await evaluate(`document.querySelector('#slajd-2').classList.contains('active')&&document.activeElement.id==='slajd-2'`);
  await send('Input.dispatchKeyEvent',{type:'keyDown',key:'End',code:'End',windowsVirtualKeyCode:35});
  keyboard=keyboard&&await evaluate(`document.querySelector('#slajd-18').classList.contains('active')`);
  await send('Input.dispatchKeyEvent',{type:'keyDown',key:'Escape',code:'Escape',windowsVirtualKeyCode:27});
  keyboard=keyboard&&await evaluate(`!document.body.classList.contains('present')&&document.activeElement.id==='mode'`);
  if(!keyboard)throw Error('Keyboard check failed');
  const mobile=[];
  for(const width of [320,390,768,1024]){
    await send('Emulation.setDeviceMetricsOverride',{width,height:844,deviceScaleFactor:1,mobile:false});
    const layout=await evaluate(`({width:innerWidth,scrollWidth:document.documentElement.scrollWidth,clipping:Array.from(document.querySelectorAll('.slide')).filter(s=>s.querySelector('.content').getBoundingClientRect().bottom>s.querySelector('footer').getBoundingClientRect().top-8).map(s=>s.id)})`);
    mobile.push(layout);if(layout.scrollWidth>width||layout.clipping.length)throw Error('Mobile clipping: '+JSON.stringify(layout));
  }
  const result={status:'PASS',slides:geometry.length,geometry,accessibility:a11y,keyboard,mobile,errors};
  if(errors.length)throw Error('Browser exception');
  await writeFile(resolve(out,'browser-verification.json'),JSON.stringify(result,null,2));
  console.log(JSON.stringify({status:'PASS',slides:geometry.length,accessibilityViolations:0,keyboard,mobile}));
}finally{if(socket)socket.close();chrome.kill();server.close();}
