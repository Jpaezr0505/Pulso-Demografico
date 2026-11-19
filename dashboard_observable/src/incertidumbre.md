---
toc: false
---
<p class="page-kicker">ANÁLISIS · 03</p>

# Incertidumbre

## ¿Qué tan probable es el 2043?

Se proyecta la población 100.000 veces, sorteando en cada una la fecundidad, la mortalidad y la migración, y se registra el año del máximo. Los resultados dependen del modelo y sus supuestos; no son una proyección oficial.

```js
import * as Plot from "npm:@observablehq/plot";
import {html} from "htl";
```

```js
const bandasFuente = await FileAttachment("data/montecarlo_bandas.csv").csv({typed: true});
const resumenMontecarloFuente = await FileAttachment("data/montecarlo_resumen.csv").csv({typed: true});
const conteoFuente = await FileAttachment("data/montecarlo_conteo_pico.csv").csv({typed: true});
```

```js
const bandasValidas = bandasFuente.filter(d =>
  Number.isFinite(d.anio) && Number.isFinite(d.p5) && Number.isFinite(d.p50) &&
  Number.isFinite(d.p95) && Number.isFinite(d.dane)
).map(d => ({
  ...d,
  p5_millones: d.p5 / 1e6,
  p50_millones: d.p50 / 1e6,
  p95_millones: d.p95 / 1e6,
  dane_millones: d.dane / 1e6
})).sort((a, b) => a.anio - b.anio);
const bandasSimuladas = bandasValidas.map(d => ({
  anio: d.anio,
  p5_millones: d.p5_millones,
  p50_millones: d.p50_millones,
  p95_millones: d.p95_millones
}));
const daneReferencia = bandasValidas.map(d => ({anio: d.anio, dane_millones: d.dane_millones}));
const resumenMontecarlo = resumenMontecarloFuente[0];
const conteoValido = conteoFuente.filter(d => Number.isFinite(d.anio_pico) && Number.isFinite(d.simulaciones));
if (!bandasValidas.length || !resumenMontecarlo || !conteoValido.length) throw new Error("Faltan datos válidos para resumir la incertidumbre.");
const formatoPorcentaje = {format: p => `${(p * 100).toLocaleString("es-CO", {minimumFractionDigits: 1, maximumFractionDigits: 1})} %`};
const formatoMillones = new Intl.NumberFormat("es-CO", {minimumFractionDigits: 2, maximumFractionDigits: 2});
const serieFrecuenciaPico = [...conteoValido].sort((a, b) => a.anio_pico - b.anio_pico);
```

<div class="editorial-section" aria-label="Indicadores de incertidumbre">
  <p class="section-kicker">DISTRIBUCIÓN DEL AÑO DEL MÁXIMO POBLACIONAL · ${new Intl.NumberFormat("es-CO").format(resumenMontecarlo.n)} SIMULACIONES</p>
  <div class="section-grid" style="grid-template-columns: repeat(auto-fit, minmax(175px, 1fr));">
    <article class="section-card"><span class="card-index">ANTES DE 2043</span><h3>${formatoPorcentaje.format(resumenMontecarlo.prob_antes_2043)}</h3><span>Proporción simulada bajo el modelo</span></article>
    <article class="section-card"><span class="card-index">EN 2043</span><h3>${formatoPorcentaje.format(resumenMontecarlo.prob_en_2043)}</h3><span>Proporción simulada bajo el modelo</span></article>
    <article class="section-card"><span class="card-index">DESPUÉS DE 2043</span><h3>${formatoPorcentaje.format(resumenMontecarlo.prob_despues_2043)}</h3><span>Proporción simulada bajo el modelo</span></article>
    <article class="section-card"><span class="card-index">MEDIANA DEL AÑO DEL MÁXIMO POBLACIONAL</span><h3>${resumenMontecarlo.pico_mediana}</h3><span>Año central de las simulaciones</span></article>
    <article class="section-card"><span class="card-index">INTERVALO P5–P95</span><h3>${resumenMontecarlo.pico_p5}–${resumenMontecarlo.pico_p95}</h3><span>Rango que contiene el 90 % de las simulaciones (percentiles 5 a 95)</span></article>
  </div>
</div>

<section class="editorial-section" aria-labelledby="abanico-incertidumbre">
  <p class="section-kicker">POBLACIÓN SIMULADA</p>
  <h2 id="abanico-incertidumbre">El rango de trayectorias se abre alrededor del máximo</h2>
  <p>El área cubre el 90 % central de las simulaciones (P5–P95); la línea continua es la mediana y la gris punteada, el DANE.</p>
</section>

