# Ficha del proyecto — ¿Qué tan firme es el pico de población de 2043?
Colombia 2018-2070 · Proyección del DANE: incertidumbre y sensibilidad

Para quien arma el tablero (persona o IA). El tablero **no calcula nada**: solo lee los CSV/GeoJSON ya generados.

---

## 1. De qué se trata

El DANE proyecta que Colombia deja de crecer en **2043** (pico de 56.048.194 personas). Esa proyección supone que las mujeres tendrán **1,65 hijos en 2025**, pero los nacimientos registrados (EEVV) indican algo mucho más bajo (**≈1,03**).

**Pregunta:** ¿qué tan firme es el 2043? ¿Cuánto se mueve si la fecundidad, la mortalidad o la migración no son lo que supone el DANE?

## 2. Qué problema ayuda a resolver

Casi toda la planeación pública depende de cuánta gente habrá y de qué edades: colegios, salud, pensiones, mercado laboral, vivienda. Hoy se usa **una sola cifra** (pico en 2043) sin decir qué tan segura es.

Este proyecto entrega, en vez de un año único:
- un **rango y una probabilidad** del año del pico;
- **qué componente pesa más** (para saber dónde conviene afinar las estimaciones);
- una **alerta basada en datos observados**: los nacimientos reales ya van por debajo de lo proyectado.

No reemplaza al DANE: lo complementa mostrando cuánta incertidumbre tiene su proyección.

## 3. Qué teníamos (datos de entrada)

| Fuente | Qué es | Se usa para |
|---|---|---|
| **Población DANE** (2018-2070) | Personas por año, sexo y edad (0-100+) | Punto de partida y comparación |
| **Fecundidad DANE** | Hijos por mujer por edad y año | Nacimientos proyectados |
| **Mortalidad y tablas de vida DANE** | Probabilidad de morir/sobrevivir por edad | Muertes proyectadas |
| **Migración DANE** | Saldo neto de migrantes por edad y año | Entradas y salidas |
| **Nacimientos EEVV 2018-2025** | Nacimientos reales por edad de la madre (nacional y por departamento) | Comparar la fecundidad real con la proyectada |
| **Mapa (MGN 2025)** | Polígonos de departamentos | Mapa del tablero |

## 4. Qué se hizo

1. **Limpieza** (`main.R`): se ordenaron todas las bases en tablas simples y se verificaron con controles automáticos (todo cuadra con los totales oficiales).
2. **Comparación con la realidad:** se calculó la fecundidad con los nacimientos EEVV y se contrastó con la del DANE.
3. **Proyector propio** (`modelo.R`): reproduce la proyección del DANE (pico 2043, error máximo 0,5 %). Con él se pueden cambiar los supuestos y ver qué pasa.
4. **Escenarios, Monte Carlo y sensibilidad:** se probó qué pasa con otras fecundidades, y se corrieron 100.000 futuros posibles con incertidumbre en fecundidad, mortalidad y migración.
5. **Departamentos y mapa** (`departamentos.R`, `mapa.R`): año del máximo, TGF y nacimientos por departamento, picos de 22 regiones y los GeoJSON del mapa (página Territorio).

## 5. Resultados (lo que el tablero debe mostrar)

**a) La fecundidad real cae más rápido de lo proyectado** (hijos por mujer)

| Año | EEVV | DANE |
|---|---|---|
| 2018 | 1,68 | 1,88 |
| 2021 | 1,48 | 1,77 |
| 2023 | 1,22 | 1,71 |
| 2025 | **1,03** | **1,65** |

**b) Escenarios**

| Escenario | Año del pico | Población en el pico |
|---|---|---|
| DANE | 2043 | 56,3 M |
| Fecundidad se queda en nivel EEVV (1,03) | **2035** | 52,5 M |
| Recuperación parcial (1,5 en 2050) | 2043 | 53,3 M |

**c) Probabilidad del año del pico (100.000 simulaciones)**
- **Antes de 2043: 76,6 %** · En 2043: 8,4 % · Después: 15,0 %
- Mediana: **2040** · Rango 90 %: **2036 a 2045**

**d) Qué componente pesa más (cuánto mueve el año del pico)**
- **Fecundidad: de −8 a +5 años** ← domina
- Mortalidad: de −2 a +1 años
- Migración: de −1 a 0 años

**Conclusión:** el 2043 es el escenario optimista; lo más probable es un pico más temprano, y la fecundidad es la clave.

## 6. Las bases, por encima

Todas en CSV, columnas sin tildes. `sexo` = hombres/mujeres; `edad` = 0-100 (100 = 100 y más).

