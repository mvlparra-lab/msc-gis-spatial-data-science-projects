# PRÁCTICA 1 - Limpieza y preparación de datos
# Autor: María Victoria León Parra
# Fecha: 2025-05-02
# Descripción: Script para limpiar y preparar el conjunto de datos ficticio de la práctica 1.

# =============================================
# 1. CARGA DE PAQUETES Y DATOS
# =============================================

# Cargar paquetes necesarios
library(pacman)
p_load(skimr)
p_load(tidyverse, janitor, lubridate, stringr)

# Importar el archivo CSV
datos <- read_csv("datos/bbdd_ejemplo.csv")

# Contar todos los valores NA en el dataset
sum(is.na(datos))
colSums(is.na(datos))

# =============================================
# 2. LIMPIEZA Y PREPARACIÓN DE LOS DATOS
# =============================================

# ---------------------------------------------
# 2.1 Limpieza de nombres de columnas
# ---------------------------------------------

# Aplicamos clean_names() para usar nombres sin espacios, tildes ni caracteres especiales
datos <- clean_names(datos)

# Verificamos los nuevos nombres
names(datos)

# ---------------------------------------------
# 2.2 Corrección de errores en columnas de texto
# ---------------------------------------------

# Revisamos los valores únicos de la columna 'genero'
distinct(datos, genero)
# Corregimos y traducimos los valores de 'genero'
datos <- datos |> 
  mutate(genero = case_when(
    genero == "male" ~ "hombre",
    genero == "female" ~ "mujer",
    TRUE ~ genero
  ))
# Rellenamos los NA con 'desconocido'
datos <- datos |> 
  mutate(genero = replace_na(genero, "desconocido"))
# Verificamos que la corrección se haya aplicado bien
distinct(datos, genero)

# Revisamos los valores únicos de la columna 'grupo_sanguineo'
# para detectar posibles errores ortográficos o inconsistencias
distinct(datos, grupo_sanguineo)
# - Rellenamos NA con 'desconocido'
datos <- datos |> 
  mutate(grupo_sanguineo = replace_na(grupo_sanguineo, "desconocido"))
# Contamos cuántas observaciones tienen el valor 'A' en grupo_sanguineo
datos |> 
  filter(grupo_sanguineo == "A") |> 
  count()
# Corregimos el valor 'A' en la columna 'grupo_sanguineo'
# Como solo hay una observación con este valor y no está claro si es A+ o A-, 
# decidimos tratarlo como 'desconocido' para no asumir información incorrecta.
datos <- datos |> 
  mutate(grupo_sanguineo = case_when(
    grupo_sanguineo == "A" ~ "desconocido",
    TRUE ~ grupo_sanguineo
  ))
distinct(datos, grupo_sanguineo)

# Revisamos valores únicos en la columna 'pais'
distinct(datos, pais)
# Corregimos y traducimos los valores de la columna 'pais'
# - Corregimos errores ortográficos ('Cainada')
# - Unificamos valores duplicados en distintos idiomas
# - Rellenamos NA con 'desconocido'

datos <- datos |> 
  mutate(pais = case_when(
    pais %in% c("Spain", "España") ~ "España",
    pais %in% c("United States", "United State") ~ "Estados Unidos",
    pais %in% c("Germany", "GERMANY") ~ "Alemania",
    pais == "Cainada" ~ "Canadá",
    pais == "Canada" ~ "Canadá",
    pais == "United Kingdom" ~ "Reino Unido",
    pais == "France" ~ "Francia",
    TRUE ~ pais
  )) |> 
  mutate(pais = replace_na(pais, "desconocido"))
# Verificamos los nuevos valores únicos
distinct(datos, pais)

# Reemplazamos los valores NA en columnas de texto por 'desconocido'
datos <- datos |> 
  mutate(
    trato = replace_na(trato, "desconocido"),
    ocupacion = replace_na(ocupacion, "desconocido"),
    empresa = replace_na(empresa, "desconocido")
  )
colSums(is.na(datos))

# ---------------------------------------------
# 2.3 Detección y eliminación de registros duplicados
# ---------------------------------------------

# Verificamos si existen filas completamente duplicadas en el dataset
sum(duplicated(datos))
# Visualizamos los registros duplicados para comprobar que son idénticos.
datos |> 
  filter(duplicated(datos))
# Eliminamos las filas duplicadas, dejando solo una copia de cada registro
datos <- datos |> distinct()
# Comprobamos que ya no quedan duplicados.
sum(duplicated(datos))

# ---------------------------------------------
# 2.4 Normalización de cadenas de texto
# ---------------------------------------------

# NOTA: Algunas columnas como 'grupo_sanguineo' y 'pais' ya fueron corregidas en la sección 2.2.
# Aquí solo se aplica normalización de formato 

