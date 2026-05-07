"""
Práctica 2 – Procesamiento de datos CSV

Este script realiza las siguientes tareas:
1. Lee varios archivos CSV con datos de alumnos.
2. Une todos los registros en una sola estructura.
3. Geocodifica las direcciones utilizando GeoPy y Nominatim.
4. Genera un nuevo archivo datos_alumnos.csv con las coordenadas.
"""

import csv
from csv_processing.read_write_csv import unir_csv
from geocoder.geocoder_nominatim import crear_geocode


def crear_csv_final(cabecera, alumnos):
    """
    Crea el archivo final datos_alumnos.csv con los campos:
    codigo, nombre, apellidos, direccion, latitud y longitud.
    """

    # Crear la función de geocodificación utilizando Nominatim
    geocode = crear_geocode()

    nueva_cabecera = ["codigo", "nombre", "apellidos", "direccion", "latitud", "longitud"]

    faltan = []

    # Crear el archivo final donde se guardarán todos los alumnos junto con las coordenadas obtenidas
    with open("datos_alumnos.csv", "w", newline="", encoding="utf-8-sig") as csv_file:
        escritor = csv.writer(csv_file, delimiter=";")
        escritor.writerow(nueva_cabecera)

        # Recorrer todos los alumnos obtenidos al unir los CSV
        for alumno in alumnos:
            codigo = alumno[0]
            direccion = alumno[5]
 
            # Intentar geocodificar la dirección, obtener la latitud y longitud a partir de la dirección, usando GeoPy
            location = geocode(direccion, language="es", timeout=10)

            if location:
                lat = location.latitude
                lon = location.longitude
                print(f"OK: {codigo}")
            else:
                lat = ""
                lon = ""
                faltan.append((codigo, direccion))
                print(f"FALTA: {codigo}")
            
            # Crear la nueva fila con los campos solicitados y las coordenadas obtenidas
            nueva_fila = [
                alumno[0],  # codigo
                alumno[3],  # nombre
                alumno[4],  # apellidos
                alumno[5],  # direccion
                lat,
                lon
            ]

            escritor.writerow(nueva_fila)

    print(f"\nCoordenadas no obtenidas: {len(faltan)}")

    if faltan:
        print("\nListado de direcciones sin coordenadas:")
        for codigo, direccion in faltan:
            print(f"{codigo} | {direccion}")

    print("\nArchivo datos_alumnos.csv creado con coordenadas")


cabecera, alumnos = unir_csv()
crear_csv_final(cabecera, alumnos)

# ------------------------------------------------------------------
# Programa principal
# ------------------------------------------------------------------

# 1. Leer y unir los CSV
cabecera, alumnos = unir_csv()

# 2. Crear el CSV final con coordenadas
crear_csv_final(cabecera, alumnos)