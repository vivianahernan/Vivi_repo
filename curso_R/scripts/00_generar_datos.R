# =============================================================================
# 00_generar_datos.R
# Propósito : Crear las bases de práctica del curso (datos SIMULADOS).
# Entrada   : ninguna
# Salida    : datos/encuesta_salud.csv, datos/defunciones.csv, datos/poblacion.csv
# Nota      : Corre este script UNA vez. Todos los demás módulos leen estas bases.
#             La estructura imita encuestas chilenas (ENS, ENSSEX, CASEN):
#             folio, región, estrato, conglomerado, factor de expansión y
#             códigos de no respuesta (88 = No sabe, 99 = No responde).
# =============================================================================

library(dplyr)
library(readr)

set.seed(2025) # Semilla: hace que los números "aleatorios" sean reproducibles

# --- 1. Encuesta de salud (nivel persona) ------------------------------------
n <- 3000

encuesta <- tibble(
  folio        = 1:n,
  region       = sample(1:16, n, replace = TRUE,
                        prob = c(2, 3, 2, 2, 10, 5, 6, 3, 6, 5, 1, 1, 40, 2, 5, 2)),
  estrato      = region * 10 + sample(1:2, n, replace = TRUE),
  conglomerado = estrato * 100 + sample(1:15, n, replace = TRUE),
  sexo         = sample(1:2, n, replace = TRUE, prob = c(0.48, 0.52)), # 1 = hombre, 2 = mujer
  edad         = pmin(90, round(18 + rgamma(n, shape = 2.2, scale = 14))),
  nivel_educ   = sample(1:4, n, replace = TRUE, prob = c(0.15, 0.40, 0.25, 0.20)),
  prevision    = sample(c(1, 2, 3), n, replace = TRUE, prob = c(0.78, 0.17, 0.05))
) |>
  mutate(
    # Síntomas depresivos (PHQ-9, 0 a 27): mayor en mujeres y menor educación
    phq9 = pmin(27, pmax(0, round(rnorm(n, 6 + 1.8 * (sexo == 2) - 0.9 * nivel_educ + 0.01 * edad, 4.5)))),
    # Hipertensión: aumenta con la edad
    hta = rbinom(n, 1, plogis(-5 + 0.07 * edad + 0.2 * (sexo == 1))),
    # IMC
    imc = round(rnorm(n, 27 + 0.03 * edad - 0.5 * nivel_educ, 4.2), 1),
    # Tabaquismo actual
    fuma = rbinom(n, 1, plogis(-0.6 - 0.02 * (edad - 40) - 0.15 * nivel_educ)),
    # Autopercepción de salud: 1 = muy mala ... 5 = muy buena
    perc_salud = pmin(5, pmax(1, round(4.2 - 0.02 * (edad - 40) - 0.08 * phq9 + 0.15 * nivel_educ + rnorm(n, 0, 0.8)))),
    # Ingreso mensual del hogar (miles de pesos), asimétrico como en la vida real
    ingreso = round(exp(rnorm(n, 6.3 + 0.25 * nivel_educ, 0.6))),
    # Factor de expansión: cuántas personas de la población representa cada encuestado.
    # Sobremuestreo de regiones pequeñas => ellas tienen factores MENORES.
    fexp = round(runif(n, 800, 1200) * ifelse(region == 13, 3.5, 1) * ifelse(edad < 30, 1.4, 1))
  )

# Introducimos datos "sucios" como en las bases reales:
idx_ns  <- sample(n, 90)   # 88 = No sabe
idx_nr  <- sample(setdiff(1:n, idx_ns), 60)  # 99 = No responde
encuesta$perc_salud[idx_ns] <- 88
encuesta$perc_salud[idx_nr] <- 99
encuesta$ingreso[sample(n, 250)] <- NA   # ingreso: pregunta con alta no respuesta
encuesta$imc[sample(n, 40)] <- 999       # código de "no medido"

write_csv(encuesta, "datos/encuesta_salud.csv")

# --- 2. Mortalidad agregada (estilo DEIS) y población (estilo INE) -----------
grupos_edad <- c("00-14", "15-29", "30-44", "45-64", "65+")
anios <- 2015:2024

poblacion <- expand.grid(anio = anios, sexo = 1:2, grupo_edad = grupos_edad,
                         stringsAsFactors = FALSE) |>
  as_tibble() |>
  mutate(
    base = c(3.7e6, 4.1e6, 3.9e6, 4.6e6, 2.3e6)[match(grupo_edad, grupos_edad)] / 2,
    # La población envejece: el grupo 65+ crece 3% anual
    poblacion = round(base * ifelse(grupo_edad == "65+", 1.03^(anio - 2015), 1.002^(anio - 2015)))
  ) |>
  select(-base)

tasa_base <- c(20, 60, 120, 450, 3800) / 1e5 # tasas por grupo de edad (por persona)
defunciones <- poblacion |>
  mutate(
    tasa = tasa_base[match(grupo_edad, grupos_edad)] * ifelse(sexo == 1, 1.25, 0.85) *
      0.99^(anio - 2015),
    defunciones = rpois(n(), poblacion * tasa)
  ) |>
  select(anio, sexo, grupo_edad, defunciones)

write_csv(poblacion, "datos/poblacion.csv")
write_csv(defunciones, "datos/defunciones.csv")

message("Listo: bases creadas en la carpeta datos/")
