"""
Práctica 5 – Scripting con SIG Desktop

Script para generar mapa de afectación de un incidente,
calculando municipios afectados y población total.

Este script realiza las siguientes tareas:
1. Crear una composición de mapa
2. Añadir elementos básicos al mapa
3. Añadir vista con análisis del área afectada
4. Añadir número de personas afectadas
5. Generar el PDF
"""

import os
from qgis.core import *
from qgis.utils import iface
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QFont, QColor

# Ruta al geopackage
if '__file__' in globals():
    carpeta_script = os.path.dirname(os.path.abspath(__file__))
else:
    carpeta_script = QgsProject.instance().homePath() or os.getcwd()
ruta_gpkg = os.path.join(carpeta_script, "datos_p5.gpkg")

# Nombre de la capa
nombre_capa = "municipios"

# Parámetros de entrada (puedes modificarlos aquí)
titulo_mapa = "Mapa de afectación"
x_incidente = 384644
y_incidente = 4626165
radio_buffer = 30000

print("Parámetros usados:")
print(titulo_mapa, x_incidente, y_incidente, radio_buffer)

# Ruta de salida PDF
titulo_archivo = titulo_mapa.replace(" ", "_")
ruta_salida_pdf = os.path.join(carpeta_script, f"{titulo_archivo}.pdf")


# -----------------------------
# -----------------------------
# Punto 1. Crear una composición de mapa
# -----------------------------
# -----------------------------
proyecto = QgsProject.instance()
proyecto.setCrs(QgsCoordinateReferenceSystem("EPSG:25831"))
manager = proyecto.layoutManager()

# Eliminar composición anterior si existe
for layout in manager.printLayouts():
    if layout.name() == "Mapa_incidente":
        manager.removeLayout(layout)

# Crear nueva composición
layout = QgsPrintLayout(proyecto)
layout.initializeDefaults()
layout.setName("Mapa_incidente")
manager.addLayout(layout)

# Configurar página
pagina = layout.pageCollection().pages()[0]
pagina.setPageSize('A2', QgsLayoutItemPage.Orientation.Portrait)

# Mapa general
mapa_general = QgsLayoutItemMap(layout)
layout.addLayoutItem(mapa_general)
mapa_general.attemptMove(QgsLayoutPoint(20, 21, QgsUnitTypes.LayoutMillimeters))
mapa_general.attemptResize(QgsLayoutSize(173, 173, QgsUnitTypes.LayoutMillimeters))
mapa_general.setFrameEnabled(True)

# Mapa detalle
mapa = QgsLayoutItemMap(layout)
layout.addLayoutItem(mapa)
mapa.attemptMove(QgsLayoutPoint(20, 194, QgsUnitTypes.LayoutMillimeters))
mapa.attemptResize(QgsLayoutSize(380, 380, QgsUnitTypes.LayoutMillimeters))
mapa.setFrameEnabled(True)

# Marco
mapa_general.setFrameEnabled(True)
mapa_general.setFrameStrokeColor(QColor("black"))
mapa_general.setFrameStrokeWidth(QgsLayoutMeasurement(1, QgsUnitTypes.LayoutMillimeters))

# Mostrar marco
mapa.setFrameEnabled(True)
mapa.setFrameStrokeColor(QColor("black"))
mapa.setFrameStrokeWidth(QgsLayoutMeasurement(1, QgsUnitTypes.LayoutMillimeters))

# Punto 2. Añadir elementos básicos al mapa
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QFont
from PyQt5.QtGui import QColor

# Título
titulo = QgsLayoutItemLabel(layout)
titulo.setText(titulo_mapa)
font = QFont("Roboto", 70)
font.setBold(True)
titulo.setFont(font)
layout.addLayoutItem(titulo)
titulo.attemptResize(QgsLayoutSize(187, 51, QgsUnitTypes.LayoutMillimeters))
titulo.attemptMove(QgsLayoutPoint(213, 20, QgsUnitTypes.LayoutMillimeters))
titulo.setHAlign(Qt.AlignCenter)
titulo.setVAlign(Qt.AlignVCenter)

# Créditos
creditos = QgsLayoutItemLabel(layout)
creditos.setText("Datos: @UniGISGirona | Autor: María Victoria León Parra")
creditos.setFont(QFont("Roboto", 20))
layout.addLayoutItem(creditos)
creditos.attemptResize(QgsLayoutSize(420, 20, QgsUnitTypes.LayoutMillimeters))
creditos.attemptMove(QgsLayoutPoint(0, 574, QgsUnitTypes.LayoutMillimeters))
creditos.setHAlign(Qt.AlignCenter)
creditos.setVAlign(Qt.AlignVCenter)

