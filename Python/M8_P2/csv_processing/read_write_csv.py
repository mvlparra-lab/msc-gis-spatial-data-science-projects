"""
Módulo para la lectura y unión de archivos CSV.

Contiene las funciones necesarias para:
1. Leer archivos CSV con distintas codificaciones.
2. Recorrer los CSV almacenados en la carpeta files.
3. Unificar todos los registros de alumnos en una sola lista.
"""

import os
import csv

# Lee un archivo CSV probando distintas codificaciones.
def leer_csv_con_codificacion(ruta_completa):
   
    # Posibles codificaciones de entrada de los archivos CSV
    codificaciones = ["utf-8", "latin-1"]

    # Probar la lectura del archivo con cada codificación disponible
    for codificacion in codificaciones:
        try:
            with open(ruta_completa, encoding=codificacion) as csv_file:
                lector = csv.reader(csv_file, delimiter=";")
                # Guardar todas las filas del CSV en una lista para su posterior procesamiento
                filas = list(lector)
                print(f"Leído correctamente con {codificacion}: {os.path.basename(ruta_completa)}")
                return filas
        except UnicodeDecodeError:
            continue

    raise ValueError(f"No se pudo leer el archivo: {ruta_completa}")


def unir_csv():

    # Lee todos los CSV de la carpeta 'files' y une su contenido.
    directorio = "files"
    todos_los_alumnos = []
    cabecera = None

    # Recorrer todos los archivos del directorio
    for archivo in os.listdir(directorio):

        # Solo procesar archivos CSV
        if archivo.endswith(".csv"):

            ruta_completa = os.path.join(directorio, archivo)
            print(f"\nProcesando: {archivo}")

            filas = leer_csv_con_codificacion(ruta_completa)

            header = filas[0]
            datos = filas[1:]

            # Guardamos la cabecera solo una vez
            if cabecera is None:
                cabecera = header

            # Añadimos todas las filas de datos a la lista general
            for fila in datos:
                todos_los_alumnos.append(fila)

    print(f"\nTotal alumnos cargados: {len(todos_los_alumnos)}")

    return cabecera, todos_los_alumnos