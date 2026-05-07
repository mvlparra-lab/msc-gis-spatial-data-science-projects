"""
Práctica 4 – Programación de geoprocesos

Este script realiza las siguientes tareas:
1. Lee las capas de edificios y curso fluvial desde un geopackage.
2. Genera un buffer alrededor del curso fluvial con una distancia definida por el usuario.
3. Identifica los edificios afectados total o parcialmente por la inundación.
4. Reproyecta las geometrías a WGS84.
5. Exporta los edificios afectados a un archivo GeoJSON.
"""

import os
import fiona
from shapely.geometry import shape, mapping
from shapely.ops import unary_union, transform
from pyproj import Transformer

# Punto 1. Lectura de las entidades contenidas en el geopackage
def read_geopackage(gpkg_path):
    # Leer capa de edificios
    with fiona.open(gpkg_path, layer='Edificios') as edificios:
        edificios_data = [shape(feature["geometry"]) for feature in edificios]

    # Leer capa del curso fluvial
    with fiona.open(gpkg_path, layer='Onyar') as curso_fluvial:
        curso_fluvial_data = [shape(feature["geometry"]) for feature in curso_fluvial]

    # Mostrar número de entidades leídas
    print(f"Tramos del río leídos: {len(curso_fluvial_data)}")
    print(f"Edificios leídos: {len(edificios_data)}")

    return edificios_data, curso_fluvial_data

# Ruta al geopackage
gpkg_path = "datos/datos_p4.gpkg"

# Llamar a la función
edificios_data, curso_fluvial_data = read_geopackage(gpkg_path)


# Punto 2. Solicitud de la distancia del buffer
def get_buffer_distance():
    while True:
        try:
            distance = float(input("Introduce la distancia del buffer en metros: "))
            if distance < 0:
                print("La distancia no puede ser negativa. Intente nuevamente.")
                continue
            return distance
        except ValueError:
            print("Entrada no válida. Por favor, ingrese un número.")

# Solicitar la distancia
distancia = get_buffer_distance()

# Mostrar valor introducido (control)
print(f"Distancia introducida: {distancia} m")


# Punto 3. Creación del buffer del curso fluvial
def create_buffer(curso_fluvial_data, distance):
    # Unir todas las geometrías del curso fluvial en una sola
    curso_union = unary_union(curso_fluvial_data)
    
    # Crear el buffer alrededor del curso fluvial
    buffer = curso_union.buffer(distance)
    
    return buffer

# Crear el buffer con la distancia introducida por el usuario
buffer_rio = create_buffer(curso_fluvial_data, distancia)

# Comprobar que el buffer se ha creado correctamente
if buffer_rio and not buffer_rio.is_empty:
    print("Buffer creado correctamente")

# Punto 4. Selección de edificios afectados por el buffer
def select_affected_buildings(edificios_data, buffer):
    affected_buildings = []
    for building in edificios_data:
        if building.intersects(buffer):
            affected_buildings.append(building)
    return affected_buildings


# Seleccionar los edificios afectados
edificios_afectados = select_affected_buildings(edificios_data, buffer_rio)

print(f"Número de edificios afectados: {len(edificios_afectados)}")


# Punto 5. Reproyección a WGS84
def reproject_buildings(edificios_afectados):
    # Crear transformador de EPSG:25831 a EPSG:4326
    transformer = Transformer.from_crs("EPSG:25831", "EPSG:4326", always_xy=True)

    edificios_reproyectados = []

    for building in edificios_afectados:
        # Reproyectar cada geometría
        building_wgs84 = transform(transformer.transform, building)
        edificios_reproyectados.append(building_wgs84)

    return edificios_reproyectados

# Reproyectar los edificios afectados
edificios_wgs84 = reproject_buildings(edificios_afectados)

# Comprobar que la reproyección se ha realizado correctamente
if edificios_wgs84 and all(not geom.is_empty for geom in edificios_wgs84):
    print("Reproyección completada correctamente")


# Punto 6. Exportación a GeoJSON
def export_to_geojson(edificios_wgs84, output_path):
    schema = {
        "geometry": "Unknown",
        "properties": {"id": "int"}
    }

    with fiona.open(
        output_path,
        mode="w",
        driver="GeoJSON",
        schema=schema,
        crs="EPSG:4326"
    ) as output:
        for i, building in enumerate(edificios_wgs84):
            output.write({
                "geometry": mapping(building),
                "properties": {"id": i}
            })

# Crear la carpeta de salida si no existe
os.makedirs("output", exist_ok=True)

# Ruta de salida
output_path = f"output/edificios_afectados_{int(distancia)}m.geojson"

# Exportar
export_to_geojson(edificios_wgs84, output_path)

# Comprobar que el archivo se ha creado correctamente
if os.path.exists(output_path):
    print("GeoJSON exportado correctamente")
else:
    print("Error en la exportación del GeoJSON")