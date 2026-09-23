# =============================================================================
# 07_regresion.R
# Propósito : Modelos de regresión más usados en salud pública y ciencias sociales.
# Entrada   : datos/encuesta_limpia.rds
# Salida    : resultados/or_depresion.csv
#
#   Resultado continuo           -> lineal (lm)            -> coeficiente beta
#   Resultado binario (0/1)      -> logística (glm binomial) -> odds ratio (OR)
#   Conteo / tasa                -> Poisson (glm poisson + offset) -> razón de tasas (RT)
#   Binario con prevalencia alta -> Poisson robusta o log-binomial -> razón de prevalencia
# =============================================================================

library(dplyr)
library(broom)
library(readr)

enc <- readRDS("datos/encuesta_limpia.rds")


# --- 1. Regresión lineal -----------------------------------------------------
m1 <- lm(phq9 ~ sexo + edad + nivel_educ, data = enc)
summary(m1)
confint(m1)
# Interpretación: "Ajustando por edad y educación, las mujeres tienen en promedio
# X puntos más en PHQ-9 que los hombres (IC 95% ...)."
# La categoría de referencia es el primer nivel del factor (Hombre, Básica).
# Cambiarla: enc$nivel_educ <- relevel(enc$nivel_educ, ref = "Universitaria")

# Diagnóstico de supuestos (residuos vs ajustados, QQ, etc.)
par(mfrow = c(2, 2)); plot(m1); par(mfrow = c(1, 1))

# Tabla ordenada de resultados con broom
tidy(m1, conf.int = TRUE)
glance(m1)   # R2, AIC, n


# --- 2. Regresión logística --------------------------------------------------
m2 <- glm(depresion ~ sexo + edad + nivel_educ + prevision,
          data = enc, family = binomial)
summary(m2)

# Los coeficientes están en log-odds: exponencia para obtener OR
tabla_or <- tidy(m2, exponentiate = TRUE, conf.int = TRUE) |>
  mutate(across(c(estimate, conf.low, conf.high), ~ round(.x, 2)),
         p.value = signif(p.value, 2)) |>
  select(termino = term, OR = estimate, IC_inf = conf.low, IC_sup = conf.high, p = p.value)
tabla_or
dir.create("resultados", showWarnings = FALSE)
write_csv(tabla_or, "resultados/or_depresion.csv")

# OJO: cuando la prevalencia del resultado es > 10%, el OR exagera la razón de
# prevalencias. Alternativa: Poisson con errores robustos
# (paquetes sandwich + lmtest: coeftest(m, vcov = vcovHC(m, type = "HC0"))).

# Comparar modelos anidados
m2b <- glm(depresion ~ sexo + edad, data = enc, family = binomial)
anova(m2b, m2, test = "LRT")


# --- 3. Regresión de Poisson para tasas --------------------------------------
defun <- read_csv("datos/defunciones.csv", show_col_types = FALSE)
pobl  <- read_csv("datos/poblacion.csv", show_col_types = FALSE)
mort  <- left_join(defun, pobl, by = c("anio", "sexo", "grupo_edad")) |>
  mutate(sexo = factor(sexo, 1:2, c("Hombre", "Mujer")))

m3 <- glm(defunciones ~ sexo + grupo_edad + anio, offset = log(poblacion),
          data = mort, family = poisson)
tidy(m3, exponentiate = TRUE, conf.int = TRUE)
# exp(coef de anio) = cambio porcentual anual de la tasa ajustada por edad y sexo.
# Revisa sobredispersión: deviance / gl >> 1 -> usa quasipoisson o binomial negativa.
m3$deviance / m3$df.residual


# --- 4. Advertencias --------------------------------------------------------
# - Asociación no es causalidad: elige covariables con un DAG, no por valor p.
# - ~10 eventos por parámetro en logística como mínimo.
# - Con encuestas complejas estos modelos van con survey::svyglm (módulo 08).


# =============================================================================
# EJERCICIOS (ejercicios/mis_respuestas_07.R)
# 1. Modelo lineal de imc ~ edad + sexo + fuma. Interpreta el coeficiente de fuma.
# 2. Logística de hta ~ edad + sexo + imc_cat. ¿Cuál es el OR de obesidad vs normal?
#    (relevel imc_cat para que "Normal" sea la referencia).
# 3. En m3, ¿cuál es la razón de tasas Mujer/Hombre? Interprétala en una frase.
# =============================================================================
