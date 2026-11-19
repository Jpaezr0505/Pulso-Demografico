# =============================================================================
# PROYECTO DEMOGRAFÍA COLOMBIA - ¿Qué tan firme es el pico de población de 2043?
# modelo.R : PROYECTOR + ESCENARIOS + MONTE CARLO + SENSIBILIDAD (fase 2)
#
# REQUISITO: haber corrido main.R (lee datos_limpios/ y resultados/).
#
# QUÉ HACE (en orden)
#   1. Carga las bases limpias
#   2. Proyector por componentes (cohortes), 2018 -> 2070
#   3. Calibración: ¿reproduce la proyección oficial del DANE (pico en 2043)?
#   4. Escenarios de fecundidad (DANE / EEVV congelada / recuperación parcial)
#   5. Monte Carlo (N trayectorias): probabilidad de que el pico sea antes/después de 2043
#   6. Sensibilidad: cuánto mueve el pico cada componente (fecundidad, mortalidad, migración)
#
# SALIDAS (carpeta resultados/):
#   calibracion_proyector.csv | escenarios_poblacion.csv | escenarios_resumen.csv
#   montecarlo_pico.csv | montecarlo_resumen.csv | montecarlo_bandas.csv
#   sensibilidad_pico.csv
#
# CÓMO LEER LOS RESULTADOS
#   - El proyector replica al DANE con un error pequeño (~0,5 %). Por eso los
#     escenarios se comparan contra el propio proyector ("escenario DANE"), no
#     contra la cifra oficial: así la diferencia se debe solo al cambio de supuesto.
#   - Los rangos de incertidumbre del bloque PARÁMETROS son SUPUESTOS del equipo;
#     cámbialos ahí y vuelve a correr.
# =============================================================================

library(tidyverse)

set.seed(2043)                                     # resultados reproducibles


# 0. PARÁMETROS (lo único que se edita) ----------------------------------------
param <- list(
  anio_inicio   = 2018,    # población base (censo 2018)
  anio_fin      = 2070,
  anio_cambio   = 2026,    # los escenarios y la incertidumbre actúan desde este año
  pico_dane     = 2043,    # año de pico oficial
  srb           = 1.05,    # razón de masculinidad al nacer (hombres por mujer)

  # Escenarios de fecundidad (TGF = hijos por mujer)
  tgf_recuperacion = 1.50, # TGF a la que llega en `anio_tgf_meta` el escenario "recuperación parcial"
  anio_tgf_meta    = 2050,

  # Incertidumbre del Monte Carlo
  n_sim         = 100000,   # trayectorias del Monte Carlo (100.000 tarda varios minutos)
  n_detalle     = 5000,     # cuántas simulaciones se guardan una por una en montecarlo_pico.csv
  tgf_min       = 1.00,    # TGF de largo plazo ~ triangular(min, moda, max)
  tgf_moda      = 1.30,
  tgf_max       = 1.80,
  mort_sd       = 0.05,    # factor sobre el riesgo de morir ~ Normal(1, sd)
  mig_media     = 1.00,    # factor sobre la migración neta ~ Normal(media, sd)
  mig_sd        = 0.50,

  # Sensibilidad: valores bajo/alto de cada componente (base = recuperación parcial)
  sens_tgf      = c(1.00, 1.80),
  sens_mort     = c(0.90, 1.10),
  sens_mig      = c(0.00, 2.00)
)

dir.create("resultados", showWarnings = FALSE)
anios <- param$anio_inicio:param$anio_fin


# 1. CARGAR BASES LIMPIAS ------------------------------------------------------
necesarios <- c("datos_limpios/poblacion_limpia.csv", "datos_limpios/asfr_limpia.csv",
                "datos_limpios/tablas_vida_limpia.csv", "datos_limpios/migracion_limpia.csv",
                "resultados/tgf_calculada_vs_dane.csv")
if (any(!file.exists(necesarios))) {
  stop("Faltan archivos (¿corriste main.R?):\n  ", paste(necesarios[!file.exists(necesarios)], collapse = "\n  "), call. = FALSE)
}

