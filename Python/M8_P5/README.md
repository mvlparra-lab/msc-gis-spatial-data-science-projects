# Incident Impact Mapping with PyQGIS

PyQGIS project developed to automate the generation of an incident impact map within QGIS Desktop.

## Objectives

The workflow combines spatial analysis and cartographic automation techniques to identify affected municipalities, calculate impacted population and generate a final PDF map composition.

## Main Tasks

- Loading municipality data from a GeoPackage
- Incident point creation
- Configurable buffer generation
- Spatial intersection analysis
- Affected municipalities selection
- Total affected population calculation
- Temporary memory layer creation
- Custom symbology and label configuration
- Programmatic map composition generation
- Addition of cartographic elements:
  - Title
  - North arrow
  - Scale bar
  - Legend
  - Population information
- Automated PDF export

## Technologies

- Python
- PyQGIS
- PyQt5
- QGIS Desktop
- os

## Workflow

```text
Municipality Layer
        ↓
Incident Point Creation
        ↓
Buffer Generation
        ↓
Spatial Intersection
        ↓
Affected Municipalities Selection
        ↓
Population Calculation
        ↓
Map Composition Creation
        ↓
Cartographic Elements
        ↓
PDF Export