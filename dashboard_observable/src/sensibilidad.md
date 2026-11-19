---
toc: false
---
<p class="page-kicker">ANÁLISIS · 04</p>

# Sensibilidad

## ¿Qué componente desplaza más el máximo poblacional?

Se cambia un componente a la vez y se mide el efecto sobre el año y el tamaño del máximo. Referencia: fecundidad con recuperación parcial; mortalidad y migración del DANE. Valores ensayados: fecundidad 1,0 y 1,8; riesgo de morir −10 % y +10 %; migración nula y doble.

```js
import * as Plot from "npm:@observablehq/plot";
```

```js
const sensibilidadFuente = await FileAttachment("data/sensibilidad_pico.csv").csv({typed: true});
```

```js
const aNumero = valor => valor == null || valor === "" ? NaN : Number(valor);
const sensibilidad = sensibilidadFuente.map(d => ({
  ...d,
  componente: String(d.componente).replace("TGF largo plazo", "TGF de largo plazo"),
  valor: aNumero(d.valor),
  anio_pico: aNumero(d.anio_pico),
  pob_pico: aNumero(d.pob_pico),
  desplaza_anios: aNumero(d.desplaza_anios),
  cambio_pob_pico_pct: aNumero(d.cambio_pob_pico_pct)
})).filter(d =>
  typeof d.componente === "string" && Number.isFinite(d.valor) &&
  Number.isFinite(d.anio_pico) && Number.isFinite(d.pob_pico) &&
  Number.isFinite(d.desplaza_anios) && Number.isFinite(d.cambio_pob_pico_pct)
);
if (!sensibilidad.length) throw new Error("No hay filas válidas en sensibilidad_pico.csv.");
const componentes = [...new Set(sensibilidad.map(d => d.componente))];
const posicionComponente = componente => componentes.length - 1 - componentes.indexOf(componente);
const resumenSensibilidad = componentes.map(componente => {
  const filas = sensibilidad.filter(d => d.componente === componente);
  return {
    componente,
    componenteCorto: componente.split(" (")[0],
    desplazamiento_min: Math.min(...filas.map(d => d.desplaza_anios)),
    desplazamiento_max: Math.max(...filas.map(d => d.desplaza_anios)),
    desplazamiento_abs: Math.max(...filas.map(d => Math.abs(d.desplaza_anios)))
  };
});
const dominante = resumenSensibilidad.reduce((a, d) => d.desplazamiento_abs > a.desplazamiento_abs ? d : a, resumenSensibilidad[0]);
const formatoNumero = new Intl.NumberFormat("es-CO", {maximumFractionDigits: 1});
const formatoDesplazamiento = valor => `${valor > 0 ? "+" : ""}${formatoNumero.format(valor)}`.replace("-", "−");
const formatoMillones = new Intl.NumberFormat("es-CO", {minimumFractionDigits: 2, maximumFractionDigits: 2});
const enMillones = valor => formatoMillones.format(valor / 1e6);
const sensibilidadOrdenada = sensibilidad.map(d => ({
  ...d,
  componenteCorto: d.componente.split(" (")[0],
  ensayo: d.componente.startsWith("Fecundidad") ? `Fecundidad: TGF ${formatoNumero.format(d.valor)}` : d.componente.startsWith("Mortalidad") ? `Mortalidad: riesgo ×${formatoNumero.format(d.valor)}` : `Migración: saldo ×${formatoNumero.format(d.valor)}`,
  direccion: d.cambio_pob_pico_pct < 0 ? "Disminución" : "Aumento"
})).sort((a, b) => componentes.indexOf(a.componente) - componentes.indexOf(b.componente) || a.valor - b.valor);
const maxAbsDesplazamiento = Math.max(1, ...sensibilidad.map(d => Math.abs(d.desplaza_anios)));
const maxAbsCambioPoblacion = Math.max(0.1, ...sensibilidad.map(d => Math.abs(d.cambio_pob_pico_pct)));
```

<div class="editorial-section" aria-label="Hallazgo principal de sensibilidad">
  <p class="section-kicker">MAYOR DESPLAZAMIENTO EN LOS ENSAYOS</p>
  <div class="section-grid" style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));">
    <article class="section-card"><span class="card-index">COMPONENTE CON MAYOR ALCANCE</span><h3>${dominante.componente}</h3><span>Desplazamiento máximo: ${formatoNumero.format(dominante.desplazamiento_abs)} años</span></article>
    <article class="section-card"><span class="card-index">ADELANTO O RETRASO DEL MÁXIMO</span><h3>${formatoDesplazamiento(dominante.desplazamiento_min)} a ${formatoDesplazamiento(dominante.desplazamiento_max)} años</h3><span>Respecto al escenario base al variar ${dominante.componente.charAt(0).toLowerCase() + dominante.componente.slice(1)}. Negativo = adelanto; positivo = retraso.</span></article>
  </div>
</div>

