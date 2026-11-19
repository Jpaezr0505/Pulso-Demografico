---
toc: false
---

<p class="page-kicker">TERRITORIO · 05</p>

# Explorador geográfico

## ¿Dónde llega antes el máximo poblacional?

El máximo de 2043 resume ritmos territoriales muy distintos. El mapa muestra, por departamento, la fecundidad, el año del máximo poblacional y la variación de los nacimientos. Haz clic en un departamento para ver su detalle.

```js
import * as Plot from "npm:@observablehq/plot";
```

```js
// Datos: polígonos (MGN) y métricas por departamento (resultados/departamentos_*.csv)
const num = v => v === "" || v == null ? NaN : Number(v);
const geo = await FileAttachment("data/mapa_departamentos.json").json();
const geoSanAndres = await FileAttachment("data/mapa_san_andres.json").json();
const metricas = (await FileAttachment("data/departamentos_metricas.csv").csv()).map(d => ({
  ...d,
  pico_anio: num(d.pico_anio), pico_censurado: d.pico_censurado === "TRUE",
  pob_2018: num(d.pob_2018), pob_2050: num(d.pob_2050),
  nac_2018: num(d.nac_2018), nac_2025: num(d.nac_2025), variacion_nac_pct: num(d.variacion_nac_pct),
  tgf_2018: num(d.tgf_2018), tgf_2025: num(d.tgf_2025)
}));
const serie = (await FileAttachment("data/departamentos_serie.csv").csv()).map(d => ({cod_dpto: d.cod_dpto, anio: num(d.anio), tgf: num(d.tgf)}));
const poblacion = (await FileAttachment("data/departamentos_poblacion.csv").csv()).map(d => ({cod_dpto: d.cod_dpto, anio: num(d.anio), poblacion: num(d.poblacion)}));
const regiones = (await FileAttachment("data/regiones_pico.csv").csv()).map(d => ({...d, pico_anio: num(d.pico_anio), pico_censurado: d.pico_censurado === "TRUE"}));

if (metricas.length !== 33 || geo.features.length !== 33) throw new Error("Se esperaban 33 departamentos en las métricas y en el mapa.");

const porCodigo = new Map(metricas.map(d => [d.cod_dpto, d]));
const tgfDe = new Map(serie.map(d => [`${d.cod_dpto}-${d.anio}`, d.tgf]));
const departamentos = geo.features.map(f => ({...f, properties: {...f.properties, ...porCodigo.get(f.properties.cod_dpto)}}));
const anios = [...new Set(serie.map(d => d.anio))].sort((a, b) => a - b);

const miles = new Intl.NumberFormat("es-CO", {useGrouping: "always", maximumFractionDigits: 0});
const dec2 = new Intl.NumberFormat("es-CO", {minimumFractionDigits: 2, maximumFractionDigits: 2});
const dec1 = new Intl.NumberFormat("es-CO", {minimumFractionDigits: 1, maximumFractionDigits: 1});
const compacto = new Intl.NumberFormat("es-CO", {notation: "compact", maximumFractionDigits: 1});
const pct = v => `${v > 0 ? "+" : "−"}${dec1.format(Math.abs(v))} %`.replace(" %", " %");
```

```js
// Estado: departamento seleccionado (clic en el mapa o lista desplegable)
const seleccion = Mutable("11");
const elegir = cod => { seleccion.value = cod; };
```

```js
// Controles (se definen una sola vez; se muestran más abajo)
const controlVista = html`<select class="geo-control" aria-label="Variable del mapa">
  <option value="tgf">Fecundidad (hijos por mujer)</option>
  <option value="pico">Año del máximo poblacional</option>
  <option value="nac">Variación de nacimientos 2018–2025</option>
</select>`;
const controlAnio = html`<input class="geo-control" type="range" min="${anios[0]}" max="${anios.at(-1)}" step="1" value="${anios.at(-1)}" aria-label="Año de la fecundidad">`;
const vista = Generators.input(controlVista);
const anio = Generators.input(controlAnio);
```

```js
// Categorías del mapa de "año del máximo"
const gruposPico = [
  {nombre: "Hasta 2030", color: "#045F54"},
  {nombre: "2031–2042", color: "#05AD98"},
  {nombre: "2043–2049", color: "#9ADBD2"},
  {nombre: "2050 o después", color: "#BBBFBF"}
];
const grupoPico = p => p.pico_censurado ? "2050 o después" : p.pico_anio <= 2030 ? "Hasta 2030" : p.pico_anio <= 2042 ? "2031–2042" : "2043–2049";
const textoPico = p => p.pico_censurado ? "2050 o después" : String(p.pico_anio);
```

