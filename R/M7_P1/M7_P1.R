# 0) Arranque limpio
rm(list = ls())

# 1) Paquetes
library(sf)
library(terra)
library(tidyverse)
library(dplyr)
library(stringr)
library(osmdata)
library(mapSpain)
library(ggplot2)

# 2) Rutas del proyecto (raíz = carpeta del .Rproj)
# Requisito: abre el proyecto con el .Rproj antes de ejecutar
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/maps", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/vectors", recursive = TRUE, showWarnings = FALSE)

# 3) Atajo de rutas
path_gpkg <- file.path("data", "raw", "suelos.gpkg")

# Verificar que existe el archivo
file.exists(path_gpkg)
# Ver qué capas/tablas trae el geopackage
st_layers(path_gpkg)

# Leer capas
cubiertas <- st_read(path_gpkg, layer = "cubiertas_suelo", quiet = TRUE)
explotaciones <- st_read(path_gpkg, layer = "explotaciones", quiet = TRUE)
cubiertas_cat <- st_read(path_gpkg, layer = "cubiertas_suelo_categorias", quiet = TRUE)

# Comprobar CRS
st_crs(cubiertas)
st_crs(explotaciones)

# Ver campos para saber cómo filtrar/join
names(cubiertas)
names(explotaciones)
names(cubiertas_cat)

# Unir categorías a cubiertas (recomendado por el foro)
cubiertas2 <- cubiertas |>
  left_join(st_drop_geometry(cubiertas_cat), by = "nivell_2")

# Comprobar rápidamente categorías disponibles (incluye el typo trasnformación)
sort(unique(cubiertas2$categoria))

# 3.1) AOI de trabajo para recortes y consulta OSM
# Se genera a partir de la huella de las cubiertas del suelo (EPSG:25831) y se crea su bbox en WGS84 para OSM
AOI <- cubiertas2 |>
  st_union() |>
  st_as_sf()

AOI_wgs84 <- st_transform(AOI, 4326)
bb_osm <- st_bbox(AOI_wgs84)

# 4) Hidrografía desde OpenStreetMap
# Descarga de ríos, arroyos y canales dentro del AOI y generación de buffers de exclusión

q_hidro <- opq(bbox = bb_osm) |>
  add_osm_feature(
    key = "waterway",
    value = c("river", "stream", "canal")
  )

hidro_osm <- osmdata_sf(q_hidro)

hidro <- hidro_osm$osm_lines |>
  st_transform(25831)

# 4.1) Separar por tipo de cauce y aplicar buffers según enunciado
# river: 350 m | stream: 150 m | canal: 50 m

hidro_rio <- hidro |> dplyr::filter(waterway == "river")
hidro_arb <- hidro |> dplyr::filter(waterway == "stream")
hidro_can <- hidro |> dplyr::filter(waterway == "canal")

buf_rio <- st_buffer(hidro_rio, 350)
buf_arb <- st_buffer(hidro_arb, 150)
buf_can <- st_buffer(hidro_can, 50)

# Unir y disolver en una sola capa de exclusión hidrológica
ANP_hidro <- dplyr::bind_rows(
  st_as_sf(buf_rio),
  st_as_sf(buf_arb),
  st_as_sf(buf_can)
) |>
  st_union() |>
  st_as_sf()


# 5) Coberturas aptas (foro: NO hay "Zonas quemadas" en este AOI/año)
cats_cob_aptas <- c(
  "Cultivos en trasnformación",  # typo del gpkg
  "Matorral",
  "Prados y herbazales",
  "Suelo desnudo forestal",
  "Zonas en transformación",
  "Suelo desnudo urbano"
)

# Filtrar coberturas aptas
cobertes_zonautil <- cubiertas2 |>
  filter(categoria %in% cats_cob_aptas)

# QC rápido
nrow(cobertes_zonautil)
table(cobertes_zonautil$categoria)

# 6) Urbanismo (viene en un gpkg separado)
path_urb <- "data/raw/urbanismo.gpkg"
file.exists(path_urb)
st_layers(path_urb)

