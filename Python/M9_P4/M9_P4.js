// ----------------------------------------------------
// Práctica 4. Clasificación supervisada de imágenes
// ----------------------------------------------------
// Zona de estudio: Banyoles
// Objetivo: clasificar una imagen Landsat en diferentes
// cubiertas del suelo mediante Random Forest
// Fuente de datos: Landsat 8 Collection 2 Level 2
// mediante Google Earth Engine
// ----------------------------------------------------

// ----------------------------------------------------
// Definición de la zona de estudio
// ----------------------------------------------------

// Crear rectángulo sobre el entorno de Banyoles
var zona_banyoles = ee.Geometry.Rectangle([2.70, 42.08, 2.82, 42.17]);


// ----------------------------------------------------
// Búsqueda y selección de imágenes Landsat
// ----------------------------------------------------

// Función para buscar la imagen con menor nubosidad
function buscarImagen(fecha_inicio, fecha_fin) {

  var imagen = ee.ImageCollection("LANDSAT/LC08/C02/T1_L2")

    // Filtrar por zona de estudio
    .filterBounds(zona_banyoles)

    // Filtrar por rango temporal
    .filterDate(fecha_inicio, fecha_fin)

    // Ordenar imágenes según porcentaje de nubosidad
    .sort("CLOUD_COVER")

    // Seleccionar la primera imagen (menos nubes)
    .first()

    // Recortar imagen a la zona de estudio
    .clip(zona_banyoles);

  return imagen;
}

// Buscar imagen Landsat 2023
var imagen_2023 = buscarImagen("2023-01-01", "2023-12-31");


// ----------------------------------------------------
// Visualización de la imagen original
// ----------------------------------------------------

// Función para visualizar una capa en el mapa
function visualizarCapa(capa, parametros, nombre) {
  Map.centerObject(zona_banyoles, 14);
  Map.addLayer(capa, parametros, nombre);
}

// Parámetros de visualización en color natural
var vis = {
  bands: ["SR_B4", "SR_B3", "SR_B2"],
  min: 7000,
  max: 18000
};

// Visualizar imagen original
visualizarCapa(imagen_2023, vis, "Imagen 2023");


// ----------------------------------------------------
// Definición de categorías
// ----------------------------------------------------

// 1 = Agua
// 2 = Vegetación
// 3 = Urbano
// 4 = Suelo libre y agrícola

// ----------------------------------------------------
// Creación de muestras de entrenamiento
// ----------------------------------------------------

// Asociar cada geometría dibujada a una clase
var muestra_agua = ee.Feature(Agua, {'class': 1});
var muestra_vegetacion = ee.Feature(Vegetacion, {'class': 2});
var muestra_urbano = ee.Feature(Urbano, {'class': 3});
var muestra_suelo = ee.Feature(Suelo, {'class': 4});

// Unir todas las muestras en una colección
var muestras = ee.FeatureCollection([
  muestra_agua,
  muestra_vegetacion,
  muestra_urbano,
  muestra_suelo
]);


// ----------------------------------------------------
// Selección de bandas espectrales
// ----------------------------------------------------

// Bandas utilizadas para la clasificación
var bandas = [
  'SR_B2',
  'SR_B3',
  'SR_B4',
  'SR_B5',
  'SR_B6',
  'SR_B7'
];


// ----------------------------------------------------
// Creación del dataset de entrenamiento
// ----------------------------------------------------

// Extraer valores espectrales de cada muestra
var areas_entrenamiento = imagen_2023.select(bandas).sampleRegions({

  // Colección de muestras
  collection: muestras,

  // Clase asociada a cada muestra
  properties: ['class'],

  // Resolución espacial Landsat
  scale: 30
});

// Mostrar dataset generado
print('Áreas de entrenamiento:', areas_entrenamiento);


// ----------------------------------------------------
// División entrenamiento / validación
// ----------------------------------------------------

// Crear columna aleatoria para dividir muestras
var muestras_random = areas_entrenamiento.randomColumn('random');

// 70% entrenamiento
var entrenamiento = muestras_random.filter(
  ee.Filter.lt('random', 0.7)
);

// 30% validación
var validacion = muestras_random.filter(
  ee.Filter.gte('random', 0.7)
);


// ----------------------------------------------------
// Entrenamiento del modelo Random Forest
// ----------------------------------------------------

// Crear clasificador supervisado
var clasificador_validado = ee.Classifier.smileRandomForest(50).train({

  // Datos de entrenamiento
  features: entrenamiento,

  // Variable objetivo
  classProperty: 'class',

  // Bandas de entrada
  inputProperties: bandas
});


// ----------------------------------------------------
// Evaluación del modelo
// ----------------------------------------------------

// Clasificar muestras de validación
var validacion_clasificada = validacion.classify(clasificador_validado);

// Crear matriz de confusión
var matriz_confusion = validacion_clasificada.errorMatrix(
  'class',
  'classification'
);

// Mostrar resultados
print('Matriz de confusión:', matriz_confusion);
print('Accuracy:', matriz_confusion.accuracy());


// ----------------------------------------------------
// Clasificación final de la imagen
// ----------------------------------------------------

// Aplicar modelo a toda la imagen
var clasificacion = imagen_2023
  .select(bandas)
  .classify(clasificador_validado);


// ----------------------------------------------------
// Visualización de la clasificación
// ----------------------------------------------------

// Añadir clasificación al mapa
var vis_clasificacion = {
  min: 1,
  max: 4,

  // Azul = agua
  // Verde = vegetación
  // Gris = urbano
  // Marrón = suelo libre y agrícola
  palette: ['blue', 'green', 'grey', 'brown']
};

// Visualizar resultado clasificado
visualizarCapa(clasificacion, vis_clasificacion, 'Clasificación');