```js
const etiquetaVista = {tgf: `Fecundidad ${anio}`, pico: "Año del máximo", nac: "Variación de nacimientos 2018–2025"}[vista];

const valorMapa = p => vista === "tgf" ? tgfDe.get(`${p.cod_dpto}-${anio}`)
  : vista === "pico" ? grupoPico(p) : p.variacion_nac_pct;

const tooltip = p => vista === "tgf" ? `${p.departamento}\nFecundidad ${anio}: ${dec2.format(valorMapa(p))} hijos por mujer`
  : vista === "pico" ? `${p.departamento}\nMáximo poblacional: ${textoPico(p)}`
  : `${p.departamento}\nNacimientos: ${miles.format(p.nac_2018)} → ${miles.format(p.nac_2025)} (${pct(p.variacion_nac_pct)})`;

const escalaColor = vista === "tgf"
  ? {type: "linear", domain: [0.6, 3.0], range: ["#E6F6F3", "#045F54"], clamp: true, legend: true, label: "Hijos por mujer", tickFormat: d => d >= 3 ? "3,0 o más" : d.toLocaleString("es-CO", {minimumFractionDigits: 1, maximumFractionDigits: 1})}
  : vista === "pico"
  ? {domain: gruposPico.map(g => g.nombre), range: gruposPico.map(g => g.color), legend: true, label: "Año del máximo"}
  : {type: "linear", domain: [-50, 0], range: ["#045F54", "#E6F6F3"], clamp: true, legend: true, label: "Variación (%)", tickFormat: d => d.toLocaleString("es-CO").replace("-", "−")};

const elegido = departamentos.find(f => f.properties.cod_dpto === seleccion);
const dibujados = departamentos.filter(f => f.properties.cod_dpto !== "88"); // San Andrés queda lejos: se elige en la lista
const chicos = departamentos.filter(f => f.properties.cod_dpto === "11");     // Bogotá casi no se ve: se marca con un punto
```

```js
const mapa = resize(ancho => {
  const fig = Plot.plot({
    width: ancho,
    height: Math.max(380, Math.min(640, ancho * 1.05)),
    margin: 4,
    projection: {type: "mercator", domain: {type: "FeatureCollection", features: dibujados}},
    color: escalaColor,
    marks: [
      Plot.geo(dibujados, {
        fill: d => valorMapa(d.properties), stroke: "#FFFFFF", strokeWidth: 0.8,
        title: d => tooltip(d.properties), tip: true
      }),
      Plot.dot(chicos, Plot.centroid({fill: d => valorMapa(d.properties), stroke: "#333333", strokeWidth: 1, r: 5})),
      Plot.text(chicos, Plot.centroid({text: () => "Bogotá", dx: 8, dy: -10, textAnchor: "start", fill: "#333333", fontSize: 11})),
      Plot.geo(elegido, {fill: "none", stroke: "#333333", strokeWidth: 2.5, pointerEvents: "none"})
    ]
  });
  fig.setAttribute("role", "img");
  fig.setAttribute("aria-label", "Mapa de los departamentos de Colombia coloreado según la métrica elegida. Con teclado, elige el departamento en la lista desplegable del panel.");
  fig.querySelector('g[aria-label="geo"]').querySelectorAll("path").forEach((ruta, i) => {
    ruta.style.cursor = "pointer";
    ruta.addEventListener("click", () => elegir(dibujados[i].properties.cod_dpto));
  });
  return fig;
});
```

```js
// Recuadro de San Andrés y Providencia: dos acercamientos para ver la silueta de cada isla
const insetSanAndres = (() => {
  const props = porCodigo.get("88");
  const poligonos = geoSanAndres.features[0].geometry.coordinates;                      // San Andrés, Providencia y Santa Catalina
  const latitud = c => c[0].reduce((s, p) => s + p[1], 0) / c[0].length;
  const grupos = [
    {nombre: "San Andrés", islas: poligonos.filter(c => latitud(c) < 13)},
    {nombre: "Providencia", islas: poligonos.filter(c => latitud(c) >= 13)}
  ];
  const contenedor = html`<div class="geo-inset-islas"></div>`;
  for (const g of grupos) {
    const area = {type: "MultiPolygon", coordinates: g.islas};
    const fig = Plot.plot({
      width: 84, height: 104, margin: 5,
      projection: {type: "mercator", domain: area},
      color: {...escalaColor, legend: false},
      marks: [Plot.geo(area, {fill: () => valorMapa(props), stroke: "#333333", strokeWidth: seleccion === "88" ? 2.5 : 1.2, title: tooltip(props), tip: true})]
    });
    fig.style.cursor = "pointer";
    fig.setAttribute("role", "button");
    fig.setAttribute("tabindex", "0");
    fig.setAttribute("aria-label", `${g.nombre}: ver detalle del archipiélago de San Andrés y Providencia`);
    fig.addEventListener("click", () => elegir("88"));
    fig.addEventListener("keydown", e => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); elegir("88"); } });
    contenedor.append(html`<figure class="geo-isla"><figcaption>${g.nombre}</figcaption>${fig}</figure>`);
  }
  return contenedor;
})();
```

