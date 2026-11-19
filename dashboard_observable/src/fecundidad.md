---
toc: false
---
<p class="page-kicker">ANÁLISIS · 01</p>

# Fecundidad

## ¿Se cumple lo proyectado?

La tasa global de fecundidad (TGF) es el promedio de hijos por mujer. Calculada con los nacimientos registrados en las Estadísticas Vitales (EEVV), cae mucho más rápido que la proyección del DANE: 1,03 frente a 1,65 en 2025.

```js
import * as Plot from "npm:@observablehq/plot";
```

```js
const tgfFuente = await FileAttachment("data/tgf_calculada_vs_dane.csv").csv({typed: true});
const fecundidadFuente = await FileAttachment("data/fecundidad_calculada_vs_dane.csv").csv({typed: true});
```

```js
const tgfValida = tgfFuente.filter(d =>
  Number.isFinite(d.anio) && Number.isFinite(d.tgf_eevv) && Number.isFinite(d.tgf_dane)
).sort((a, b) => a.anio - b.anio);
if (!tgfValida.length) throw new Error("No hay filas válidas en tgf_calculada_vs_dane.csv.");
const tgfUltimo = tgfValida.at(-1);
const tgfSeries = tgfValida.flatMap(d => [
  {anio: d.anio, valor: d.tgf_eevv, fuente: "EEVV · calculada"},
  {anio: d.anio, valor: d.tgf_dane, fuente: "DANE · proyectada"}
]);
const serieTgfEevv = tgfValida.map(d => ({anio: d.anio, valor: d.tgf_eevv}));
const serieTgfDane = tgfValida.map(d => ({anio: d.anio, valor: d.tgf_dane}));
const formatoTgf = new Intl.NumberFormat("es-CO", {minimumFractionDigits: 2, maximumFractionDigits: 2});
const brechaTgf = tgfUltimo.tgf_dane - tgfUltimo.tgf_eevv;
```

```js
const tasasValidas = fecundidadFuente.filter(d =>
  Number.isFinite(d.anio) && Number.isFinite(d.tasa_eevv) && Number.isFinite(d.tasa_dane)
);
const detalleValido = tasasValidas;
if (!detalleValido.length) throw new Error("No hay tasas válidas por grupo de edad.");
const maxTasaDetalle = Math.ceil(Math.max(...detalleValido.flatMap(d => [d.tasa_eevv, d.tasa_dane])) * 50) / 50;
const formatoTasaDetalle = new Intl.NumberFormat("es-CO", {minimumFractionDigits: 5, maximumFractionDigits: 5});
```

<div class="editorial-section" aria-label="Indicadores de fecundidad">
  <p class="section-kicker">ÚLTIMO AÑO DISPONIBLE · ${tgfUltimo.anio}</p>
  <div class="section-grid" style="grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));">
    <article class="section-card"><span class="card-index">EEVV · TGF CALCULADA</span><h3>${formatoTgf.format(tgfUltimo.tgf_eevv)}</h3><span>Hijos por mujer</span></article>
    <article class="section-card"><span class="card-index">DANE · TGF PROYECTADA</span><h3>${formatoTgf.format(tgfUltimo.tgf_dane)}</h3><span>Hijos por mujer</span></article>
    <article class="section-card"><span class="card-index">BRECHA DANE − EEVV</span><h3>${formatoTgf.format(brechaTgf)}</h3><span>Hijos por mujer en el último año disponible</span></article>
  </div>
</div>

<section class="editorial-section" aria-labelledby="tgf-tiempo">
  <p class="section-kicker">TENDENCIA NACIONAL</p>
  <h2 id="tgf-tiempo">La TGF calculada con EEVV se separa de la proyección del DANE</h2>
  <p>La brecha entre ambas series crece de 0,2 hijos por mujer en 2018 a 0,6 en 2025. La línea de 2,1 es el nivel de reemplazo.</p>
</section>

