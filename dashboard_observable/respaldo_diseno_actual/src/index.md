---
toc: false
---
<div class="home-hero">
  <p class="eyebrow">INVESTIGACIÓN · POBLACIÓN Y FUTURO</p>
  <h1>Más allá de 2043: escenarios para el futuro demográfico de Colombia
</h1>
  <p class="home-deck">Colombia 2018–2070 · Proyección del DANE: incertidumbre y sensibilidad</p>
  <p class="home-intro">Según el DANE, la población de Colombia alcanza su máximo en 2043. Esa fecha depende de la fecundidad, la mortalidad y la migración. Este tablero evalúa qué tan firme es.</p>
</div>

```js
import * as Plot from "npm:@observablehq/plot";
```

```js
const poblacionDane = await FileAttachment("data/serie_dane_poblacion_total.csv").csv({typed: true});
```

```js
const serieOverview = poblacionDane
  .filter(d => Number.isFinite(d.anio) && Number.isFinite(d.poblacion_dane) && d.anio >= 2018 && d.anio <= 2070)
  .map(d => ({...d, poblacion_millones: d.poblacion_dane / 1e6}))
  .sort((a, b) => a.anio - b.anio);
const registroPico = serieOverview.reduce((max, d) => d.poblacion_dane > max.poblacion_dane ? d : max, serieOverview[0]);
const registro2043 = serieOverview.find(d => d.anio === 2043);
if (!serieOverview.length || !registro2043) throw new Error("La serie DANE no contiene datos válidos para 2018–2070 y 2043.");
const formatoMillones = new Intl.NumberFormat("es-CO", {minimumFractionDigits: 2, maximumFractionDigits: 2});
```

<section class="editorial-section" aria-label="Indicadores principales">
  <p class="section-kicker">EN UNA MIRADA · PROYECCIÓN OFICIAL</p>
  <div class="section-grid" style="grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));">
    <article class="section-card">
      <span class="card-index">AÑO DEL MÁXIMO POBLACIONAL</span>
      <h3>${registroPico.anio}</h3>
      <span>Máximo de la serie oficial del DANE</span>
    </article>
    <article class="section-card">
      <span class="card-index">POBLACIÓN EN 2043</span>
      <h3>${formatoMillones.format(registro2043.poblacion_millones)} millones</h3>
      <span>Habitantes proyectados por el DANE</span>
    </article>
    <article class="section-card">
      <span class="card-index">HORIZONTE DE ANÁLISIS</span>
      <h3>2018–2070</h3>
      <span>Serie anual de población</span>
    </article>
  </div>
  ${registroPico.anio !== 2043 ? `<p class="pending-note"><span class="pending-marker"></span>La serie alcanza su máximo en ${registroPico.anio}, no en 2043. El gráfico conserva los datos originales.</p>` : ""}
</section>

<section class="editorial-section" aria-labelledby="trayectoria-dane">
  <p class="section-kicker">TRAYECTORIA DEMOGRÁFICA</p>
  <h2 id="trayectoria-dane">La proyección oficial alcanza su máximo en ${registroPico.anio}</h2>
  <p>Proyección oficial del DANE: la población crece hasta el máximo y luego disminuye. La línea vertical marca 2043 y el punto, el máximo de la serie.</p>

```js
  Plot.plot({
    width,
    height: 390,
    marginLeft: 76,
    marginBottom: 48,
    x: {label: "Año", ticks: 8, tickFormat: d => String(Math.round(d))},
    y: {label: "Población (millones de habitantes)", grid: true, tickFormat: d => d.toLocaleString("es-CO", {maximumFractionDigits: 0})},
    marks: [
      Plot.ruleX([2043], {stroke: "#C8795B", strokeDasharray: "4,4", strokeWidth: 1.5}),
      Plot.line(serieOverview, {x: "anio", y: "poblacion_millones", stroke: "var(--series-dane)", strokeWidth: 2.5}),
      Plot.dot([registroPico], {x: "anio", y: "poblacion_millones", r: 5, fill: "var(--series-dane)", stroke: "white", strokeWidth: 1.5}),
      Plot.dot(serieOverview, Plot.pointerX({
        x: "anio",
        y: "poblacion_millones",
        r: 4,
        fill: "var(--series-dane)"
      })),
      Plot.tip(serieOverview, Plot.pointerX({
        x: "anio",
        y: "poblacion_millones",
        title: d => `${d.anio}\nPoblación: ${formatoMillones.format(d.poblacion_millones)} millones de habitantes`
      }))
    ]
  })
```

<p class="method-note"><strong>Lectura:</strong> población en millones; la línea marca 2043. El cursor muestra año y población.</p>
</section>

<section class="editorial-section" aria-labelledby="lectura-maximo-poblacional">
  <p class="section-kicker">POR QUÉ IMPORTA</p>
  <h2 id="lectura-maximo-poblacional">Un año de referencia, no una certeza</h2>
  <p>2043 es una estimación condicionada a supuestos, no una fecha cierta. Las secciones siguientes la contrastan con los nacimientos registrados, escenarios alternativos, simulaciones y un análisis de sensibilidad.</p>
  <aside class="method-note"><strong>Nota metodológica:</strong> en 2043 el DANE proyecta <strong>56,05 millones</strong> y el proyector del equipo, <strong>56,30 millones</strong> (+0,45 %). Los escenarios se comparan con el proyector, no con la cifra oficial.</aside>
</section>

<section class="editorial-section section-links" aria-labelledby="explorar-secciones">
  <p class="section-kicker">CONTINÚA EL RECORRIDO</p>
  <h2 id="explorar-secciones">Explora qué puede cambiar el máximo poblacional</h2>
  <div class="section-grid">
    <a class="section-card" href="./fecundidad"><span class="card-index">01 / FECUNDIDAD</span><h3>¿Se cumple lo proyectado?</h3><span class="card-arrow" aria-hidden="true">↗</span></a>
    <a class="section-card" href="./escenarios"><span class="card-index">02 / ESCENARIOS</span><h3>¿Y si la fecundidad no se recupera?</h3><span class="card-arrow" aria-hidden="true">↗</span></a>
    <a class="section-card" href="./incertidumbre"><span class="card-index">03 / INCERTIDUMBRE</span><h3>¿Qué tan firme es el 2043?</h3><span class="card-arrow" aria-hidden="true">↗</span></a>
    <a class="section-card" href="./sensibilidad"><span class="card-index">04 / SENSIBILIDAD</span><h3>¿Qué componente desplaza más el máximo poblacional?</h3><span class="card-arrow" aria-hidden="true">↗</span></a>
    <a class="section-card section-card-territory" href="./explorador-geografico"><span class="card-index">05 / TERRITORIO</span><h3>¿Dónde cambian los nacimientos?</h3><span class="card-arrow" aria-hidden="true">↗</span></a>
  </div>
</section>