<section class="editorial-section" aria-labelledby="desplazamiento-maximo-poblacional">
  <p class="section-kicker">DESPLAZAMIENTO TEMPORAL</p>
  <h2 id="desplazamiento-maximo-poblacional">Efecto de cada parámetro sobre el año máximo</h2>
  <p>Cada punto es un valor ensayado y el segmento une los dos de cada componente. Cero es el año de referencia. Pasa el cursor para ver el detalle.</p>
</section>

```js
Plot.plot({
  width,
  height: 310,
  marginLeft: width < 600 ? 110 : 150,
  marginBottom: 48,
  x: {label: width < 600 ? "Años" : "Desplazamiento (años)", domain: [-maxAbsDesplazamiento - 1, maxAbsDesplazamiento + 1], grid: true, ticks: width < 600 ? 5 : 9, tickFormat: d => String(d).replace("-", "−")},
  y: {
    label: null,
    domain: [0, componentes.length - 1],
    ticks: componentes.map((_, i) => i),
    tickFormat: y => componentes[componentes.length - 1 - Math.round(y)]?.split(" (")[0]
  },
  marks: [
    Plot.ruleX([0], {stroke: "#A8B2BE", strokeWidth: 1}),
    Plot.ruleY(resumenSensibilidad, {
      x1: "desplazamiento_min",
      x2: "desplazamiento_max",
      y: d => posicionComponente(d.componente),
      stroke: "#176B73",
      strokeWidth: 3
    }),
    Plot.dot(sensibilidad, {
      x: "desplaza_anios",
      y: d => posicionComponente(d.componente),
      fill: "#176B73",
      r: 8,
      stroke: "white",
      strokeWidth: 2
    }),
    Plot.dot(sensibilidad, Plot.pointer({
      x: "desplaza_anios",
      y: d => posicionComponente(d.componente),
      r: 11,
      fill: "#C8795B",
      stroke: "white",
      strokeWidth: 2,
      maxRadius: 40
    })),
    Plot.tip(sensibilidad, Plot.pointer({
      x: "desplaza_anios",
      y: d => posicionComponente(d.componente),
      maxRadius: 40,
      title: d => `${d.componente}\nValor ensayado: ${formatoNumero.format(d.valor)}\nDesplazamiento: ${formatoDesplazamiento(d.desplaza_anios)} años\nAño máximo: ${d.anio_pico}\nCambio en la población máxima: ${formatoNumero.format(d.cambio_pob_pico_pct)} %`
    }))
  ]
})
```

<section class="editorial-section" aria-labelledby="cambio-poblacion-maxima">
  <p class="section-kicker">VARIACIÓN DE LA POBLACIÓN MÁXIMA</p>
  <h2 id="cambio-poblacion-maxima">Cambio porcentual frente al escenario base</h2>
  <p>Las barras representan el cambio porcentual por ensayo. A la izquierda del cero hay disminución; a la derecha, aumento.</p>
</section>

```js
Plot.plot({
  width,
  height: 370,
  marginLeft: width < 600 ? 150 : 200,
  marginBottom: 52,
  color: {domain: ["Disminución", "Aumento"], range: ["#176B73", "#C8795B"], legend: true},
  x: {label: width < 600 ? "Cambio (%)" : "Cambio poblacional (%)", domain: [-maxAbsCambioPoblacion * 1.2, maxAbsCambioPoblacion * 1.2], grid: true, tickFormat: d => d.toLocaleString("es-CO", {minimumFractionDigits: 1, maximumFractionDigits: 1}).replace("-", "−")},
  y: {label: null, domain: sensibilidadOrdenada.map(d => d.ensayo)},
  marks: [
    Plot.ruleX([0], {stroke: "#A8B2BE", strokeWidth: 1}),
    Plot.barX(sensibilidadOrdenada, {
      x: "cambio_pob_pico_pct",
      y: "ensayo",
      fill: "direccion",
      tip: true,
      title: d => `${d.componente}\nValor ensayado: ${formatoNumero.format(d.valor)}\nCambio: ${formatoNumero.format(d.cambio_pob_pico_pct)} %\nPoblación máxima: ${enMillones(d.pob_pico)} millones\nAño máximo: ${d.anio_pico}`
    })
  ]
})
```

<section class="editorial-section" aria-labelledby="lectura-sensibilidad">
  <p class="section-kicker">INTERPRETACIÓN</p>
  <h2 id="lectura-sensibilidad">Mayor sensibilidad observada: ${dominante.componente}</h2>
  <p>Este componente mueve el máximo entre ${formatoDesplazamiento(dominante.desplazamiento_min)} y ${formatoDesplazamiento(dominante.desplazamiento_max)} años respecto a la referencia (negativo: antes; positivo: después). Es el efecto de esos valores, no una probabilidad.</p>
  <aside class="method-note"><strong>Cómo leerlo:</strong> los rangos son elección del equipo; la fecundidad domina en parte por tener el rango más amplio.</aside>
  <aside class="method-note"><strong>Alcance:</strong> un componente por vez; no se evalúan interacciones ni se compara con el DANE.</aside>
</section>
