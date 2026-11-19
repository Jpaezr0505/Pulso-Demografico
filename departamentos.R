# =============================================================================
# PROYECTO DEMOGRAFÍA COLOMBIA
# departamentos.R : MÉTRICAS POR DEPARTAMENTO PARA EL MAPA
#
# REQUISITO: haber corrido main.R (usa datos_limpios/eevv_departamental.csv) y tener
#   datos_crudos/dane/PPED-AreaSexoEdadDep-2018-2050_VP.xlsx  (DANE, proyección departamental)
#
# QUÉ CALCULA (por departamento)
#   1. Población total 2018-2050 y mujeres de 10 a 49 años por grupo quinquenal (DANE)
#   2. Año del máximo poblacional según el DANE (si es 2050, el máximo es "después de 2050")
#   3. Fecundidad 2018-2025 (hijos por mujer): nacimientos EEVV / mujeres DANE, con el
#      mismo método de main.R (50-54 se suma a 45-49; "sin información" se reparte)
#   4. Nacimientos 2018-2025 y su variación
#
# SALIDAS (carpeta resultados/)
#   departamentos_metricas.csv    una fila por departamento
#   departamentos_serie.csv       departamento x año: nacimientos, mujeres 15-49, TGF (2018-2025)
#   departamentos_poblacion.csv   departamento x año: población DANE 2018-2050
#   regiones_pico.csv             año del máximo de las 22 regiones demográficas del DANE (2018-2050)
# =============================================================================

library(tidyverse)
library(readxl)

archivo <- "datos_crudos/dane/PPED-AreaSexoEdadDep-2018-2050_VP.xlsx"
if (!file.exists(archivo)) stop("Falta ", archivo, call. = FALSE)
dir.create("resultados", showWarnings = FALSE)

# 1. POBLACIÓN DEPARTAMENTAL (DANE) --------------------------------------------
# Hoja 3, datos desde la fila 10. Columnas: 4 de identificación, total, hombres,
# mujeres, y luego hombres 0-100, mujeres 0-100, total 0-100.
edades <- 0:100
nombres <- c("cod_dpto", "dpto", "anio", "area", "tot", "tot_h", "tot_m",
             paste0("h_", edades), paste0("m_", edades), paste0("t_", edades))

pob <- read_excel(archivo, sheet = 3, skip = 9, col_names = nombres) %>%
  filter(area == "Total", !is.na(anio)) %>%               # solo el total del departamento
  mutate(anio = as.integer(anio))

stopifnot(n_distinct(pob$cod_dpto) == 33, setequal(unique(pob$anio), 2018:2050))

poblacion <- pob %>% transmute(cod_dpto, anio, poblacion = as.numeric(tot))

# Mujeres de 10-49 por grupo quinquenal (mismos grupos que las EEVV)
grupo_5 <- function(e) as.character(cut(e, c(9, 14, 19, 24, 29, 34, 39, 44, 49),
  labels = c("10-14", "15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49")))

mujeres <- pob %>%
  select(cod_dpto, anio, starts_with("m_")) %>%
  pivot_longer(starts_with("m_"), names_to = "edad", names_prefix = "m_", values_to = "mujeres") %>%
  mutate(edad = as.integer(edad)) %>%
  filter(edad %in% 10:49) %>%
  mutate(grupo = grupo_5(edad)) %>%
  group_by(cod_dpto, anio, grupo) %>% summarise(mujeres = sum(as.numeric(mujeres)), .groups = "drop")


# 2. AÑO DEL MÁXIMO POBLACIONAL ------------------------------------------------
pico <- poblacion %>%
  group_by(cod_dpto) %>%
  summarise(pico_anio = anio[which.max(poblacion)],
            pico_poblacion = max(poblacion),
            pob_2018 = poblacion[anio == 2018],
            pob_2050 = poblacion[anio == 2050],
            .groups = "drop") %>%
  mutate(pico_censurado = pico_anio == 2050)                # sigue creciendo al final de la serie