pob  <- read_csv("datos_limpios/poblacion_limpia.csv", show_col_types = FALSE) %>% filter(area == "total")
asfr <- read_csv("datos_limpios/asfr_limpia.csv", show_col_types = FALSE)
tv   <- read_csv("datos_limpios/tablas_vida_limpia.csv", show_col_types = FALSE) %>% filter(tipo_tabla == "completa")
mig  <- read_csv("datos_limpios/migracion_limpia.csv", show_col_types = FALSE) %>% filter(tipo == "internacional")
tgf_eevv <- read_csv("resultados/tgf_calculada_vs_dane.csv", show_col_types = FALSE)

# Matrices [edad 0..100 x sexo (hombres, mujeres)] por año, en listas con nombre = año
matriz <- function(d, col, a) {
  x <- d %>% filter(anio == a) %>% arrange(sexo, edad)
  cbind(h = x[[col]][x$sexo == "hombres"], m = x[[col]][x$sexo == "mujeres"])
}
por_anio <- function(f) set_names(map(anios, f), anios)

P_dane <- por_anio(~ matriz(pob, "poblacion", .x))                  # población oficial (para calibrar)
S      <- por_anio(~ matriz(tv, "sx", .x))                          # supervivencia anual por edad
L0     <- por_anio(~ matriz(tv, "nLx", .x)[1, ] / 100000)           # supervivencia del recién nacido
M      <- por_anio(~ matriz(mig, "saldo", .x))                      # migración neta internacional
F_dane <- por_anio(function(a) {                                    # fecundidad por edad (vector 0..100)
  v <- numeric(101); x <- asfr %>% filter(anio == a); v[x$edad + 1] <- x$tasa; v })

tgf_dane_anio <- map_dbl(F_dane, sum)                               # TGF implícita = suma de tasas
total_dane    <- map_dbl(P_dane, sum)


# 2. PROYECTOR -----------------------------------------------------------------
# De un año al siguiente (t -> t+1), con las convenciones que mejor reproducen al DANE:
#   - sobreviven con la tabla de vida de t; el grupo 100+ se acumula
#   - se suma la migración neta de t
#   - nacimientos = tasas del año t+1 x promedio de mujeres al inicio y al final
#
#   fec_f : vector con nombre = año; factor que multiplica las tasas de fecundidad de ese año
#   k     : factor sobre el riesgo de morir (1 = DANE; >1 = más mortalidad), desde anio_cambio
#   mig_f : factor sobre la migración neta (1 = DANE), desde anio_cambio
# Devuelve el total de población por año.
proyectar <- function(fec_f = NULL, k = 1, mig_f = 1) {
  cur <- P_dane[[as.character(param$anio_inicio)]]
  total <- numeric(length(anios)); total[1] <- sum(cur)
  for (i in seq_along(anios)[-length(anios)]) {
    y <- anios[i]
    aplica <- y >= param$anio_cambio
    s <- S[[as.character(y)]]
    if (aplica && k != 1) s <- s^k                                   # k > 1: riesgo de morir mayor
    m <- M[[as.character(y)]] * (if (aplica) mig_f else 1)

    nxt <- matrix(0, 101, 2, dimnames = list(NULL, c("h", "m")))
    nxt[2:101, ] <- cur[1:100, ] * s[1:100, ]
    nxt[101, ]   <- nxt[101, ] + cur[101, ] * s[101, ]
    nxt <- nxt + m

    f <- F_dane[[as.character(y + 1)]] * (if (is.null(fec_f)) 1 else fec_f[[as.character(y + 1)]])
    nac <- sum(f * (cur[, "m"] + pmax(nxt[, "m"], 0)) / 2)
    l0 <- L0[[as.character(y)]]
    if (aplica && k != 1) l0 <- l0^k
    nxt[1, "h"] <- nac * param$srb / (1 + param$srb) * l0["h"]
    nxt[1, "m"] <- nac / (1 + param$srb) * l0["m"]

    cur <- nxt; total[i + 1] <- sum(cur)
  }
  set_names(total, anios)
}