# Cargar la capa base de municipios
capa_municipios = QgsVectorLayer(
    f"{ruta_gpkg}|layername={nombre_capa}",
    "Municipios",
    "ogr"
)

if not capa_municipios.isValid():
    raise Exception("Error al cargar la capa de municipios")

QgsProject.instance().addMapLayer(capa_municipios)

# Simbología de municipios
symbol_municipios = capa_municipios.renderer().symbol()
symbol_municipios.setColor(QColor(0, 0, 0))
symbol_municipios.setSize(4)
capa_municipios.triggerRepaint()

# Escala mapa general
escala_general = QgsLayoutItemScaleBar(layout)
escala_general.setStyle("Single Box")
escala_general.setLinkedMap(mapa_general)
escala_general.setUnits(QgsUnitTypes.DistanceKilometers)
escala_general.setUnitLabel("km")
escala_general.setNumberOfSegments(2)
escala_general.setNumberOfSegmentsLeft(0)
escala_general.setUnitsPerSegment(25)
escala_general.setFont(QFont("Roboto", 20))
escala_general.update()
layout.addLayoutItem(escala_general) 
escala_general.attemptMove(QgsLayoutPoint(138, 174, QgsUnitTypes.LayoutMillimeters))

# Escala mapa detalle
escala = QgsLayoutItemScaleBar(layout)
escala.setStyle("Single Box")
escala.setLinkedMap(mapa)
escala.setUnits(QgsUnitTypes.DistanceKilometers)
escala.setUnitLabel("km")
escala.setNumberOfSegments(2)
escala.setNumberOfSegmentsLeft(0)
escala.setUnitsPerSegment(10)
escala.setFont(QFont("Roboto", 20))
escala.update()
layout.addLayoutItem(escala)
escala.attemptMove(QgsLayoutPoint(21, 556, QgsUnitTypes.LayoutMillimeters))

# Flecha norte general
norte_general = QgsLayoutItemPicture(layout)
norte_general.setPicturePath(":/images/north_arrows/layout_default_north_arrow.svg")
layout.addLayoutItem(norte_general)
norte_general.attemptResize(QgsLayoutSize(20, 20, QgsUnitTypes.LayoutMillimeters))
norte_general.attemptMove(QgsLayoutPoint(154, 150, QgsUnitTypes.LayoutMillimeters))

# Flecha norte detalle
norte = QgsLayoutItemPicture(layout)
norte.setPicturePath(":/images/north_arrows/layout_default_north_arrow.svg")
layout.addLayoutItem(norte)
norte.attemptResize(QgsLayoutSize(30, 30, QgsUnitTypes.LayoutMillimeters))
norte.attemptMove(QgsLayoutPoint(360, 200, QgsUnitTypes.LayoutMillimeters))

# Leyenda
leyenda = QgsLayoutItemLegend(layout)
font_labels = QFont("Roboto", 30)
leyenda.setStyleFont(QgsLegendStyle.Subgroup, font_labels)
leyenda.setStyleFont(QgsLegendStyle.SymbolLabel, font_labels)
layout.addLayoutItem(leyenda)
leyenda.attemptMove(QgsLayoutPoint(231, 81, QgsUnitTypes.LayoutMillimeters))
leyenda.setSymbolWidth(12)
leyenda.setStyleMargin(QgsLegendStyle.Symbol, 4)
leyenda.setStyleMargin(QgsLegendStyle.Subgroup, 4)
leyenda.setBoxSpace(5)


# Punto 3. Añadir vista con análisis del área afectada
# Crear punto del incidente
punto_incidente = QgsPointXY(x_incidente, y_incidente)
geom_punto = QgsGeometry.fromPointXY(punto_incidente)

# Crear buffer (área de afectación)
area_afectacion = geom_punto.buffer(radio_buffer, 20)

# -----------------------------
# Capa del punto del incidente
# -----------------------------
capa_incidente = QgsVectorLayer("Point?crs=EPSG:25831", "Incidente", "memory")
prov_incidente = capa_incidente.dataProvider()

feature_incidente = QgsFeature()
feature_incidente.setGeometry(geom_punto)
prov_incidente.addFeature(feature_incidente)
capa_incidente.updateExtents()

QgsProject.instance().addMapLayer(capa_incidente)

# Simbología del incidente
symbol_incidente = capa_incidente.renderer().symbol()
symbol_incidente.setColor(QColor("red"))
symbol_incidente.setSize(3)
capa_incidente.triggerRepaint()

