# ============================================================
# PRACTICA 2 - Analisis de impacto visual municipal (La Segarra)
# Victoria Leon
# ============================================================

# ============================================================
# 0) Entorno limpio
# ============================================================
rm(list = ls())


# ============================================================
# 1) Paquetes necesarios
# ============================================================
pkgs <- c(
  "sf",
  "terra",
  "dplyr",
  "ggplot2",
  "CatastRo"
)

to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(to_install) > 0) install.packages(to_install)

invisible(lapply(pkgs, library, character.only = TRUE))


# ============================================================
# 2) Carpetas del proyecto
# ============================================================
dir_data <- "01_data"
dir_raw  <- file.path(dir_data, "raw")
dir_out  <- "03_output"
dir_fig  <- "04_figures"
dir_tab  <- "05_tables"

dirs <- c(dir_data, dir_raw, dir_out, dir_fig, dir_tab)
invisible(lapply(dirs, dir.create, showWarnings = FALSE, recursive = TRUE))


# ============================================================
# 3) Opciones globales
# ============================================================
sf::sf_use_s2(FALSE)
set.seed(2026)

message("OK Paso 3: entorno inicializado correctamente")


# ============================================================
# 4) Importacion de datos
# ============================================================

# 4.1 MDE (raster)
mde <- terra::rast(file.path(dir_raw, "mde_5m.tif"))

# 4.2 Municipios (vector sf)
muni <- sf::st_read(file.path(dir_raw, "municipios.geojson"), quiet = TRUE)

# 4.3 Cubiertas del suelo (vector; viene en GeoPackage)
# Listamos capas disponibles dentro del gpkg para elegir la correcta
terra::vect(file.path(dir_raw, "cubiertas_suelo.gpkg")) -> cubiertas

# 4.4 Tabla de equivalencias
tabla_cub <- read.csv(file.path(dir_raw, "tabla_cubiertas.csv"),
                      stringsAsFactors = FALSE)

# 4.5 Chequeos basicos (para entender lo que hay)
crs_mde  <- terra::crs(mde)
crs_muni <- sf::st_crs(muni)

print(crs_mde)
print(crs_muni)
print(names(tabla_cub))
print(head(tabla_cub, 3))


# ============================================================
# 5) Mascara comarcal y recorte del MDE
# ============================================================

# 5.1 Disolver municipios -> limite comarcal (una sola geometria)
comarca <- muni |> dplyr::summarise(geometry = sf::st_union(geometry))

# 5.2 Pasar a vector terra para usarlo como mascara
comarca_v <- terra::vect(comarca)

# 5.3 Recortar por extension y enmascarar
mde_crop <- terra::crop(mde, comarca_v)
mde_mask <- terra::mask(mde_crop, comarca_v)

# 5.4 Control rapido
print(mde)
print(mde_mask)


# ============================================================
# 6) Min/max del MDE y zonas > 750 m
# ============================================================

# 6.1 Min y max (ya los vimos, pero lo dejamos calculado en el script)
mde_min <- terra::global(mde_mask, "min", na.rm = TRUE)
mde_max <- terra::global(mde_mask, "max", na.rm = TRUE)

print(mde_min)
print(mde_max)

# 6.2 Raster binario: 1 si > 750, NA si no
zonas_750 <- mde_mask > 750
zonas_750 <- terra::ifel(zonas_750, 1, NA)

print(zonas_750)


# ============================================================
# 7) Plot 1: relieve sombreado + zonas > 750 m
# ============================================================

# 7.1 Hillshade (relieve sombreado)
slope  <- terra::terrain(mde_mask, v = "slope", unit = "radians")
aspect <- terra::terrain(mde_mask, v = "aspect", unit = "radians")
hs     <- terra::shade(slope, aspect)

# paleta hillshade en grises 
pal_hs <- grey(seq(0.15, 0.95, length.out = 200))