# 6.1) Leer urbanismo
urbanismo <- st_read(path_urb, layer = "urbanismo", quiet = TRUE)

# QC mínimo
nrow(urbanismo)
names(urbanismo)
st_crs(urbanismo)

# 6.2) Urbanismo apto
cats_urb_aptas <- c(
  "Suelo urbano no consolidado",
  "Suelo urbanizable no delimitado",
  "Suelo urbanizable delimitado"
)

urbanisme_zonautil <- urbanismo |>
  filter(D_CLAS_MUC %in% cats_urb_aptas)

# QC rápido
nrow(urbanisme_zonautil)
table(urbanisme_zonautil$D_CLAS_MUC)

# 7) Geología (gpkg separado)
path_geo <- "data/raw/geologia.gpkg"
file.exists(path_geo)
st_layers(path_geo)

# 7.1) Leer geología
geologia <- st_read(path_geo, layer = "geologia", quiet = TRUE)

# QC mínimo
st_crs(geologia)
names(geologia)
nrow(geologia)

# Fijar CRS correcto si viene incompleto (ETRS89 / UTM 31N)
if (is.na(st_crs(geologia)$epsg)) {
  st_crs(geologia) <- 25831
}

# Confirmar
st_crs(geologia)

# 7.2) Pasar geología a UTM 31N (metros) para que sea compatible con el resto
geologia <- st_transform(geologia, 25831)

# Confirmar
st_crs(geologia)

# 7.3) Tabla de equivalencias: litología -> codi_permeabilitat (1 = apta)
geologia_perm <- tibble::tibble(
  categoria = c(
    "Arcillas con cantos rodados",
    "Arcillas con cantos rodados dispersos",
    "Arcillas rojas y margas grises",
    "Arcillas y limos",
    "Gravas con matriz lutítica",
    "Lutitas con intercalaciones de areniscas",
    "Calcáreas miocríticas",
    "Conglomerados que forman bancos lenticulares",
    "Depósitos de lechos de arroyos y torrentes actuales",
    "Gravas con matriz arenosa y arcillosa",
    "Gravas y limos",
    "Lecho actual, llanura inundable y terraza más baja",
    "Litosomas de microconglomerados y areniscas",
    "Lutitas con areniscas y microconglomerados",
    "Tramos conglomeráticos lenticulares"
  ),
  codi_permeabilitat = c(1,1,1,1,1,1, 2,2,2,2,2,2,2,2,2)
)

# Join por DESCRIPCIO (geologia) -> categoria (tabla)
geologia2 <- geologia |>
  left_join(geologia_perm, by = c("DESCRIPCIO" = "categoria"))

# QC: cuántos se han clasificado
table(geologia2$codi_permeabilitat, useNA = "ifany")

# Filtrar geología apta (permeabilidad 1)
geologia_util <- geologia2 |>
  filter(codi_permeabilitat == 1)

# QC rápido
nrow(geologia_util)

# 8) AP = intersección de condiciones favorables
# (opcional pero recomendado) reparar geometrías antes de overlay
geologia_util      <- st_make_valid(geologia_util)
cobertes_zonautil  <- st_make_valid(cobertes_zonautil)
urbanisme_zonautil <- st_make_valid(urbanisme_zonautil)

AP <- geologia_util |>
  st_intersection(cobertes_zonautil) |>
  st_intersection(urbanisme_zonautil) |>
  st_union(by_feature = FALSE) |>
  st_cast("POLYGON") |>
  st_as_sf()

# QC: cuántos polígonos quedan y área total aproximada
nrow(AP)
sum(st_area(AP))

# 9) Inventario de capas disponibles 
gpkg_files <- list.files("data/raw", pattern = "\\.gpkg$", full.names = TRUE)

capas_disponibles <- lapply(gpkg_files, st_layers)
names(capas_disponibles) <- basename(gpkg_files)

# Ver nombres de capas por geopackage
lapply(capas_disponibles, function(x) x$name)

# 10) ANP = combinación de restricciones (protección.gpkg)
path_prot <- "data/raw/proteccion.gpkg"

