"""
Script para calcular la severidad de un incendio forestal mediante el índice dNBR.

El script utiliza un catálogo STAC para buscar imágenes satelitales antes y
después del incendio. Las bandas se cargan como datos raster y se emplean
para calcular el índice NBR y posteriormente el dNBR.

Área de estudio: Evros, Grecia 2023.

Flujo:
1. Búsqueda de imágenes pre y post incendio
2. Selección por menor nubosidad
3. Carga de bandas NIR y SWIR2
4. Cálculo de NBR y dNBR
5. Clasificación de severidad
6. Visualización del resultado
"""

from funciones import (
    buscar_imagenes,
    seleccionar_menor_nubosidad,
    cargar_banda,
    calcular_nbr,
    calcular_dnbr,
    clasificar_dnbr,
    plot_dnbr
)

# Definir área de estudio
bbox = [26.05, 41.00, 26.25, 41.20]

# Buscar imágenes antes y después del incendio
imagenes_pre = buscar_imagenes(bbox, "2023-07-01", "2023-07-15")
imagenes_post = buscar_imagenes(bbox, "2023-08-25", "2023-09-10")

print("Número de imágenes pre-incendio:", len(imagenes_pre))
print("Número de imágenes post-incendio:", len(imagenes_post))

# Seleccionar las imágenes con menor nubosidad
imagen_pre = seleccionar_menor_nubosidad(imagenes_pre)
imagen_post = seleccionar_menor_nubosidad(imagenes_post)

print("Imagen pre:", imagen_pre.id)
print("Nubes pre:", imagen_pre.properties["eo:cloud_cover"])
print("Imagen post:", imagen_post.id)
print("Nubes post:", imagen_post.properties["eo:cloud_cover"])

# Cargar bandas NIR y SWIR2 necesarias para calcular el NBR (con clip al área de estudio)
nir_pre = cargar_banda(imagen_pre, "B8A", bbox)
swir_pre = cargar_banda(imagen_pre, "B12", bbox)
nir_post = cargar_banda(imagen_post, "B8A", bbox)
swir_post = cargar_banda(imagen_post, "B12", bbox)

print("Shape NIR:", nir_pre.shape)

# Calcular NBR antes y después del incendio
nbr_pre = calcular_nbr(nir_pre, swir_pre)
nbr_post = calcular_nbr(nir_post, swir_post)

print("NBR calculado")

# Calcular y clasificar el dNBR
dnbr = calcular_dnbr(nbr_pre, nbr_post)
clases_dnbr = clasificar_dnbr(dnbr)

print("dNBR calculado y clasificado")
print(clases_dnbr.shape)

# Mostrar mapa final
plot_dnbr(clases_dnbr)