# color verde semitransparente para el mapa
col_750 <- adjustcolor("#3EBB9E", alpha.f = 0.45)

# color sólido para la leyenda
col_750_leg <- "#3EBB9E"

# Extensión para posicionar elementos en coordenadas UTM reales
e <- terra::ext(hs)
xmin <- e[1]; xmax <- e[2]; ymin <- e[3]; ymax <- e[4]
dx <- xmax - xmin
dy <- ymax - ymin

# 7.2 Plot y guardado
png(
  filename = file.path(dir_fig, "fig01_relieve750.png"),
  width = 1300, height = 1300, res = 200
)

# Márgenes más ajustados (menos blanco)
par(
  mar = c(2, 2, 3, 1),
  plt = c(0.05, 0.70, 0.05, 0.95),
  xaxs = "i",
  yaxs = "i"
)

# Mapa base: hillshade + overlay > 750m + límite
plot(
  hs,
  col = pal_hs,
  main = "Áreas por encima de 750 m en la comarca de La Segarra (Lleida)",
  axes = FALSE,
  legend = FALSE
)

plot(zonas_750, add = TRUE, col = col_750, legend = FALSE)
plot(terra::vect(comarca), add = TRUE, lwd = 1)

# permitir dibujar fuera del área del mapa si hiciera falta
par(xpd = NA)

# --- Leyenda
x_leg <- xmax  - 0.10 * dx
y_leg <- ymin + 0.90 * dy

legend(
  x = x_leg, y = y_leg,
  legend = "Altitud > 750 m",
  fill = col_750_leg,
  border = "grey20",
  bty = "n",
  bg = NA,
  xjust = 0, yjust = 1,
  cex = 1
)

# --- Norte 
xN  <- xmin
yN0 <- ymin + 0.87 * dy
yN1 <- ymin + 0.92 * dy

arrows(
  x0 = xN, y0 = yN0,
  x1 = xN, y1 = yN1,
  length = 0.10,
  lwd = 2
)
text(xN, yN1 + 0.015 * dy, "N", cex = 1.1, font = 2)

# --- Escala gráfica 2 km (abajo izquierda) SIN CAJETÍN
L  <- 2000  # metros
xS0 <- xmin
xS1 <- xS0 + L
yS  <- ymin + 0.05 * dy

segments(x0 = xS0, y0 = yS, x1 = xS1, y1 = yS, lwd = 3)
segments(x0 = xS0, y0 = yS, x1 = xS0, y1 = yS + 0.012 * dy, lwd = 2)
segments(x0 = xS1, y0 = yS, x1 = xS1, y1 = yS + 0.012 * dy, lwd = 2)
text(xS0 + L/2, yS - 0.030 * dy, "2 km", cex = 0.9)

dev.off()

message("OK Paso 7: fig01_relieve750.png guardada en 04_figures")


# ============================================================
# 8) Aerogeneradores: 4 puntos > 750 m con ID y Z
# ============================================================

# 8.1 Convertir las zonas > 750 m a puntos candidatos
candidatos <- terra::as.points(zonas_750, values = FALSE)

# 8.2 Muestrear 4 puntos (replicable por set.seed(2026))
idx <- sample(seq_len(nrow(candidatos)), 4)
aero_v <- candidatos[idx, ]

# 8.3 Extraer la cota Z del MDE para cada punto
z <- terra::extract(mde_mask, aero_v)[, 2]

# 8.4 Crear sf con ID y Z
aero_sf <- sf::st_as_sf(aero_v)
aero_sf$ID <- paste0("A", 1:4)
aero_sf$Z  <- z

# 8.5 Orden final de columnas
aero_sf <- aero_sf |> dplyr::select(ID, Z, geometry)

print(aero_sf)


# ============================================================
# 9) Analisis de impacto visual: cuencas visuales y acumulado
# ============================================================

