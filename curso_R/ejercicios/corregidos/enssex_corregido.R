# =============================================================================
# enssex_corregido.R
# Propósito : Versión corregida y completa de ayudantia_3_1.R + tu parte de
#             resolucion_ejercicio2.R (ENSSEX 2022-2023).
# Entrada   : ENSSEX desde datos.gob.cl (se descarga una vez a datos/)
# Salida    : datos/enssex_proc.rds, resultados/enssex_perc_salud_region.csv
#
# Los parámetros de la sección 0 están VERIFICADOS contra la base publicada
# (20240516_enssex_data.rdata, objeto enssex4: 20.392 personas, 1.126 variables).
# =============================================================================

library(dplyr)
library(readr)
library(survey)

# --- 0. Parámetros del diseño (verificados en la base) -----------------------
# OJO: existe una variable "exp" pero viene VACÍA (todo ""). El ponderador de
# personas es w_personas_cal ("calibrado 3 márgenes: sexo_edad, región, educ.");
# suma 13,58 millones = población de 18+ años.
# (w_personas_cal_nr_mod_hogar es solo para el módulo hogar: 6.738 casos.)
VAR_FEXP     <- "w_personas_cal"  # factor de expansión de personas
VAR_ESTRATO  <- "varstrat"        # pseudo-estrato (84)
VAR_CONGLOM  <- "varunit"         # pseudo-conglomerado (372)
CODIGOS_NR   <- c(8, 9)           # p8 y p10: 8 = No sabe, 9 = No responde

# --- 1. Cargar (descarga solo la primera vez) --------------------------------
url_enssex <- "https://datos.gob.cl/dataset/c6983439-49f6-4e71-85fe-e8de6e73dae0/resource/ed81f50c-1c7d-43d9-9083-dfc161e0cd66/download/20240516_enssex_data.rdata"
archivo <- "datos/enssex_2023.rdata"
if (!file.exists(archivo)) download.file(url_enssex, archivo, mode = "wb")
load(archivo)            # crea el objeto enssex4
stopifnot(exists("enssex4"))

faltan <- setdiff(c("p1", "p4", "p8", "p10", "region", VAR_FEXP, VAR_ESTRATO, VAR_CONGLOM),
                  names(enssex4))
if (length(faltan) > 0) stop("No existen en enssex4: ", paste(faltan, collapse = ", "),
                             ". Revisa la sección 0 con el libro de códigos.")

# --- 2. Seleccionar, renombrar, limpiar -------------------------------------
enssex_proc <- enssex4 |>
  select(edad = p4, sexo = p1, region, calidad_vida = p8, perc_salud = p10,
         fexp = all_of(VAR_FEXP), estrato = all_of(VAR_ESTRATO),
         conglomerado = all_of(VAR_CONGLOM)) |>
  mutate(
    # haven::zap_labels() por si vienen como variables etiquetadas de SPSS/Stata
    across(c(edad, sexo, calidad_vida, perc_salud), ~ as.numeric(haven::zap_labels(.x))),
    calidad_vida = if_else(calidad_vida %in% CODIGOS_NR, NA_real_, calidad_vida),
    perc_salud   = if_else(perc_salud %in% CODIGOS_NR, NA_real_, perc_salud),
    edad_tramos  = cut(edad, breaks = c(17, 24, 34, 44, 54, 64, Inf),
                       labels = c("18-24", "25-34", "35-44", "45-54", "55-64", "65+"))
  )

# Verificaciones: nada debe quedar fuera de rango
summary(enssex_proc)
table(enssex_proc$edad_tramos, useNA = "ifany")
table(enssex_proc$perc_salud, useNA = "ifany")

saveRDS(enssex_proc, "datos/enssex_proc.rds")

# --- 3. Descriptivos no ponderados (tu parte del ejercicio 2, corregida) ----
# Original: de = sd(p)  -> Error: object 'p' not found. Debía ser sd(edad).
enssex_proc |>
  group_by(sexo) |>
  summarise(n = n(), min = min(edad), max = max(edad), media = mean(edad),
            mediana = median(edad), de = sd(edad), .groups = "drop")

# --- 4. Estimaciones poblacionales (ponderadas) ------------------------------
options(survey.lonely.psu = "adjust")
diseno <- svydesign(ids = ~conglomerado, strata = ~estrato, weights = ~fexp,
                    data = enssex_proc, nest = TRUE)

# Punto (5)+(6) del ejercicio bien hecho: excluir 18-24 con subset() del diseño,
# no con filter() de la base.
diseno_25mas <- subset(diseno, edad_tramos != "18-24")
perc_region <- svyby(~perc_salud, ~region, diseno_25mas, svymean,
                     na.rm = TRUE, vartype = c("ci", "cv"))
perc_region

dir.create("resultados", showWarnings = FALSE)
write_csv(as_tibble(perc_region), "resultados/enssex_perc_salud_region.csv")
