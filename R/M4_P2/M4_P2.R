# PRÁCTICA 2 - Análisis exploratorio de datos
# Autor: María Victoria León Parra
# Fecha: 2025-05-03
# Descripción: Script para limpiar, preparar y analizar el conjunto de datos 'massachusetts.csv'.
#              Incluye carga de datos, tratamiento de valores faltantes, identificación de outliers,
#              resumen estadístico y visualización con ggplot2.

# =============================================
# 1. CARGA DE PAQUETES Y DATOS
# =============================================

# Cargamos los paquetes necesarios
library(pacman)
p_load(tidyverse, janitor, skimr, naniar, lubridate, stringr)

# Cargamos el archivo de datos
datos <- read_csv("datos/massachusetts.csv")

# Vista rápida de las primeras filas
head(datos)

# Estructura de las variables
str(datos)

# Estadísticas básicas por variable
skim(datos)

# ---------------------------------------------
# 1.1 Limpieza de nombres de columnas
# ---------------------------------------------

# Estandarizamos los nombres de las columnas: minúsculas, sin espacios ni caracteres especiales
datos <- clean_names(datos)

# Verificamos los nuevos nombres
names(datos)

# ---------------------------------------------
# 1.2 Detección y tratamiento de valores NA
# ---------------------------------------------

# Contamos cuántos valores NA hay en total y por variable
cat("Total de valores NA en el dataset:", sum(is.na(datos)), "\n")
colSums(is.na(datos))

# Visualización rápida de NA por variable
gg_miss_var(datos) +
  labs(title = "Valores NA por variable",
       x = "Variables",
       y = "Número de valores NA")

# Guardamos el gráfico de NA en la carpeta 'salida'
ggsave("salida/na_por_variable.png", width = 8, height = 5, bg = "white")

# Imputamos NA en variables numéricas con la media
datos <- datos |> 
  mutate(across(where(is.numeric), ~replace_na(., mean(., na.rm = TRUE))))

# Confirmamos que ya no hay NA
colSums(is.na(datos))

# ---------------------------------------------
# 1.3 Preparación de variables derivadas
# ---------------------------------------------

# Creamos nuevas variables que nos ayudarán en el análisis

# Proporciones de género
datos <- datos |> 
  mutate(
    prop_hombres = male / pop,
    prop_mujeres = female / pop
  )

# Tasa de desempleo
datos <- datos |> 
  mutate(tasa_paro = unemployed / labor_force)

# Tasas por 100.000 habitantes
datos <- datos |> 
  mutate(
    tasa_suicidios = suicides / pop * 100000,
    tasa_homicidios = homicides / pop * 100000
  )

# Verificamos las nuevas variables creadas
select(datos, name, prop_hombres, tasa_paro, tasa_suicidios, tasa_homicidios) |> head()

# =============================================
# 2. IDENTIFICACIÓN DE OUTLIERS
# =============================================

# ---------------------------------------------
# 2.1 Visualización de outliers con boxplot
# ---------------------------------------------

# Visualizamos los posibles outliers en la variable 'suicides'
ggplot(datos, aes(y = suicides)) +
  geom_boxplot(fill = "lightblue", outlier.color = "red") +
  labs(title = "Outliers en la variable 'suicides'",
       y = "Tasa de suicidios") +
  theme_minimal()

# Guardamos el boxplot de suicides en la carpeta 'salida'
ggsave("salida/boxplot_suicides.png", width = 6, height = 5, bg = "white")

# ---------------------------------------------
# 2.2 Detección de outliers con boxplot.stats()
# ---------------------------------------------

# Detectamos los valores atípicos en la variable 'suicides'
outliers_suicides <- boxplot.stats(datos$suicides)$out
# Mostramos los valores identificados como outliers
cat("Outliers detectados en la variable 'suicides':\n")
print(outliers_suicides)
# Creamos una tabla con los outliers en suicides
outliers_tabla <- datos |> 
  filter(suicides %in% outliers_suicides) |> 
  select(name, suicides)