# 9.1 Matriz de coordenadas (X, Y) de los aerogeneradores
locs <- sf::st_coordinates(aero_sf)  # 4 filas (A1..A4)

# 9.2 Altura del aerogenerador (60 m) como altura del observador
obs_h <- 60

# 9.3 Calcular cuenca visual por aerogenerador
# output "yes/no" devuelve visible/no visible (TRUE/FALSE)
v_list <- lapply(1:nrow(locs), function(i) {
  terra::viewshed(
    x = mde_mask,
    loc = cbind(locs[i, 1], locs[i, 2]),
    observer = obs_h,
    target = 0,
    output = "yes/no"
  )
})

# 9.4 Convertir TRUE/FALSE a 1/0 para poder sumar
v_list_10 <- lapply(v_list, function(v) terra::ifel(v, 1, 0))

# 9.5 Impacto visual acumulado (0 a 4)
impacto_acum <- v_list_10[[1]] + v_list_10[[2]] + v_list_10[[3]] + v_list_10[[4]]
names(impacto_acum) <- "impacto_acum"

print(impacto_acum)


# ============================================================
# 10) Plot 2: impacto visual acumulado + aerogeneradores
# ============================================================
library(viridis)

# 10.1 Límites municipales en el mismo CRS del raster
muni_v <- terra::vect(sf::st_transform(muni, sf::st_crs(aero_sf)))

# 10.2 Paleta viridis discreta (0–4)
cols_0_4 <- viridis::viridis(5)
labs_0_4 <- 0:4

# Extensión para norte y escala
e <- terra::ext(impacto_acum)
xmin <- e[1]; xmax <- e[2]; ymin <- e[3]; ymax <- e[4]
dx <- xmax - xmin
dy <- ymax - ymin

png(
  filename = file.path(dir_fig, "fig02_impacto_acumulado.png"),
  width = 1200, height = 1200, res = 200
)

par(mar = c(2, 2, 3, 1), xaxs = "i", yaxs = "i")

# Raster de impacto acumulado (discreto)
plot(
  impacto_acum,
  col = adjustcolor(cols_0_4, alpha.f = 0.75),
  breaks = seq(-0.5, 4.5, by = 1),
  main = "Impacto visual acumulado de los aerogeneradores",
  axes = FALSE,
  legend = FALSE
)

# Límites municipales
plot(muni_v, add = TRUE, lwd = 1, col = NA, border = "black")

# Aerogeneradores
plot(
  terra::vect(aero_sf),
  add = TRUE,
  pch = 19,
  col = "red",
  cex = 1
)

par(xpd = NA)

# Leyenda impacto acumulado
legend(
  x = xmax - 0.22 * dx,
  y = ymin + 0.92 * dy,
  legend = labs_0_4,
  fill = cols_0_4,
  title = "Impacto acumulado\n(nº aerogeneradores visibles)",
  bty = "n",
  cex = 0.9
)

# Leyenda aerogeneradores
legend(
  x = xmax - 0.10 * dx,
  y = ymin + 0.65 * dy,
  legend = "Aerogenerador",
  pch = 19,
  col = "red",
  pt.cex = 1.2,
  bty = "n",
  cex = 1
)

# Norte
xN  <- xmin
yN0 <- ymin + 0.87 * dy
yN1 <- ymin + 0.92 * dy
arrows(x0 = xN, y0 = yN0, x1 = xN, y1 = yN1, length = 0.10, lwd = 2)
text(xN, yN1 + 0.015 * dy, "N", cex = 1.1, font = 2)

# Escala gráfica 2 km
L  <- 2000
xS0 <- xmin
xS1 <- xS0 + L
yS  <- ymin + 0.05 * dy
segments(x0 = xS0, y0 = yS, x1 = xS1, y1 = yS, lwd = 3)
segments(x0 = xS0, y0 = yS, x1 = xS0, y1 = yS + 0.012 * dy, lwd = 2)
segments(x0 = xS1, y0 = yS, x1 = xS1, y1 = yS + 0.012 * dy, lwd = 2)
text(xS0 + L/2, yS - 0.030 * dy, "2 km", cex = 0.9)

