# Optimal Location Analysis for a Livestock Waste Management Plant

Spatial suitability analysis developed in R to identify optimal locations for a livestock waste management plant in the Pla d’Urgell region (Lleida, Spain).

## Objectives

The project combines environmental, geological, hydrological and urban planning constraints to identify suitable candidate areas through spatial analysis workflows.

## Main Tasks

- Spatial data preprocessing
- CRS harmonization to EPSG:25831
- Land cover suitability analysis
- Urban planning filtering
- Geological permeability classification
- Environmental restriction analysis
- Hydrological constraints from OpenStreetMap
- Vector overlay and geoprocessing
- Polygon area filtering
- Terrain slope analysis using DEM
- Identification of final candidate zones
- GeoJSON export
- Cartographic visualization with ggplot2

## Technologies

- R
- sf
- terra
- tidyverse
- osmdata
- ggplot2
- mapSpain

## Workflow

```text
Input Spatial Data
   ↓
CRS Harmonization
   ↓
Land Cover Filtering
   ↓
Environmental Constraints
   ↓
Hydrological Restrictions
   ↓
Area Filtering
   ↓
Slope Analysis
   ↓
Final Candidate Zones 