humedales          <- st_read(path_prot, layer = "humedales", quiet = TRUE) |> st_make_valid() |> st_transform(25831)
fauna_flora        <- st_read(path_prot, layer = "interes_fauna_flora", quiet = TRUE) |> st_make_valid() |> st_transform(25831)
espacios_naturales <- st_read(path_prot, layer = "espacios_naturales", quiet = TRUE) |> st_make_valid() |> st_transform(25831)
agua_subterranea   <- st_read(path_prot, layer = "masa_agua_subterranea", quiet = TRUE) |> st_make_valid() |> st_transform(25831)

# 10.1) Buffers obligatorios
buf_espacios  <- st_buffer(espacios_naturales, 1000)  # espacios naturales protegidos: 1000 m
buf_humedales <- st_buffer(humedales, 500)            # humedales: 500 m
buf_fauna     <- st_buffer(fauna_flora, 500)          # fauna y flora: 500 m

# 10.2) Unir todo en una sola capa ANP (incluye hidrografía OSM)
ANP <- dplyr::bind_rows(
  st_as_sf(buf_espacios),
  st_as_sf(buf_humedales),
  st_as_sf(buf_fauna),
  st_as_sf(agua_subterranea),
  st_as_sf(ANP_hidro)
) |>
  st_union() |>
  st_as_sf()

# 11) Zonas candidatas = AP - ANP (tras aplicar todas las restricciones)
# Asegurar CRS homogéneo y geometrías válidas
AP  <- st_transform(st_make_valid(AP), 25831)
ANP <- st_transform(st_make_valid(ANP), 25831)

# Diferencia espacial (zonas aptas menos zonas no aptas)
zones_raw <- st_difference(AP, ANP)

# Disolver y pasar a polígonos limpios
zones <- zones_raw |>
  st_union() |>
  st_cast("POLYGON") |>
  st_as_sf()

# QC mínimo
nrow(zones)
sum(st_area(zones))

# 12) Área por polígono (ha) + filtro >= 3 ha
zones_area <- zones |>
  mutate(
    area_m2 = as.numeric(st_area(zones)),
    area_ha = area_m2 / 10000
  )

# QC rápido
summary(zones_area$area_ha)

# Filtrar polígonos candidatos por superficie mínima
zones_3ha <- zones_area |>
  filter(area_ha >= 3) |>
  arrange(desc(area_ha))

# QC
nrow(zones_3ha)
zones_3ha |> select(area_ha) |> head()

# 13) Pendiente media por polígono (criterio <= 5%)
# 13.1) Leer MDE
path_dem <- "data/raw/mde_5m_20241210_124521.tif"
dem <- rast(path_dem)

# 13.2) Asegurar CRS igual que polígonos (EPSG:25831)
if (!terra::same.crs(dem, "EPSG:25831")) {
  dem <- project(dem, "EPSG:25831")
}

# 13.3) Calcular pendiente en %
slope_deg <- terrain(dem, v = "slope", unit = "degrees")
slope_pct <- tan(slope_deg * pi/180) * 100

# 13.4) Pasar polígonos sf -> SpatVector
zones_3ha_v <- terra::vect(zones_3ha)

# 13.5) Estadística zonal (media, min, max)
sl_stats <- terra::extract(
  slope_pct,
  zones_3ha_v,
  fun = c("mean", "min", "max"),
  na.rm = TRUE,
  bind = TRUE
)

# 13.6) Filtro final por pendiente media
zones_final <- sl_stats[ sl_stats$mean_slope <= 5, ]

# QC
nrow(zones_final)

# 14) Preparar salida final (sf) + atributos requeridos
zones_final_sf <- sf::st_as_sf(zones_final)

zones_final_sf <- zones_final_sf |>
  dplyr::mutate(
    area_m2 = as.numeric(sf::st_area(zones_final_sf)),
    area_ha = area_m2 / 10000,
    id_poly = dplyr::row_number()
  ) |>
  dplyr::arrange(dplyr::desc(area_ha))

# QC mínimo
zones_final_sf |>
  dplyr::select(id_poly, area_ha, mean_slope, min_slope, max_slope)

