"use strict";

(() => {
  const DATA = window.ANALYSIS_RESULTS;
  const error = document.querySelector("#data-error");
  if (!DATA) {
    if (error) error.hidden = false;
    throw new Error("ANALYSIS_RESULTS is missing. Run analysis.R before opening the report.");
  }

  const requiredArrays = [
    "actors", "actorTotals", "themes", "actorShares", "themeByActor", "categoryGap",
    "sharpByActor", "toneRikByThemeActor", "dailyZ", "peakEvents",
    "peakRows", "eventComposition", "rhythmEffects"
  ];
  const missing = requiredArrays.filter(key => !Array.isArray(DATA[key]) || DATA[key].length === 0);
  if (missing.length) {
    if (error) error.hidden = false;
    throw new Error(`Incomplete analysis data: ${missing.join(", ")}`);
  }

  const NS = "http://www.w3.org/2000/svg";
  const HR0 = new Intl.NumberFormat("hr-HR", { maximumFractionDigits: 0 });
  const HR1 = new Intl.NumberFormat("hr-HR", { minimumFractionDigits: 1, maximumFractionDigits: 1 });
  const HR2 = new Intl.NumberFormat("hr-HR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const HR_DATE = new Intl.DateTimeFormat("hr-HR", { day: "numeric", month: "long", year: "numeric", timeZone: "UTC" });
  const pct = value => `${HR1.format(value)} %`;
  const signed = (value, digits = 1) => {
    const formatter = digits === 2 ? HR2 : HR1;
    if (!Number.isFinite(value)) return "nije izvještajno";
    if (Math.abs(value) < 0.5 * 10 ** -digits) return formatter.format(0);
    return `${value > 0 ? "+" : "−"}${formatter.format(Math.abs(value))}`;
  };
  const short = (text, length = 24) => text.length > length ? `${text.slice(0, length - 1)}…` : text;
  const actorMap = Object.fromEntries(DATA.actors.map(actor => [actor.key, actor]));
  const themeMap = Object.fromEntries(DATA.themes.map(theme => [theme.key, theme]));
  const themeDescriptions = {
    faith: "Molitva, liturgija, sakramenti, duhovnost, teologija i crkveni nauk.",
    institution: "Papa i Vatikan, biskupi, upravljanje Crkvom, financije, misije i život Crkve u svijetu.",
    public_questions: "Politika i država, bioetika, znanost i vjera te društveni i unutarcrkveni prijepori.",
    community: "Karitas i socijalna pravda, mladi, digitalna evangelizacija te dijalog s drugim religijama i pogledima.",
    history_culture: "Crkvena povijest, nacionalni identitet, mediji, umjetnost i kulturna baština.",
    abuse: "Zlostavljanje, odgovornost, istrage i narušeno povjerenje u Crkvu."
  };

  function node(name, attributes = {}, text = null) {
    const element = document.createElementNS(NS, name);
    Object.entries(attributes).forEach(([key, value]) => {
      if (value !== null && value !== undefined) element.setAttribute(key, String(value));
    });
    if (text !== null) element.textContent = text;
    return element;
  }

  function makeSvg(target, width, height, label) {
    target.replaceChildren();
    const image = node("svg", {
      viewBox: `0 0 ${width} ${height}`,
      role: "img",
      "aria-label": label,
      preserveAspectRatio: "xMidYMid meet"
    });
    target.append(image);
    return image;
  }

  function text(parent, x, y, value, attributes = {}) {
    const element = node("text", { x, y, ...attributes }, value);
    parent.append(element);
    return element;
  }

  function line(parent, x1, y1, x2, y2, attributes = {}) {
    parent.append(node("line", { x1, y1, x2, y2, ...attributes }));
  }

  function rect(parent, x, y, width, height, attributes = {}) {
    parent.append(node("rect", { x, y, width, height, ...attributes }));
  }

  function circle(parent, cx, cy, r, attributes = {}) {
    parent.append(node("circle", { cx, cy, r, ...attributes }));
  }

  function setAccessible(id, title, lines) {
    const target = document.querySelector(`#${id}`);
    if (!target) return;
    target.textContent = `${title} ${lines.join(" ")}`;
  }

  function addLegend(svg, items, x, y, columns = items.length) {
    const columnWidth = Math.max(130, 680 / columns);
    items.forEach((item, index) => {
      const column = index % columns;
      const row = Math.floor(index / columns);
      const itemX = x + column * columnWidth;
      const itemY = y + row * 24;
      rect(svg, itemX, itemY - 10, 12, 12, { fill: item.color, rx: 2 });
      text(svg, itemX + 18, itemY, item.label, { class: "svg-legend" });
    });
  }

  function populateSourceGuide() {
    DATA.actorTotals.forEach(actor => {
      const card = document.querySelector(`[data-actor-card="${actor.key}"]`);
      if (card) card.style.setProperty("--actor-color", actor.color);
      const total = document.querySelector(`[data-actor-total="${actor.key}"]`);
      if (total) total.textContent = `${pct(actor.postShare)} svih objava · ${HR0.format(actor.posts)} objava`;
    });
  }

  function populateThemeGuide() {
    const guide = document.querySelector("#theme-guide");
    if (!guide) return;
    guide.replaceChildren();
    const totalPosts = DATA.themeByActor.reduce((sum, row) => sum + Number(row.posts || 0), 0);
    DATA.themes.forEach(theme => {
      const posts = DATA.themeByActor
        .filter(row => row.theme === theme.key)
        .reduce((sum, row) => sum + Number(row.posts || 0), 0);
      const card = document.createElement("div");
      card.style.setProperty("--theme-color", theme.color);
      const swatch = document.createElement("span");
      swatch.className = "theme-guide__swatch";
      swatch.setAttribute("aria-hidden", "true");
      const title = document.createElement("h3");
      title.textContent = theme.label;
      const description = document.createElement("p");
      description.textContent = themeDescriptions[theme.key] || "Široka tema razgovora o Crkvi.";
      const total = document.createElement("strong");
      total.textContent = `${pct(100 * posts / totalPosts)} · ${HR0.format(posts)} objava`;
      card.append(swatch, title, description, total);
      guide.append(card);
    });
  }

  function actorShareChart() {
    const target = document.querySelector("#actor-share-chart");
    const width = 1100;
    const height = 470;
    const svg = makeSvg(target, width, height, "Tko objavljuje o Crkvi i na čije objave publika reagira");
    const panels = [
      { key: "posts", label: "Udio objava" },
      { key: "interactions", label: "Udio reakcija" }
    ];
    const top = 95;
    const bottom = 60;
    const panelWidth = 470;
    const panelGap = 60;
    const left = 55;
    const chartHeight = height - top - bottom;
    const maxValue = Math.max(60, Math.ceil(Math.max(...DATA.actorShares.flatMap(row => [...row.posts, ...row.interactions])) / 10) * 10);
    addLegend(svg, DATA.actors.map(actor => ({ label: actor.short, color: actor.color })), 70, 34, 4);

    panels.forEach((panel, panelIndex) => {
      const x0 = left + panelIndex * (panelWidth + panelGap);
      text(svg, x0, 78, panel.label, { class: "svg-panel-title" });
      [0, 20, 40, 60, 80].filter(value => value <= maxValue).forEach(value => {
        const y = top + chartHeight - value / maxValue * chartHeight;
        line(svg, x0, y, x0 + panelWidth, y, { class: "svg-grid" });
        text(svg, x0 - 10, y + 4, `${value} %`, { class: "svg-axis", "text-anchor": "end" });
      });
      DATA.actorShares.forEach((row, index) => {
        const x = x0 + index / (DATA.actorShares.length - 1) * panelWidth;
        const label = row.period.startsWith("2026.") ? "2026." : row.period;
        text(svg, x, top + chartHeight + 24, label, { class: "svg-axis", "text-anchor": "middle" });
      });
      DATA.actors.forEach((actor, actorIndex) => {
        const points = DATA.actorShares.map((row, index) => {
          const x = x0 + index / (DATA.actorShares.length - 1) * panelWidth;
          const y = top + chartHeight - row[panel.key][actorIndex] / maxValue * chartHeight;
          return [x, y, row[panel.key][actorIndex]];
        });
        svg.append(node("polyline", {
          points: points.map(point => `${point[0]},${point[1]}`).join(" "),
          fill: "none",
          stroke: actor.color,
          "stroke-width": 3,
          "stroke-linejoin": "round",
          "stroke-linecap": "round"
        }));
        points.forEach(point => {
          circle(svg, point[0], point[1], 4.5, { fill: actor.color, stroke: "#fff", "stroke-width": 2 });
          const title = node("title", {}, `${actor.label}. ${pct(point[2])}`);
          svg.lastChild.append(title);
        });
      });
    });
    setAccessible(
      "actor-share-data",
      "Udio objava i reakcija.",
      DATA.actorShares.flatMap(row => DATA.actors.map((actor, index) =>
        `${row.period} ${actor.label}. Objave ${pct(row.posts[index])}. Reakcije ${pct(row.interactions[index])}.`
      ))
    );
  }

  function themeByActorChart() {
    const target = document.querySelector("#theme-by-actor-chart");
    const width = 1120;
    const height = 760;
    const svg = makeSvg(target, width, height, "Teme koje bira svaka skupina izvora");
    const globalMax = Math.ceil(Math.max(...DATA.themeByActor.map(row => row.share)) / 10) * 10;
    const panelWidth = 530;
    const panelHeight = 330;
    const left = 25;
    const top = 35;
    const barLeft = 205;
    const barWidth = 290;
    DATA.actors.forEach((actor, actorIndex) => {
      const col = actorIndex % 2;
      const rowIndex = Math.floor(actorIndex / 2);
      const x0 = left + col * (panelWidth + 25);
      const y0 = top + rowIndex * (panelHeight + 35);
      text(svg, x0, y0, actor.label, { class: "svg-panel-title" });
      const rows = DATA.themeByActor.filter(row => row.actor_group === actor.key);
      rows.forEach((row, index) => {
        const y = y0 + 38 + index * 43;
        text(svg, x0 + barLeft - 12, y + 13, short(row.label, 29), { class: "svg-category", "text-anchor": "end" });
        rect(svg, x0 + barLeft, y, barWidth, 18, { fill: "#edf0ee", rx: 3 });
        rect(svg, x0 + barLeft, y, row.share / globalMax * barWidth, 18, { fill: row.color, rx: 3 });
        text(svg, x0 + barLeft + row.share / globalMax * barWidth + 7, y + 14, pct(row.share), { class: "svg-value" });
      });
      line(svg, x0 + barLeft, y0 + 31, x0 + barLeft, y0 + 291, { class: "svg-axis-line" });
      text(svg, x0 + barLeft, y0 + 310, "0 %", { class: "svg-axis", "text-anchor": "middle" });
      text(svg, x0 + barLeft + barWidth, y0 + 310, `${globalMax} %`, { class: "svg-axis", "text-anchor": "middle" });
    });
    setAccessible(
      "theme-by-actor-data",
      "Teme po skupinama izvora.",
      DATA.themeByActor.map(row => `${actorMap[row.actor_group].label}. ${row.label}. ${pct(row.share)}.`)
    );
  }

  function categoryGapChart() {
    const target = document.querySelector("#category-gap-chart");
    const rows = [...DATA.categoryGap].sort((a, b) => Math.abs(b.gap) - Math.abs(a.gap)).slice(0, 8);
    const width = 1030;
    const height = 510;
    const svg = makeSvg(target, width, height, "Teme koje češće biraju katolički i ostali javni izvori");
    const left = 320;
    const right = 70;
    const top = 70;
    const bottom = 45;
    const plotWidth = width - left - right;
    const zero = left + plotWidth / 2;
    const maxGap = Math.max(5, Math.ceil(Math.max(...rows.map(row => Math.abs(row.gap))) / 5) * 5);
    text(svg, left, 30, "Češće u katoličkim izvorima", { class: "svg-side-label" });
    text(svg, width - right, 30, "Češće u ostalim javnim izvorima", { class: "svg-side-label", "text-anchor": "end" });
    [-maxGap, -maxGap / 2, 0, maxGap / 2, maxGap].forEach(value => {
      const x = zero + value / (2 * maxGap) * plotWidth;
      line(svg, x, top - 12, x, height - bottom, { class: value === 0 ? "svg-zero" : "svg-grid" });
      text(svg, x, height - 18, HR1.format(Math.abs(value)), { class: "svg-axis", "text-anchor": "middle" });
    });
    rows.forEach((row, index) => {
      const y = top + index * 48;
      const barWidth = Math.abs(row.gap) / (2 * maxGap) * plotWidth;
      const x = row.gap >= 0 ? zero : zero - barWidth;
      const negativeValueFitsInside = row.gap < 0 && barWidth >= 60;
      text(svg, left - 16, y + 16, short(row.label, 40), { class: "svg-category", "text-anchor": "end" });
      rect(svg, x, y, barWidth, 24, { fill: row.gap >= 0 ? "#2f73b8" : "#2f8f6b", rx: 3 });
      text(svg, row.gap >= 0 ? x + barWidth + 8 : negativeValueFitsInside ? x + 8 : x - 8, y + 17, HR1.format(Math.abs(row.gap)), {
        class: negativeValueFitsInside ? "svg-stack-value" : "svg-value",
        "text-anchor": row.gap >= 0 || negativeValueFitsInside ? "start" : "end"
      });
    });
    setAccessible(
      "category-gap-data",
      "Najveće razlike u izboru tema.",
      rows.map(row => row.gap < 0
        ? `${row.label}. Približno ${HR1.format(Math.abs(row.gap))} više na 100 objava u katoličkim izvorima.`
        : `${row.label}. Približno ${HR1.format(Math.abs(row.gap))} više na 100 objava u ostalim javnim izvorima.`)
    );
  }

  function sharpShareChart() {
    const target = document.querySelector("#sharp-share-chart");
    const width = 960;
    const height = 410;
    const svg = makeSvg(target, width, height, "Koliko je oštriji govor čest i koliko reakcija dobiva");
    const left = 285;
    const right = 70;
    const top = 80;
    const plotWidth = width - left - right;
    const maxValue = Math.max(30, Math.ceil(Math.max(...DATA.sharpByActor.flatMap(row => [row.post_share, row.interaction_share])) / 10) * 10);
    addLegend(svg, [
      { label: "Objave", color: "#0f4c5c" },
      { label: "Reakcije", color: "#c47b21" }
    ], left, 32, 2);
    [0, 10, 20, 30, 40, 50].filter(value => value <= maxValue).forEach(value => {
      const x = left + value / maxValue * plotWidth;
      line(svg, x, top - 15, x, height - 45, { class: "svg-grid" });
      text(svg, x, height - 18, `${value} %`, { class: "svg-axis", "text-anchor": "middle" });
    });
    DATA.sharpByActor.forEach((row, index) => {
      const y = top + index * 70;
      text(svg, left - 18, y + 22, actorMap[row.actor_group].label, { class: "svg-category", "text-anchor": "end" });
      rect(svg, left, y, row.post_share / maxValue * plotWidth, 18, { fill: "#0f4c5c", rx: 3 });
      rect(svg, left, y + 25, row.interaction_share / maxValue * plotWidth, 18, { fill: "#c47b21", rx: 3 });
      text(svg, left + row.post_share / maxValue * plotWidth + 7, y + 14, pct(row.post_share), { class: "svg-value" });
      text(svg, left + row.interaction_share / maxValue * plotWidth + 7, y + 39, pct(row.interaction_share), { class: "svg-value" });
    });
    setAccessible(
      "sharp-share-data",
      "Oštriji govor po skupinama.",
      DATA.sharpByActor.map(row => `${actorMap[row.actor_group].label}. Objave ${pct(row.post_share)}. Reakcije ${pct(row.interaction_share)}.`)
    );
  }

  function mixColor(a, b, amount) {
    const parse = color => color.match(/[a-f\d]{2}/gi).map(value => parseInt(value, 16));
    const left = parse(a);
    const right = parse(b);
    const rgb = left.map((value, index) => Math.round(value + (right[index] - value) * amount));
    return `#${rgb.map(value => value.toString(16).padStart(2, "0")).join("")}`;
  }

  function toneColor(value, limit) {
    if (!Number.isFinite(value)) return "#e6e5e1";
    const strength = Math.min(1, Math.abs(value) / limit);
    return value >= 0 ? mixColor("#f7f4ee", "#2f8f6b", strength) : mixColor("#f7f4ee", "#b5462f", strength);
  }

  function toneRikChart() {
    const target = document.querySelector("#tone-rik-chart");
    const width = 1080;
    const height = 570;
    const svg = makeSvg(target, width, height, "Ton objava i jezik sukoba po temama i skupinama izvora");
    const left = 280;
    const top = 108;
    const cellWidth = 185;
    const cellHeight = 62;
    const observedTone = DATA.toneRikByThemeActor.filter(row => row.reportable).map(row => Math.abs(row.tone));
    const toneLimit = Math.max(0.05, Math.max(...observedTone));
    DATA.actors.forEach((actor, index) => {
      const x = left + index * cellWidth + cellWidth / 2;
      const words = actor.short.split(" ");
      text(svg, x, 64, words.slice(0, 2).join(" "), { class: "svg-column-title", "text-anchor": "middle" });
      text(svg, x, 82, words.slice(2).join(" "), { class: "svg-column-title", "text-anchor": "middle" });
    });
    DATA.themes.forEach((theme, themeIndex) => {
      const y = top + themeIndex * cellHeight;
      text(svg, left - 18, y + 34, short(theme.label, 35), { class: "svg-category", "text-anchor": "end" });
      DATA.actors.forEach((actor, actorIndex) => {
        const row = DATA.toneRikByThemeActor.find(item => item.theme === theme.key && item.actor_group === actor.key);
        const x = left + actorIndex * cellWidth;
        rect(svg, x + 2, y + 2, cellWidth - 5, cellHeight - 5, {
          fill: toneColor(row?.tone, toneLimit),
          stroke: "#fff",
          "stroke-width": 2,
          rx: 4
        });
        text(svg, x + cellWidth / 2, y + 38, row?.reportable ? signed(row.rik, 1) : "—", {
          class: "svg-heat-value",
          "text-anchor": "middle"
        });
      });
    });
    const legendX = left;
    const legendY = height - 55;
    [-1, -0.5, 0, 0.5, 1].forEach((position, index) => {
      rect(svg, legendX + index * 58, legendY, 58, 13, { fill: toneColor(position * toneLimit, toneLimit) });
    });
    text(svg, legendX, legendY + 32, "negativnije riječi", { class: "svg-axis" });
    text(svg, legendX + 290, legendY + 32, "pozitivnije riječi", { class: "svg-axis", "text-anchor": "end" });
    text(svg, legendX + 380, legendY + 20, "Broj: + više, − manje riječi sukoba", { class: "svg-note" });
    setAccessible(
      "tone-rik-data",
      "Ton riječi i jezik sukoba po temama i skupinama.",
      DATA.toneRikByThemeActor.map(row => row.reportable
        ? `${row.theme_label}. ${row.actor_label}. Ton riječi ${signed(row.tone, 2)}. Jezik sukoba ${signed(row.rik, 1)}. Na temelju ${HR0.format(row.n)} objava.`
        : `${row.theme_label}. ${row.actor_label}. Premalo objava za usporedbu.`)
    );
  }

  function peakCalendarChart() {
    const target = document.querySelector("#peak-calendar-chart");
    const width = 1140;
    const height = 630;
    const svg = makeSvg(target, width, height, "Dani kada se o Crkvi najviše objavljivalo od 2021. do 2026.");
    const left = 90;
    const right = 35;
    const top = 70;
    const rowHeight = 86;
    const plotWidth = width - left - right;
    const maxZ = Math.max(6, Math.max(...DATA.peakEvents.map(event => event.amplitude)));
    addLegend(svg, [
      { label: "Veliki blagdan", color: DATA.eventTypes.liturgical.color },
      { label: "Papinski događaj", color: DATA.eventTypes.papal.color },
      { label: "Drugi veliki porast", color: DATA.eventTypes.other.color }
    ], left, 27, 3);
    const monthStarts = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    const monthLabels = ["sij", "velj", "ožu", "tra", "svi", "lip", "srp", "kol", "ruj", "lis", "stu", "pro"];
    DATA.dailyZ.forEach((yearRow, yearIndex) => {
      const yBase = top + yearIndex * rowHeight + 51;
      text(svg, left - 20, yBase + 4, `${yearRow.year}.`, { class: "svg-year", "text-anchor": "end" });
      line(svg, left, yBase, left + plotWidth, yBase, { class: "svg-axis-line" });
      monthStarts.forEach((day, index) => {
        const x = left + day / 365 * plotWidth;
        line(svg, x, yBase - 36, x, yBase + 5, { class: "svg-grid" });
        if (yearIndex === DATA.dailyZ.length - 1) text(svg, x + 2, yBase + 24, monthLabels[index], { class: "svg-axis" });
      });
      const points = yearRow.values.map((value, day) => {
        if (!Number.isFinite(value)) return null;
        const x = left + day / (yearRow.values.length - 1) * plotWidth;
        const y = yBase - Math.min(value, maxZ) / maxZ * 42;
        return [x, y];
      }).filter(Boolean);
      let segment = [];
      const flush = () => {
        if (segment.length > 1) svg.append(node("polyline", {
          points: segment.map(point => point.join(",")).join(" "),
          fill: "none", stroke: "#8ba0a6", "stroke-width": 1.4
        }));
        segment = [];
      };
      yearRow.values.forEach((value, day) => {
        if (!Number.isFinite(value)) return flush();
        segment.push([left + day / (yearRow.values.length - 1) * plotWidth, yBase - Math.min(value, maxZ) / maxZ * 42]);
      });
      flush();
      DATA.peakEvents.filter(event => event.year === yearRow.year).forEach(event => {
        const x = left + event.index / (yearRow.values.length - 1) * plotWidth;
        const y = yBase - Math.min(event.amplitude, maxZ) / maxZ * 42;
        const definition = DATA.eventTypes[event.type] || DATA.eventTypes.other;
        circle(svg, x, y, event.type === "other" ? 3.5 : 5, { fill: definition.color, stroke: "#fff", "stroke-width": 1.5 });
        svg.lastChild.append(node("title", {}, `${event.label}. Dan s neuobičajeno mnogo objava.`));
        if (event.type !== "other") {
          let labelX = x;
          let labelY = y - 10;
          let anchor = "middle";
          if (event.label === "Smrt pape Franje") {
            labelX = x - 8;
            labelY = y - 22;
            anchor = "end";
          } else if (event.label === "Sprovod pape Franje") {
            labelX = x + 8;
            anchor = "start";
          } else if (event.index > 330) {
            labelX = x - 7;
            anchor = "end";
          }
          text(svg, labelX, labelY, event.label, { class: "svg-event-label", "text-anchor": anchor });
        }
      });
    });
    setAccessible(
      "peak-calendar-data",
      "Dani s velikim porastom broja objava.",
      DATA.peakEvents.map(event => `${event.year}. ${event.label}.`)
    );
  }

  function peaksTable() {
    const body = document.querySelector("#peaks-table tbody");
    body.replaceChildren();
    DATA.peakRows.forEach(row => {
      const tr = document.createElement("tr");
      const tone = !Number.isFinite(row.tone_shift)
        ? { label: "Premalo objava", key: "unknown" }
        : row.tone_shift > 0.03
          ? { label: "Pozitivniji", key: "positive" }
          : row.tone_shift < -0.03
            ? { label: "Negativniji", key: "negative" }
            : { label: "Gotovo jednak", key: "same" };
      const values = [
        HR_DATE.format(new Date(`${row.peak_date}T00:00:00Z`)),
        row.event,
        DATA.eventTypes[row.type]?.label || DATA.eventTypes.other.label,
        tone.label
      ];
      values.forEach((value, index) => {
        const cell = document.createElement(index === 0 ? "th" : "td");
        if (index === 0) cell.scope = "row";
        if (index === 2) {
          const pill = document.createElement("span");
          pill.className = `type-pill type-pill--${row.type}`;
          pill.textContent = value;
          cell.append(pill);
        } else if (index === 3) {
          const pill = document.createElement("span");
          pill.className = `tone-shift tone-shift--${tone.key}`;
          pill.textContent = value;
          cell.append(pill);
        } else {
          cell.textContent = value;
        }
        tr.append(cell);
      });
      body.append(tr);
    });
  }

  function eventCompositionChart() {
    const target = document.querySelector("#event-composition-chart");
    const width = 1160;
    const height = 630;
    const svg = makeSvg(target, width, height, "Tko je objavljivao tijekom osam velikih događaja");
    const left = 70;
    const right = 30;
    const top = 122;
    const bottom = 125;
    const plotHeight = height - top - bottom;
    const plotWidth = width - left - right;
    addLegend(svg, DATA.actors.map(actor => ({ label: actor.short, color: actor.color })), left, 30, 4);
    const band = plotWidth / DATA.eventComposition.length;
    const barWidth = Math.min(72, band * 0.7);
    text(svg, left + band / 2, 84, "Cijelo razdoblje", { class: "svg-side-label", "text-anchor": "middle" });
    text(svg, left + band + (plotWidth - band) / 2, 84, "Veliki događaji", { class: "svg-side-label", "text-anchor": "middle" });
    line(svg, left + band, 96, left + band, top + plotHeight, { class: "svg-divider" });
    [0, 25, 50, 75, 100].forEach(value => {
      const y = top + plotHeight - value / 100 * plotHeight;
      line(svg, left, y, left + plotWidth, y, { class: "svg-grid" });
      text(svg, left - 10, y + 4, `${value} %`, { class: "svg-axis", "text-anchor": "end" });
    });
    DATA.eventComposition.forEach((event, eventIndex) => {
      const x = left + eventIndex * band + (band - barWidth) / 2;
      let y = top + plotHeight;
      DATA.actors.forEach(actor => {
        const share = Number(event.shares[actor.key] || 0);
        const segmentHeight = share / 100 * plotHeight;
        y -= segmentHeight;
        rect(svg, x, y, barWidth, segmentHeight, { fill: actor.color, stroke: "#fff", "stroke-width": 0.7 });
        if (segmentHeight > 26) text(svg, x + barWidth / 2, y + segmentHeight / 2 + 4, `${HR0.format(share)} %`, {
          class: "svg-stack-value",
          "text-anchor": "middle"
        });
      });
      const labelX = x + barWidth / 2;
      text(svg, labelX, top + plotHeight + 26, short(event.label, 17), { class: "svg-axis-label", "text-anchor": "middle" });
      text(svg, labelX, top + plotHeight + 44, event.peakDate ? `${event.peakDate.slice(0, 4)}.` : "2021.–2026.", { class: "svg-axis", "text-anchor": "middle" });
    });
    setAccessible(
      "event-composition-data",
      "Udio skupina izvora u cijelom razdoblju i tijekom velikih događaja.",
      DATA.eventComposition.flatMap(event => DATA.actors.map(actor => `${event.label}. ${actor.label}. ${pct(Number(event.shares[actor.key] || 0))}.`))
    );
  }

  function rhythmChart() {
    const target = document.querySelector("#rhythm-chart");
    const width = 960;
    const height = 400;
    const svg = makeSvg(target, width, height, "Promjena broja objava oko velikih blagdana");
    const left = 300;
    const right = 90;
    const top = 70;
    const plotWidth = width - left - right;
    const minObserved = Math.min(0, ...DATA.rhythmEffects.map(row => row.lower));
    const maxObserved = Math.max(0, ...DATA.rhythmEffects.map(row => row.upper));
    const minValue = Math.floor(minObserved / 20) * 20;
    const maxValue = Math.ceil(maxObserved / 20) * 20;
    const scale = value => left + (value - minValue) / (maxValue - minValue) * plotWidth;
    text(svg, scale(minValue), 34, "manje objava", { class: "svg-side-label" });
    text(svg, scale(0), 34, "bez promjene", { class: "svg-side-label", "text-anchor": "middle" });
    text(svg, scale(maxValue), 34, "više objava", { class: "svg-side-label", "text-anchor": "end" });
    const tickStep = Math.max(20, Math.ceil((maxValue - minValue) / 5 / 20) * 20);
    for (let value = minValue; value <= maxValue; value += tickStep) {
      const x = scale(value);
      line(svg, x, top - 20, x, height - 50, { class: value === 0 ? "svg-zero" : "svg-grid" });
      text(svg, x, height - 20, `${signed(value, 1)} %`, { class: "svg-axis", "text-anchor": "middle" });
    }
    DATA.rhythmEffects.forEach((row, index) => {
      const actor = actorMap[row.actor_group];
      const y = top + index * 66;
      text(svg, left - 20, y + 5, actor.label, { class: "svg-category", "text-anchor": "end" });
      line(svg, scale(row.lower), y, scale(row.upper), y, { stroke: actor.color, "stroke-width": 5, "stroke-linecap": "round" });
      circle(svg, scale(row.estimate), y, 7, { fill: actor.color, stroke: "#fff", "stroke-width": 2 });
      text(svg, Math.min(width - 6, scale(row.upper) + 12), y + 5, `${signed(row.estimate, 1)} %`, { class: "svg-value" });
    });
    setAccessible(
      "rhythm-data",
      "Promjena broja objava oko velikih blagdana.",
      DATA.rhythmEffects.map(row => `${actorMap[row.actor_group].label}. ${signed(row.estimate, 1)} %. Mogući raspon od ${signed(row.lower, 1)} % do ${signed(row.upper, 1)} %.`)
    );
  }

  function trendChart() {
    const target = document.querySelector("#trend-chart");
    const width = 980;
    const height = 420;
    const svg = makeSvg(target, width, height, "Udio web-objava crkvenih medija i ustanova po polugodištu");
    const left = 78;
    const right = 35;
    const top = 55;
    const bottom = 70;
    const plotWidth = width - left - right;
    const plotHeight = height - top - bottom;
    const trend = DATA.churchMediaTrend;
    const periods = ["2021. I", "2021. II", "2022. I", "2022. II", "2023. I", "2023. II", "2024. II", "2025. I", "2025. II", "2026. I"];
    const values = [...trend.series.pre, ...trend.series.post];
    trend.yTicks.forEach(value => {
      const y = top + plotHeight - (value - trend.yMin) / (trend.yMax - trend.yMin) * plotHeight;
      line(svg, left, y, left + plotWidth, y, { class: "svg-grid" });
      text(svg, left - 10, y + 4, `${value} %`, { class: "svg-axis", "text-anchor": "end" });
    });
    const xAt = index => left + index / (periods.length - 1) * plotWidth;
    const yAt = value => top + plotHeight - (value - trend.yMin) / (trend.yMax - trend.yMin) * plotHeight;
    periods.forEach((period, index) => {
      text(svg, xAt(index), top + plotHeight + 28, period, { class: "svg-axis", "text-anchor": "middle" });
    });
    const points = values.map((value, index) => [xAt(index), yAt(value), value]);
    svg.append(node("polyline", {
      points: points.map(point => `${point[0]},${point[1]}`).join(" "),
      fill: "none", stroke: "#0f4c5c", "stroke-width": 4, "stroke-linecap": "round", "stroke-linejoin": "round"
    }));
    points.forEach((point, index) => {
      circle(svg, point[0], point[1], 6, { fill: "#0f4c5c", stroke: "#fff", "stroke-width": 2 });
      text(svg, point[0], point[1] - 12, pct(point[2]), {
        class: "svg-value",
        "text-anchor": index === 0 ? "start" : index === points.length - 1 ? "end" : "middle"
      });
    });
    setAccessible("trend-data", "Udio web-objava crkvenih medija i ustanova.", periods.map((period, index) => `${period}. ${pct(values[index])}.`));
  }

  function renderNarrative() {
    document.querySelectorAll("[data-fragment='scope']").forEach(node => { node.textContent = DATA.scope; });
    const headline = Object.fromEntries(DATA.findings.headlineNumbers.map(item => [item.key, item]));
    document.querySelector("#metric-corpus").textContent = HR0.format(DATA.meta.corpusRows);
    document.querySelector("#metric-public-share").textContent = pct(headline.actor_posts.value);
    document.querySelector("#metric-faith-share").textContent = pct(headline.leading_theme.value);
    document.querySelector("#metric-largest-day").textContent = HR0.format(headline.largest_peak.value);

    const verdict = DATA.findings.verdict;
    document.querySelector("#hero-finding-title").textContent = verdict.title;
    document.querySelector("#hero-finding-summary").textContent = verdict.summary;
    document.querySelector("#verdict-title").textContent = verdict.title;
    document.querySelector("#verdict-summary").textContent = [verdict.summary, verdict.estimateNote].filter(Boolean).join(" ");

    const stories = DATA.findings.narrative;
    Object.entries({
      actor: "#story-actor",
      themes: "#story-themes",
      categoryGap: "#story-category-gap",
      sharp: "#story-sharp",
      tone: "#story-tone",
      peaks: "#story-peaks",
      composition: "#story-composition",
      rhythm: "#story-rhythm",
      trend: "#story-trend"
    }).forEach(([key, selector]) => { document.querySelector(selector).textContent = stories[key]; });
    if (DATA.meta.themeFallbackWeb) {
      document.querySelector("#story-themes").textContent += " Ovdje su prikazane web-objave jer na drugim platformama nije bilo dovoljno teksta za jednaku usporedbu.";
    }

    const synthesis = document.querySelector("#synthesis-list");
    synthesis.replaceChildren();
    DATA.findings.synthesis.forEach(sentence => {
      const item = document.createElement("li");
      item.textContent = sentence;
      synthesis.append(item);
    });
    document.querySelector("#capability-sentence").textContent = DATA.findings.capability;

    const method = document.querySelector("#method-description");
    method.textContent = `Analiza razvrstava ${HR0.format(DATA.meta.corpusRows)} objava u četiri skupine izvora i šest širokih tema. Računalna obrada prepoznaje riječi i veće obrasce. Ne može utvrditi namjeru autora ni istinitost pojedine tvrdnje.`;
    const caveats = document.querySelector("#caveat-list");
    caveats.replaceChildren();
    DATA.method.caveats.forEach(value => {
      const item = document.createElement("li");
      item.textContent = value;
      caveats.append(item);
    });
  }

  function renderAll() {
    renderNarrative();
    populateSourceGuide();
    populateThemeGuide();
    actorShareChart();
    themeByActorChart();
    categoryGapChart();
    sharpShareChart();
    toneRikChart();
    peakCalendarChart();
    peaksTable();
    eventCompositionChart();
    rhythmChart();
    trendChart();
    document.querySelectorAll(".chart-frame--scroll, .table-scroll").forEach(region => {
      region.tabIndex = 0;
      region.setAttribute("aria-label", "Pomaknite prikaz vodoravno za cijeli sadržaj.");
    });
    document.documentElement.dataset.analysisReady = "true";
  }

  renderAll();
})();