```js
// Panel de detalle del departamento seleccionado
const sel = porCodigo.get(seleccion);
const lista = html`<select class="geo-control" aria-label="Departamento">
  ${[...metricas].sort((a, b) => a.departamento.localeCompare(b.departamento, "es")).map(d => html`<option value="${d.cod_dpto}" selected=${d.cod_dpto === seleccion}>${d.departamento}</option>`)}
</select>`;
lista.addEventListener("change", () => elegir(lista.value));

const pobSel = poblacion.filter(d => d.cod_dpto === seleccion);
const picoSel = pobSel.reduce((m, d) => d.poblacion > m.poblacion ? d : m, pobSel[0]);
const tgfSel = serie.filter(d => d.cod_dpto === seleccion);

const graficoPoblacion = resize(ancho => Plot.plot({
  width: ancho, height: 170, marginLeft: 46, marginBottom: 28,
  x: {label: null, tickFormat: d => String(d), ticks: ancho < 400 ? 3 : 5},
  y: {label: null, grid: true, tickFormat: d => compacto.format(d), nice: true},
  marks: [
    Plot.line(pobSel, {x: "anio", y: "poblacion", stroke: "#05AD98", strokeWidth: 2.2}),
    Plot.dot([picoSel], {x: "anio", y: "poblacion", r: 5, fill: sel.pico_censurado ? "#FFFFFF" : "#045F54", stroke: "#045F54", strokeWidth: 1.5}),
    Plot.tip(pobSel, Plot.pointerX({x: "anio", y: "poblacion", title: d => `${d.anio}\n${miles.format(d.poblacion)} habitantes`}))
  ]
}));

const graficoTgf = resize(ancho => Plot.plot({
  width: ancho, height: 170, marginLeft: 46, marginBottom: 28,
  x: {label: null, tickFormat: d => String(d), ticks: 4},
  y: {label: null, grid: true, domain: [0, Math.max(2.4, ...tgfSel.map(d => d.tgf))], tickFormat: d => dec1.format(d)},
  marks: [
    Plot.ruleY([2.1], {stroke: "#878787", strokeDasharray: "4,4"}),
    Plot.text([{anio: 2018, tgf: 2.1}], {x: "anio", y: "tgf", text: () => "Reemplazo (2,1)", dy: -7, textAnchor: "start", fill: "#666666", fontSize: 11}),
    Plot.line(tgfSel, {x: "anio", y: "tgf", stroke: "#333333", strokeWidth: 2.2}),
    Plot.dot(tgfSel, {x: "anio", y: "tgf", r: 3, fill: "#333333"}),
    Plot.tip(tgfSel, Plot.pointerX({x: "anio", y: "tgf", title: d => `${d.anio}\n${dec2.format(d.tgf)} hijos por mujer`}))
  ]
}));

const panel = html`<aside class="geo-panel" aria-live="polite">
  <label class="geo-label">Departamento ${lista}</label>
  <dl class="geo-kpis">
    <div><dt>Máximo poblacional</dt><dd>${textoPico(sel)}</dd></div>
    <div><dt>Población 2018</dt><dd>${miles.format(sel.pob_2018)}</dd></div>
    <div><dt>Fecundidad 2018 → 2025</dt><dd>${dec2.format(sel.tgf_2018)} → ${dec2.format(sel.tgf_2025)}</dd></div>
    <div><dt>Nacimientos 2018 → 2025</dt><dd>${miles.format(sel.nac_2018)} → ${miles.format(sel.nac_2025)} <small>(${pct(sel.variacion_nac_pct)})</small></dd></div>
  </dl>
  <p class="geo-chart-title">Población proyectada por el DANE, 2018–2050</p>
  ${graficoPoblacion}
  <p class="geo-chart-title">Fecundidad calculada con EEVV, 2018–2025</p>
  ${graficoTgf}
</aside>`;
```

<div class="geo-controls">
  <label class="geo-label">Variable ${controlVista}</label>
  <label class="geo-label ${vista === "tgf" ? "" : "geo-label-off"}">Año de la fecundidad: <strong>${anio}</strong> ${controlAnio}</label>