# 15) Exportación de la capa final (GeoJSON)
sf::st_write(
  zones_final_sf,
  "outputs/vectors/zonas_candidatas_P1.geojson",
  delete_dsn = TRUE
)

# QC
file.exists("outputs/vectors/zonas_candidatas_P1.geojson")

# 16) Límite comarcal: Pla d’Urgell (marco del mapa)
munis_cat <- mapSpain::esp_get_munic_siane(epsg = 3857, region = "Catalunya") |>
  sf::st_transform(25831) |>
  sf::st_make_valid()

munis_AOI_map <- munis_cat |>
  sf::st_intersection(sf::st_make_valid(AOI))

# Disolver para un único límite (marco comarcal/territorial del área)
lim_comarca <- munis_AOI_map |>
  sf::st_union() |>
  sf::st_as_sf()

# QC
nrow(lim_comarca)

# 16.1) Previsualización del límite y encuadre
ggplot() +
  geom_sf(data = lim_comarca, fill = NA, color = "black", linewidth = 0.7) +
  geom_sf(data = AOI, fill = NA, color = "red", linewidth = 0.4) +
  coord_sf(datum = 25831) +
  labs(title = "límite territorial") +
  theme_minimal()

# Recorte cartográfico: limitar ANP al límite comarcal para visualización
ANP_map <- sf::st_intersection(sf::st_make_valid(ANP), sf::st_make_valid(lim_comarca))

# 17) Mapa final
map_final <- ggplot() +
  
# Zonas no aptas
geom_sf(data = ANP_map, aes(fill = "Zonas no aptas"), color = NA, alpha = 0.6) +
  
# Zonas candidatas
geom_sf(data = zones_final_sf, aes(fill = "Zonas candidatas"),
          color = "#7a2b8f", linewidth = 0.5) +
  
# Límite comarcal
geom_sf(data = lim_comarca, aes(color = "Límite comarcal"), fill = NA, linewidth = 0.9) +
  
# Grid UTM
coord_sf(datum = 25831) +
  
# Textos obligatorios
labs(
  title = "Análisis de localización óptima de una planta de gestión",
  subtitle = "Comarca del Pla d’Urgell, Lleida.",
  caption = "Datos: @UNIGISGirona, OpenStreetMap | Autor: Maria Victoria León Parra"
) +
  
# Leyenda del mapa
scale_color_manual(
   name = NULL,
   breaks = c("Límite comarcal"),
   values = c("Límite comarcal" = "black")
) +
scale_fill_manual(
  name = NULL,
  breaks = c("Zonas no aptas", "Zonas candidatas"),
  values = c(
    "Zonas no aptas"   = "grey80",
    "Zonas candidatas" = "#bd5fda"
  )
) +

guides(
  fill  = guide_legend(order = 2),
  color = guide_legend(order = 1)
) +
  
# Estilo limpio y académico
theme_minimal() +
theme(
  plot.title = element_text(size = 30, face = "bold", hjust = 0.5),
  plot.subtitle = element_text(size = 20, hjust = 0.5),
  plot.caption = element_text(size = 12, hjust = 0.5, margin = margin(t = 9)),
   plot.title.position = "plot",
  axis.text = element_text(size = 7),
  axis.title = element_blank(),
  panel.grid.major = element_line(color = "grey85", linewidth = 0.3),
  panel.grid.minor = element_blank(),
  legend.position = c(0.755, 0.20),
  legend.justification = c(0, 0),
  legend.text = element_text(size = 9),
  legend.box.spacing = unit(0, "cm"),
  legend.spacing.y = unit(0, "cm"),
  legend.margin = margin(0, 0, 0, 0)
)

ggsave(
  filename = "outputs/maps/P1_Leon_Parra_MariaVictoria_Map.png",
  plot = map_final,
  width = 30,
  height = 20,
  units = "cm",
  dpi = 300
)

ggsave(
  filename = "outputs/maps/P1_Leon_Parra_MariaVictoria_Map.pdf",
  plot = map_final,
  width = 30,
  height = 20,
  units = "cm",
  device = cairo_pdf
)