dev.off()

message("OK Paso 10: fig02_impacto_acumulado.png guardada en 04_figures")


# ============================================================
# 11) Impacto visual medio por municipio (tabla comarcal)
# ============================================================

# 11.1 Comprobación de CRS
crs_muni <- sf::st_crs(muni)
crs_imp  <- terra::crs(impacto_acum)

print(crs_muni)
print(crs_imp)

# 11.2 Convertir municipios a SpatVector para extraer del raster
muni_v <- terra::vect(muni)

# 11.3 Extraer el valor medio del impacto acumulado por municipio
# (mean de los pixeles dentro de cada poligono)
imp_muni <- terra::extract(impacto_acum, muni_v, fun = mean, na.rm = TRUE)

# 11.4 Unir la media al objeto municipios
muni$imp_mean <- imp_muni[, 2]

# 11.5 Crear tabla final: nombre municipio, id, geometria, impacto medio
names(muni)


# ============================================================
# 12) Tabla ordenada + municipio con mayor impacto medio (captura PNG)
# ============================================================

# 12.1 Tabla sf/data.frame con las columnas pedidas, ordenada de mayor a menor
tabla_imp_muni <- muni |>
  dplyr::select(CODIMUNI, NOMMUNI, imp_mean, geometry) |>
  dplyr::arrange(dplyr::desc(imp_mean))

print(tabla_imp_muni)

# 12.2 Municipio con mayor impacto medio
muni_top <- tabla_imp_muni[1, ]
print(muni_top[, c("CODIMUNI", "NOMMUNI", "imp_mean")])

# 12.3 Tabla final
tabla_imp_muni_cap <- tabla_imp_muni |>
  sf::st_drop_geometry() |>
  dplyr::mutate(imp_mean = round(imp_mean, 3)) |>
  dplyr::select(CODIMUNI, NOMMUNI, imp_mean)

# 12.4 Captura PNG estilo tabla (robusta)
if (!requireNamespace("gridExtra", quietly = TRUE)) install.packages("gridExtra")
if (!requireNamespace("grid", quietly = TRUE)) install.packages("grid")

png(
  filename = file.path(dir_tab, "tab01_ImpVisMed.png"),
  width = 1500, height = 1500, res = 200
)

grid::grid.newpage()
grid::grid.text(
  "Impacto visual medio por municipio (La Segarra)",
  y = 0.97, gp = grid::gpar(fontsize = 18, fontface = "bold")
)

tabla_grob <- gridExtra::tableGrob(
  tabla_imp_muni_cap,
  rows = NULL
)

grid::grid.draw(tabla_grob)

dev.off()

message("OK Punto 12: tab01_ImpVisMed.png guardada en 05_tables")


# ============================================================
# 13) Analisis municipal: seleccionar municipio top y recortar MDE
# ============================================================

# 13.1 Objeto de estudio: municipio con mayor impacto medio
muni_estudio <- muni_top

# 13.2 Recortar MDE a la extension del municipio (crop + mask)
muni_est_v <- terra::vect(muni_estudio)

mde_muni_crop <- terra::crop(mde_mask, muni_est_v)
mde_muni_mask <- terra::mask(mde_muni_crop, muni_est_v)

print(mde_muni_mask)


# ============================================================
# 14) Impacto maximo (valor 4) en el municipio
# ============================================================

impacto_muni_crop <- terra::crop(impacto_acum, muni_est_v)
impacto_muni_mask <- terra::mask(impacto_muni_crop, muni_est_v)

print(impacto_muni_mask)

# 14.2 Impacto maximo: solo valor 4
impacto_4 <- terra::ifel(impacto_muni_mask == 4, 1, NA)