</div>

<div class="geo-layout">
  <div class="geo-map">${mapa}<div class="geo-inset"><span>San Andrés y Providencia</span>${insetSanAndres}</div></div>
  ${panel}
</div>

```js
const antes = metricas.filter(d => !d.pico_censurado && d.pico_anio < 2043);
const sigue = metricas.filter(d => d.pico_censurado);
const picoDe = nombre => metricas.find(d => d.departamento === nombre);
const notaVista = {
  tgf: html`<strong>Fecundidad:</strong> nacimientos EEVV (departamento de residencia de la madre) ÷ mujeres de 10 a 49 años de la proyección del DANE. Excluye los nacimientos de madres en el exterior o sin departamento (menos de 2,5 %). Los años recientes pueden cambiar por registros tardíos. En departamentos con pocos nacimientos (Vaupés, Guainía, Amazonas, San Andrés) la cifra varía mucho de un año a otro.`,
  pico: html`<strong>Año del máximo:</strong> año de mayor población en la proyección departamental del DANE, que llega hasta 2050. En ${sigue.length} departamentos la población sigue creciendo en 2050, así que su máximo es posterior.`,
  nac: html`<strong>Nacimientos:</strong> variación de 2025 respecto a 2018 según EEVV, por departamento de residencia de la madre.`
}[vista];
```

<aside class="method-note">${notaVista}</aside>

<section class="editorial-section" aria-labelledby="lectura-territorio">
  <p class="section-kicker">LECTURA</p>
  <h2 id="lectura-territorio">Los departamentos no alcanzan su máximo al mismo tiempo</h2>
  <p>${antes.length} de 33 departamentos alcanzan su máximo antes de 2043 (Bogotá, en ${picoDe("Bogotá").pico_anio}; Quindío, en ${picoDe("Quindío").pico_anio}), y en ${sigue.length} la población sigue creciendo en 2050 (por ejemplo, La Guajira y Cesar); los otros ${33 - antes.length - sigue.length} lo alcanzan entre 2043 y 2049. El máximo nacional de 2043 es el resultado de combinar ambos grupos.</p>
</section>

<section class="editorial-section" aria-labelledby="regiones-dane">
  <p class="section-kicker">REGIONES DEMOGRÁFICAS DEL DANE</p>
  <h2 id="regiones-dane">Año del máximo en las 22 regiones</h2>
  <p>Las 22 regiones agrupan municipios, no departamentos completos. Por eso se muestran en un gráfico y no en el mapa.</p>

```js
const ordenRegiones = regiones.map(d => d.territorio);
display(resize(ancho => Plot.plot({
  width: ancho,
  height: 30 + regiones.length * 24,
  marginLeft: ancho < 600 ? ancho * 0.5 : 310,
  marginRight: 30,
  marginTop: 24,
  marginBottom: 54,
  x: {label: "Año del máximo poblacional", labelAnchor: "center", domain: [2025, 2054], ticks: ancho < 600 ? 3 : 6, tickFormat: d => String(d)},
  y: {label: null, domain: ordenRegiones, tickFormat: n => ancho < 600 && n.length > 20 ? n.slice(0, 19) + "…" : n},
  marks: [
    Plot.ruleX([2043], {stroke: "#878787", strokeDasharray: "4,4"}),
    Plot.text([2043], {x: d => d, frameAnchor: "top", dy: -14, text: () => "2043 · máximo nacional", fill: "#666666", fontSize: 11}),
    Plot.ruleY(regiones, {y: "territorio", x1: 2025, x2: "pico_anio", stroke: "#BBBFBF"}),
    Plot.dot(regiones, {x: "pico_anio", y: "territorio", r: 5.5, stroke: "#05AD98", strokeWidth: 2, fill: d => d.pico_censurado ? "#FFFFFF" : "#05AD98"}),
    Plot.text(regiones.filter(d => d.pico_censurado), {x: "pico_anio", y: "territorio", text: () => ancho < 600 ? "sigue" : "sigue creciendo", dx: 10, textAnchor: "start", fill: "#666666", fontSize: 11}),
    Plot.tip(regiones, Plot.pointer({x: "pico_anio", y: "territorio", title: d => `${d.territorio}\n${d.pico_censurado ? "Máximo: 2050 o después" : "Máximo: " + d.pico_anio}`}))
  ]
})));
```

  <p class="method-note"><strong>Lectura:</strong> la línea punteada marca 2043, el año del máximo nacional. Los puntos huecos son regiones cuya población aún crece en 2050, el último año de la proyección regional del DANE.</p>
</section>
