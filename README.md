# Sentinel-2 RGB to Cloud Optimized GeoTIFF (COG)

This script converts Sentinel-2 10m bands into an RGB Cloud Optimized
GeoTIFF (COG).\
It also supports optional clipping to a polygon feature from a GeoJSON
file.

## Features

-   Automatically detects Sentinel-2 bands (B02, B03, B04 at 10m
    resolution)
-   Converts to 8-bit RGB with fixed scale (`0–4000`) and gamma
    correction (`0.95`)
-   Produces a **Cloud Optimized GeoTIFF (COG)** with Google Maps
    compatible tiling scheme
-   Optional clipping using a **GeoJSON polygon**
-   Works on **Linux** and **macOS**

## Requirements

-   [GDAL](https://gdal.org) installed and available in your PATH\
    (on macOS with QGIS: add GDAL tools to your PATH, e.g.\
    `export PATH="/Applications/QGIS.app/Contents/MacOS/bin:$PATH"`)

## Usage

``` bash
./make_rgb_cog.sh /path/to/input_folder /path/to/output_folder [clip_geojson] [clip_where]
```

### Parameters

-   `/path/to/input_folder` → folder containing Sentinel-2 JP2 files
    (B02, B03, B04, 10m resolution)
-   `/path/to/output_folder` → folder where outputs will be created
-   `[clip_geojson]` → optional GeoJSON file containing polygons to clip
    against
-   `[clip_where]` → optional filter expression as a condition applied to properties.attribute 

(e.g. `"fid='2'"` to select one polygon with attribute fid equal to string '2'), 

(e.g. `"id = 2"` to select one polygon with attribute id equal to number 2).

### Example

Convert Sentinel-2 JP2 files into a COG:

``` bash
./make_rgb_cog.sh ./S2_input ./output
```

Convert and clip to a specific feature from a GeoJSON:

``` bash
./make_rgb_cog.sh ./S2_input ./output area.geojson "fid = 2"
```

## Outputs

-   `sentinel2_RGB_cog.tif` → the full RGB Cloud Optimized GeoTIFF
-   `sentinel2_RGB_cog_clipped.tif` → clipped version (if GeoJSON and
    filter are provided)

## Notes

-   The script applies **gamma correction (0.95)** by default to
    slightly lighten the image.\
-   If clipping by feature, ensure your GeoJSON has an attribute (`fid`,
    `id`, etc.) that you can filter on.
-   Temporary files are automatically cleaned up.

------------------------------------------------------------------------

### License

MIT License
