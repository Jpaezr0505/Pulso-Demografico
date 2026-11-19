# =============================================================================
# PROYECTO DEMOGRAFÍA COLOMBIA
# mapa.R : PREPARA LOS POLÍGONOS PARA EL MAPA DEL TABLERO
#
# REQUISITO: haber corrido main.R y departamentos.R.
#
# POLÍGONOS (en datos_crudos/mapa/, cualquiera de las dos opciones)
#   - departamentos_mgn2018.geojson   (incluido; Marco Geoestadístico DANE 2018), o
#   - MGN_DPTO_POLITICO.shp (+ .shx .dbf .prj)  del Geoportal DANE (MGN, nivel Departamento).
#     Si está el .shp, se usa en lugar del geojson (es la versión más reciente).
#   Ambos deben traer la columna DPTO_CCDGO (código de 2 dígitos).
#
# QUÉ HACE
#   1. Lee los polígonos, los pasa a WGS84 y los simplifica (liviano para web)
#   2. Comprueba que los 33 departamentos casen con resultados/departamentos_metricas.csv
#   3. (Opcional) Disuelve municipios en las 22 regiones del DANE
#
# SALIDAS
#   datos_limpios/mapa_departamentos.geojson   polígonos (cod_dpto, nombre); las métricas se unen en el tablero
#   datos_limpios/mapa_san_andres.geojson      contorno del archipiélago para el recuadro
#   datos_limpios/mapa_regiones.geojson        solo si existe la tabla municipio -> región
# =============================================================================

library(tidyverse)
library(sf)

dir.create("datos_crudos/mapa", recursive = TRUE, showWarnings = FALSE)

# Lee un shapefile o geojson, lo pasa a WGS84 (lat/lon) y lo simplifica (tolerancia en grados)
leer_capa <- function(patron_shp, geojson = NULL, tolerancia = 0.01) {
  shp <- list.files("datos_crudos/mapa", pattern = patron_shp, full.names = TRUE, ignore.case = TRUE)
  shp <- shp[str_detect(shp, "(?i)\\.shp$")]
  f <- if (length(shp) > 0) shp[1] else file.path("datos_crudos/mapa", geojson %||% "")
  if (!file.exists(f)) stop("No encuentro polígonos para '", patron_shp, "' en datos_crudos/mapa/", call. = FALSE)
  cat("Polígonos:", f, "\n")
  st_read(f, quiet = TRUE) %>%
    st_transform(4326) %>%
    st_make_valid() %>%
    st_simplify(dTolerance = tolerancia, preserveTopology = TRUE)
}


# 1. DEPARTAMENTOS -------------------------------------------------------------
dptos <- leer_capa("DPTO", "departamentos_mgn2018.geojson")
if (!"DPTO_CCDGO" %in% names(dptos)) stop("Falta la columna DPTO_CCDGO; columnas: ", paste(names(dptos), collapse = ", "), call. = FALSE)

dptos <- dptos %>% transmute(cod_dpto = str_pad(as.character(DPTO_CCDGO), 2, pad = "0"))

# 2. Control: los 33 departamentos casan uno a uno con las métricas -------------
metricas <- read_csv("resultados/departamentos_metricas.csv", show_col_types = FALSE,
                     col_types = cols(cod_dpto = col_character()))
sin_poligono <- setdiff(metricas$cod_dpto, dptos$cod_dpto)
sin_datos    <- setdiff(dptos$cod_dpto, metricas$cod_dpto)
if (length(sin_poligono) + length(sin_datos) > 0) {
  stop("Códigos que no casan. Sin polígono: ", paste(sin_poligono, collapse = ", "),
       " | Sin datos: ", paste(sin_datos, collapse = ", "), call. = FALSE)
}
cat("Departamentos con polígono y datos:", nrow(dptos), "(deben ser 33)\n")

dptos <- dptos %>% left_join(select(metricas, cod_dpto, nombre = departamento), by = "cod_dpto") %>% arrange(cod_dpto)

if (file.exists("datos_limpios/mapa_departamentos.geojson")) file.remove("datos_limpios/mapa_departamentos.geojson")
st_write(dptos, "datos_limpios/mapa_departamentos.geojson", quiet = TRUE,
         layer_options = "COORDINATE_PRECISION=3")


# 2b. INSET DE SAN ANDRÉS Y PROVIDENCIA ------------------------------------------
# El polígono de 2018 trae el archipiélago como un solo cuadro; para el recuadro del mapa se usa
# un contorno detallado de geoBoundaries (CC BY 4.0) guardado en datos_crudos/mapa/.
archi <- "datos_crudos/mapa/san_andres_geoboundaries.geojson"
if (file.exists(archi)) {
  sa <- st_read(archi, quiet = TRUE) %>% st_transform(4326) %>% transmute(cod_dpto = "88")
  if (file.exists("datos_limpios/mapa_san_andres.geojson")) file.remove("datos_limpios/mapa_san_andres.geojson")
  st_write(sa, "datos_limpios/mapa_san_andres.geojson", quiet = TRUE, layer_options = "COORDINATE_PRECISION=4")
} else cat("(sin recuadro de San Andrés: falta", archi, ")\n")


# 3. REGIONES DEL DANE (OPCIONAL) ----------------------------------------------
# Las 22 regiones demográficas se arman con MUNICIPIOS (no con departamentos
# completos): hacen falta el shapefile municipal y la tabla municipio -> región
# (datos_crudos/mapa/municipio_region.csv con columnas cod_mpio y region).
tabla_region <- "datos_crudos/mapa/municipio_region.csv"
hay_mpio <- length(list.files("datos_crudos/mapa", pattern = "MPIO.*\\.shp$", ignore.case = TRUE)) > 0

if (file.exists(tabla_region) && hay_mpio) {
  mpios <- leer_capa("MPIO", tolerancia = 0.003)
  if (!"MPIO_CDPMP" %in% names(mpios)) stop("El shapefile municipal no trae MPIO_CDPMP.", call. = FALSE)
  m2r <- read_csv(tabla_region, col_types = "cc") %>% transmute(cod_mpio = str_pad(cod_mpio, 5, pad = "0"), region)

  mapa_reg <- mpios %>%
    transmute(cod_mpio = str_pad(as.character(MPIO_CDPMP), 5, pad = "0")) %>%
    left_join(m2r, by = "cod_mpio")
  if (any(is.na(mapa_reg$region))) stop(sum(is.na(mapa_reg$region)), " municipios sin región en municipio_region.csv", call. = FALSE)
  mapa_reg <- mapa_reg %>% group_by(region) %>% summarise(geometry = st_union(geometry), .groups = "drop")
  cat("Regiones:", nrow(mapa_reg), "(deben ser 22; la sigla NAL es el total nacional y no se mapea)\n")

  if (file.exists("datos_limpios/mapa_regiones.geojson")) file.remove("datos_limpios/mapa_regiones.geojson")
  st_write(mapa_reg, "datos_limpios/mapa_regiones.geojson", quiet = TRUE)
} else {
  cat("(regiones omitidas: falta datos_crudos/mapa/municipio_region.csv o el shapefile municipal)\n")
}

cat("\nListo: datos_limpios/mapa_departamentos.geojson\n")
