# =============================================================================
# notas_corregida.R
# Propósito : Versión corregida de Ayudantia_20250326.R (descriptivos de notas).
# Entrada   : datos/notas.csv (columnas Prueba1 ... Prueba4; puede tener un id)
# Salida    : resultados/notas_resumen.csv
# Cambios vs original:
#   - sin setwd(); read_csv asignado a un objeto
#   - "matriz" -> "notas": es un data frame, no una matriz
#   - 20 líneas copiadas (mean/sd/min/max x 4) -> una sola llamada con across()
#   - sum(matriz) eliminado: sumar TODA la tabla no tiene interpretación
#   - rowMeans solo sobre las columnas de pruebas (no sobre el id)
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)

notas <- read_csv("datos/notas.csv", show_col_types = FALSE)
glimpse(notas)

# --- 1. Descriptivos por prueba (formato largo = una fila por prueba) -------
resumen <- notas |>
  pivot_longer(starts_with("Prueba"), names_to = "prueba", values_to = "nota") |>
  group_by(prueba) |>
  summarise(n = sum(!is.na(nota)), media = mean(nota, na.rm = TRUE),
            de = sd(nota, na.rm = TRUE), min = min(nota, na.rm = TRUE),
            max = max(nota, na.rm = TRUE), .groups = "drop")
resumen
dir.create("resultados", showWarnings = FALSE)
write_csv(resumen, "resultados/notas_resumen.csv")

# --- 2. Promedio por estudiante ---------------------------------------------
notas <- notas |>
  mutate(promedio = rowMeans(pick(starts_with("Prueba")), na.rm = TRUE))
notas

# Estudiante 4 y 8 (lo que hacías con matriz[4, ] y matriz[8, ]):
notas |> slice(c(4, 8))
