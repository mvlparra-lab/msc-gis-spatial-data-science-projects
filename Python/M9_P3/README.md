# Burn Severity Assessment Using dNBR

Python project developed to analyse wildfire severity using satellite imagery and spectral indices.

## Objectives

The workflow uses HLS (Harmonized Landsat Sentinel) imagery accessed through a STAC catalog to calculate the Normalized Burn Ratio (NBR) before and after a wildfire event and derive the dNBR burn severity index.

## Main Tasks

- HLS imagery search using a STAC API
- Date range and cloud cover filtering
- Automatic selection of the scene with the lowest cloud coverage
- NIR and SWIR spectral band loading
- Spatial clipping using the study area bounding box
- Pre-fire and post-fire NBR calculation
- dNBR burn severity index calculation
- Burn severity classification
- Wildfire severity visualization
- PNG export of the final burn severity map

## Study Area

- Evros, Greece
- Wildfire event: 2023

## Technologies

- Python
- pystac-client
- planetary-computer
- rasterio
- numpy
- matplotlib

## Workflow

```text
STAC Search
        ↓
Image Filtering
        ↓
Lowest Cloud Selection
        ↓
Band Loading (NIR & SWIR)
        ↓
Spatial Clip
        ↓
NBR Calculation
        ↓
dNBR Calculation
        ↓
Severity Classification
        ↓
Final Visualization