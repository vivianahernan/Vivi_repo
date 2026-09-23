# =============================================================================
# 06_inferencia_bivariada.R
# Propósito : Pruebas de hipótesis para dos variables, con tamaño de efecto.
# Entrada   : datos/encuesta_limpia.rds
#
# Ninguno de tus scripts llega a esta etapa: todos terminan en descriptivos.
# Guía para elegir la prueba:
#
#   Resultado     | Grupo/predictor        | Prueba paramétrica   | Alternativa
#   --------------|------------------------|----------------------|-------------------
#   Categórico    | Categórico             | Chi-cuadrado         | Fisher (n pequeño)
#   Continuo      | 2 grupos independientes| t de Welch           | Mann-Whitney (Wilcoxon)
#   Continuo      | 3+ grupos              | ANOVA                | Kruskal-Wallis
#   Continuo      | Continuo               | Correlación Pearson  | Spearman
#   Continuo      | 2 mediciones pareadas  | t pareada            | Wilcoxon pareado
#
# Un valor p NO dice cuán grande es la diferencia: reporta siempre la estimación
# (diferencia, OR, r) con su IC 95%.
# =============================================================================

library(dplyr)

enc <- readRDS("datos/encuesta_limpia.rds")


# --- 1. Categórica x categórica: chi-cuadrado --------------------------------
tab <- table(enc$sexo, enc$depresion)
tab
chi <- chisq.test(tab)
chi
chi$expected          # supuesto: esperados >= 5 en todas las celdas
# Si no se cumple: fisher.test(tab)

# Tamaño de efecto: diferencia de proporciones con IC
prop.test(x = tab[, "1"], n = rowSums(tab))
# Razón de prevalencias (RP) Mujer/Hombre
p <- prop.table(tab, 1)[, "1"]
p["Mujer"] / p["Hombre"]


# --- 2. Continua x 2 grupos: t de Welch --------------------------------------
# Welch (var.equal = FALSE, el default) no asume varianzas iguales: úsala siempre.
t.test(phq9 ~ sexo, data = enc)

# Supuesto de normalidad: con n grande (> 30 por grupo) el TCL lo relaja.
# Mira el histograma/QQ plot en vez de depender de shapiro.test (con n = 3000
# rechaza por diferencias triviales).
qqnorm(enc$phq9); qqline(enc$phq9)

# d de Cohen (tamaño de efecto)
d_cohen <- function(x, g) {
  m <- tapply(x, g, mean, na.rm = TRUE); s <- tapply(x, g, sd, na.rm = TRUE)
  n <- tapply(!is.na(x), g, sum)
  sp <- sqrt(((n[1] - 1) * s[1]^2 + (n[2] - 1) * s[2]^2) / (sum(n) - 2))
  unname((m[2] - m[1]) / sp)
}
d_cohen(enc$phq9, enc$sexo)   # ~0.2 pequeño, ~0.5 mediano, ~0.8 grande

# No paramétrica
wilcox.test(ingreso ~ sexo, data = enc)


# --- 3. Continua x 3+ grupos: ANOVA ------------------------------------------
modelo_aov <- aov(phq9 ~ nivel_educ, data = enc)
summary(modelo_aov)
TukeyHSD(modelo_aov)          # comparaciones post hoc con ajuste por multiplicidad
kruskal.test(phq9 ~ nivel_educ, data = enc)


# --- 4. Continua x continua: correlación -------------------------------------
cor.test(enc$edad, enc$imc)                       # Pearson
cor.test(enc$phq9, enc$perc_salud, method = "spearman", exact = FALSE) # ordinal


# --- 5. Cómo reportar (formato APA/epidemiológico) ---------------------------
res <- t.test(phq9 ~ sexo, data = enc)
cat(sprintf(
  "Las mujeres presentaron mayor puntaje PHQ-9 que los hombres (diferencia = %.2f; IC 95%%: %.2f a %.2f; t(%.0f) = %.2f; p %s).\n",
  diff(res$estimate), -res$conf.int[2], -res$conf.int[1], res$parameter, abs(res$statistic),
  ifelse(res$p.value < 0.001, "< 0,001", sprintf("= %.3f", res$p.value))
))


# =============================================================================
# EJERCICIOS (ejercicios/mis_respuestas_06.R)
# 1. ¿Se asocia fumar con el nivel educacional? Chi-cuadrado y % por fila.
# 2. ¿Difiere el IMC entre quienes tienen y no tienen HTA? t de Welch y d de Cohen.
# 3. Si haces 20 pruebas con alfa = 0,05, ¿cuántos "hallazgos" esperas por azar?
#    Aplica p.adjust(p, method = "holm") a un vector de valores p.
# =============================================================================
