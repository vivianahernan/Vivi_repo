# =============================================================================
# nombre_del_archivo.R
# Proyecto  : (tesis / informe / ayudantía)
# Propósito : (qué pregunta responde este script, en una frase)
# Autor/a   : (tu nombre)
# Fecha     : AAAA-MM-DD
# Entrada   : datos/xxx.csv            (datos CRUDOS: nunca se modifican a mano)
# Salida    : datos/xxx_limpia.rds, resultados/xxx.csv
# =============================================================================

# 0. Paquetes -----------------------------------------------------------------
# (install.packages() se corre UNA vez en la consola, no aquí)
library(dplyr)
library(readr)

# 1. Cargar datos -------------------------------------------------------------
datos <- read_csv("datos/xxx.csv")   # ruta RELATIVA al proyecto .Rproj

# 2. Revisión ------------------------------------------------------------------
glimpse(datos)
summary(datos)

# 3. Limpieza y variables nuevas --------------------------------------------------
# (códigos de no respuesta -> NA, factores con etiquetas, recodificaciones)
# Verifica cada recodificación con table(original, nueva)

# 4. Análisis --------------------------------------------------------------------

# 5. Guardar resultados --------------------------------------------------------------

# Prueba final: Session > Restart R  y luego  Ctrl+Shift+Enter.
# Si no corre completo de arriba a abajo, el script no está terminado.