print(impacto_4)


# ============================================================
# 15) Cubiertas del suelo: recorte municipal + rasterizacion
# ============================================================

# 15.1 Recortar cubiertas al municipio (vector)
cub_muni_v <- terra::crop(cubiertas, muni_est_v)

# 15.2 Crear un raster "plantilla" con la misma geometria que el impacto municipal
plantilla <- impacto_muni_mask

# 15.3 Identificar el campo (columna) que contiene el codigo de cubierta
print(names(cub_muni_v))

# 15.4 Definir el campo que contiene los codigos tipo 111, 221, 222...
campo_codigo_cubierta <- "nivel_2"

# 15.5 Rasterizar cubiertas usando la plantilla (misma res/ext)
cub_ras <- terra::rasterize(
  cub_muni_v,
  plantilla,
  field = campo_codigo_cubierta
)

print(cub_ras)


# ============================================================
# 16) Tabla de cubiertas afectadas por impacto maximo (4)
# ============================================================

# 16.1 Enmascarar cubiertas solo donde hay impacto 4
cub_impacto4 <- terra::mask(cub_ras, impacto_4)

# 16.2 Frecuencias (terra suele devolver value/count)
freq_raw <- as.data.frame(terra::freq(cub_impacto4))

if (!all(c("value","count") %in% names(freq_raw))) {
  stop("freq() no devuelve columnas 'value' y 'count'. Pega names(freq_raw) para ajustarlo.")
}

freq_cub <- freq_raw |>
  dplyr::select(value, count) |>
  dplyr::filter(!is.na(value)) |>
  dplyr::group_by(value) |>
  dplyr::summarise(N_PIX = sum(count), .groups = "drop") |>
  dplyr::rename(CODIGO_CUBIERTA = value)

# 16.3 Calcular area en hectareas (5m x 5m = 25 m2)
pix_m2 <- prod(terra::res(cub_ras))
freq_cub$AREA_HA <- freq_cub$N_PIX * pix_m2 / 10000

# 16.4 Unir con tabla auxiliar para obtener CATEGORIA
tabla_cub_aux <- tabla_cub |>
  dplyr::select(nivel_2, categoria) |>
  dplyr::distinct()

tabla_cub_impacto4 <- freq_cub |>
  dplyr::left_join(tabla_cub_aux, by = c("CODIGO_CUBIERTA" = "nivel_2")) |>
  dplyr::mutate(IDENTIFICADOR = dplyr::row_number()) |>
  dplyr::select(IDENTIFICADOR,
                CODIGO_CUBIERTA,
                CATEGORIA = categoria,
                AREA_HA) |>
  dplyr::arrange(dplyr::desc(AREA_HA))

print(tabla_cub_impacto4)

# 16.5 Tabla final para captura
tabla_cub_cap <- tabla_cub_impacto4 |>
  dplyr::mutate(AREA_HA = round(AREA_HA, 3)) |>
  dplyr::select(IDENTIFICADOR, CODIGO_CUBIERTA, CATEGORIA, AREA_HA)

# 16.6 Captura PNG tipo tabla (método seguro)
png(
  filename = file.path(dir_tab, "tab02_Cubiertas_ImpactoMax.png"),
  width = 2200, height = 900, res = 200
)

par(mar = c(1, 1, 2, 1))
plot.new()
title("Cubiertas afectadas por impacto visual máximo (4)", cex.main = 1.2)

# preparar layout de columnas
x_id   <- 0.02
x_cod  <- 0.18
x_cat  <- 0.35
x_area <- 0.95

y_top <- 0.90
dy   <- 0.06

# cabecera
text(x_id,  y_top, "IDENTIFICADOR", adj = c(0, 1), font = 2, cex = 0.95)
text(x_cod, y_top, "CODIGO_CUBIERTA", adj = c(0, 1), font = 2, cex = 0.95)
text(x_cat, y_top, "CATEGORIA", adj = c(0, 1), font = 2, cex = 0.95)
text(x_area,y_top, "AREA_HA", adj = c(1, 1), font = 2, cex = 0.95)

