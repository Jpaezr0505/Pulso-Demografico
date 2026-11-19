# Pulso Demográfico · Demografía de Colombia 2018–2070

**Del dato a la decisión: un explorador estadístico de la demografía colombiana.**
Proyecto de Estadística (curso de Demografía) que contrasta la proyección de población del DANE con la fecundidad calculada desde las Estadísticas Vitales (EEVV) y mide qué tan probable es que el máximo poblacional de **2043** se cumpla.

**Autores:** Juan David Jerónimo González · Juan Esteban Páez Ruiz

🌐 **Tablero en línea:** _(pegar aquí el enlace de Netlify)_

> El análisis propio complementa —no reemplaza— la proyección oficial. Las probabilidades de Monte Carlo son condicionales a los supuestos del modelo; la fecundidad EEVV es una estimación indirecta.

## Pregunta y hallazgos

El DANE proyecta que Colombia alcanza su máximo en **2043** (56.048.194 personas), suponiendo 1,65 hijos por mujer en 2025. Con los nacimientos registrados (EEVV) la fecundidad calculada es ≈ **1,03**. Con esa brecha, el repositorio responde: ¿qué tan firme es el 2043?

El tablero tiene cinco secciones: **Fecundidad** (DANE vs. EEVV), **Escenarios** (DANE, EEVV congelada, recuperación parcial), **Incertidumbre** (Monte Carlo de 100.000 trayectorias), **Sensibilidad** (qué componente mueve más el máximo) y **Territorio** (año del máximo por departamento y región).

## Reproducir el análisis

**Requisitos:** R (versión reciente) con los paquetes `tidyverse`, `readxl` y `sf`; Node.js ≥ 18 y npm. Todos los insumos están en el repositorio (`datos_crudos/`), no hay que descargar nada.

```r
# En R/RStudio, desde la raíz del repositorio
install.packages(c("tidyverse", "readxl", "sf"))
source("reproducir.R")   # main.R -> modelo.R -> departamentos.R -> mapa.R
```

```sh
# Tablero (Observable Framework)
cd dashboard_observable
npm ci
npm run dev      # vista local en http://localhost:3000
npm run build    # compilación de producción en dist/
```

- `modelo.R` fija `set.seed(2043)`: los resultados del Monte Carlo son idénticos en cada ejecución.
- `main.R` termina con una lista de controles de calidad (`resultados/controles.csv`); deben pasar todos.
- El tablero **no calcula nada**: solo lee los CSV y GeoJSON generados por R.
- En cada `push`, GitHub Actions compila el tablero para comprobar que sigue funcionando.

## Flujo de datos

```
datos_crudos/ (Excel DANE, EEVV, geojson)
   │  main.R
   ▼
datos_limpios/ ──► modelo.R ──► resultados/ (escenarios, Monte Carlo, sensibilidad)
   │                 departamentos.R ──► resultados/ + mapa.R ──► datos_limpios/*.geojson
   ▼
dashboard_observable/  (loaders en src/data/ leen resultados/ y datos_limpios/)  ──►  sitio web
```

## Estructura

| Ruta | Contenido |
|---|---|
| `reproducir.R` | Ejecuta todo el análisis en orden |
| `main.R` | Limpieza y validación de datos DANE y EEVV |
| `modelo.R` | Proyector por cohortes, escenarios, Monte Carlo y sensibilidad |
| `departamentos.R` | Métricas por departamento (pico, TGF, nacimientos) y picos regionales |
| `mapa.R` | Procesamiento territorial y generación de GeoJSON |
| `datos_crudos/` | Insumos originales sin modificar (DANE, EEVV, MGN 2018, geoBoundaries) |
| `datos_limpios/` | Datos procesados para el modelo y el tablero |
| `resultados/` | Tablas generadas por los scripts R |
| `dashboard_observable/` | Sitio web (Observable Framework) |
| `FICHA_TECNICA.md` | Metodología, supuestos y fuentes |
| `PROJECT_CONTEXT.md` | Contexto técnico ampliado |
| `netlify.toml` | Configuración de publicación en Netlify |

## Limitaciones

- La fecundidad EEVV es calculada, no observada: incluye nacimientos de madres residentes en el exterior y usa población proyectada como denominador.
- Los rangos del Monte Carlo y de la sensibilidad son supuestos del equipo, no probabilidades oficiales.
- En 8 de las 22 regiones el máximo cae después de 2050, el último año de la proyección regional del DANE.

## Fuentes y licencia

DANE (proyecciones de población 2018–2070, fecundidad, mortalidad, migración, Marco Geoestadístico Nacional), Estadísticas Vitales (nacimientos 2018–2025) y geoBoundaries (San Andrés, CC BY 4.0). Detalles y atribución en `FICHA_TECNICA.md`.

Los datos son de sus entidades de origen y se incluyen para reproducibilidad; verificar sus condiciones de uso antes de redistribuir. El código del proyecto aún no tiene licencia asignada.
