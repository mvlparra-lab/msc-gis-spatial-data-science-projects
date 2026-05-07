# Flooded Buildings Detection using Geoprocessing

Python project developed to automate the identification of buildings affected by river overflow using geoprocessing techniques.

## Objectives

The workflow combines spatial analysis and vector geoprocessing operations to detect flooded buildings, reproject the results to WGS84 and export the final affected areas as GeoJSON.

## Main Tasks

- Reading GeoPackage layers with Fiona
- Geometry processing with Shapely
- Dynamic buffer generation
- Spatial intersection analysis
- Flood impact assessment
- Geometry reprojection to WGS84
- GeoJSON export automation
- Automated output folder creation

## Technologies

- Python
- fiona
- shapely
- pyproj
- os

## Workflow

```text
GeoPackage Layers
        ↓
Geometry Extraction
        ↓
Dynamic River Buffer
        ↓
Spatial Intersection
        ↓
Affected Buildings Selection
        ↓
Reprojection to WGS84
        ↓
GeoJSON Export