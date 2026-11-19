---
toc: false
---

```js
import * as Plot from "npm:@observablehq/plot";
```

```js
const bandasFuente = await FileAttachment("data/montecarlo_bandas.csv").csv({typed: true});
const resumenFuente = await FileAttachment("data/montecarlo_resumen.csv").csv({typed: true});
const conteoFuente = await FileAttachment("data/montecarlo_conteo_pico.csv").csv({typed: true});
const escenariosFuente = await FileAttachment("data/escenarios_resumen.csv").csv({typed: true});
const tgfFuente = await FileAttachment("data/tgf_calculada_vs_dane.csv").csv({typed: true});
const sensibilidadFuente = await FileAttachment("data/sensibilidad_pico.csv").csv({typed: true});
```

```js
const bandas = bandasFuente
  .filter(d => [d.anio, d.p5, d.p50, d.p95, d.dane].every(Number.isFinite))
  .map(d => ({anio: d.anio, p5: d.p5 / 1e6, p50: d.p50 / 1e6, p95: d.p95 / 1e6, dane: d.dane / 1e6}))
  .sort((a, b) => a.anio - b.anio);
const mc = resumenFuente[0];
const conteo = conteoFuente.filter(d => Number.isFinite(d.anio_pico) && Number.isFinite(d.simulaciones)).sort((a, b) => a.anio_pico - b.anio_pico);
const escenarios = escenariosFuente.filter(d => typeof d.escenario === "string" && Number.isFinite(d.anio_pico));
const tgf = tgfFuente.filter(d => Number.isFinite(d.anio) && Number.isFinite(d.tgf_eevv) && Number.isFinite(d.tgf_dane)).sort((a, b) => a.anio - b.anio);
const sens = sensibilidadFuente.filter(d => typeof d.componente === "string" && Number.isFinite(d.desplaza_anios));
if (!bandas.length || !mc || !conteo.length || !escenarios.length || !tgf.length || !sens.length) throw new Error("Faltan datos válidos para la portada.");

const nfPct = new Intl.NumberFormat("es-CO", {style: "percent", minimumFractionDigits: 1, maximumFractionDigits: 1});
const pct = {format: valor => nfPct.format(valor).replace("%", "\u00a0%")};
const dos = new Intl.NumberFormat("es-CO", {minimumFractionDigits: 2, maximumFractionDigits: 2});
const millones = valor => dos.format(valor / 1e6);
const ultimoTgf = tgf[tgf.length - 1];
const picoDane = bandas.reduce((a, d) => d.dane > a.dane ? d : a, bandas[0]);
const picoMediana = bandas.reduce((a, d) => d.p50 > a.p50 ? d : a, bandas[0]);
const anio = d => String(Math.round(d));
```

