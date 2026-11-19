# Diagnóstico técnico de fuentes CSV

Página temporal para verificar la carga de datos. La ficha técnica indicada (`../FICHA_TECNICA.md`) no está presente en el proyecto; las columnas esperadas siguientes se contrastaron con los encabezados de los CSV y los esquemas descritos en `main.R` y `modelo.R`.

```js
const fuentes = [
  {nombre: "serie_dane_poblacion_total.csv", columnasEsperadas: ["anio", "poblacion_dane"], datos: await FileAttachment("data/serie_dane_poblacion_total.csv").csv()},
  {nombre: "calibracion_proyector.csv", columnasEsperadas: ["anio", "pob_modelo", "pob_dane", "error_pct"], datos: await FileAttachment("data/calibracion_proyector.csv").csv()},
  {nombre: "tgf_calculada_vs_dane.csv", columnasEsperadas: ["anio", "tgf_eevv", "tgf_dane", "razon"], datos: await FileAttachment("data/tgf_calculada_vs_dane.csv").csv()},
  {nombre: "fecundidad_calculada_vs_dane.csv", columnasEsperadas: ["anio", "grupo", "tasa_eevv", "tasa_dane", "razon"], datos: await FileAttachment("data/fecundidad_calculada_vs_dane.csv").csv()},
  {nombre: "escenarios_poblacion.csv", columnasEsperadas: ["escenario", "anio", "poblacion"], datos: await FileAttachment("data/escenarios_poblacion.csv").csv()},
  {nombre: "escenarios_resumen.csv", columnasEsperadas: ["escenario", "anio_pico", "pob_pico", "pob_2043", "pob_2070"], datos: await FileAttachment("data/escenarios_resumen.csv").csv()},
  {nombre: "montecarlo_bandas.csv", columnasEsperadas: ["anio", "p5", "p50", "p95", "dane"], datos: await FileAttachment("data/montecarlo_bandas.csv").csv()},
  {nombre: "montecarlo_pico.csv", columnasEsperadas: ["sim", "tgf_largo", "k_mort", "f_mig", "anio_pico", "pob_pico"], datos: await FileAttachment("data/montecarlo_pico.csv").csv()},
  {nombre: "montecarlo_resumen.csv", columnasEsperadas: ["n", "prob_antes_2043", "prob_en_2043", "prob_despues_2043", "pico_p5", "pico_mediana", "pico_p95", "pob_pico_p5", "pob_pico_mediana", "pob_pico_p95"], datos: await FileAttachment("data/montecarlo_resumen.csv").csv()},
  {nombre: "sensibilidad_pico.csv", columnasEsperadas: ["componente", "valor", "anio_pico", "pob_pico", "desplaza_anios", "cambio_pob_pico_pct"], datos: await FileAttachment("data/sensibilidad_pico.csv").csv()},
  {nombre: "controles.csv", columnasEsperadas: ["etapa", "control", "ok", "detalle"], datos: await FileAttachment("data/controles.csv").csv()},
  {nombre: "diccionario_datos.csv", columnasEsperadas: ["archivo", "columnas", "descripcion"], datos: await FileAttachment("data/diccionario_datos.csv").csv()},
  {nombre: "eevv_nacional.csv", columnasEsperadas: ["anio", "grupo_edad", "nacimientos", "hombres", "mujeres", "indeterminado"], datos: await FileAttachment("data/eevv_nacional.csv").csv()},
  {nombre: "eevv_departamental.csv", columnasEsperadas: ["anio", "cod_dpto", "departamento", "grupo_edad", "nacimientos", "total_depto"], datos: await FileAttachment("data/eevv_departamental.csv").csv()}
];

const validaciones = fuentes.map((fuente) => {
  const columnas = fuente.datos.length ? Object.keys(fuente.datos[0]) : [];
  const columnasOk = columnas.join(",") === fuente.columnasEsperadas.join(",");
  const noVacio = fuente.datos.length > 0;
  const codigo05 = fuente.nombre !== "eevv_departamental.csv"
    || fuente.datos.some((fila) => fila.cod_dpto === "05" && typeof fila.cod_dpto === "string");
  const estado = [
    noVacio ? null : "VACÍO",
    columnasOk ? null : "ENCABEZADOS NO COINCIDEN",
    codigo05 ? null : 'NO SE CONSERVÓ cod_dpto="05" COMO TEXTO'
  ].filter(Boolean).join("; ") || "OK";
  return {nombre: fuente.nombre, filas: fuente.datos.length, columnas: columnas.join(", ") || "(sin encabezados)", estado};
});
```

```js
 display(html`<table>
  <thead><tr><th>Fuente</th><th>Filas</th><th>Columnas observadas</th><th>Validación</th></tr></thead>
  <tbody>${validaciones.map((fila) => html`<tr><td>${fila.nombre}</td><td>${fila.filas}</td><td>${fila.columnas}</td><td>${fila.estado}</td></tr>`)}</tbody>
</table>`);
```

Comprobación específica de `cod_dpto`: ${validaciones.find((fila) => fila.nombre === "eevv_departamental.csv").estado === "OK" ? 'el código "05" se conservó como texto.' : 'falló; revisar el estado de eevv_departamental.csv en la tabla.'}

Todos los CSV se cargan con `.csv()` sin `typed: true`; esta página no convierte ni calcula indicadores.