# -----------------------------
# Capa del área de afectación
# -----------------------------
capa_buffer = QgsVectorLayer("Polygon?crs=EPSG:25831", "Área de afectación", "memory")
prov_buffer = capa_buffer.dataProvider()

feature_buffer = QgsFeature()
feature_buffer.setGeometry(area_afectacion)
prov_buffer.addFeature(feature_buffer)
capa_buffer.updateExtents()

QgsProject.instance().addMapLayer(capa_buffer)

# Simbología del buffer
symbol_buffer = capa_buffer.renderer().symbol()
symbol_buffer.setColor(QColor(255, 0, 0, 80))
capa_buffer.triggerRepaint()

# -----------------------------
# Municipios afectados
# -----------------------------
municipios_afectados = []

for municipio in capa_municipios.getFeatures():
    geom_municipio = municipio.geometry()
    if geom_municipio.intersects(area_afectacion):
        municipios_afectados.append(municipio)

# Crear capa de municipios afectados
capa_afectados = QgsVectorLayer("Point?crs=EPSG:25831", "Municipios afectados", "memory")
prov_afectados = capa_afectados.dataProvider()

# Copiar campos de la capa original
prov_afectados.addAttributes(capa_municipios.fields())
capa_afectados.updateFields()

# Añadir features afectados
prov_afectados.addFeatures(municipios_afectados)
capa_afectados.updateExtents()

QgsProject.instance().addMapLayer(capa_afectados)

# Simbología de municipios afectados
symbol_afectados = capa_afectados.renderer().symbol()
symbol_afectados.setColor(QColor("blue"))
symbol_afectados.setSize(4)
capa_afectados.triggerRepaint()

# -----------------------------
# Etiquetado de municipios afectados
# -----------------------------
settings = QgsPalLayerSettings()
settings.fieldName = "NOMCAP"
settings.enabled = True

text_format = QgsTextFormat()
text_format.setFont(QFont("Roboto", 12))
text_format.setSize(12)

buffer_settings = QgsTextBufferSettings()
buffer_settings.setEnabled(True)
buffer_settings.setSize(1)
buffer_settings.setColor(QColor("white"))
text_format.setBuffer(buffer_settings)

settings.setFormat(text_format)
settings.placement = QgsPalLayerSettings.AroundPoint
settings.displayAll = False

labeling = QgsVectorLayerSimpleLabeling(settings)
capa_afectados.setLabelsEnabled(True)
capa_afectados.setLabeling(labeling)
capa_afectados.triggerRepaint()

# -----------------------------
# Actualizar mapas del layout
# -----------------------------

# Mapa general: solo municipios + buffer
mapa_general.setLayers([capa_buffer, capa_municipios])
extension_general = capa_municipios.extent()
extension_general.grow(10000)
mapa_general.zoomToExtent(extension_general)

# Mapa detalle: municipios + buffer + afectados + incidente
mapa.setLayers([capa_buffer, capa_afectados, capa_incidente])
extension_detalle = capa_buffer.extent()
extension_detalle.grow(2000)
mapa.zoomToExtent(extension_detalle)

# Refrescar mapas
mapa_general.refresh()
mapa.refresh()

# Actualizar leyenda con las capas del mapa detalle
leyenda.setLinkedMap(mapa)
leyenda.updateLegend()


# -----------------------------
# -----------------------------
# Punto 4. Añadir número de personas afectadas
# -----------------------------
# -----------------------------

# Calcular población total afectada
poblacion_total = 0

for municipio in municipios_afectados:
    poblacion_total += municipio["POBLACION"]

# Texto de población afectada
texto_poblacion = QgsLayoutItemLabel(layout)
texto_poblacion.setText(f"Población total afectada: {poblacion_total}")

font_poblacion = QFont("Roboto", 40)
font_poblacion.setBold(True)
texto_poblacion.setFont(font_poblacion)

layout.addLayoutItem(texto_poblacion)

# Posición
texto_poblacion.attemptResize(QgsLayoutSize(203, 40, QgsUnitTypes.LayoutMillimeters))
texto_poblacion.attemptMove(QgsLayoutPoint(197, 150, QgsUnitTypes.LayoutMillimeters))

texto_poblacion.setHAlign(Qt.AlignCenter)
texto_poblacion.setVAlign(Qt.AlignVCenter)

# -----------------------------
# -----------------------------
# Punto 5. Generar el PDF
# -----------------------------
# -----------------------------

exportador = QgsLayoutExporter(layout)
resultado = exportador.exportToPdf(ruta_salida_pdf, QgsLayoutExporter.PdfExportSettings())

if resultado == QgsLayoutExporter.Success:
    print("PDF generado correctamente")
else:
    print("Error al generar el PDF")