# =============================================================================
# 08_encuestas_complejas.R
# Propósito : Estimar prevalencias poblacionales con factores de expansión y
#             diseño muestral (ENS, ENSSEX, CASEN, ENSM, Termómetro de Salud Mental).
# Entrada   : datos/encuesta_limpia.rds
# Salida    : resultados/prev_ponderada_region.csv
#
# ESTE ES EL MÓDULO MÁS IMPORTANTE PARA SALUD PÚBLICA.
# Con mean() o t.test() sobre la ENSSEX asumes que cada persona pesa lo mismo y
# que fue un muestreo aleatorio simple. Es falso: el diseño es estratificado,
# por conglomerados y con probabilidades de selección distintas. Consecuencias:
#   1) Estimaciones puntuales sesgadas (sin fexp)
#   2) Errores estándar subestimados -> IC muy estrechos y p falsamente pequeños
#      (sin estrato/conglomerado)
# Los nombres cambian en cada base. En la ENSSEX 2022-2023 (verificado):
#   ponderador = w_personas_cal, estrato = varstrat, conglomerado = varunit.
#   (Existe una variable "exp" pero viene vacía: siempre revisa summary() del peso.)
# =============================================================================

library(dplyr)
library(readr)
library(survey)

enc <- readRDS("datos/encuesta_limpia.rds")

# Si algún estrato queda con un solo conglomerado (frecuente al subdividir):
options(survey.lonely.psu = "adjust")


# --- 1. Declarar el diseño (una vez, sobre la base COMPLETA) -----------------
diseno <- svydesign(
  ids     = ~conglomerado,   # unidad primaria de muestreo
  strata  = ~estrato,
  weights = ~fexp,
  data    = enc,
  nest    = TRUE
)
diseno


# --- 2. Comparar: sin ponderar vs ponderado ----------------------------------
mean(enc$depresion)                       # muestra
svymean(~depresion, diseno)               # población, con error estándar
confint(svymean(~depresion, diseno))

# Tamaño poblacional estimado (suma de factores)
svytotal(~depresion, diseno)

# Efecto de diseño: cuánto "infla" la varianza el diseño respecto de MAS
svymean(~depresion, diseno, deff = TRUE)


# --- 3. Prevalencias por subgrupo --------------------------------------------
svyby(~depresion, ~sexo, diseno, svymean, vartype = c("se", "ci"))

prev_region <- svyby(~depresion, ~nombre_region, diseno, svymean, vartype = c("se", "ci", "cv"))
prev_region
# Coeficiente de variación (cv) > 0.30: estimación NO confiable (criterio INE:
# > 0.20-0.30 se reporta con advertencia). Con n pequeño por región, pasa seguido.
dir.create("resultados", showWarnings = FALSE)
write_csv(as_tibble(prev_region), "resultados/prev_ponderada_region.csv")

# Categórica con varios niveles
svymean(~perc_salud_f, diseno, na.rm = TRUE)


# --- 4. Subpoblaciones: subset() del diseño, NUNCA filter() antes -------------
# Correcto:
adultos_mayores <- subset(diseno, edad >= 65)
svymean(~hta, adultos_mayores)
# Incorrecto (pierde la información de estratos/conglomerados de la muestra):
# svydesign(..., data = filter(enc, edad >= 65))


# --- 5. Pruebas y modelos con diseño -----------------------------------------
svychisq(~sexo + depresion, diseno)             # chi-cuadrado de Rao-Scott
svyttest(phq9 ~ sexo, diseno)

m_svy <- svyglm(depresion ~ sexo + edad + nivel_educ, design = diseno,
                family = quasibinomial)   # quasibinomial evita warnings con pesos
round(exp(cbind(OR = coef(m_svy), confint(m_svy))), 2)


# =============================================================================
# EJERCICIOS (ejercicios/mis_respuestas_08.R)
# 1. Prevalencia ponderada de HTA por edad_tramos, con IC 95% y cv.
# 2. Compara la prevalencia de tabaquismo ponderada vs no ponderada. ¿Cuánto cambia?
# 3. Rehace el punto (6) de la ayudantía 2 con la ENSSEX real: media ponderada de
#    percepción de salud por región con svyby(). Antes, busca en el manual los
#    nombres de las variables de diseño y los códigos de no respuesta de p10.
# =============================================================================
