# CSV Processing and Geocoding of Student Data

Python project developed to automate the processing, merging and geocoding of student records stored across multiple CSV files.

## Objectives

The workflow combines CSV processing and geocoding techniques to generate a unified dataset containing student information and geographic coordinates derived from postal addresses.

## Main Tasks

- Automatic detection of CSV files from a directory
- Reading and merging multiple CSV datasets
- UTF-8 and Latin-1 encoding handling
- Address geocoding using GeoPy and Nominatim
- Latitude and longitude extraction
- Unified CSV generation
- Error handling for non-geocoded addresses
- Modular Python project structure

## Technologies

- Python
- os
- csv
- geopy

## Workflow

```text
Multiple CSV Files
        ↓
CSV Detection & Reading
        ↓
Data Merging
        ↓
Address Geocoding
        ↓
Coordinate Extraction
        ↓
Error Handling
        ↓
Unified CSV Output