# Vemos la tabla resultante
outliers_tabla

# Creamos una lista vacía para guardar los resultados
outliers_por_variable <- list()
# Recorremos todas las variables numéricas (excepto 'fips')
numeric_vars <- datos |> 
  select(where(is.numeric), -fips) |> 
  names()
# Para cada variable numérica, identificamos outliers y guardamos los condados correspondientes
for (var in numeric_vars) {
  valores_out <- boxplot.stats(datos[[var]])$out
  if (length(valores_out) > 0) {
    condados <- datos |> 
      filter(.data[[var]] %in% valores_out) |> 
      pull(name)
    
    outliers_por_variable[[var]] <- unique(condados)
  }
}
# Mostramos un resumen
print(outliers_por_variable)

# Añadimos outliers de 'homicides' a la tabla outliers_tabla
outliers_tabla <- full_join(
  outliers_tabla,
  datos |> filter(name %in% outliers_por_variable$homicides) |> select(name, homicides),
  by = "name"
)
# Añadimos outliers de 'housing_problems' a la tabla
outliers_tabla <- full_join(
  outliers_tabla,
  datos |> 
    filter(name %in% outliers_por_variable$housing_problems) |> 
    select(name, housing_problems),
  by = "name"
)
# Añadimos outliers de 'tasa_homicidios' a la tabla
outliers_tabla <- full_join(
  outliers_tabla,
  datos |> 
    filter(name %in% outliers_por_variable$tasa_homicidios) |> 
    select(name, tasa_homicidios),
  by = "name"
)
# Añadimos outliers de 'prop_hombres'
outliers_tabla <- full_join(
  outliers_tabla,
  datos |> 
    filter(name %in% outliers_por_variable$prop_hombres) |> 
    select(name, prop_hombres),
  by = "name"
)
# Añadimos outliers de 'prop_mujeres'
outliers_tabla <- full_join(
  outliers_tabla,
  datos |> 
    filter(name %in% outliers_por_variable$prop_mujeres) |> 
    select(name, prop_mujeres),
  by = "name"
)
write_csv(outliers_tabla, "salida/outliers_tabla.csv")

# =============================================
# 3. RESUMEN ESTADÍSTICO DEL CONJUNTO DE DATOS
# =============================================

# ---------------------------------------------
# 3.1 Resumen básico con 'summary()'
# ---------------------------------------------

# Excluimos 'name' porque es texto y no aporta en este resumen
summary(select(datos, -name))
# Guardamos la salida de summary() en un archivo .txt
sink("salida/resumen_summary.txt")
summary(select(datos, -name))
sink()

# ---------------------------------------------
# 3.2 Resumen detallado con 'skimr'
# ---------------------------------------------

# 'skim()' ofrece: media, sd, min, max, percentiles, etc.
skim(select(datos, -name))
# Guardamos la salida de skim() en un archivo .txt
sink("salida/resumen_skim.txt")
print(skim(select(datos, -name)))
sink()

# =============================================
# 4. VISUALIZACIÓN DE DATOS
# =============================================

# ---------------------------------------------
# 4.1 Histograma de la variable 'avg_income'
# ---------------------------------------------

ggplot(datos, aes(x = avg_income)) +
  geom_histogram(binwidth = 5000, fill = "steelblue", color = "white") +
  geom_vline(aes(xintercept = mean(avg_income)), color = "red", linetype = "dashed", size = 1) +
  labs(
    title = "Distribución del ingreso medio",
    x = "Ingreso medio",
    y = "Frecuencia"
  ) +
  theme_minimal()

# Este histograma muestra la distribución del ingreso medio por condado.
# La línea roja discontinua representa la media del ingreso medio.
# Se observa que la mayoría de los condados tienen ingresos por debajo de la media,
# lo que sugiere una distribución sesgada hacia la derecha (asimetría positiva).