# filas
for (i in seq_len(nrow(tabla_cub_cap))) {
  y <- y_top - i * dy
  text(x_id,  y, as.character(tabla_cub_cap$IDENTIFICADOR[i]), adj = c(0, 1), cex = 0.9)
  text(x_cod, y, as.character(tabla_cub_cap$CODIGO_CUBIERTA[i]), adj = c(0, 1), cex = 0.9)
  text(x_cat, y, as.character(tabla_cub_cap$CATEGORIA[i]), adj = c(0, 1), cex = 0.9)
  text(x_area,y, format(tabla_cub_cap$AREA_HA[i], nsmall = 3), adj = c(1, 1), cex = 0.9)
}

dev.off()

message("OK Punto 16: tab02_Cubiertas_ImpactoMax.png guardada en 05_tables")


# ============================================================
# 17) Catastro: parcelas afectadas por impacto maximo (4)
# ============================================================

# 17.1 Activar CatastRo (nota: el paquete se llama CatastRo)
library(CatastRo)

# 17.2 Municipio de estudio (nombre para la consulta)
nom_muni_estudio <- as.character(muni_estudio$NOMMUNI)
nom_prov_estudio <- "Lleida"

print(nom_muni_estudio)
print(nom_prov_estudio)


# ============================================================
# 18) Descarga de parcelas (CatastRo)
# ============================================================
ls("package:CatastRo")

# 18.1 BBOX del municipio en 4326 (Catastro trabaja en lon/lat)
muni_est_4326 <- sf::st_transform(muni_estudio, 4326)
bb_muni <- sf::st_bbox(muni_est_4326)
bbox_muni_vec <- as.numeric(bb_muni)  # xmin, ymin, xmax, ymax

# 18.2 Calcular área aproximada del bbox (km2) para verificar límite (4 km2)
bb_muni_poly <- sf::st_as_sfc(bb_muni)
area_bbox_km2 <- as.numeric(sf::st_area(sf::st_transform(bb_muni_poly, 3857))) / 1e6

cat("P18 | Área bbox municipal aprox (km2):", round(area_bbox_km2, 2), "\n")


# ============================================================
# 19) Preparar poligono de impacto 4 y bbox pequeño
# ============================================================

# 19.1 Poligono del impacto maximo (4)
impacto4_pol <- terra::as.polygons(
  impacto_4,
  dissolve = TRUE,
  values = TRUE,
  na.rm = TRUE
)

# quedarnos solo con las zonas con valor 1 (impacto_4 era binario 1/NA)
impacto4_pol <- impacto4_pol[!is.na(impacto4_pol[[1]]), ]

# 19.2 Pasar a sf y CRS correcto
impacto4_sf <- sf::st_as_sf(impacto4_pol)

if (is.na(sf::st_crs(impacto4_sf))) {
  sf::st_crs(impacto4_sf) <- 25831
} else if (sf::st_crs(impacto4_sf)$epsg != 25831) {
  impacto4_sf <- sf::st_transform(impacto4_sf, 25831)
}

# asegurar geometría válida
impacto4_sf <- sf::st_make_valid(impacto4_sf)

# 19.3 BBOX del impacto en 4326
impacto4_4326 <- sf::st_transform(impacto4_sf, 4326)
bb_imp <- sf::st_bbox(impacto4_4326)

# Area aproximada del bbox (km2), para verificar que no supera 4 km2
impacto4_4326 <- sf::st_transform(impacto4_sf, 4326)
bb_imp <- sf::st_bbox(impacto4_4326)

bb_poly <- sf::st_as_sfc(bb_imp)
area_km2 <- as.numeric(sf::st_area(sf::st_transform(bb_poly, 3857))) / 1e6

