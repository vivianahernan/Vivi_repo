# =============================================================================
# 01_fundamentos.R
# Propósito : Lo mínimo indispensable del lenguaje R.
# Cómo usar : Ejecuta línea por línea con Ctrl+Enter (Cmd+Enter en Mac) y
#             LEE lo que aparece en la consola antes de pasar a la siguiente.
# Errores tuyos que este módulo corrige (vistos en tu .Rhistory):
#   - votes2<c(299,300,301)      -> "<" compara, "<-" asigna
#   - (votes – mean(votes))^2    -> "–" (guion largo pegado de un PDF) no es un "-"
#   - install.packages(tidyverse)-> los nombres de paquete van entre comillas
#   - mean(Prueba1)              -> R no sabe en qué tabla está Prueba1
#   - ds(x), read.cvs(), dataframe(), getWd() -> R distingue cada letra y mayúscula
# =============================================================================


# --- 1. R como calculadora --------------------------------------------------
2 + 3
10 / 4
2^3
sqrt(16)
log(100)          # logaritmo natural
log10(100)


# --- 2. Objetos y asignación ------------------------------------------------
# "<-" guarda un valor con un nombre. Atajo en RStudio: Alt + "-"
edad <- 34
edad
edad * 12

# ERROR CLÁSICO: con un espacio o sin el guion, haces una COMPARACIÓN:
edad < 40         # TRUE: "¿edad es menor que 40?" No guarda nada.

# Nombres: usa minúsculas y guion_bajo, sin tildes ni espacios.
# Bien: perc_salud, edad_tramos      Mal: "Percepción Salud", Edad.Tramos2final


# --- 3. Vectores: la unidad básica de R --------------------------------------
# Una variable de tu base de datos ES un vector.
votos <- c(200, 300, 400)
length(votos)
mean(votos)

# Varianza "a mano" (lo que intentabas en la ayudantía):
desvios <- votos - mean(votos)     # resta a cada elemento
desvios^2
sum(desvios^2) / length(votos)     # varianza poblacional (divide por n)
var(votos)                         # R usa n - 1 (varianza MUESTRAL). Son distintas.
sum(desvios^2) / (length(votos) - 1)
sd(votos)                          # desviación estándar = sqrt(var)


# --- 4. Tipos de datos ---------------------------------------------------------
x_num <- c(1.5, 2, 3)                    # numeric
x_int <- c(1L, 2L)                       # integer
x_chr <- c("hombre", "mujer", "mujer")   # character
x_log <- c(TRUE, FALSE, TRUE)            # logical
class(x_num); class(x_chr); class(x_log)

# TRUE vale 1 y FALSE vale 0  ->  la media de un lógico es una PROPORCIÓN
mean(x_log)          # 0.667 = 66.7% de TRUE

# Esto aplica a tu tarea WeatherPred: Performance es 0/1, entonces
# mean(Performance) YA ES la proporción de aciertos. No necesitas la moda.

# Factor: variable categórica con niveles y etiquetas (como value labels en SPSS)
sexo <- c(1, 2, 2, 1, 2)
sexo_f <- factor(sexo, levels = c(1, 2), labels = c("Hombre", "Mujer"))
sexo_f
table(sexo_f)
# sum(sexo_f)  # <- daría error: no se puede sumar una categoría (tú hiciste sum(gender))


# --- 5. Valores perdidos: NA ---------------------------------------------------
ingreso <- c(500, 800, NA, 1200)
mean(ingreso)                  # NA: R no inventa respuestas
mean(ingreso, na.rm = TRUE)    # excluye explícitamente los NA
is.na(ingreso)
sum(is.na(ingreso))            # cuántos perdidos hay (SIEMPRE revisa esto)

# OJO: en encuestas los perdidos vienen como 88, 99, 999... R los trata como números
perc <- c(4, 5, 99, 3, 88)
mean(perc)                     # 39.8 -> resultado absurdo y silencioso
perc[perc %in% c(88, 99)] <- NA
mean(perc, na.rm = TRUE)       # 4


# --- 6. Indexar: sacar partes de un vector -----------------------------------
edades <- c(23, 45, 67, 34, 19)
edades[2]              # segundo elemento
edades[c(1, 3)]        # primero y tercero
edades[edades >= 30]   # los que cumplen una condición
which(edades >= 30)    # en qué POSICIONES están


# --- 7. Data frames: la base de datos ------------------------------------------
# Un data frame es una lista de vectores del mismo largo (columnas = variables).
# NO es una matriz (en tu script le llamaste "matriz" a un data frame: ojo con eso,
# una matriz tiene un solo tipo de dato; un data frame mezcla números y texto).
mi_familia <- data.frame(
  id     = c("A", "B", "C", "D", "E"),
  edad   = c(43, 42, 12, 8, 5),
  genero = factor(c("Hombre", "Mujer", "Hombre", "Mujer", "Mujer")),
  peso   = c(188, 136, 83, 61, 44)
)
str(mi_familia)        # estructura: SIEMPRE lo primero que haces con una base
summary(mi_familia)
nrow(mi_familia); ncol(mi_familia)

# El signo $ saca UNA columna de UNA tabla: tabla$columna
mi_familia$edad
mean(mi_familia$edad)
# mean(edad) usaría el objeto suelto "edad" (34), no la columna. Por eso fallaba mean(Prueba1).

# Corchetes [filas, columnas]
mi_familia[4, ]                    # fila 4, todas las columnas
mi_familia[, "peso"]               # columna peso
mi_familia[mi_familia$edad > 18, ] # filas que cumplen condición


# --- 8. Funciones ------------------------------------------------------------
# nombre_funcion(argumento1 = valor, argumento2 = valor)
round(3.14159, digits = 2)
?round                 # ayuda. Lee la sección "Arguments" y "Examples".

# Puedes escribir tus propias funciones (evita copiar y pegar 4 veces lo mismo):
describir <- function(x) {
  c(n = sum(!is.na(x)), media = mean(x, na.rm = TRUE), de = sd(x, na.rm = TRUE),
    min = min(x, na.rm = TRUE), max = max(x, na.rm = TRUE))
}
describir(mi_familia$edad)
describir(mi_familia$peso)


# --- 9. Paquetes -------------------------------------------------------------
# install.packages("dplyr")  # DESCARGA el paquete. Una sola vez por computador.
#                            # Va en la consola, NO dentro del script.
library(dplyr)               # CARGA el paquete. En cada sesión, al inicio del script.
# "library" no baja nada de internet (en tu script comentaste lo contrario).
# paquete::funcion() usa una función sin cargar todo el paquete: dplyr::select()


# =============================================================================
# EJERCICIOS (resuélvelos en un script nuevo: ejercicios/mis_respuestas_01.R)
# 1. Crea un vector con las notas 5.5, 6.1, 3.9, 4.8, 7.0 y calcula media, mediana,
#    desviación estándar y la proporción de notas >= 4.0 (pista: mean(x >= 4)).
# 2. Crea un vector phq <- c(3, 12, 99, 8, 15, 88, 21). Reemplaza 88 y 99 por NA y
#    calcula la proporción con phq >= 10 entre quienes respondieron.
# 3. Escribe una función cv(x) que calcule el coeficiente de variación (de/media).
# 4. ¿Por qué mean(c("1", "2")) da un warning? Arréglalo con as.numeric().
# =============================================================================
