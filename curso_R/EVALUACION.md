# Evaluación de tus scripts de R

**Revisados:** 10 archivos de R de tu Google Drive (marzo a junio de 2025). No pude ejecutarlos con tus datos originales porque `WeatherPred_data.csv` y `notas.csv` no están en el Drive, y el contenedor no tiene acceso a datos.gob.cl. Leí el código completo y probé las versiones corregidas con datos sintéticos que tienen la misma estructura.

## Veredicto

**Nivel actual: principiante, con vocabulario intermedio.** Reconoces los verbos de `dplyr` (`select`, `mutate`, `case_when`, `group_by`, `summarise`). Todavía no escribes un script que corra solo de principio a fin, y ninguno de tus archivos llega a un análisis inferencial: todos se quedan en cargar los datos, mirarlos y calcular promedios. Para el trabajo con encuestas nacionales el problema más grave es de fondo, no de sintaxis: **en ningún script se usan factores de expansión ni se tratan los códigos de no respuesta.**

## Quién escribió cada archivo

Hay que separar lo tuyo de lo ajeno para que la evaluación sea justa.

| Archivo | Autoría | ¿Se evalúa? |
|---|---|---|
| `.Rhistory` (26-mar y 7-jul-2025) | Tuyo: registro de la consola | Sí, es lo más revelador |
| `Ayudantia_20250326.R` | Tuyo | Sí |
| `Apendix_B_20250326.R` | Tuyo (ejercicio del libro de Stanton) | Sí |
| `tarea_WP_data_20250409.R` | Tuyo | Sí |
| `ayudantia_3_1.R` | Tuyo | Sí |
| `resolucion_ejercicio2.R` (versión del 19-jun) | Del ayudante (M. Venegas); **los dos `summarise()` del final son tuyos** | Solo tu parte |
| `pregunta1_revisada_final.R` | **De otra persona** (la ruta es `/Users/abhi/...`) | Como referencia |
| `Reporte de mortalidad Chile 1990-2024.Rmd` | **De otra persona** (B. Kaempfe, MINSAL) | No; lo uso en el módulo 09 |
| `recodificando los nombres ... SPSS.txt.R` | Tuyo, pero es **sintaxis SPSS**, no R | Sí |

Si entregaste `pregunta1_revisada_final.R` como tu tarea, ten claro que resuelve justo lo que tu script no logró: agregar los datos por participante. Esa agregación es la habilidad que te falta, y no se aprende copiando la solución.

## Errores concretos, del más grave al menos grave

### 1. Ninguno de tus scripts se puede reproducir (grave)
- **Todos empiezan con `setwd("C:/Users/vehll/OneDrive/...")`**, así que solo corren en tu computador y solo mientras no muevas la carpeta.
- `ayudantia_3_1.R` usa `enssex4` sin cargarlo nunca: en una sesión nueva falla en la línea 7.
- En `Ayudantia_20250326.R`, `read.csv("notas.csv")` no se asigna a ningún objeto: la base se imprime en pantalla y se pierde (la línea 4 la vuelve a leer).
- Usas `save.image()` y `View()` como forma de trabajar. El `.Rhistory` muestra el mismo `View(encuesta_1)` cinco veces seguidas.
- **Tu forma de trabajar:** escribes en la consola, pruebas hasta que algo funciona y después copias fragmentos al script. Por eso los scripts quedan incompletos. Ejemplo: `tarea_WP` termina en `head(Participant&Performance,52)`, que no hace lo que buscabas.

**Qué cambiar:** trabaja siempre dentro de un proyecto `.Rproj`, usa rutas relativas y sigue la plantilla (`scripts/plantilla_script.R`). Criterio de término: el script corre con *Restart R* seguido de *Source*.

### 2. No distingues el objeto de la columna ni el data frame de la matriz (grave)
En el `.Rhistory`, para calcular la media de una columna, intentaste en orden:
```r
mean(prueba1); mean(Prueba1); mean("Prueba"); mean("Prueba1"); sum(matriz)mean(Prueba1)
df$(Prueba1); matriz$(Prueba1); matriz$; matriz$prueba1; matriz$Prueba1   # ← aquí funcionó
matriz(mean[4,]); mean(matriz)[4,]; mean[8, ]
```
Es prueba y error, sin un modelo mental de `tabla$columna` ni de `[filas, columnas]`. En `tarea_WP` pasa lo mismo: `mfv(Performance)` y `head(Participant&Performance, 52)` usan nombres de columna sueltos. Además, el `&` es un Y lógico: no sirve para "mostrar dos columnas".
**Qué hacer:** el módulo 01, secciones 6 y 7.

