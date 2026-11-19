# =============================================================================
# reproducir.R : ejecuta todo el análisis en orden, de los Excel crudos a los
# CSV que lee el tablero.
#
# Uso (desde la raíz del repositorio):   source("reproducir.R")
# Tiempo aproximado: varios minutos (el Monte Carlo usa 100.000 trayectorias).
# Los resultados son reproducibles: modelo.R fija set.seed(2043).
# =============================================================================

paquetes <- c("tidyverse", "readxl", "sf")
faltan <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltan)) stop("Instala primero: install.packages(c(",
                         paste0('"', faltan, '"', collapse = ", "), "))")

pasos <- c(
  "main.R",           # 1. Limpieza y validación (DANE + EEVV)  -> datos_limpios/
  "modelo.R",         # 2. Proyector, escenarios, Monte Carlo, sensibilidad -> resultados/
  "departamentos.R",  # 3. Métricas por departamento y picos regionales
  "mapa.R"            # 4. GeoJSON para el mapa del tablero
)

for (p in pasos) {
  cat("\n>>> Ejecutando", p, "\n")
  source(p, echo = FALSE)
}
cat("\nListo. Ahora compila el tablero: cd dashboard_observable && npm ci && npm run build\n")
cat("Versión de R:", R.version.string, "\n")