pico <- function(tot) tibble(anio_pico = as.integer(names(which.max(tot))), pob_pico = max(tot))


# 3. CALIBRACIÓN ---------------------------------------------------------------
base <- proyectar()
calibracion <- tibble(anio = anios, pob_modelo = base, pob_dane = total_dane,
                      error_pct = 100 * (pob_modelo / pob_dane - 1))
write_csv(calibracion, "resultados/calibracion_proyector.csv")

cat("\n== Calibración del proyector contra el DANE ==\n")
cat("Pico DANE:", names(which.max(total_dane)), "| pico del modelo:", pico(base)$anio_pico, "\n")
cat("Error absoluto máximo:", round(max(abs(calibracion$error_pct)), 2), "% | en 2043:",
    round(calibracion$error_pct[calibracion$anio == 2043], 2), "%\n")
stopifnot("El proyector no reproduce el pico de 2043 del DANE" = pico(base)$anio_pico == param$pico_dane,
          "El error del proyector supera 1 %" = max(abs(calibracion$error_pct)) < 1)


# 4. ESCENARIOS DE FECUNDIDAD --------------------------------------------------
# Un escenario es una trayectoria de TGF. El factor que se aplica a las tasas por
# edad es TGF_escenario / TGF_DANE de cada año (se conserva la forma por edad del DANE).
# Hasta 2025 los escenarios "EEVV" usan la TGF calculada con EEVV (nacimientos reales).
tgf_eevv_v <- set_names(tgf_eevv$tgf_eevv, tgf_eevv$anio)
tgf_2025   <- tgf_eevv_v[["2025"]]

trayectoria_tgf <- function(tgf_largo, anio_meta = param$anio_tgf_meta) {
  map_dbl(anios, function(a) {
    if (a <= 2025 && as.character(a) %in% names(tgf_eevv_v)) return(tgf_eevv_v[[as.character(a)]])
    if (a <= 2025) return(tgf_dane_anio[[as.character(a)]])
    tgf_2025 + (tgf_largo - tgf_2025) * min(1, (a - 2025) / (anio_meta - 2025))
  }) %>% set_names(anios)
}
factor_fec <- function(tgf_trayectoria) (tgf_trayectoria / tgf_dane_anio) %>% set_names(anios)

escenarios <- list(
  "DANE"                  = NULL,
  "EEVV congelada"        = factor_fec(trayectoria_tgf(tgf_2025)),
  "Recuperación parcial"  = factor_fec(trayectoria_tgf(param$tgf_recuperacion))
)

escenarios_poblacion <- imap_dfr(escenarios, function(f, nombre) {
  tibble(escenario = nombre, anio = anios, poblacion = proyectar(fec_f = f))
})
escenarios_resumen <- escenarios_poblacion %>%
  group_by(escenario) %>%
  summarise(anio_pico = anio[which.max(poblacion)], pob_pico = max(poblacion),
            pob_2043 = poblacion[anio == 2043], pob_2070 = poblacion[anio == 2070], .groups = "drop")

write_csv(escenarios_poblacion, "resultados/escenarios_poblacion.csv")
write_csv(escenarios_resumen,   "resultados/escenarios_resumen.csv")
cat("\n== Escenarios de fecundidad ==\n"); print(escenarios_resumen)


# 5. MONTE CARLO ---------------------------------------------------------------
# Cada trayectoria sortea: TGF de largo plazo (triangular), factor de mortalidad y
# factor de migración. La fecundidad parte de la TGF calculada con EEVV hasta 2025.
rtriang <- function(n, a, c, b) {                    # triangular(mín, moda, máx) por inversa
  u <- runif(n); fc <- (c - a) / (b - a)
  ifelse(u < fc, a + sqrt(u * (b - a) * (c - a)), b - sqrt((1 - u) * (b - a) * (b - c)))
}