cat("P19 | Área bbox impacto 4 aprox (km2):", round(area_km2, 2), "\n")


# ============================================================
# 20) Grid para consultas WFS 
# ============================================================

# 20.1 En CRS metrico para crear celdas
impacto4_3857 <- sf::st_transform(impacto4_sf, 3857)

# 20.2 Grid de 1000 m 
grid_1km <- sf::st_make_grid(impacto4_3857, cellsize = 1000, square = TRUE) |>
  sf::st_sf(geometry = _)

# 20.3 Quedarnos solo con celdas que intersectan el impacto 4
grid_1km <- sf::st_intersection(grid_1km, sf::st_union(impacto4_3857))

# 20.4 Pasar a 4326 para Catastro
grid_1km_4326 <- sf::st_transform(grid_1km, 4326)

# 20.5 Control: numero de celdas
n_celdas <- nrow(grid_1km_4326)
cat("P20 | Nº celdas grid:", n_celdas, "\n")


# ============================================================
# 21) Descargar parcelas por grid (WFS) y unir resultados
# ============================================================
parcelas_list <- vector("list", length = nrow(grid_1km_4326))

ok_count <- 0
skip_count <- 0
fail_count <- 0

for (i in seq_len(nrow(grid_1km_4326))) {
  
  bb_i <- sf::st_bbox(grid_1km_4326[i, ])
  
  # bbox como vector xmin, ymin, xmax, ymax
  bb_vec <- as.numeric(bb_i)
  
  # control de área del bbox (km2) en CRS métrico, para respetar 4 km2
  bb_poly <- sf::st_as_sfc(bb_i)
  bb_km2 <- as.numeric(sf::st_area(sf::st_transform(bb_poly, 3857))) / 1e6
  
  cat("P21 | Celda", i, "| bbox_km2:", round(bb_km2, 2), "| bbox:", bb_vec, "\n")
  
  if (bb_km2 > 4) {
    skip_count <- skip_count + 1
    parcelas_list[[i]] <- NULL
    next
  }
  
  tmp <- tryCatch(
    CatastRo::catr_wfs_get_parcels_bbox(x = bb_vec, srs = 4326),
    error = function(e) NULL
  )
  
  if (is.null(tmp)) {
    fail_count <- fail_count + 1
  } else {
    ok_count <- ok_count + 1
  }
  
  parcelas_list[[i]] <- tmp
}

cat("P21 | Celdas OK:", ok_count, "| Celdas saltadas (>4 km2):", skip_count, "| Celdas fallidas:", fail_count, "\n")

# combinar solo los no-NULL
parcelas_ok <- parcelas_list[!vapply(parcelas_list, is.null, logical(1))]

parcelas_sf <- do.call(rbind, parcelas_ok)

cat("P21 | Parcelas descargadas:", nrow(parcelas_sf), "\n")
print(parcelas_sf)


# ============================================================
# 22) Parcelas afectadas por impacto maximo (4)
# ============================================================

# 22.1 Reproyectar parcelas a 25831 para cruzarlas con el impacto
parcelas_25831 <- sf::st_transform(parcelas_sf, 25831)

# 22.2 Asegurar geometrías válidas
parcelas_25831 <- sf::st_make_valid(parcelas_25831)
impacto4_sf    <- sf::st_make_valid(impacto4_sf)

# 22.3 Intersección: quedarnos solo con parcelas que intersectan impacto 4
parcelas_afectadas <- sf::st_intersection(
  parcelas_25831,
  sf::st_union(impacto4_sf)
)

cat("Parcelas afectadas (impacto 4):", nrow(parcelas_afectadas), "\n")


# ============================================================
# 23 Plot obligatorio: parcelas afectadas (impacto 4)
# ============================================================

# Color parcelas afectadas (violeta)
col_parcel  <- adjustcolor("#7B2CBF", alpha.f = 0.65)
col_par_leg <- "#7B2CBF"