### 3. Estadística sin criterio según el tipo de variable (grave)
- `tarea_WP`: buscabas la **moda** de `Performance`, que vale 0 o 1. Con una variable 0/1, la **media es la proporción de aciertos**, que es la respuesta. La moda no aporta nada.
- `max(WP_data$Participant)` como "cantidad de participantes" solo funciona si los ID van de 1 a N sin saltos. Lo correcto es `n_distinct()`.
- `sum(WP_data$Trial)` y `sum(matriz)` suman cosas sin interpretación: números de ensayo o todas las notas junto con el ID.
- `rowMeans(matriz)` promedia también la columna de ID si existe.
- Ejercicio ENSSEX: se calcula `mean(perc_salud)` sobre una escala ordinal **sin quitar los códigos de no respuesta**. Si la variable tiene códigos 88/99 (revísalo en el libro de códigos), la media queda inflada sin que aparezca ningún aviso.

### 4. Sin factores de expansión en la ENSSEX (grave para salud pública)
Todo lo calculado con `enssex4` describe **la muestra**, no a la población chilena. Además, si filtras con `filter()` antes de declarar el diseño, los errores estándar quedan mal calculados. Una prevalencia de una encuesta nacional sin `fexp`, estrato y conglomerado no se puede publicar. Lo trabajas en el módulo 08, y la versión corregida está en `ejercicios/corregidos/enssex_corregido.R`.

### 5. Errores de sintaxis que se repiten (moderado)
| Lo que escribiste | Problema | Correcto |
|---|---|---|
| `votes2<c(299,300,301)` | `<` compara, no asigna | `votes2 <- c(...)` |
| `(votes – mean(votes))^2` | "–" es un guion largo pegado desde el PDF | `-` |
| `install.packages(tidyverse)` | Faltan las comillas | `install.packages("tidyverse")` |
| `load(https://datos.gob.cl/...)` | Una URL necesita `url()` y comillas | `load(url("https://..."))` |
| `setwd(C:/Users/...)` y `setwd("C:\Users\...")` | Faltan comillas / `\` es carácter de escape | Proyecto `.Rproj` sin `setwd` |
| `read.cvs`, `ds()`, `dataframe()`, `getWd()`, `consum()`, `library(dbplyr)` | Errores de tipeo: R distingue cada letra | `read.csv`, `sd`, `data.frame`, `getwd`, `cumsum`, `dplyr` |
| `de = sd(p)` (tu parte del ejercicio 2) | El objeto `p` no existe, así que da error | `sd(p4)` |
| `sum(gender)` | No se puede sumar texto | `table(gender)` |
| `install.packages("modeest")` 3 veces | Instalar va una sola vez y en la consola | `library(modeest)` en el script |
| `#bajar el paquete junto con el library` | `library()` no descarga nada | `install.packages()` descarga; `library()` carga |

### 6. Código repetido en lugar de funciones (moderado)
En `Ayudantia_20250326.R` hay 20 líneas (`mean/sd/min/max` × 4 pruebas) que se reducen a una llamada con `across()` o `pivot_longer()` + `summarise()`. Cada copia es una oportunidad de error. Revisa `ejercicios/corregidos/notas_corregida.R`.

### 7. Sintaxis SPSS guardada como `.R` (menor, pero muestra confusión)
`RENAME VARIABLES(V1 ... = ANO_DEF ...)` no es R. Su equivalente en R es `janitor::clean_names()` o `names(df) <- c(...)` (módulo 03, sección 10).

## Lo que sí haces bien
- En `ayudantia_3_1.R`, `case_when` con tramos de edad está correcto y cubre todos los casos.
- Usas `saveRDS()` para guardar la base procesada, que es la práctica correcta.
- Comentas lo que intentas hacer, aunque a veces el comentario queda en lugar del código.
- Hiciste el cálculo de varianza y DE "a mano" antes de usar `var()`/`sd()`, que es buena forma de aprender.

## Plan de trabajo (en orden, sin saltarse módulos)

| Semana | Módulo | Meta verificable |
|---|---|---|
| 1 | 01 y 02 | Resolver los ejercicios **sin mirar la consola primero**: script → Source |
| 2 | 03 | Rehacer `tarea_WP` sin ayuda, **sin mirar** `tarea_WP_corregida.R`, y después comparar |
| 3 | 04 y 05 | Tabla 1 y 3 gráficos de la base simulada, exportados a `resultados/` |
| 4 | 06 | Elegir la prueba correcta para 5 preguntas y reportarlas con IC |
| 5 | 07 | Un modelo logístico interpretado en un párrafo, como en un artículo |
| 6 | 08 | Prevalencia ponderada de un indicador de la ENSSEX real, con IC y CV |
| 7 | 09 | Tasas ajustadas por edad con la base DEIS real de defunciones |

**Regla para toda la ruta:** no copies código que no puedas explicar línea por línea. Cuando un script ajeno te sirva (como el del MINSAL), reescríbelo con tus nombres y tus comentarios.