# Guardamos el histograma en la carpeta 'salida'
ggsave("salida/histograma_avg_income.png", width = 7, height = 5, bg = "white")

# ---------------------------------------------
# 4.2 Gráfico de densidad de la variable 'avg_income'
# ---------------------------------------------

ggplot(datos, aes(x = avg_income)) +
  geom_density(fill = "skyblue", alpha = 0.5) +
  labs(title = "Densidad del ingreso medio",
       x = "Ingreso medio",
       y = "Densidad") +
  theme_minimal()
# El gráfico de densidad permite observar cómo se distribuyen los ingresos medios de forma continua.
# Se observa una concentración clara en torno a valores bajos o medios, reforzando lo visto en el histograma.
# La curva sugiere una distribución sesgada a la derecha, con algunos condados con ingresos más elevados.

# Guardamos el gráfico de densidad
ggsave("salida/densidad_avg_income.png", width = 7, height = 5, bg = "white")

# ---------------------------------------------
# 4.3 Diagrama de caja de la variable 'homicides'
# ---------------------------------------------

ggplot(datos, aes(y = homicides)) +
  geom_boxplot(fill = "cadetblue", outlier.color = "red") +
  labs(
    title = "Boxplot del número de homicidios por condado",
    y = "Número de homicidios"
  ) +
  theme_minimal()
# Este boxplot muestra la distribución del número de homicidios entre condados.
# Los puntos rojos corresponden a condados con valores atípicos (outliers),
# que están significativamente por encima del resto.

# Guardamos el gráfico
ggsave("salida/boxplot_homicidios.png", width = 6, height = 4, bg = "white")

# ---------------------------------------------
# 4.4 Gráfico de dispersión: ingreso vs esperanza de vida
# ---------------------------------------------

ggplot(datos, aes(x = avg_income, y = life_expectancy)) +
  geom_point(color = "dodgerblue", size = 3) +
  geom_smooth(method = "lm", se = FALSE, color = "grey") +
  labs(title = "Relación entre ingreso medio y esperanza de vida",
       x = "Ingreso medio",
       y = "Esperanza de vida (años)") +
  theme_minimal()
# Este gráfico de dispersión muestra la relación positiva entre ingreso medio y esperanza de vida.
# La línea gris de tendencia refuerza esta asociación: a mayor ingreso, mayor esperanza de vida.
# La mayoría de los condados siguen esta tendencia, lo que sugiere una relación consistente.

# Guardamos el gráfico
ggsave("salida/scatter_income_life_expectancy.png", width = 7, height = 5, bg = "white")

# ---------------------------------------------
# 4.5 Gráfico de burbujas con color por salud
# ---------------------------------------------

ggplot(datos, aes(x = avg_income, y = life_expectancy, size = pop, color = poor_health)) +
  geom_point(alpha = 0.8) +
  scale_size_continuous(range = c(3, 12)) +
  scale_color_gradient(low = "lightblue", high = "darkred") +
  labs(
    title = "Relación entre ingreso, salud, longevidad y población",
    x = "Ingreso medio",
    y = "Esperanza de vida",
    size = "Población",
    color = "Mala salud (%)"
  ) +
  theme_minimal()
# Este gráfico de burbujas enriquece el análisis mostrando:
# - Ingreso medio (eje x)
# - Esperanza de vida (eje y)
# - Población (tamaño de la burbuja)
# - % de mala salud (color)
# Se observa que condados con ingresos más altos tienden a tener menor porcentaje de mala salud y mayor esperanza de vida.

# Guardamos el gráfico
ggsave("salida/burbujas_ingreso_vida_salud.png", width = 8, height = 6, bg = "white")

# =============================================
# 5. GUARDADO DEL ENTORNO DE TRABAJO
# =============================================

# Guardamos todos los objetos creados durante el análisis
save.image("salida/analisis_massachusetts.RData")
