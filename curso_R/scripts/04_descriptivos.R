# =============================================================================
# 04_descriptivos.R
# Propósito : Estadística descriptiva correcta según el tipo de variable,
#             y una "Tabla 1" exportable.
# Entrada   : datos/encuesta_limpia.rds (se crea en el módulo 03)
# Salida    : resultados/tabla1.csv
#
# Todo lo de este módulo es NO PONDERADO: describe la MUESTRA. Para estimar
# prevalencias de la POBLACIÓN con encuestas nacionales -> módulo 08.
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)

enc <- readRDS("datos/encuesta_limpia.rds")

# --- 1. ¿Qué resumen corresponde a cada tipo de variable? --------------------
#   Nominal (sexo, previsión)      -> frecuencias y %
#   Ordinal (perc_salud 1-5)       -> frecuencias, %, mediana, RIC. La media de una
#                                     Likert se reporta a veces, pero no es lo ideal
#   Binaria (hta, depresión)       -> proporción (= media de 0/1)
#   Continua simétrica (imc)       -> media y DE
#   Continua asimétrica (ingreso)  -> mediana y RIC (la media se infla con extremos)
#   La moda casi nunca aporta en investigación: por eso no hay mfv() aquí.


# --- 2. Variables categóricas -----------------------------------------------
table(enc$prevision)
prop.table(table(enc$prevision)) * 100
round(prop.table(table(enc$perc_salud_f, useNA = "ifany")) * 100, 1)

# La forma tidy, que puedes exportar:
enc |>
  count(perc_salud_f) |>
  mutate(pct = round(100 * n / sum(n), 1))

# Tabla cruzada con % por fila (¿cómo se distribuye la depresión DENTRO de cada sexo?)
tab <- table(enc$sexo, enc$depresion)
tab
round(prop.table(tab, margin = 1) * 100, 1)   # margin = 1 filas, 2 columnas


# --- 3. Variables continuas -------------------------------------------------
resumen_continua <- function(x) {
  tibble(
    n       = sum(!is.na(x)),
    perdidos = sum(is.na(x)),
    media   = mean(x, na.rm = TRUE),
    de      = sd(x, na.rm = TRUE),
    mediana = median(x, na.rm = TRUE),
    p25     = quantile(x, 0.25, na.rm = TRUE),
    p75     = quantile(x, 0.75, na.rm = TRUE),
    min     = min(x, na.rm = TRUE),
    max     = max(x, na.rm = TRUE)
  )
}
resumen_continua(enc$imc)
resumen_continua(enc$ingreso)   # compara media vs mediana: asimetría

# Por grupos
enc |>
  group_by(nivel_educ) |>
  summarise(resumen_continua(phq9))


# --- 4. Intervalo de confianza de una proporción y de una media --------------
# Prevalencia de depresión con IC 95% (muestra aleatoria simple)
x <- sum(enc$depresion); n <- nrow(enc)
prop.test(x, n)$conf.int          # IC de Wilson
binom.test(x, n)$conf.int         # IC exacto (Clopper-Pearson), útil con n pequeño

# IC 95% de la media de IMC
t.test(enc$imc)$conf.int


# --- 5. Tabla 1 (descriptiva por grupo) -------------------------------------
# Así se construye "a mano"; en tu trabajo real puedes usar gtsummary::tbl_summary()
# (install.packages("gtsummary")), que la hace en una línea y exporta a Word.
tabla1_cont <- enc |>
  group_by(sexo) |>
  summarise(
    `Edad, media (DE)` = sprintf("%.1f (%.1f)", mean(edad), sd(edad)),
    `IMC, media (DE)`  = sprintf("%.1f (%.1f)", mean(imc, na.rm = TRUE), sd(imc, na.rm = TRUE)),
    `Ingreso, mediana [RIC]` = sprintf("%.0f [%.0f-%.0f]",
                                       median(ingreso, na.rm = TRUE),
                                       quantile(ingreso, .25, na.rm = TRUE),
                                       quantile(ingreso, .75, na.rm = TRUE)),
    `HTA, n (%)`       = sprintf("%d (%.1f)", sum(hta), 100 * mean(hta)),
    `Depresión, n (%)` = sprintf("%d (%.1f)", sum(depresion), 100 * mean(depresion)),
    `Fuma, n (%)`      = sprintf("%d (%.1f)", sum(fuma), 100 * mean(fuma))
  ) |>
  pivot_longer(-sexo, names_to = "Variable") |>
  pivot_wider(names_from = sexo, values_from = value)

tabla1_cont
dir.create("resultados", showWarnings = FALSE)
write_csv(tabla1_cont, "resultados/tabla1.csv")


# =============================================================================
# EJERCICIOS (ejercicios/mis_respuestas_04.R)
# 1. Distribución de imc_cat por sexo con % por columna. ¿Qué sexo tiene más obesidad?
# 2. Prevalencia de HTA con IC 95% en personas de 65+.
# 3. Agrega a la Tabla 1 una fila "Salud buena o muy buena, n (%)". Ojo: tiene NA.
#    ¿El denominador es el total de la muestra o solo quienes respondieron? Decláralo.
# =============================================================================
