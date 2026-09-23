# =============================================================================
# tarea_WP_corregida.R
# Propósito : Versión corregida de tarea_WP_data_20250409.R (Seminario Metodológico).
#             Desempeño por participante en la tarea Weather Prediction.
# Entrada   : datos/WeatherPred_data.csv  (cópialo a la carpeta datos/ del proyecto)
#             Columnas esperadas: Participant, Trial, Performance (0/1), Sex
# Salida    : resultados/wp_por_participante.csv, resultados/wp_*.png
# =============================================================================

library(dplyr)
library(readr)
library(ggplot2)

archivo <- "datos/WeatherPred_data.csv"
if (!file.exists(archivo)) stop("Copia WeatherPred_data.csv a la carpeta datos/")
wp <- read_csv(archivo, show_col_types = FALSE)

# --- 1. Estructura ---------------------------------------------------------
glimpse(wp)
stopifnot(all(c("Participant", "Trial", "Performance", "Sex") %in% names(wp)))

n_participantes <- n_distinct(wp$Participant)      # NO max(Participant)
ensayos_por_part <- count(wp, Participant)
summary(ensayos_por_part$n)                         # ¿todos tienen los mismos ensayos?
table(wp$Performance, useNA = "ifany")              # 0/1 y NA (ensayos sin respuesta)
table(wp$Sex, useNA = "ifany")                      # REVISA el libro de códigos del sexo

# --- 2. Resumen por participante -------------------------------------------
# Performance es 0/1: su media = proporción de respuestas correctas.
# No se usa la moda (mfv): con 0/1 solo diría si acertó más de la mitad.
por_part <- wp |>
  group_by(Participant) |>
  summarise(
    sexo          = first(Sex),             # el sexo es constante dentro de la persona
    n_ensayos     = n(),
    n_respondidos = sum(!is.na(Performance)),
    prop_correct  = mean(Performance, na.rm = TRUE),
    .groups = "drop"
  )
stopifnot(nrow(por_part) == n_participantes)

# Chequeo: ¿alguien tiene sexo distinto entre ensayos? (error de digitación)
wp |> group_by(Participant) |> summarise(k = n_distinct(Sex)) |> filter(k > 1)

cat("Participantes:", n_participantes, "\n")
cat("Proporción media de aciertos:", round(mean(por_part$prop_correct), 3), "\n")
cat("% que responde sobre el azar (> 0.5):",
    round(100 * mean(por_part$prop_correct > 0.5), 1), "\n")

dir.create("resultados", showWarnings = FALSE)
write_csv(por_part, "resultados/wp_por_participante.csv")

# --- 3. Gráficos ------------------------------------------------------------
g_hist <- ggplot(por_part, aes(prop_correct)) +
  geom_histogram(binwidth = 0.05, boundary = 0, fill = "lightblue", color = "white") +
  geom_vline(xintercept = 0.5, linetype = "dashed") +
  labs(x = "Proporción de respuestas correctas", y = "N° de participantes",
       title = "Desempeño en la tarea Weather Prediction",
       subtitle = "Línea: desempeño esperado por azar")
ggsave("resultados/wp_hist.png", g_hist, width = 7, height = 4.5, dpi = 300)

g_box <- ggplot(por_part, aes(factor(sexo), prop_correct)) +
  geom_boxplot() + geom_jitter(width = 0.1, alpha = 0.5) +
  labs(x = "Sexo (ver códigos)", y = "Proporción de respuestas correctas")
ggsave("resultados/wp_box_sexo.png", g_box, width = 6, height = 4.5, dpi = 300)

# --- 4. Inferencia (lo que el script original no llegaba a hacer) ------------
# ¿El grupo supera el azar? t de una muestra contra 0.5
t.test(por_part$prop_correct, mu = 0.5)
# ¿Difiere por sexo? (unidad de análisis = participante, NO ensayo)
if (n_distinct(por_part$sexo) == 2) t.test(prop_correct ~ sexo, data = por_part)

# Nivel más avanzado: modelo logístico multinivel a nivel de ensayo, con
# aprendizaje a lo largo de los ensayos (install.packages("lme4")):
# lme4::glmer(Performance ~ Trial + Sex + (1 | Participant), data = wp, family = binomial)
