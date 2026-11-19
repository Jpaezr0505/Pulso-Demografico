---
toc: false
---
<p class="page-kicker">ANÁLISIS · 02</p>

# Escenarios

## ¿Y si la fecundidad no se recupera?

Las trayectorias comparan proyecciones precalculadas bajo distintos supuestos de fecundidad y muestran su efecto en el máximo poblacional.

```js
import * as Plot from "npm:@observablehq/plot";
import {html} from "htl";
```

```js
const escenariosFuente = await FileAttachment("data/escenarios_poblacion.csv").csv({typed: true});
const resumenFuente = await FileAttachment("data/escenarios_resumen.csv").csv({typed: true});
```

```js
const escenariosSerie = escenariosFuente
  .filter(d => typeof d.escenario === "string" && Number.isFinite(d.anio) && Number.isFinite(d.poblacion))
  .map(d => ({...d, poblacion_millones: d.poblacion / 1e6}))
  .sort((a, b) => a.anio - b.anio);
const resumenEscenarios = resumenFuente.filter(d =>
  typeof d.escenario === "string" && Number.isFinite(d.anio_pico) &&
  Number.isFinite(d.pob_pico) && Number.isFinite(d.pob_2043) && Number.isFinite(d.pob_2070)
);
if (!escenariosSerie.length || !resumenEscenarios.length) throw new Error("No hay datos válidos para construir la comparación de escenarios.");
const escenarioBase = resumenEscenarios.find(d => /dane/i.test(d.escenario));
const escenariosOrden = [...new Set([
  ...(escenarioBase ? [escenarioBase.escenario] : []),
  ...resumenEscenarios.map(d => d.escenario).filter(nombre => nombre !== escenarioBase?.escenario)
])];
const paletaEscenarios = ["#687789", "#C8795B", "#C79B45"];
const formatoPoblacion = new Intl.NumberFormat("es-CO", {minimumFractionDigits: 2, maximumFractionDigits: 2});
const enMillones = valor => formatoPoblacion.format(valor / 1e6);
const menor2043 = resumenEscenarios.reduce((a, d) => d.pob_2043 < a.pob_2043 ? d : a, resumenEscenarios[0]);
const mayor2043 = resumenEscenarios.reduce((a, d) => d.pob_2043 > a.pob_2043 ? d : a, resumenEscenarios[0]);
const brecha2043 = mayor2043.pob_2043 - menor2043.pob_2043;
const maximoTemprano = Math.min(...resumenEscenarios.map(d => d.anio_pico));
const maximoTardio = Math.max(...resumenEscenarios.map(d => d.anio_pico));
```

<section class="editorial-section" aria-labelledby="comparacion-escenarios">
  <p class="section-kicker">TRAYECTORIAS DE POBLACIÓN</p>
  <h2 id="comparacion-escenarios">Los supuestos producen máximos poblacionales distintos</h2>
  <p>Las curvas corresponden al proyector calibrado del equipo, no a la serie oficial del DANE. La línea vertical marca 2043.</p>
</section>

```js
Plot.plot({
  width,
  height: 410,
  marginLeft: 78,
  marginBottom: 48,
  color: {domain: escenariosOrden, range: paletaEscenarios, legend: true},
  x: {label: "Año", ticks: 8, tickFormat: d => String(Math.round(d))},
  y: {label: "Población (millones de habitantes)", grid: true, tickFormat: d => d.toLocaleString("es-CO", {maximumFractionDigits: 0})},
  marks: [
    Plot.ruleX([2043], {stroke: "#A8B2BE", strokeDasharray: "4,4", strokeWidth: 1.5}),
    Plot.line(escenariosSerie, {x: "anio", y: "poblacion_millones", stroke: "escenario", z: "escenario", strokeWidth: 2.5, tip: true}),
    Plot.dot(escenariosSerie, Plot.pointerX({
      x: "anio",
      y: "poblacion_millones",
      fill: "escenario",
      r: 4,
      title: d => `${d.anio} · ${d.escenario}\n${formatoPoblacion.format(d.poblacion_millones)} millones`
    }))
  ]
})
```

<p class="method-note"><strong>Lectura:</strong> el color identifica el escenario; el cursor muestra año, escenario y población.</p>

<section class="editorial-section" aria-labelledby="resumen-escenarios">
  <p class="section-kicker">AÑO DEL MÁXIMO POBLACIONAL Y NIVELES DE POBLACIÓN</p>
  <h2 id="resumen-escenarios">La comparación para cada escenario</h2>
  <p>Valores en millones de habitantes.</p>
</section>

```js
const formatoAnio = valor => String(Math.round(valor));
display(html`<div class="section-grid" style="grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));">
  ${resumenEscenarios.map(d => html`<article class="section-card">
    <span class="card-index">${d.escenario}</span>
    <h3>Máximo poblacional en ${formatoAnio(d.anio_pico)}</h3>
    <span>Población en el máximo: <strong>${enMillones(d.pob_pico)} millones</strong></span>
    <span>En 2043: ${enMillones(d.pob_2043)} millones</span>
    <span>En 2070: ${enMillones(d.pob_2070)} millones</span>
  </article>`)}
</div>`);
```

<section class="editorial-section" aria-labelledby="lectura-escenarios">
  <p class="section-kicker">LECTURA DEMOGRÁFICA</p>
  <h2 id="lectura-escenarios">El momento del máximo poblacional depende de los supuestos</h2>
  <p>El máximo se alcanza entre ${maximoTemprano} y ${maximoTardio}. En 2043, la brecha entre ${menor2043.escenario} y ${mayor2043.escenario} es de ${enMillones(brecha2043)} millones de habitantes. Con recuperación parcial el máximo sigue en 2043, pero con menos población que en el escenario DANE; con fecundidad congelada llega antes.</p>
  <aside class="method-note"><strong>Referencia:</strong> en 2043 el proyector del equipo estima <strong>56,30 millones</strong> y el DANE <strong>56,05 millones</strong>. Los escenarios se comparan solo con el proyector.</aside>
</section>