```js
// Abanico de incertidumbre (gráfico principal)
function abanico(width) {
  return Plot.plot({
    width,
    height: Math.max(260, Math.round(width * 0.5)),
    marginLeft: 36,
    marginBottom: 32,
    marginTop: 14,
    x: {label: null, ticks: [2020, 2030, 2040, 2050, 2060, 2070], tickFormat: anio},
    y: {label: null, grid: true, domain: [42, 58], ticks: [44, 48, 52, 56]},
    marks: [
      Plot.areaY(bandas, {x: "anio", y1: "p5", y2: "p95", fill: "#0B7A6E", fillOpacity: 0.16}),
      Plot.ruleX([2043], {stroke: "#B4532F", strokeDasharray: "4,4", strokeWidth: 1.5}),
      Plot.line(bandas, {x: "anio", y: "dane", stroke: "#5B6B7C", strokeWidth: 2, strokeDasharray: "6,5"}),
      Plot.line(bandas, {x: "anio", y: "p50", stroke: "#0B7A6E", strokeWidth: 3}),
      Plot.dot([picoMediana], {x: "anio", y: "p50", r: 6, fill: "#0B7A6E", stroke: "white", strokeWidth: 2.5}),
      Plot.dot([picoDane], {x: "anio", y: "dane", r: 5.5, fill: "#5B6B7C", stroke: "white", strokeWidth: 2.5}),
      Plot.link([{x1: picoMediana.anio, y1: picoMediana.p50 - 0.5, x2: picoMediana.anio, y2: 50.9}], {x1: "x1", y1: "y1", x2: "x2", y2: "y2", stroke: "#0B7A6E", strokeWidth: 1.25}),
      Plot.text([{x: picoMediana.anio, y: 50.3, t: `Mediana · máximo en ${picoMediana.anio}`}], {x: "x", y: "y", text: "t", textAnchor: "middle", fill: "#0B6258", fontWeight: 650, fontSize: 12.5}),
      Plot.text([picoDane], {x: "anio", y: "dane", text: d => `DANE · ${d.anio} · ${dos.format(d.dane)} M`, dx: 12, dy: -12, textAnchor: "start", fill: "#3E4A56", fontWeight: 650, fontSize: 12.5, stroke: "white", strokeWidth: 4, paintOrder: "stroke"}),
      Plot.tip(bandas, Plot.pointerX({
        x: "anio",
        y: "p50",
        title: d => `${d.anio}\nP5: ${dos.format(d.p5)} M\nMediana: ${dos.format(d.p50)} M\nP95: ${dos.format(d.p95)} M\nDANE: ${dos.format(d.dane)} M`
      }))
    ]
  });
}

// Mini: fecundidad registrada vs DANE
function miniFecundidad(width) {
  return Plot.plot({
    width,
    height: 110,
    margin: 6,
    marginRight: 44,
    x: {axis: null, domain: [2018, 2025]},
    y: {axis: null, domain: [0.9, 2]},
    marks: [
      Plot.line(tgf, {x: "anio", y: "tgf_dane", stroke: "#5B6B7C", strokeWidth: 2, strokeDasharray: "5,4"}),
      Plot.line(tgf, {x: "anio", y: "tgf_eevv", stroke: "#B4532F", strokeWidth: 2.8, strokeLinecap: "round"}),
      Plot.dot([ultimoTgf], {x: "anio", y: "tgf_eevv", r: 4, fill: "#B4532F"}),
      Plot.text([ultimoTgf], {x: "anio", y: "tgf_eevv", text: d => dos.format(d.tgf_eevv), dx: 8, textAnchor: "start", fill: "#B4532F", fontWeight: 650, fontSize: 12}),
      Plot.text([ultimoTgf], {x: "anio", y: "tgf_dane", text: d => dos.format(d.tgf_dane), dx: 8, textAnchor: "start", fill: "#3E4A56", fontWeight: 650, fontSize: 12})
    ]
  });
}

// Mini: histograma del año del máximo
function miniHistograma(width) {
  const datos = conteo.filter(d => d.anio_pico >= 2032 && d.anio_pico <= 2050);
  return Plot.plot({
    width,
    height: 120,
    marginTop: 6,
    marginBottom: 22,
    marginLeft: 6,
    marginRight: 6,
    x: {type: "band", label: null, tickSize: 0, tickFormat: d => [2032, 2040, 2043, 2050].includes(d) ? String(d) : ""},
    y: {axis: null},
    marks: [
      Plot.barY(datos, {x: "anio_pico", y: "simulaciones", fill: d => d.anio_pico < 2043 ? "#0B7A6E" : d.anio_pico === 2043 ? "#B4532F" : "#A9B4BE", rx: 2,
        title: d => `${d.anio_pico}: ${d.simulaciones.toLocaleString("es-CO")} simulaciones`, tip: true}),
      Plot.ruleY([0], {stroke: "#C9C6BC"})
    ]
  });
}

// Mini: desplazamiento del máximo por componente
function miniSensibilidad(width) {
  const filas = [...new Set(sens.map(d => d.componente))].map(componente => {
    const v = sens.filter(d => d.componente === componente).map(d => d.desplaza_anios);
    return {componente: componente.split(" (")[0], min: Math.min(...v), max: Math.max(...v)};
  });
  return Plot.plot({
    width,
    height: 110,
    marginLeft: 76,
    marginTop: 4,
    marginBottom: 22,
    marginRight: 10,
    x: {label: null, domain: [-9, 6], ticks: [-8, -4, 0, 4], tickFormat: d => d > 0 ? `+${d}` : String(d).replace("-", "−")},
    y: {label: null, domain: filas.map(d => d.componente), tickSize: 0},
    marks: [
      Plot.ruleX([0], {stroke: "#C9C6BC"}),
      Plot.ruleY(filas, {y: "componente", x1: "min", x2: "max", stroke: (d, i) => i === 0 ? "#B4532F" : "#0B7A6E", strokeWidth: 9, strokeLinecap: "round"})
    ]
  });
}
```

<div class="hero">
  <div class="hero-copy">
    <p class="eyebrow">Investigación · Población y futuro</p>
    <h1>¿Qué tan firme es el pico de población de 2043?</h1>
    <p class="hero-lead">El DANE proyecta que Colombia alcanzará su máximo en 2043. Con los nacimientos registrados, en <strong>3 de cada 4 simulaciones</strong> ese máximo llega antes.</p>
    <div class="hero-actions">
      <a class="btn btn-primary" href="./incertidumbre">Ver incertidumbre →</a>
      <a class="btn btn-ghost" href="./fecundidad">Ver fecundidad</a>
    </div>
    <p class="hero-meta">Proyección DANE 2018–2070 · ${Number(mc.n).toLocaleString("es-CO")} simulaciones · Cifras condicionadas al modelo</p>
  </div>
  <figure class="hero-chart" style="margin: 0;">
    <div class="chart-head">
      <span class="chart-title">Población total simulada</span>
      <span class="chart-sub">Millones de habitantes</span>
    </div>
    ${resize((width) => abanico(width))}
    <div class="legend">
      <span><i class="sw sw-line"></i>Mediana</span>
      <span><i class="sw sw-band"></i>90 % de las simulaciones</span>
      <span><i class="sw sw-dash"></i>Proyección del DANE</span>
    </div>
  </figure>
