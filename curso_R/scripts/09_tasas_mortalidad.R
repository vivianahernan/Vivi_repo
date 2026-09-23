# =============================================================================
# 09_tasas_mortalidad.R
# Propósito : Tasas crudas, específicas y ajustadas por edad (método directo),
#             como en los reportes de mortalidad DEIS/MINSAL.
# Entrada   : datos/defunciones.csv, datos/poblacion.csv
# Salida    : resultados/tasas_mortalidad.csv, resultados/g_tasas.png
#
# Tienes en tu Drive el "Reporte de mortalidad Chile 1990-2024.Rmd" (de otro
# autor, MINSAL). Este módulo te enseña la lógica central de ese reporte en
# 60 líneas, para que puedas leerlo y adaptarlo en vez de copiarlo.
# =============================================================================

library(dplyr)
library(readr)
library(ggplot2)

defun <- read_csv("datos/defunciones.csv", show_col_types = FALSE)
pobl  <- read_csv("datos/poblacion.csv", show_col_types = FALSE)

mort <- defun |>
  left_join(pobl, by = c("anio", "sexo", "grupo_edad")) |>
  mutate(sexo = factor(sexo, 1:2, c("Hombre", "Mujer")))
stopifnot(!anyNA(mort$poblacion))   # todo estrato de defunciones tiene población


# --- 1. Tasa cruda por 100.000 -----------------------------------------------
tasa_cruda <- mort |>
  group_by(anio) |>
  summarise(defunciones = sum(defunciones), poblacion = sum(poblacion)) |>
  mutate(tasa_cruda = defunciones / poblacion * 1e5)
tasa_cruda
# La tasa cruda SUBE aunque el riesgo por edad BAJA 1% al año (así se simuló):
# la población envejece. Por eso se ajusta por edad para comparar años/regiones.


# --- 2. Tasas específicas por edad -------------------------------------------
mort <- mort |> mutate(tasa_esp = defunciones / poblacion * 1e5)
mort |> filter(anio == 2024) |> select(sexo, grupo_edad, tasa_esp)


# --- 3. Ajuste directo con población estándar OMS ----------------------------
# Población estándar OMS 2000-2025 colapsada en los mismos tramos. Son los valores
# que usa el Rmd del MINSAL (suman 100.030 por redondeo; al dividir por la suma,
# los pesos quedan exactos).
estandar_oms <- tibble(
  grupo_edad = c("00-14", "15-29", "30-44", "45-64", "65+"),
  pob_std    = c(26150, 24620, 21350, 19680, 8230)
) |>
  mutate(peso = pob_std / sum(pob_std))

tasas <- mort |>
  left_join(estandar_oms, by = "grupo_edad") |>
  group_by(anio, sexo) |>
  # summarise() evalúa en orden: la línea que reescribe "defunciones" va AL FINAL,
  # para que las anteriores usen los valores por grupo de edad y no el total.
  summarise(
    tasa_cruda  = sum(defunciones) / sum(poblacion) * 1e5,
    tasa_ajust  = sum(tasa_esp * peso),       # suma ponderada de tasas específicas
    # Error estándar aproximado (Poisson) de la tasa ajustada
    ee_ajust    = sqrt(sum(peso^2 * defunciones / poblacion^2)) * 1e5,
    defunciones = sum(defunciones),
    .groups = "drop"
  ) |>
  mutate(ic_inf = tasa_ajust - 1.96 * ee_ajust,
         ic_sup = tasa_ajust + 1.96 * ee_ajust)
tasas

dir.create("resultados", showWarnings = FALSE)
write_csv(tasas, "resultados/tasas_mortalidad.csv")


# --- 4. Razón de tasas y cambio porcentual -----------------------------------
tasas |>
  select(anio, sexo, tasa_ajust) |>
  tidyr::pivot_wider(names_from = sexo, values_from = tasa_ajust) |>
  mutate(razon_H_M = Hombre / Mujer)

tasas |>
  group_by(sexo) |>
  summarise(cambio_pct_2015_2024 =
              100 * (tasa_ajust[anio == 2024] / tasa_ajust[anio == 2015] - 1))


# --- 5. Gráfico cruda vs ajustada -------------------------------------------
g <- tasas |>
  tidyr::pivot_longer(c(tasa_cruda, tasa_ajust), names_to = "tipo", values_to = "tasa") |>
  mutate(tipo = recode(tipo, tasa_cruda = "Cruda", tasa_ajust = "Ajustada por edad (OMS)")) |>
  ggplot(aes(anio, tasa, color = sexo, linetype = tipo)) +
  geom_line(linewidth = 0.9) +
  labs(x = "Año", y = "Tasa por 100.000 hab.", color = NULL, linetype = NULL,
       title = "Mortalidad general: tasa cruda vs ajustada por edad",
       caption = "Datos simulados. Población estándar OMS.") +
  theme_minimal()
ggsave("resultados/g_tasas.png", g, width = 8, height = 4.5, dpi = 300)


# =============================================================================
# EJERCICIOS (ejercicios/mis_respuestas_09.R)
# 1. Calcula la tasa ajustada para ambos sexos juntos por año.
# 2. ¿Por qué la tasa cruda sube y la ajustada baja? Explícalo en 3 líneas.
# 3. Abre el Rmd del MINSAL y localiza el chunk donde calcula "sub_tasa". Compáralo
#    con la sección 3 de este script: ¿qué hace igual y qué distinto?
# =============================================================================
