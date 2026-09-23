# Curso de R para análisis estadístico en ciencias sociales y salud pública

Ruta de aprendizaje desde cero, construida a partir de los errores reales de tus scripts. Empieza por **`EVALUACION.md`**: ahí está el diagnóstico de tu código y el plan semanal.

## Cómo empezar

1. Instala [R](https://cran.r-project.org/) y [RStudio](https://posit.co/download/rstudio-desktop/).
2. En la **consola** de RStudio (una sola vez):
   ```r
   install.packages(c("tidyverse", "broom", "survey", "haven", "readxl", "janitor"))
   ```
3. Descarga esta carpeta y abre **`curso_R.Rproj`** con doble clic. Desde ese momento no necesitas `setwd()`.
4. Abre los scripts de `scripts/` en orden y ejecútalos línea por línea (`Ctrl+Enter`).
5. Resuelve los ejercicios del final de cada módulo en un script nuevo, dentro de `ejercicios/`.

## Contenido

| Archivo | Tema | Lo que aprendes |
|---|---|---|
| `scripts/00_generar_datos.R` | Datos de práctica | Crea una encuesta simulada (con `fexp`, estrato, conglomerado y códigos 88/99) y datos de mortalidad |
| `scripts/01_fundamentos.R` | El lenguaje | Objetos, vectores, tipos, `NA`, `$`, `[ , ]`, funciones y paquetes |
| `scripts/02_importar_y_explorar.R` | Proyecto y datos | `.Rproj`, rutas relativas, `read_csv`, `glimpse`, chequeos de calidad y libro de códigos |
| `scripts/03_limpiar_y_transformar.R` | dplyr | Códigos de no respuesta → `NA`, factores, `case_when`, `group_by`, joins, `pivot` |
| `scripts/04_descriptivos.R` | Descriptivos | Qué resumen usar según el tipo de variable, IC y "Tabla 1" |
| `scripts/05_graficos.R` | ggplot2 | Histogramas, boxplots, barras, dispersión, paneles y `ggsave` |
| `scripts/06_inferencia_bivariada.R` | Pruebas | Chi-cuadrado, t de Welch, ANOVA, correlación, tamaño de efecto y cómo reportar |
| `scripts/07_regresion.R` | Modelos | Regresión lineal, logística (OR) y de Poisson para tasas |
| `scripts/08_encuestas_complejas.R` | **survey** | Factores de expansión, `svymean`, `svyby`, CV, `subset` y `svyglm` |
| `scripts/09_tasas_mortalidad.R` | Epidemiología | Tasas crudas, específicas y ajustadas por edad (OMS) |
| `scripts/10_mortalidad_real_deis.R` | **Datos reales** | Tasas de mortalidad 2010-2025 de Chile y regiones con la base del DEIS |
| `scripts/plantilla_script.R` | Plantilla | Estructura que deben tener todos tus scripts |
| `ejercicios/corregidos/` | Tus scripts corregidos | `tarea_WP`, notas y ENSSEX, reescritos correctamente |

Los scripts 03 al 08 usan `datos/encuesta_limpia.rds`, que genera el **03**, así que ejecútalo antes. Los datos de los módulos 00 a 09 son **simulados**: las cifras no describen a Chile.

## Bases reales (se descargan solas la primera vez)

| Base | Script | Fuente |
|---|---|---|
| ENSSEX 2022-2023 (`enssex4`) | `ejercicios/corregidos/enssex_corregido.R` | datos.gob.cl |
| Defunciones por semana, sexo, edad y región 2010-hoy (con población) | `scripts/10_mortalidad_real_deis.R` | DEIS-MINSAL vía datos.gob.cl |
| Proyecciones de población comunal 2002-2035 | (para tus propios análisis) | [INE](https://www.ine.gob.cl/docs/default-source/proyecciones-de-poblacion/cuadros-estadisticos/base-2017/estimaciones-y-proyecciones-2002-2035-comunas.xlsx) |

Para buscar otras bases de datos.gob.cl desde R: `jsonlite::fromJSON("https://datos.gob.cl/api/3/action/package_search?q=defunciones")`.

## Reglas que aplican a todos los scripts

1. Sin `setwd()`: trabaja en un proyecto `.Rproj` con rutas relativas.
2. El script carga sus propios datos y paquetes, y corre completo con *Restart R* + *Source*.
3. Los datos crudos no se editan a mano; toda transformación queda escrita en el script.
4. Antes de analizar, revisa el libro de códigos y convierte los códigos de no respuesta a `NA`.
5. Con encuestas nacionales, siempre usa el diseño muestral (`survey`).
6. Reporta estimaciones con su IC 95%, no solo valores p.
