# PROJECT_CONTEXT — Pulso Demográfico (Demografía de Colombia)

## Propósito

Proyecto académico sobre la trayectoria demográfica de Colombia entre 2018 y 2070. Compara la proyección oficial del DANE con la fecundidad calculada a partir de nacimientos de Estadísticas Vitales (EEVV), y analiza escenarios, incertidumbre y sensibilidad ante cambios en fecundidad, mortalidad y migración. El dashboard comunica resultados ya calculados; no ejecuta el modelo demográfico dentro del navegador.

**Pregunta central:** ¿qué tan firme es el máximo poblacional que el DANE proyecta hacia 2043, y cuánto puede cambiar si varían los supuestos demográficos?

Los resultados propios complementan la proyección del DANE; no son una proyección oficial ni la reemplazan. Las probabilidades Monte Carlo están condicionadas por los supuestos del modelo.

## Estructura del proyecto

- `main.R`: importa, limpia y valida las bases de entrada; genera CSV limpios y algunos resultados comparativos.
- `modelo.R`: proyecta la población por cohortes, calibra el proyector, calcula escenarios, Monte Carlo y sensibilidad.
- `departamentos.R`: métricas por departamento y picos regionales (usa DANE por departamento y EEVV).
- `mapa.R`: prepara los GeoJSON del mapa (departamentos y San Andrés ampliado).
- `datos_crudos/dane/`, `datos_crudos/eevv/`, `datos_crudos/mapa/`: fuentes originales. No sobrescribirlas al modificar el dashboard.
- `datos_limpios/`: bases procesadas que usa el modelo.
- `resultados/`: CSV generados por los scripts R y consumidos por el dashboard.
- `dashboard_observable/`: aplicación web Observable Framework.
  - `src/*.md`: páginas y visualizaciones Observable Plot.
  - `src/data/*.csv.js`: cargadores que leen los CSV de `../resultados/` o `../datos_limpios/`.
  - `src/style.css`: sistema visual compartido.
  - `observablehq.config.js`: título y navegación.

## Flujo de datos y ejecución

Trabajar desde la carpeta raíz del proyecto (`demografia-colombia`). Para reconstruir los resultados desde las fuentes:

1. Abrir esta carpeta en RStudio y ejecutar `source("main.R")`.
2. Ejecutar `source("modelo.R")` después de `main.R`.
3. Ejecutar `source("departamentos.R")` y luego `source("mapa.R")` para actualizar la página Territorio.
4. Para el dashboard, abrir una terminal en `dashboard_observable/` y ejecutar `npm run dev`; normalmente queda disponible en `http://localhost:3000`.
5. Validar la compilación estática con `npm run build` desde `dashboard_observable/` (genera `dist/`).

El proyecto R requiere los paquetes usados en los scripts, incluyendo `tidyverse`. El dashboard requiere Node.js 18 o posterior y las dependencias declaradas en `dashboard_observable/package.json` (`npm install` si no están instaladas).

**Importante:** los cargadores del dashboard resuelven los archivos de datos desde la carpeta raíz del proyecto, un nivel arriba de `dashboard_observable`. Si falta un CSV, identificar primero qué script lo genera; no crear datos ficticios ni editar manualmente un archivo generado.

## Estado actual del análisis

- `modelo.R` usa `set.seed(2043)` para reproducibilidad y `n_sim = 5000` simulaciones Monte Carlo.
- Los resultados de Monte Carlo deben describirse como resultados bajo los supuestos configurados en `modelo.R`, no como probabilidades oficiales.
- El resumen de 5.000 simulaciones verificado en una ejecución previa dio mediana del año del máximo en 2040 y percentiles P5–P95 de 2036–2045. Recalcular/consultar `resultados/montecarlo_resumen.csv` si se necesita citar cifras actuales.
- La página Inicio muestra la serie oficial de población y su máximo; Fecundidad contrasta EEVV calculada y DANE; Escenarios compara supuestos; Incertidumbre muestra bandas Monte Carlo y distribución del año máximo; Sensibilidad muestra desplazamientos y cambios en población máxima; el Explorador geográfico presenta resultados territoriales.
- Las cifras generadas por los CSV son la referencia para el estado del análisis. `FICHA_TECNICA.md` y `LEEME.md` son documentos de apoyo que pueden contener cifras o descripciones de versiones anteriores; comprobar su vigencia antes de repetirlas como actuales.

## Convenciones analíticas

- La población de referencia usada por el modelo filtra `area == "total"`.
- La migración considerada por el modelo filtra `tipo == "internacional"`.
- `modelo.R` compara los escenarios con su propio escenario DANE calibrado, no directamente con la serie oficial, para aislar el efecto de cambiar supuestos. La serie oficial se conserva como referencia externa.
- La TGF calculada con EEVV es una estimación indirecta: no es una medición directa de fecundidad poblacional y no es estrictamente equivalente a la proyección del DANE. Conservar las advertencias metodológicas al editar los textos.
- Sensibilidad varía un componente a la vez; sus resultados no representan interacciones ni todas las combinaciones posibles.
- Usar “máximo poblacional” o “año del máximo poblacional” en vez de “pico” en textos editoriales nuevos, salvo en nombres de archivos/columnas heredados que deban conservarse por compatibilidad.

## Convenciones visuales y de implementación

- El dashboard está en español y utiliza Observable Framework con páginas Markdown y Observable Plot.
- Mantener textos editoriales breves, técnicos y precisos; una página debe responder una pregunta clara.
- Seguir los tokens, tipografía y colores de `dashboard_observable/src/style.css`; no introducir paletas nuevas sin motivo. La identidad del DANE y de la serie propia debe permanecer consistente entre páginas.
- Mantener tooltips separados por serie cuando se comparen EEVV/estimación propia y DANE: cada interacción debe presentar solo los datos de la serie correspondiente.
- El énfasis visual de `<strong>`/`<b>` está estilizado como subrayado en el CSS global; conservar el marcado semántico, no reemplazarlo por estilos inline.
- Asegurar etiquetas y unidades comprensibles, títulos con conclusión, notas metodológicas y comportamiento legible en móvil.
- En Observable, usar las interacciones documentadas por Observable Plot y comprobar que el patrón elegido realmente responde al cursor en el navegador.

## Pendiente de verificación conocido

El tooltip/interacción del primer gráfico de `dashboard_observable/src/sensibilidad.md` ha sido reportado como no interactivo. La versión más reciente añade `tip: true` a los puntos, pero su funcionamiento con el cursor real no quedó confirmado. Si se retoma esa tarea, probar la página en navegador; si continúa fallando, reemplazarlo por una interacción Observable Plot ya comprobada, sin duplicar innecesariamente el gráfico de barras.

## Archivos principales del dashboard

- `dashboard_observable/src/index.md`
- `dashboard_observable/src/fecundidad.md`
- `dashboard_observable/src/escenarios.md`
- `dashboard_observable/src/incertidumbre.md`
- `dashboard_observable/src/sensibilidad.md`
- `dashboard_observable/src/explorador-geografico.md`
- `dashboard_observable/src/style.css`
- `dashboard_observable/observablehq.config.js`

Antes de editar, inspeccionar el archivo y el cargador de datos correspondiente. Después de cambios en páginas o datos, ejecutar `npm run build` desde `dashboard_observable/` y reportar fielmente cualquier error. No afirmar que una interacción fue probada manualmente si solo se compiló el sitio.