sim <- tibble(sim = 1:param$n_sim,
              tgf_largo = rtriang(param$n_sim, param$tgf_min, param$tgf_moda, param$tgf_max),
              k_mort    = pmax(rnorm(param$n_sim, 1, param$mort_sd), 0.5),
              f_mig     = rnorm(param$n_sim, param$mig_media, param$mig_sd))

trayectorias <- pmap(sim, function(sim, tgf_largo, k_mort, f_mig) {
  proyectar(fec_f = factor_fec(trayectoria_tgf(tgf_largo)), k = k_mort, mig_f = f_mig)
})
mat_sim <- do.call(rbind, trayectorias)                                   # N x años
colnames(mat_sim) <- anios

mc_pico <- sim %>% mutate(anio_pico = anios[apply(mat_sim, 1, which.max)],
                          pob_pico  = apply(mat_sim, 1, max))

mc_resumen <- mc_pico %>%
  summarise(n = n(),
            prob_antes_2043   = mean(anio_pico < param$pico_dane),
            prob_en_2043      = mean(anio_pico == param$pico_dane),
            prob_despues_2043 = mean(anio_pico > param$pico_dane),
            pico_p5  = quantile(anio_pico, 0.05), pico_mediana = median(anio_pico),
            pico_p95 = quantile(anio_pico, 0.95),
            pob_pico_p5 = quantile(pob_pico, 0.05), pob_pico_mediana = median(pob_pico),
            pob_pico_p95 = quantile(pob_pico, 0.95))

mc_bandas <- tibble(anio = anios,
                    p5  = apply(mat_sim, 2, quantile, 0.05),
                    p50 = apply(mat_sim, 2, quantile, 0.50),
                    p95 = apply(mat_sim, 2, quantile, 0.95),
                    dane = total_dane)

# Con muchas simulaciones el detalle completo pesa decenas de MB: el tablero usa el conteo por año
mc_conteo <- mc_pico %>% count(anio_pico, name = "simulaciones")
write_csv(mc_conteo,  "resultados/montecarlo_conteo_pico.csv")
write_csv(head(mc_pico, param$n_detalle), "resultados/montecarlo_pico.csv")   # muestra de ejemplo
write_csv(mc_resumen, "resultados/montecarlo_resumen.csv")
write_csv(mc_bandas,  "resultados/montecarlo_bandas.csv")
cat("\n== Monte Carlo (", param$n_sim, " trayectorias) ==\n", sep = ""); print(t(mc_resumen))


# 6. SENSIBILIDAD --------------------------------------------------------------
# Se mueve un componente a la vez entre su valor bajo y alto; los demás quedan en la
# base (fecundidad: recuperación parcial; mortalidad y migración: DANE).
f_base <- factor_fec(trayectoria_tgf(param$tgf_recuperacion))
pico_base <- pico(proyectar(fec_f = f_base))

sens_una <- function(componente, valores) {
  map_dfr(valores, function(v) {
    tot <- switch(componente,
                  "Fecundidad (TGF largo plazo)" = proyectar(fec_f = factor_fec(trayectoria_tgf(v))),
                  "Mortalidad (factor de riesgo)" = proyectar(fec_f = f_base, k = v),
                  "Migración (factor sobre el saldo)" = proyectar(fec_f = f_base, mig_f = v))
    bind_cols(tibble(componente = componente, valor = v), pico(tot))
  })
}

sensibilidad <- bind_rows(
  sens_una("Fecundidad (TGF largo plazo)",      param$sens_tgf),
  sens_una("Mortalidad (factor de riesgo)",     param$sens_mort),
  sens_una("Migración (factor sobre el saldo)", param$sens_mig)
) %>%
  mutate(desplaza_anios = anio_pico - pico_base$anio_pico,
         cambio_pob_pico_pct = 100 * (pob_pico / pico_base$pob_pico - 1))

write_csv(sensibilidad, "resultados/sensibilidad_pico.csv")
cat("\n== Sensibilidad (base: pico", pico_base$anio_pico, ") ==\n"); print(sensibilidad)

cat("\nListo: resultados en la carpeta resultados/\n")