# Extensión para norte y escala (UTM)
e <- sf::st_bbox(muni_estudio)
xmin <- e["xmin"]; xmax <- e["xmax"]; ymin <- e["ymin"]; ymax <- e["ymax"]
dx <- as.numeric(xmax - xmin)
dy <- as.numeric(ymax - ymin)

png(
  filename = file.path(dir_fig, "fig03_parcelas_impacto4.png"),
  width = 1300, height = 1300, res = 200
)

par(
  mar = c(2, 2, 3, 1),
  xaxs = "i",
  yaxs = "i"
)

# Mapa base: municipio
plot(
  sf::st_geometry(muni_estudio),
  col = "grey95",
  border = "grey50",
  main = paste0(
    "Parcelas afectadas por el impacto visual máximo\nen el Municipio de ",
    muni_estudio$NOMMUNI
  ),
  axes = FALSE
)

# Parcelas afectadas
plot(
  sf::st_geometry(parcelas_afectadas),
  add = TRUE,
  col = col_parcel,
  border = "grey20",
  lwd = 0.3
)

par(xpd = NA)

# --- Leyenda (arriba derecha)
legend(
  x = as.numeric(xmin),
  y = as.numeric(ymin) + 0.10 * dy,
  legend = "Parcelas afectadas",
  fill = col_par_leg,
  border = "grey20",
  bty = "n",
  cex = 0.95
)

# --- Norte (arriba izquierda)
xN  <- as.numeric(xmin) + 0.03 * dx
yN0 <- as.numeric(ymin) + 0.86 * dy
yN1 <- as.numeric(ymin) + 0.93 * dy

arrows(x0 = xN, y0 = yN0, x1 = xN, y1 = yN1, length = 0.10, lwd = 2)
text(xN, yN1 + 0.015 * dy, "N", cex = 1.1, font = 2)

# --- Escala gráfica 2 km (abajo izquierda)
L  <- 2000
xS0 <- as.numeric(xmin)
xS1 <- xS0 + L
yS  <- as.numeric(ymin)

segments(x0 = xS0, y0 = yS, x1 = xS1, y1 = yS, lwd = 3)
segments(x0 = xS0, y0 = yS, x1 = xS0, y1 = yS + 0.012 * dy, lwd = 2)
segments(x0 = xS1, y0 = yS, x1 = xS1, y1 = yS + 0.012 * dy, lwd = 2)
text(xS0 + L/2, yS - 0.030 * dy, "2 km", cex = 0.9)

dev.off()

message("OK Punto 23: fig03_parcelas_impacto4.png guardada en 04_figures")


# ============================================================
# 24 Lista de referencias catastrales afectadas (para captura PNG)
# ============================================================

# 24.1 Crear objeto lista
lista_parcelas <- list(
  referencias = sort(unique(parcelas_afectadas$nationalCadastralReference))
)

print(lista_parcelas)

# 24.2 Captura PNG con el print() tal cual (estilo consola)
png(
  filename = file.path(dir_tab, "tab03_refs_catastrales_impacto4.png"),
  width = 2000, height = 1800, res = 200
)

par(mar = c(1, 1, 1, 1))
plot.new()

# --- Título
text(
  x = 0.01, y = 0.99,
  labels = paste0(
    "Referencias catastrales afectadas por impacto visual máximo (4)\nen el Municipio de ",
    muni_estudio$NOMMUNI
  ),
  adj = c(0, 1),
  cex = 1.2,
  font = 2
)

# --- Texto tipo consola, un poco más abajo
txt <- capture.output(print(lista_parcelas))

text(
  x = 0.01, y = 0.90,
  labels = paste(txt, collapse = "\n"),
  adj = c(0, 1),
  family = "mono",
  cex = 1
)

dev.off()

message("OK Punto 24: tab03_refs_catastrales_impacto4.png guardada en 05_tables")