# Normalizamos la columna 'nombre' para que cada nombre comience con mayúscula.
datos <- datos |> 
  mutate(nombre = str_to_title(nombre))
# Verificamos  los valores
distinct(datos, nombre)

# Normalizamos la columna 'apellido' para que cada apellido comience con mayúscula.
datos <- datos |> 
  mutate(apellido = str_to_title(apellido))
# Verificamos los valores
distinct(datos, apellido)

# Normalizamos la columna 'ciudad' para que cada palabra comience con mayúscula.
datos <- datos |> 
  mutate(ciudad = str_to_title(ciudad))
# Verificamos los valores
distinct(datos, ciudad)

# Normalizamos la columna 'trato' a minúsculas para mantener consistencia (Ej: 'MR.' → 'mr.')
datos <- datos |> 
  mutate(trato = str_to_lower(trato))
# Verificamos los valores
distinct(datos, trato)

# Normalizamos la columna 'ocupacion' a minúsculas para unificar términos
datos <- datos |> 
  mutate(ocupacion = str_to_lower(ocupacion))
# Verificamos los valores
distinct(datos, ocupacion)

# Normalizamos la columna 'empresa' a minúsculas para facilitar agrupaciones futuras
datos <- datos |> 
  mutate(empresa = str_to_lower(empresa))
# Verificamos los valores
distinct(datos, empresa)

# Normalizamos la columna 'pais' a formato título para que cada palabra comience con mayúscula
datos <- datos |> 
  mutate(pais = str_to_title(pais))
# Verificamos los valores
distinct(datos, pais)

# Normalizamos la columna 'grupo_sanguineo' a mayúsculas según la convención médica (Ej: 'O+', 'AB-')
datos <- datos |> 
  mutate(grupo_sanguineo = str_to_upper(grupo_sanguineo))
# Verificamos los valores
distinct(datos, grupo_sanguineo)

# ---------------------------------------------
# 2.5 Separación de la columna 'fecha_de_nacimiento'
# ---------------------------------------------

# Convertimos 'fecha_de_nacimiento' a formato fecha usando lubridate::dmy()
# Luego extraemos día, mes y año en tres nuevas columnas: dia, mes, año
datos <- datos |> 
  mutate(fecha_de_nacimiento = dmy(fecha_de_nacimiento)) |> 
  mutate(
    dia = day(fecha_de_nacimiento),
    mes = month(fecha_de_nacimiento),
    año = year(fecha_de_nacimiento)
  )
# Filtramos las fechas que fallaron (NA después de dmy())
datos |> 
  filter(is.na(fecha_de_nacimiento)) |> 
  select(fecha_de_nacimiento) |> 
  distinct()

# Verificamos las nuevas columnas generadas
select(datos, fecha_de_nacimiento, dia, mes, año) |> head()

# ---------------------------------------------
# 2.6 Separación de la columna 'vehiculo'
# ---------------------------------------------

# Separamos la columna 'vehiculo' en dos:
# - 'fecha_vehiculo': contiene la fecha de matriculación en formato "MM/YYYY"
# - 'modelo_vehiculo': contiene la marca y modelo del coche
datos <- datos |> 
  separate(vehiculo, into = c("fecha_vehiculo", "modelo_vehiculo"), sep = " ", extra = "merge", fill = "right")

# Verificamos las nuevas columnas generadas
select(datos, fecha_vehiculo, modelo_vehiculo) |> head(10)

# ---------------------------------------------
# 2.7 Cálculo del Índice de Masa Corporal (IMC)
# ---------------------------------------------

# Creamos una nueva columna 'imc_valor' aplicando la fórmula:
# IMC = peso (kg) dividido por la talla (m) al cuadrado
datos <- datos |> 
  mutate(imc_valor = peso / ( (talla / 100)^2 ))

# Verificamos los valores calculados
select(datos, peso, talla, imc_valor) |> head(10)

# ---------------------------------------------
# 2.8 Clasificación del Índice de Masa Corporal (IMC)
# ---------------------------------------------

# Creamos una nueva columna 'imc' con categorías según el valor del IMC:
# peso bajo, peso normal, sobrepeso, obesidad
datos <- datos |> 
  mutate(imc = case_when(
    imc_valor < 18.5 ~ "peso bajo",
    imc_valor >= 18.5 & imc_valor < 24.9 ~ "peso normal",
    imc_valor >= 24.9 & imc_valor < 29.9 ~ "sobrepeso",
    imc_valor >= 30 ~ "obesidad"
  ))

# Verificamos la distribución de las categorías
count(datos, imc)

# =============================================
# 3. GUARDAR EL OBJETO FINAL
# =============================================

# Guardamos el dataset limpio como archivo .RData
# en la carpeta 'salida' para su entrega y uso posterior
save(datos, file = "salida/datos_limpios.RData")