**`datos_limpios/`**
- `poblacion_limpia` — anio, area, sexo, edad, poblacion. *Usar `area == "total"`.*
- `asfr_limpia` / `tgf_limpia` — fecundidad por edad / hijos por mujer (DANE).
- `mortalidad_limpia`, `tablas_vida_limpia` — mortalidad y supervivencia.
- `migracion_limpia` — saldo migratorio. *Usar `tipo == "internacional"`.*
- `eevv_nacional` / `eevv_departamental` — nacimientos reales por edad de la madre / por departamento (`cod_dpto` de 2 dígitos como texto, "05").
- `mapa_departamentos.geojson` — polígonos de los 33 departamentos (`cod_dpto`, `nombre`); las métricas están en `resultados/departamentos_metricas.csv`.
- `mapa_san_andres.geojson` — San Andrés, Providencia y Santa Catalina (geoBoundaries) para el recuadro ampliado.

**`resultados/`** (lo que más usa el tablero)

| Archivo | Para qué gráfico |
|---|---|
| `serie_dane_poblacion_total` | Curva oficial 2018-2070 |
| `tgf_calculada_vs_dane` | Fecundidad EEVV vs DANE |
| `fecundidad_calculada_vs_dane` | Lo mismo por grupo de edad |
| `escenarios_poblacion`, `escenarios_resumen` | Curvas y tabla de escenarios |
| `montecarlo_bandas` | Abanico de incertidumbre (p5, p50, p95) |
| `montecarlo_pico` | Histograma del año del pico |
| `montecarlo_resumen` | Tarjetas de probabilidad |
| `sensibilidad_pico` | Gráfico de barras por componente |
| `mapa_metricas_departamento` | Datos del mapa en tabla |

## 7. Ideas para el tablero (claro e intuitivo)

**Regla:** cada pestaña responde **una pregunta** con **un gráfico principal** y un título que dice la conclusión. Pocas pestañas, mismos colores en todas.

| Pestaña | Pregunta | Gráfico principal |
|---|---|---|
| 1. Inicio | ¿Qué dice el DANE? | Curva de población con el pico 2043 marcado + 3 tarjetas (pico, año, población) |
| 2. Fecundidad | ¿Se cumple lo proyectado? | Dos líneas: EEVV vs DANE, con la brecha. Línea de referencia en 2,1 |
| 3. Escenarios | ¿Y si la fecundidad no se recupera? | 3 curvas de población con el año de pico de cada una |
| 4. Incertidumbre | ¿Qué tan firme es el 2043? | Abanico de incertidumbre + histograma del año del pico + tarjetas de probabilidad |
| 5. Qué pesa más | ¿Qué lo mueve? | Barras horizontales por componente |
| 6. Mapa | ¿Dónde bajan más los nacimientos? | Mapa por departamento con selector de año |

**Consejos**
- Tarjetas grandes con la cifra clave: "**77 %** de probabilidad de que el pico llegue antes de 2043".
- El DANE siempre en gris; los escenarios en colores distintos.
- Selector simple (escenario o año), no más.
- Texto corto en cada pestaña: qué se ve y por qué importa.
- Mejora opcional: deslizadores que recalculen en vivo (hay que llevar la función `proyectar()` de `modelo.R`).

**Tecnología:** R Shiny o Quarto (`plotly`, `leaflet`), Streamlit o web estática. Lo más simple de publicar: Quarto o web estática.

## 8. Advertencias (deben verse en el tablero)

- Es fecundidad **"calculada con EEVV"**, no "observada": incluye hijos de madres residentes en el exterior y la población del denominador es una proyección. Es una señal fuerte, no una medida exacta.
- Las probabilidades dependen de **supuestos del equipo** (TGF entre 1,0 y 1,8; mortalidad ±5 %; migración ±50 %). Decir "según los supuestos del modelo".
- El modelo da 56,30 M en 2043 y el DANE 56,05 M (+0,45 %): comparar escenarios contra la curva "DANE" del modelo, y mostrar la oficial como referencia.
- Los escenarios, Monte Carlo y sensibilidad son solo nacionales. El mapa es por departamento (año del máximo según la proyección DANE por departamento, TGF y nacimientos EEVV); las 22 regiones se muestran en un gráfico, no en el mapa (se arman con municipios y la tabla no es pública).

## 9. Pendientes

- Sustituir el MGN 2018 por el MGN 2025 en `datos_crudos/mapa/` y volver a correr `mapa.R`.
- Pedir al DANE la tabla municipio → región (para mapear las 22 regiones).
- Revisar y justificar los rangos de incertidumbre.
- Informe técnico.

## 10. Si eres una IA

- Lee solo los archivos de la sección 6; no recalcules ni inventes datos.
- Usa los nombres de columna tal cual. `cod_dpto` es texto de 2 caracteres.
- Filtra `area == "total"` en población y `tipo == "internacional"` en migración.
- Usa las probabilidades exactas (76,6 %, 8,4 %, 15,0 %) y muestra siempre las advertencias de la sección 8.
- Si falta un archivo, indica qué script lo genera (`main.R`, `modelo.R` o `mapa.R`).

**Fuentes:** DANE — Proyecciones de población 2018-2070 (jul-2025), Estimaciones del cambio demográfico, Estadísticas Vitales (nacimientos 2018-2025), Marco Geoestadístico Nacional 2025.
