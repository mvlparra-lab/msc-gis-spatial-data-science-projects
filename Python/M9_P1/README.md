# Sentinel-2 Image Search and Footprint Generation

Python project developed to automate the search, filtering and footprint generation of Sentinel-2 satellite images over Catalonia.

## Objectives

The workflow uses the Copernicus STAC API to retrieve Sentinel-2 Level-2A scenes from the last 30 days, select the best scene per tile based on cloud coverage, and export the selected footprints as GeoJSON.

## Main Tasks

- Automatic temporal range generation using `datetime`
- Study area definition using a bounding box
- Copernicus STAC API query
- Sentinel-2 Level-2A scene retrieval
- Scene metadata extraction
- Scene grouping by Sentinel-2 tile
- Lowest cloud coverage scene selection
- Final scene list generation
- GeoJSON footprint export
- Visualization and validation in QGIS

## Technologies

- Python
- requests
- json
- datetime
- Copernicus STAC API
- QGIS

## Workflow

```text
Define Time Range
        ↓
Define Catalonia Bounding Box
        ↓
Query Copernicus STAC API
        ↓
Retrieve Sentinel-2 Scenes
        ↓
Extract Metadata
        ↓
Group Scenes by Tile
        ↓
Select Lowest Cloud Coverage
        ↓
Generate Final Scene List
        ↓
Export Footprints to GeoJSON