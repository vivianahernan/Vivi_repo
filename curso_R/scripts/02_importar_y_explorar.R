# =============================================================================
# 02_importar_y_explorar.R
# Propósito : Organizar un proyecto, importar una base y hacer la primera revisión.
# Entrada   : datos/encuesta_salud.csv
# Salida    : ninguna (solo exploración)
#
# REGLA 1 — Nunca más setwd("C:/Users/vehll/OneDrive/...")
#   Todos tus scripts empiezan con setwd() a una ruta de TU computador. Nadie más
#   puede correrlos (ni siquiera en tu computador si mueves la carpeta). Solución: abre el archivo
#   curso_R.Rproj. RStudio fija la carpeta del proyecto como directorio de trabajo
#   y usas rutas RELATIVAS: "datos/encuesta_salud.csv".
#
# REGLA 2 — El script debe correr de principio a fin en una sesión limpia.
#   Prueba: Session > Restart R, luego Ctrl+Shift+Enter (Source). Si falla, no
#   está terminado. Tu ayudantia_3_1.R usa "enssex4" sin haberlo cargado: falla.
#
# REGLA 3 — No guardes el workspace (.RData) ni uses save.image().
#   Tools > Global Options > General: "Save workspace on exit" = Never.
#   Lo que importa es el SCRIPT y los datos crudos; los objetos se recrean.
# =============================================================================

library(dplyr)
library(readr)

# --- 1. Importar -------------------------------------------------------------
encuesta <- read_csv("datos/encuesta_salud.csv")
# Si solo escribes read_csv("...") sin "encuesta <-", la base se imprime y se pierde
# (esto pasó en tu Ayudantia_20250326.R: read.csv("notas.csv") en la línea 3).

# Otros formatos frecuentes en salud pública:
# haven::read_sav("base.sav")        # SPSS (conserva etiquetas de valores)
# haven::read_dta("base.dta")        # Stata
# readxl::read_excel("base.xlsx", sheet = 1)
# read_delim("defunciones_deis.csv", delim = ";",
#            locale = locale(encoding = "latin1"))  # CSV del DEIS: ";" y tildes latin1
# load("base.RData")                 # crea el objeto que venga adentro (p.ej. enssex4)


# --- 2. Primera mirada: SIEMPRE estas funciones -----------------------------
dim(encuesta)        # filas (personas) y columnas (variables)
glimpse(encuesta)    # tipo de cada variable y primeros valores
head(encuesta, 10)
summary(encuesta)    # busca aquí: máximos absurdos (88, 99, 999) y NA

# Imprimir una columna completa (WP_data$Trial) NO es "describirla": son 3000 números.
# Describir = resumir:
summary(encuesta$edad)


# --- 3. Chequeos de calidad --------------------------------------------------
# ¿El identificador es único? (una fila = una persona)
n_distinct(encuesta$folio) == nrow(encuesta)

# ¿Cuántas personas/participantes hay? Usa n_distinct(), NO max(id):
# max() solo funciona si los id van de 1 a N sin saltos (tu tarea WP usaba max()).
n_distinct(encuesta$folio)

# Perdidos por variable
colSums(is.na(encuesta))

# Valores posibles de variables categóricas (aquí aparecen 88 y 99)
table(encuesta$perc_salud, useNA = "ifany")
table(encuesta$sexo, useNA = "ifany")

# Rango de variables continuas (aquí aparece el 999 del IMC)
range(encuesta$imc, na.rm = TRUE)
sort(unique(encuesta$imc), decreasing = TRUE)[1:5]

# ¿Rango de edad coherente con la población objetivo (18+)?
range(encuesta$edad)


# --- 4. Libro de códigos -----------------------------------------------------
# Antes de analizar CUALQUIER base real (ENS, ENSSEX, CASEN, DEIS), descarga su
# libro de códigos y anota para cada variable que uses:
#   - pregunta exacta, tipo (nominal/ordinal/continua), códigos válidos,
#     códigos de no respuesta, filtro (a quién se le preguntó).
# Esta base simulada:
#   sexo: 1 = hombre, 2 = mujer
#   nivel_educ: 1 = básica, 2 = media, 3 = técnica, 4 = universitaria
#   prevision: 1 = FONASA, 2 = ISAPRE, 3 = otra
#   perc_salud: 1 = muy mala ... 5 = muy buena; 88 = no sabe; 99 = no responde
#   phq9: 0-27 (>= 10 = síntomas depresivos moderados o más)
#   hta, fuma: 0 = no, 1 = sí
#   imc: kg/m2; 999 = no medido
#   ingreso: miles de pesos; NA = no responde
#   fexp: factor de expansión; estrato y conglomerado: diseño muestral


# =============================================================================
# EJERCICIOS (ejercicios/mis_respuestas_02.R)
# 1. ¿Cuántas personas hay por región? (table). ¿Qué región concentra más casos?
# 2. ¿Qué porcentaje de la muestra tiene ingreso perdido?
# 3. Busca en internet el libro de códigos de la ENSSEX 2022-2023 y anota qué
#    códigos de no respuesta tienen p8 (calidad de vida) y p10 (percepción de salud).
#    Si existen, ¿se excluían en el ejercicio de la ayudantía 2? (En ese script no
#    se filtraba ningún código antes de calcular mean(perc_salud).)
# =============================================================================
