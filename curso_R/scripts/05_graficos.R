# =============================================================================
# 05_graficos.R
# Propósito : Gráficos con ggplot2 listos para un informe.
# Entrada   : datos/encuesta_limpia.rds
# Salida    : resultados/*.png
#
# Lógica de ggplot: datos + aes(qué variable va en qué eje/color) + geom_(tipo)
# Se agregan capas con "+", no con "|>".
# =============================================================================

library(dplyr)
library(ggplot2)

enc <- readRDS("datos/encuesta_limpia.rds")
dir.create("resultados", showWarnings = FALSE)
theme_set(theme_minimal(base_size = 12))


# --- 1. Distribución de una variable continua: histograma --------------------
g1 <- ggplot(enc, aes(x = phq9)) +
  geom_histogram(binwidth = 1, fill = "steelblue", color = "white") +
  geom_vline(xintercept = 10, linetype = "dashed") +
  labs(title = "Distribución del puntaje PHQ-9",
       subtitle = "Línea: punto de corte de síntomas depresivos (>= 10)",
       x = "PHQ-9", y = "Número de personas",
       caption = "Fuente: base simulada del curso")
g1
ggsave("resultados/g1_hist_phq9.png", g1, width = 7, height = 4.5, dpi = 300)


# --- 2. Comparar grupos: boxplot (lo que hacía tu pregunta 1) ---------------
g2 <- ggplot(enc, aes(x = nivel_educ, y = phq9, fill = sexo)) +
  geom_boxplot(outlier.alpha = 0.3) +
  labs(x = "Nivel educacional", y = "PHQ-9", fill = "Sexo")
ggsave("resultados/g2_box_phq9.png", g2, width = 7, height = 4.5, dpi = 300)


# --- 3. Proporciones por grupo: barras con % ya calculado --------------------
prev <- enc |>
  group_by(edad_tramos, sexo) |>
  summarise(prev_hta = mean(hta), n = n(), .groups = "drop")

g3 <- ggplot(prev, aes(x = edad_tramos, y = prev_hta, fill = sexo)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = scales::percent) +
  labs(title = "Prevalencia de hipertensión por edad y sexo (no ponderada)",
       x = "Tramo de edad", y = "Prevalencia", fill = NULL)
ggsave("resultados/g3_prev_hta.png", g3, width = 7, height = 4.5, dpi = 300)


# --- 4. Relación entre dos continuas: dispersión + tendencia -----------------
g4 <- ggplot(filter(enc, !is.na(imc)), aes(x = edad, y = imc)) +
  geom_point(alpha = 0.2) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(x = "Edad (años)", y = "IMC (kg/m²)")
ggsave("resultados/g4_edad_imc.png", g4, width = 7, height = 4.5, dpi = 300)


# --- 5. Paneles por grupo: facet_wrap ----------------------------------------
g5 <- ggplot(enc |> filter(!is.na(perc_salud_f)), aes(x = perc_salud_f)) +
  geom_bar(fill = "darkseagreen") +
  facet_wrap(~ sexo) +
  labs(x = "Autopercepción de salud", y = "n") +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))
ggsave("resultados/g5_perc_salud.png", g5, width = 8, height = 4.5, dpi = 300)

# Reglas para gráficos de informes:
# - Título que diga qué muestra, ejes con unidades, fuente en caption.
# - Si los datos son de encuesta, grafica estimaciones PONDERADAS (módulo 08).
# - Barras siempre desde 0. Evita gráficos de torta y 3D.


# =============================================================================
# EJERCICIOS (ejercicios/mis_respuestas_05.R)
# 1. Histograma de ingreso y de log_ingreso. ¿Cuál se ve más simétrico?
# 2. Gráfico de barras de % con depresión por nivel educacional, separado por sexo.
# 3. Guarda tus gráficos con ggsave() en resultados/.
# =============================================================================