```js
Plot.plot({
  width,
  height: 380,
  marginLeft: width < 600 ? 44 : 70,
  marginBottom: 48,
  color: {
    domain: ["EEVV · calculada", "DANE · proyectada"],
    range: ["#176B73", "#687789"],
    legend: true
  },
  x: {label: "Año", ticks: width < 600 ? 4 : 8, tickFormat: d => String(Math.round(d))},
  y: {label: "Hijos por mujer", grid: true, domain: [0, 2.2], tickFormat: d => d.toLocaleString("es-CO", {minimumFractionDigits: 1, maximumFractionDigits: 1})},
  marks: [
    Plot.ruleY([2.1], {stroke: "#C79B45", strokeDasharray: "4,4", strokeWidth: 1.5}),
    Plot.text([{anio: 2018, valor: 2.1}], {x: "anio", y: "valor", text: () => "Nivel de reemplazo (2,1)", dy: -8, textAnchor: "start", fill: "#6B6F6F", fontSize: 12}),
    Plot.line(tgfSeries, {x: "anio", y: "valor", stroke: "fuente", z: "fuente", strokeWidth: 2.5}),
    Plot.dot(serieTgfEevv, Plot.pointer({
      x: "anio",
      y: "valor",
      maxRadius: 12,
      fill: "#176B73",
      stroke: "white",
      r: 4
    })),
    Plot.tip(serieTgfEevv, Plot.pointer({
      x: "anio",
      y: "valor",
      maxRadius: 12,
      title: d => `${d.anio} · EEVV calculada\n${formatoTgf.format(d.valor)} hijos por mujer`
    })),
    Plot.dot(serieTgfDane, Plot.pointer({
      x: "anio",
      y: "valor",
      maxRadius: 12,
      fill: "#687789",
      stroke: "white",
      r: 4
    })),
    Plot.tip(serieTgfDane, Plot.pointer({
      x: "anio",
      y: "valor",
      maxRadius: 12,
      title: d => `${d.anio} · DANE proyectada\n${formatoTgf.format(d.valor)} hijos por mujer`
    }))
  ]
})
```

<p class="method-note"><span aria-hidden="true" style="display:inline-block; width:1.6rem; margin-right:0.5rem; border-top:2px dashed #C79B45; vertical-align:middle;"></span><strong>Referencia (2,1):</strong> nivel convencional de reemplazo; no es un valor observado. El cursor muestra año, fuente y TGF.</p>

<section class="editorial-section" aria-labelledby="relacion-fuentes">
  <p class="section-kicker">COMPARACIÓN POR GRUPO DE EDAD</p>
  <h2 id="relacion-fuentes">Relación entre las tasas por grupo de edad</h2>
  <p>Cada punto es un año y un grupo de edad de la madre. Bajo la diagonal, los nacimientos registrados son menores que los proyectados.</p>
</section>

```js
Plot.plot({
  width,
  height: 400,
  marginLeft: width < 600 ? 50 : 70,
  marginBottom: 54,
  color: {legend: true, label: "Grupo de edad de la madre", domain: [...new Set(detalleValido.map(d => d.grupo))].sort(), range: ["#687789", "#C79B45", "#C8795B", "#05AD98", "#045F54", "#75AEB1", "#8A4A32", "#EBB3A0"]},
  x: {label: "Tasa DANE proyectada", domain: [0, maxTasaDetalle], grid: true, tickFormat: d => d.toLocaleString("es-CO", {minimumFractionDigits: 2, maximumFractionDigits: 2})},
  y: {label: "Tasa calculada con EEVV", domain: [0, maxTasaDetalle], grid: true, tickFormat: d => d.toLocaleString("es-CO", {minimumFractionDigits: 2, maximumFractionDigits: 2})},
  marks: [
    Plot.line([{tasa: 0}, {tasa: maxTasaDetalle}], {x: "tasa", y: "tasa", stroke: "#A8B2BE", strokeDasharray: "4,4"}),
    Plot.dot(detalleValido, {
      x: "tasa_dane",
      y: "tasa_eevv",
      r: 5,
      fill: "grupo",
      stroke: "white",
      tip: true,
      title: d => `${String(d.anio)} · ${d.grupo}\nEEVV: ${formatoTasaDetalle.format(d.tasa_eevv)}\nDANE: ${formatoTasaDetalle.format(d.tasa_dane)}`
    })
  ]
})
```

<div class="method-note"><strong>Limitación:</strong> la TGF EEVV es calculada, no observada: incluye nacimientos de madres residentes en el exterior, usa población proyectada como denominador y los años recientes pueden cambiar por registros tardíos.</div>
