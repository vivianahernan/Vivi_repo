# =============================================================================
# 03_limpiar_y_transformar.R
# Propósito : Preparar la base analítica con dplyr (select, rename, filter,
#             mutate, case_when, group_by, summarise, joins, pivot).
# Entrada   : datos/encuesta_salud.csv
# Salida    : datos/encuesta_limpia.rds
#
# Tú ya conoces estos verbos (ayudantías 2 y 3). Lo que falta es usarlos para
# LIMPIAR antes de analizar y verificar cada transformación.
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)

encuesta <- read_csv("datos/encuesta_salud.csv", show_col_types = FALSE)

# --- 1. El pipe -------------------------------------------------------------
# x |> f() |> g()  se lee "toma x, LUEGO aplica f, LUEGO g".
# |> (nativo, R >= 4.1) y %>% (magrittr) son casi equivalentes. Usa uno solo.


# --- 2. Recodificar códigos de no respuesta a NA -----------------------------
enc <- encuesta |>
  mutate(
    perc_salud = if_else(perc_salud %in% c(88, 99), NA_real_, perc_salud),
    imc        = na_if(imc, 999)
  )

# VERIFICA cada recodificación con una tabla cruzada original vs nueva:
table(original = encuesta$perc_salud, nueva = enc$perc_salud, useNA = "ifany")
summary(enc$imc)


# --- 3. Variables categóricas como factores con etiquetas --------------------
enc <- enc |>
  mutate(
    sexo = factor(sexo, levels = 1:2, labels = c("Hombre", "Mujer")),
    nivel_educ = factor(nivel_educ, levels = 1:4,
                        labels = c("Básica", "Media", "Técnica", "Universitaria")),
    prevision = factor(prevision, levels = 1:3, labels = c("FONASA", "ISAPRE", "Otra")),
    # Variable ordinal: el orden importa
    perc_salud_f = factor(perc_salud, levels = 1:5,
                          labels = c("Muy mala", "Mala", "Regular", "Buena", "Muy buena"),
                          ordered = TRUE)
  )


# --- 4. Crear variables nuevas ----------------------------------------------
enc <- enc |>
  mutate(
    # Tramos de edad con case_when. La última condición TRUE ~ atrapa "lo demás".
    edad_tramos = case_when(
      edad < 25 ~ "18-24",
      edad < 35 ~ "25-34",
      edad < 45 ~ "35-44",
      edad < 55 ~ "45-54",
      edad < 65 ~ "55-64",
      edad >= 65 ~ "65+",
      TRUE ~ NA_character_
    ),
    # Alternativa con cut(): útil cuando hay muchos tramos
    edad_tramos2 = cut(edad, breaks = c(17, 24, 34, 44, 54, 64, Inf),
                       labels = c("18-24", "25-34", "35-44", "45-54", "55-64", "65+")),
    # Dicotomizar con punto de corte validado
    depresion = if_else(phq9 >= 10, 1, 0),
    # Salud autopercibida buena/muy buena (indicador habitual en reportes)
    salud_buena = if_else(perc_salud >= 4, 1, 0),   # NA se mantiene NA
    # Clasificación OMS del IMC
    imc_cat = cut(imc, breaks = c(0, 18.5, 25, 30, Inf), right = FALSE,
                  labels = c("Bajo peso", "Normal", "Sobrepeso", "Obesidad")),
    log_ingreso = log(ingreso)
  )

# Verificación: ¿los dos métodos de tramos coinciden? ¿quedó alguien sin tramo?
table(enc$edad_tramos, enc$edad_tramos2, useNA = "ifany")
enc |> group_by(edad_tramos) |> summarise(min = min(edad), max = max(edad), n = n())


# --- 5. Seleccionar, renombrar, filtrar, ordenar -----------------------------
enc |> select(folio, sexo, edad, phq9) |> head()
enc |> select(starts_with("edad")) |> head()
enc |> rename(id = folio) |> names()
enc |> filter(sexo == "Mujer", edad >= 65) |> nrow()
enc |> filter(!is.na(perc_salud)) |> nrow()
enc |> arrange(desc(phq9)) |> select(folio, phq9) |> head(3)

