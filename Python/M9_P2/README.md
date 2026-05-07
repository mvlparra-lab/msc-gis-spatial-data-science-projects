# Exploration and Visualization of Satellite Images

Python project developed to explore, visualize and process Landsat 9 satellite imagery using a Jupyter Notebook workflow.

## Objectives

The workflow combines raster processing and spectral analysis techniques to visualize Landsat 9 bands, apply cloud masking, generate RGB compositions, clip the imagery to Barcelona municipality and calculate vegetation and water indices.

## Main Tasks

- Reading and visualization of Landsat 9 bands
- Histogram generation for visible and NIR bands
- Scatter plot analysis between Red and NIR bands
- Cloud masking using the QA_PIXEL band
- Natural color RGB composition
- False color image composition
- Image clipping using a shapefile
- NDVI calculation
- NDWI calculation
- Contrast enhancement for image visualization
- Application of Landsat Collection 2 Level 2 scaling factors

## Technologies

- Python
- Jupyter Notebook
- numpy
- rasterio
- matplotlib
- geopandas

## Workflow

```text
Landsat 9 Bands
        ↓
Band Visualization
        ↓
Histogram Analysis
        ↓
Scatter Plot Analysis
        ↓
Cloud Masking
        ↓
RGB Composition
        ↓
False Color Composition
        ↓
Spatial Clipping
        ↓
NDVI & NDWI Calculation

## Data Availability

Original Landsat 9 raster datasets are not included in this repository due to file size limitations.