```js
Plot.plot({
  width,
  height: 410,
  marginLeft: width < 600 ? 50 : 82,
  marginRight: width < 600 ? 58 : 78,
  marginBottom: 48,
  x: {label: "Año", ticks: width < 600 ? 4 : 8, tickFormat: d => String(Math.round(d))},
  y: {label: "Población (millones de habitantes)", grid: true, tickFormat: d => d.toLocaleString("es-CO", {maximumFractionDigits: 0})},
  marks: [
    Plot.areaY(bandasValidas, {x: "anio", y1: "p5_millones", y2: "p95_millones", fill: "#DCEBEC"}),
    Plot.ruleX([2043], {stroke: "#C8795B", strokeDasharray: "4,4", strokeWidth: 1.5}),
    Plot.line(bandasValidas, {x: "anio", y: "p5_millones", stroke: "#75AEB1", strokeDasharray: "3,3", strokeWidth: 1}),
    Plot.line(bandasValidas, {x: "anio", y: "p95_millones", stroke: "#75AEB1", strokeDasharray: "3,3", strokeWidth: 1}),
    Plot.line(bandasValidas, {x: "anio", y: "p50_millones", stroke: "#176B73", strokeWidth: 2.5}),
    Plot.line(bandasValidas, {x: "anio", y: "dane_millones", stroke: "#687789", strokeWidth: 2, strokeDasharray: "6,3"}),
    Plot.text(bandasValidas.slice(-1), {x: "anio", y: "dane_millones", text: () => "DANE", dx: 6, textAnchor: "start", fill: "#475569", fontSize: 12}),
    Plot.text(bandasValidas.slice(-1), {x: "anio", y: "p95_millones", text: () => "P95", dx: 6, textAnchor: "start", fill: "#3F7F83", fontSize: 12}),
    Plot.text(bandasValidas.slice(-1), {x: "anio", y: "p50_millones", text: () => "Mediana", dx: 6, textAnchor: "start", fill: "#176B73", fontSize: 12, fontWeight: 600}),
    Plot.text(bandasValidas.slice(-1), {x: "anio", y: "p5_millones", text: () => "P5", dx: 6, textAnchor: "start", fill: "#3F7F83", fontSize: 12}),
    Plot.dot(bandasSimuladas, Plot.pointer({
      x: "anio",
      y: "p50_millones",
      maxRadius: 12,
      r: 4,
      fill: "#176B73"
    })),
    Plot.tip(bandasSimuladas, Plot.pointer({
      x: "anio",
      y: "p50_millones",
      maxRadius: 12,
      title: d => `Año: ${d.anio}\nSimulación Monte Carlo\nP5: ${formatoMillones.format(d.p5_millones)} millones\nP50: ${formatoMillones.format(d.p50_millones)} millones\nP95: ${formatoMillones.format(d.p95_millones)} millones`
    })),
    Plot.dot(daneReferencia, Plot.pointer({
      x: "anio",
      y: "dane_millones",
      maxRadius: 12,
      r: 4,
      fill: "#687789"
    })),
    Plot.tip(daneReferencia, Plot.pointer({
      x: "anio",
      y: "dane_millones",
      maxRadius: 12,
      title: d => `Año: ${d.anio}\nDANE: ${formatoMillones.format(d.dane_millones)} millones`
    }))
  ]
})
```

<p class="method-note"><strong>Lectura:</strong> área = P5–P95; línea central = P50; gris = DANE; vertical = 2043. El cursor muestra los valores anuales.</p>

<section class="editorial-section" aria-labelledby="distribucion-maximo-poblacional">
  <p class="section-kicker">DISTRIBUCIÓN DE SIMULACIONES</p>
  <h2 id="distribucion-maximo-poblacional">Distribución simulada del año máximo</h2>
  <p>Cada barra cuenta las simulaciones cuyo máximo ocurre en ese año. La línea vertical marca 2043.</p>
</section>

```js
Plot.plot({
  width,
  height: 300,
  marginLeft: width < 600 ? 56 : 70,
  marginBottom: 48,
  x: {label: "Año del máximo poblacional", tickFormat: d => width < 600 && d % 5 !== 0 ? "" : String(Math.round(d))},
  y: {label: "Simulaciones", grid: true, tickFormat: d => d.toLocaleString("es-CO")},
  color: {domain: ["Antes de 2043", "En 2043", "Después de 2043"], range: ["#C8795B", "#687789", "#176B73"], legend: true},
  marks: [
    Plot.ruleX([2043], {stroke: "#687789", strokeDasharray: "4,4"}),
    Plot.barY(serieFrecuenciaPico, {
      x: "anio_pico",
      y: "simulaciones",
      fill: d => d.anio_pico < 2043 ? "Antes de 2043" : d.anio_pico === 2043 ? "En 2043" : "Después de 2043",
      tip: true,
      title: d => `Año del máximo poblacional: ${String(d.anio_pico)}\nSimulaciones: ${d.simulaciones.toLocaleString("es-CO")}`
    })
  ]
})
```

<section class="editorial-section" aria-labelledby="lectura-incertidumbre">
  <p class="section-kicker">LECTURA E INTERPRETACIÓN</p>
  <h2 id="lectura-incertidumbre">El máximo simulado suele llegar antes de 2043</h2>
  <p>La mitad de las simulaciones alcanza su máximo en ${resumenMontecarlo.pico_mediana} o antes; el 90 % central cae entre ${resumenMontecarlo.pico_p5} y ${resumenMontecarlo.pico_p95}. El máximo llega antes de 2043 en ${formatoPorcentaje.format(resumenMontecarlo.prob_antes_2043)}, en 2043 en ${formatoPorcentaje.format(resumenMontecarlo.prob_en_2043)} y después en ${formatoPorcentaje.format(resumenMontecarlo.prob_despues_2043)} de los casos.</p>
  <aside class="method-note"><strong>Supuestos:</strong> fecundidad de largo plazo entre 1,0 y 1,8 hijos por mujer (más probable 1,3), alcanzada en 2050; la mortalidad varía ±5 % y la migración ±50 %, ambas desde 2026.</aside>
  <aside class="method-note"><strong>Alcance:</strong> son supuestos del equipo, no probabilidades oficiales. Parten de que la fecundidad EEVV refleja el nivel actual; por eso en 2043 el DANE queda por encima del rango P5–P95.</aside>
</section>
