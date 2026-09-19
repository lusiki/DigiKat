/* Aggregate-only thematic explorer; the same fixed model serves every filter. */
(function () {
  "use strict";
  const selectRows = (rows, platform = "all", year = "all") => rows.filter(row =>
    (platform === "all" || row.platform === platform) && (year === "all" || row.month.startsWith(year + "-")));
  function summarize(rows, topics, platform = "all", year = "all") {
    const selected = selectRows(rows, platform, year), counts = new Map();
    let total = 0;
    selected.forEach(row => { total += row.records; counts.set(row.topic, (counts.get(row.topic) || 0) + row.records); });
    return {total, rows:selected, topics:topics.map(topic => ({...topic, records:counts.get(topic.id) || 0,
      share:total ? 100 * (counts.get(topic.id) || 0) / total : null}))
      .sort((a,b) => b.records - a.records || a.id.localeCompare(b.id))};
  }
  function distribution(rows, topic, field) {
    const counts = new Map();
    rows.filter(row => row.topic === topic).forEach(row => {
      const key = field === "year" ? row.month.slice(0,4) : row[field];
      counts.set(key, (counts.get(key) || 0) + row.records);
    });
    return [...counts].map(([key,records]) => ({key,records})).sort((a,b) => b.records-a.records || a.key.localeCompare(b.key));
  }
  if (typeof module !== "undefined" && module.exports) module.exports = {selectRows, summarize, distribution};
  if (typeof document === "undefined") return;
  const payload = document.getElementById("mt-data");
  if (!payload) return;
  const data = JSON.parse(payload.textContent);
  const platform = document.getElementById("mt-platform"), year = document.getElementById("mt-year");
  const list = document.getElementById("mt-topics"), detail = document.getElementById("mt-detail");
  const status = document.getElementById("mt-status");
  const fmt = (n, digits = 0) => Number(n).toLocaleString("hr-HR", {minimumFractionDigits:digits,maximumFractionDigits:digits});
  const percent = n => n > 0 && n < .1 ? "< 0,1" : fmt(n,1);
  const el = (tag, className, text) => {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  };
  Object.entries(data.platform_labels).sort((a,b) => a[1].localeCompare(b[1],"hr")).forEach(([id,label]) => {
    const option=el("option",null,label); option.value=id; platform.append(option);
  });
  [...new Set(data.monthly.map(row => row.month.slice(0,4)))].sort().forEach(value => {
    const option=el("option",null,value === data.data_through.slice(0,4)
      ? `${value}. (do ${data.data_through.slice(8,10)}. ${Number(data.data_through.slice(5,7))}.)` : value+".");
    option.value=value; year.append(option);
  });
  let active = null, state;
  function renderDetail(announce = false) {
    detail.replaceChildren();
    const topic = state.topics.find(item => item.id === active);
    list.querySelectorAll("button").forEach(button => button.setAttribute("aria-pressed",String(button.dataset.topic === active)));
    if (!topic || !state.total) {
      detail.append(el("h3",null,"Nema objava u odabranom razdoblju"),
        el("p",null,"Druga platforma ili šire razdoblje otvara pripadajuće teme."));
      return;
    }
    detail.append(el("p","dkb-kicker","Odabrana tema"),el("h3",null,topic.label),el("p",null,topic.editorial_note));
    const count=el("p","dkb-topic-count");
    count.append(el("strong","dkb-mono",fmt(topic.records)),document.createTextNode(` objava · ${percent(topic.share)} % odabranog skupa`));
    detail.append(count);
    if (topic.terms.length) {
      detail.append(el("h4",null,"Riječi koje povezuju objave"));
      const words=el("ul","dkb-topic-words");
      topic.terms.slice(0,6).forEach(term=>words.append(el("li",null,term)));
      detail.append(words);
    }
    if (topic.records) {
      detail.append(el("h4",null,"Objave po platformama"));
      const platforms=distribution(state.rows,topic.id,"platform");
      const table=el("table","dkb-topic-platforms");
      const caption=el("caption","visually-hidden",`${topic.label} — broj objava po platformama`);
      table.append(caption);
      const head=table.createTHead().insertRow();
      ["Platforma","Objave"].forEach(label=>{const cell=el("th",null,label);cell.scope="col";head.append(cell);});
      const body=table.createTBody();
      platforms.forEach(row=>{
        const tr=body.insertRow(),name=el("th",null,data.platform_labels[row.key]);name.scope="row";
        const cell=el("td",null,fmt(row.records));tr.append(name,cell);
      });
      detail.append(table);
      const years=distribution(state.rows,topic.id,"year");
      if (year.value === "all" && years.length) detail.append(el("p","dkb-status",
        `Najviše objava ove teme: ${years[0].key}. (${fmt(years[0].records)}).`));
    } else detail.append(el("p",null,"Ova tema nema objava u odabranom skupu."));
    const back=el("a","dkb-topic-back","Natrag na popis tema");back.href="#mt-topics";detail.append(back);
    if (announce) status.textContent = `${platform.selectedOptions[0].textContent} · ${year.selectedOptions[0].textContent}. ${topic.label}: ${fmt(topic.records)} objava, ${percent(topic.share)} % odabranog skupa.`;
  }
  function render() {
    state=summarize(data.monthly,data.topics,platform.value,year.value);
    const current=state.topics.find(topic=>topic.id===active);
    if (!current?.records) active=state.topics.find(topic=>topic.records)?.id || null;
    status.textContent=`${platform.selectedOptions[0].textContent} · ${year.selectedOptions[0].textContent} · ${fmt(state.total)} objava. Udjeli su izračunani unutar ovog odabira.`;
    list.replaceChildren();
    if (!state.total) list.append(el("p","dkb-empty","Za ovaj odabir nema uključenih objava."));
    else state.topics.forEach(topic=>{
      if (!topic.records) return;
      const button=el("button","dkb-topic-button");button.type="button";button.dataset.topic=topic.id;
      button.setAttribute("aria-controls","mt-detail");
      button.setAttribute("aria-label",`${topic.label}: ${fmt(topic.records)} objava, ${percent(topic.share)} posto`);
      const heading=el("span","dkb-topic-button-heading");
      heading.append(el("span",null,topic.label),el("span","dkb-mono",`${fmt(topic.records)} · ${percent(topic.share)} %`));
      const track=el("span","dkb-topic-track"),bar=el("span","dkb-topic-bar");
      track.setAttribute("aria-hidden","true");bar.style.width=topic.share+"%";track.append(bar);
      button.append(heading,track);
      button.addEventListener("click",()=>{
        active=topic.id;renderDetail(true);
        if(window.matchMedia("(max-width:740px)").matches)detail.scrollIntoView({block:"start",behavior:"instant"});
      });
      list.append(button);
    });
    renderDetail();
  }
  platform.addEventListener("change",render); year.addEventListener("change",render);
  document.getElementById("mt-reset").addEventListener("click",()=>{platform.value="all";year.value="all";active=null;render();});
  // Reveal enhanced UI only after the first complete render succeeds.
  render();
  document.getElementById("mt-controls").hidden=false;
  document.getElementById("mt-interactive").hidden=false;
  document.getElementById("mt-static").hidden=true;
})();