# 3. FECUNDIDAD EEVV POR DEPARTAMENTO ------------------------------------------
eevv <- read_csv("datos_limpios/eevv_departamental.csv", show_col_types = FALSE,
                 col_types = cols(cod_dpto = col_character())) %>%
  filter(!cod_dpto %in% c("EX", "SI"))                      # sin departamento no se mapea

nombres_dpto <- eevv %>% distinct(cod_dpto, departamento)

nac <- eevv %>%
  mutate(grupo = if_else(grupo_edad == "50-54", "45-49", grupo_edad)) %>%
  group_by(cod_dpto, anio, grupo) %>% summarise(nacimientos = sum(nacimientos), .groups = "drop")

serie <- nac %>%
  group_by(cod_dpto, anio) %>%
  mutate(sin_info = sum(nacimientos[grupo == "sin_info"]),
         nac_total = sum(nacimientos)) %>%                  # incluye sin_info
  filter(grupo != "sin_info") %>%
  mutate(nacimientos_aj = nacimientos * (1 + sin_info / sum(nacimientos))) %>%   # reparte sin_info
  ungroup() %>%
  left_join(mujeres, by = c("cod_dpto", "anio", "grupo")) %>%
  group_by(cod_dpto, anio) %>%
  summarise(nacimientos = first(nac_total),
            mujeres_15_49 = sum(mujeres[grupo != "10-14"]),
            tgf = 5 * sum(nacimientos_aj / mujeres),
            .groups = "drop")


# 4. TABLA FINAL ---------------------------------------------------------------
metricas <- pico %>%
  left_join(nombres_dpto, by = "cod_dpto") %>%
  left_join(serie %>% filter(anio == 2018) %>% select(cod_dpto, nac_2018 = nacimientos, tgf_2018 = tgf), by = "cod_dpto") %>%
  left_join(serie %>% filter(anio == 2025) %>% select(cod_dpto, nac_2025 = nacimientos, tgf_2025 = tgf), by = "cod_dpto") %>%
  mutate(variacion_nac_pct = 100 * (nac_2025 / nac_2018 - 1),
         cambio_tgf = tgf_2025 - tgf_2018) %>%
  select(cod_dpto, departamento, pico_anio, pico_censurado, pico_poblacion, pob_2018, pob_2050,
         nac_2018, nac_2025, variacion_nac_pct, tgf_2018, tgf_2025, cambio_tgf) %>%
  arrange(cod_dpto)

# Controles
stopifnot(nrow(metricas) == 33, !anyNA(metricas), !anyNA(serie))
nac_nacional <- read_csv("datos_limpios/eevv_nacional.csv", show_col_types = FALSE) %>%
  group_by(anio) %>% summarise(n = sum(nacimientos))
dif <- serie %>% group_by(anio) %>% summarise(n_dptos = sum(nacimientos)) %>% left_join(nac_nacional, by = "anio") %>%
  mutate(sin_dpto = n - n_dptos)
cat("Nacimientos nacionales - suma de departamentos (exterior + sin información):\n"); print(dif)

# 5. AÑO DEL MÁXIMO EN LAS 22 REGIONES DEL DANE ---------------------------------
regiones <- read_csv("datos_limpios/totales_oficiales_regional_limpia.csv", show_col_types = FALSE) %>%
  filter(area == "total") %>%
  group_by(sigla, territorio) %>%
  summarise(pico_anio = anio[which.max(total)], pob_2018 = total[anio == 2018], pob_pico = max(total), .groups = "drop") %>%
  mutate(pico_censurado = pico_anio == 2050) %>%
  arrange(pico_anio, territorio)
stopifnot(nrow(regiones) == 22)

write_csv(regiones,    "resultados/regiones_pico.csv")
write_csv(metricas,    "resultados/departamentos_metricas.csv")
write_csv(serie,       "resultados/departamentos_serie.csv")
write_csv(poblacion,   "resultados/departamentos_poblacion.csv")
cat("\nListo: resultados/departamentos_*.csv\n")
