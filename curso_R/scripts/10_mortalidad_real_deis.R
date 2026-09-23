# =============================================================================
# 10_mortalidad_real_deis.R
# Propósito : Aplicar el módulo 09 a datos REALES del DEIS: tasas de mortalidad
#             cruda y ajustada por edad, Chile y regiones, 2010-2025.
# Entrada   : "Defunciones por Semana Epidemiológica, Sexo, Grupo de Edad y Región"
#             (MINSAL/DEIS, publicado en datos.gob.cl). Se descarga la primera vez.
#             Separador "|"; trae MUERTES_OBS y POBLACION (repetida cada semana).
# Salida    : resultados/deis_tasas_nacionales.csv, resultados/deis_tasas_region.csv,
#             resultados/deis_tasas.png
# Notas     : - ANO_ESTADISTICO es el año EPIDEMIOLÓGICO (52 o 53 semanas).
#             - El último año está incompleto y los 2-3 anteriores son preliminares.
# =============================================================================

library(dplyr)
library(readr)
library(ggplot2)

url_deis <- "https://datos.gob.cl/dataset/1c2811cd-13a4-4406-b20d-cda1544b65d0/resource/90d092cc-bf19-4bcc-bfb0-22b0c5db6707/download/def_semana_epidemiologica.csv"
archivo <- "datos/deis_def_semana_epidemiologica.csv"
if (!file.exists(archivo)) download.file(url_deis, archivo, mode = "wb")

def <- read_delim(archivo, delim = "|", show_col_types = FALSE) |>
  rename_with(tolower)   # ANO_ESTADISTICO -> ano_estadistico
glimpse(def)


# --- 1. Chequeos -------------------------------------------------------------
table(def$grupo_edad)
def |> count(ano_estadistico, name = "filas") |> print(n = 30)

# La población es anual: debe ser la misma en todas las semanas del año
chequeo <- def |>
  group_by(ano_estadistico, grupo_edad, sexo, region) |>
  summarise(k = n_distinct(poblacion), .groups = "drop")
stopifnot(all(chequeo$k == 1))

# Excluimos el año en curso (incompleto): el último año de la base
ultimo_anio <- max(def$ano_estadistico)
def <- def |> filter(ano_estadistico < ultimo_anio)


# --- 2. Base anual: defunciones y población por año, región, sexo y edad -----
anual <- def |>
  group_by(anio = ano_estadistico, region, sexo, grupo_edad) |>
  summarise(defunciones = sum(muertes_obs),
            poblacion   = first(poblacion),   # NO sumar: se repite cada semana
            .groups = "drop")


# --- 3. Población estándar OMS colapsada a los grupos del DEIS ---------------
# 0-14: 8.86+8.69+8.60 | 15-39: 8.47+8.22+7.93+7.61+7.15 | 40-64: 6.59+6.04+5.37+4.55+3.72
# 65-79: 2.96+2.21+1.52 | 80+: 0.91+0.63
estandar <- tibble(
  grupo_edad = c("0 a 14", "15 a 39", "40 a 64", "65 a 79", "80 +"),
  pob_std    = c(26.15, 39.38, 26.27, 6.69, 1.54)
) |>
  mutate(peso = pob_std / sum(pob_std))
stopifnot(setequal(estandar$grupo_edad, unique(anual$grupo_edad)))

tasas_ajustadas <- function(datos, ...) {
  datos |>
    group_by(anio, ..., grupo_edad) |>
    summarise(defunciones = sum(defunciones), poblacion = sum(poblacion), .groups = "drop") |>
    left_join(estandar, by = "grupo_edad") |>
    group_by(anio, ...) |>
    # ORDEN IMPORTANTE: summarise() evalúa de arriba a abajo. Si primero escribes
    # defunciones = sum(defunciones), las líneas siguientes ya ven el TOTAL y no
    # los valores por grupo de edad (la tasa ajustada saldría igual a la cruda).
    summarise(
      tasa_ajust  = sum(defunciones / poblacion * peso) * 1e5,
      ee_ajust    = sqrt(sum(peso^2 * defunciones / poblacion^2)) * 1e5,
      tasa_cruda  = sum(defunciones) / sum(poblacion) * 1e5,
      defunciones = sum(defunciones),
      poblacion   = sum(poblacion),
      .groups = "drop"
    ) |>
    mutate(ic_inf = tasa_ajust - 1.96 * ee_ajust, ic_sup = tasa_ajust + 1.96 * ee_ajust)
}


# --- 4. Resultados -----------------------------------------------------------
nacional <- tasas_ajustadas(anual)
nacional |> select(anio, defunciones, tasa_cruda, tasa_ajust) |> print(n = 20)
# Observa: 2020-2022 (COVID-19) sube la mortalidad; la tasa cruda crece más que
# la ajustada en el período porque la población envejece.

por_sexo   <- tasas_ajustadas(anual, sexo) |> mutate(sexo = factor(sexo, 1:2, c("Hombre", "Mujer")))
por_region <- tasas_ajustadas(anual, region)

# Ranking regional del último año completo: la tasa CRUDA engaña porque las
# regiones tienen estructuras de edad distintas; compara con la AJUSTADA.
por_region |>
  filter(anio == max(anio)) |>
  mutate(rank_cruda = rank(-tasa_cruda), rank_ajust = rank(-tasa_ajust)) |>
  arrange(desc(tasa_ajust)) |>
  select(region, tasa_cruda, rank_cruda, tasa_ajust, rank_ajust)

dir.create("resultados", showWarnings = FALSE)
write_csv(nacional, "resultados/deis_tasas_nacionales.csv")
write_csv(por_region, "resultados/deis_tasas_region.csv")


# --- 5. Gráfico --------------------------------------------------------------
g <- ggplot(por_sexo, aes(anio, tasa_ajust, color = sexo)) +
  geom_ribbon(aes(ymin = ic_inf, ymax = ic_sup, fill = sexo), alpha = 0.2, color = NA) +
  geom_line(linewidth = 0.9) +
  annotate("rect", xmin = 2019.5, xmax = 2022.5, ymin = -Inf, ymax = Inf, alpha = 0.08) +
  annotate("text", x = 2021, y = max(por_sexo$tasa_ajust) * 1.03, label = "COVID-19", size = 3.5) +
  labs(x = "Año epidemiológico", y = "Tasa ajustada por 100.000 hab.", color = NULL, fill = NULL,
       title = "Mortalidad general ajustada por edad, Chile",
       caption = "Fuente: DEIS-MINSAL, datos.gob.cl. Población estándar OMS. Últimos años preliminares.") +
  theme_minimal()
ggsave("resultados/deis_tasas.png", g, width = 8, height = 4.5, dpi = 300)


# =============================================================================
# EJERCICIOS (ejercicios/mis_respuestas_10.R)
# 1. Calcula el exceso de mortalidad de 2020 y 2021: defunciones observadas menos
#    el promedio 2015-2019 (en conteos y en tasa ajustada).
# 2. ¿Qué región tiene la mayor diferencia entre su ranking crudo y ajustado? ¿Por qué?
# 3. Repite el gráfico solo para el grupo de 80+ (tasa específica, no ajustada).
# =============================================================================