# CUIDADO: filtrar filas en una ENCUESTA con diseño complejo antes de declarar el
# diseño sesga los errores estándar. Para subpoblaciones usa subset() de survey
# (módulo 08). En la ayudantía 2 se filtró a los de 18-24 con filter(): para
# descriptivos no ponderados da igual; para inferencia con fexp, no.


# --- 6. Resúmenes por grupo -------------------------------------------------
enc |>
  group_by(sexo) |>
  summarise(
    n        = n(),
    edad_med = mean(edad),
    phq9_med = mean(phq9),
    phq9_de  = sd(phq9),
    prev_dep = mean(depresion),                 # proporción
    perc_med = mean(perc_salud, na.rm = TRUE),  # sin na.rm, da NA
    .groups  = "drop"                          # equivale a ungroup()
  )

# Aplicar la misma función a varias columnas (reemplaza copiar y pegar 4 veces
# mean/sd/min/max como en tu script de notas):
enc |>
  summarise(across(c(edad, phq9, imc, ingreso),
                   list(media = ~ mean(.x, na.rm = TRUE), de = ~ sd(.x, na.rm = TRUE))))


# --- 7. Agregar por unidad (lo que pedía tu tarea WeatherPred) ---------------
# Datos "largos": muchas filas por participante (ensayos). Pregunta típica:
# "desempeño promedio de cada participante". Simulamos una base así:
set.seed(1)
ensayos <- tibble(
  participante = rep(1:40, each = 50),
  ensayo       = rep(1:50, times = 40),
  sexo         = rep(sample(c("Hombre", "Mujer"), 40, replace = TRUE), each = 50),
  acierto      = rbinom(2000, 1, prob = rep(runif(40, 0.5, 0.85), each = 50))
)
por_participante <- ensayos |>
  group_by(participante, sexo) |>
  summarise(prop_aciertos = mean(acierto, na.rm = TRUE), n_ensayos = n(), .groups = "drop")
por_participante
# Esto reemplaza: tapply(...) dos veces + data.frame(...) + unir a mano.


# --- 8. Unir tablas (joins) --------------------------------------------------
nombres_region <- tibble(
  region = 1:16,
  nombre_region = c("Tarapacá", "Antofagasta", "Atacama", "Coquimbo", "Valparaíso",
                    "O'Higgins", "Maule", "Biobío", "Araucanía", "Los Lagos", "Aysén",
                    "Magallanes", "Metropolitana", "Los Ríos", "Arica y Parinacota", "Ñuble")
)
enc <- enc |> left_join(nombres_region, by = "region")
# Verifica que el join no duplicó filas ni dejó NA:
stopifnot(nrow(enc) == nrow(encuesta), !anyNA(enc$nombre_region))


# --- 9. Formato ancho <-> largo (pivot) --------------------------------------
tabla_ancha <- enc |>
  count(nombre_region, sexo) |>
  pivot_wider(names_from = sexo, values_from = n)
head(tabla_ancha)
tabla_ancha |> pivot_longer(c(Hombre, Mujer), names_to = "sexo", values_to = "n") |> head()


# --- 10. Renombrar muchas variables de golpe (tu archivo "SPSS .R") ----------
# Tu archivo "recodificando los nombres de la base mortalidad en SPSS.txt.R" es
# sintaxis SPSS guardada con extensión .R: R no la puede ejecutar. En R:
#   names(defunciones) <- c("ano_def", "fecha_def", "glosa_sexo", ...)   # por posición
#   defunciones <- janitor::clean_names(defunciones)  # ANO_DEF -> ano_def, automático
#   defunciones <- rename_with(defunciones, tolower)  # todo a minúsculas


# --- 11. Guardar la base analítica -----------------------------------------
# .rds conserva factores y etiquetas; el CSV no.
saveRDS(enc, "datos/encuesta_limpia.rds")


# =============================================================================
# EJERCICIOS (ejercicios/mis_respuestas_03.R)
# 1. Crea obesidad = 1 si imc >= 30 (NA si imc es NA). Verifica con table().
# 2. Calcula por nivel educacional: n, media de phq9 y % con depresión.
# 3. Calcula la prevalencia de HTA por edad_tramos y sexo, y pásala a formato ancho.
# 4. En tu script de ayudantía 2 aparece de = sd(p). ¿Qué error da y por qué?
# =============================================================================