</div>

<div class="kpis">
  <div class="kpi kpi-dark">
    <span class="kpi-label">Máximo antes de 2043</span>
    <span class="kpi-value">${pct.format(mc.prob_antes_2043)}</span>
    <span class="kpi-note">de las simulaciones · ${pct.format(mc.prob_en_2043)} en 2043 · ${pct.format(mc.prob_despues_2043)} después</span>
  </div>
  <div class="kpi kpi-teal">
    <span class="kpi-label">Año mediano del máximo</span>
    <span class="kpi-value">${mc.pico_mediana}</span>
    <span class="kpi-note">${picoDane.anio - mc.pico_mediana} años antes que el DANE</span>
  </div>
  <div class="kpi">
    <span class="kpi-label">Rango del 90 %</span>
    <span class="kpi-value">${mc.pico_p5}–${String(mc.pico_p95).slice(2)}</span>
    <span class="kpi-note">Años del máximo poblacional</span>
  </div>
  <div class="kpi kpi-warm">
    <span class="kpi-label">Hijos por mujer, ${ultimoTgf.anio}</span>
    <span class="kpi-value">${dos.format(ultimoTgf.tgf_eevv)}</span>
    <span class="kpi-note">Con nacimientos registrados; el DANE supone ${dos.format(ultimoTgf.tgf_dane)}</span>
  </div>
</div>

<div class="journey-head">
  <p class="section-kicker">El recorrido</p>
  <h2>Cuatro preguntas para poner a prueba el 2043</h2>
</div>

<div class="journey">
  <a class="j-card" href="./fecundidad">
    <span class="card-index">01 · Fecundidad</span>
    <h3>¿Se cumple lo proyectado?</h3>
    <div class="j-viz">${resize((width) => miniFecundidad(width))}</div>
    <p class="j-text">Los nacimientos registrados caen mucho más rápido que lo proyectado.</p>
  </a>
  <a class="j-card" href="./escenarios">
    <span class="card-index">02 · Escenarios</span>
    <h3>¿Y si la fecundidad no se recupera?</h3>
    <div class="j-rows j-viz">
      ${escenarios.map(d => html`<div class="j-row ${/congelada/i.test(d.escenario) ? "warm" : /recuperaci/i.test(d.escenario) ? "cool" : ""}"><b>${d.escenario}</b><span>${d.anio_pico} · ${millones(d.pob_pico)} M</span></div>`)}
    </div>
    <p class="j-text">Año del máximo y población en el máximo.</p>
  </a>
  <a class="j-card" href="./incertidumbre">
    <span class="card-index">03 · Incertidumbre</span>
    <h3>¿Qué tan firme es el 2043?</h3>
    <div class="j-viz">${resize((width) => miniHistograma(width))}</div>
    <p class="j-text">El año más frecuente del máximo es ${conteo.reduce((a, d) => d.simulaciones > a.simulaciones ? d : a, conteo[0]).anio_pico}, no 2043.</p>
  </a>
  <a class="j-card" href="./sensibilidad">
    <span class="card-index">04 · Sensibilidad</span>
    <h3>¿Qué componente pesa más?</h3>
    <div class="j-viz">${resize((width) => miniSensibilidad(width))}</div>
    <p class="j-text">Cuántos años mueve el máximo cada componente.</p>
  </a>
</div>

<div class="reading">
  <div>
    <p class="section-kicker">Cómo leer estos resultados</p>
    <h2>Son escenarios del modelo, no una proyección oficial</h2>
  </div>
  <ul>
    <li><span><strong>Fecundidad calculada, no observada.</strong> Usa nacimientos registrados (EEVV) sobre población proyectada; los años recientes pueden cambiar.</span></li>
    <li><span><strong>Supuestos del equipo.</strong> Fecundidad de largo plazo entre 1,0 y 1,8, mortalidad ±5 % y migración ±50 %.</span></li>
    <li><span><strong>Proyector propio.</strong> Reproduce el máximo del DANE en 2043 con +0,45 % de diferencia: 56,30 frente a 56,05 millones.</span></li>
  </ul>
</div>
