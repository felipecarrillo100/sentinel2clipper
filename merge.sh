#!/bin/bash
# Sentinel-2 RGB batch converter producing a Cloud Optimized GeoTIFF (COG)
# Usage: ./make_rgb_cog.sh /path/to/input_folder /path/to/output_folder [clip_geojson] [clip_where]

set -euo pipefail

INPUT_FOLDER="$1"
OUTPUT_FOLDER="$2"
GEOJSON="${3:-}"
CWHERE="${4:-}"

# Check arguments
if [[ -z "$INPUT_FOLDER" ]]; then
  echo "ERROR: Please provide input folder"
  exit 1
fi

if [[ -z "$OUTPUT_FOLDER" ]]; then
  echo "ERROR: Please provide output folder"
  exit 1
fi

# Make sure output folder exists
mkdir -p "$OUTPUT_FOLDER"

# Find JP2 band files
BAND2=$(ls "$INPUT_FOLDER"/*B02_10m.jp2 2>/dev/null | head -n 1 || true)
BAND3=$(ls "$INPUT_FOLDER"/*B03_10m.jp2 2>/dev/null | head -n 1 || true)
BAND4=$(ls "$INPUT_FOLDER"/*B04_10m.jp2 2>/dev/null | head -n 1 || true)

# Validate bands
if [[ -z "$BAND2" ]]; then echo "ERROR: B02 file not found"; exit 1; fi
if [[ -z "$BAND3" ]]; then echo "ERROR: B03 file not found"; exit 1; fi
if [[ -z "$BAND4" ]]; then echo "ERROR: B04 file not found"; exit 1; fi

# Convert each band to 8-bit with fixed scale 0-4000 + gamma 0.95
echo "Converting bands to 8-bit with fixed gamma 0.95..."
gdal_translate -scale 0 4000 0 255 -exponent 0.95 -ot Byte "$BAND4" "$OUTPUT_FOLDER/tmp_R.tif"
gdal_translate -scale 0 4000 0 255 -exponent 0.95 -ot Byte "$BAND3" "$OUTPUT_FOLDER/tmp_G.tif"
gdal_translate -scale 0 4000 0 255 -exponent 0.95 -ot Byte "$BAND2" "$OUTPUT_FOLDER/tmp_B.tif"

# Build a VRT with the three bands
gdalbuildvrt -separate "$OUTPUT_FOLDER/tmp_RGB.vrt" \
  "$OUTPUT_FOLDER/tmp_R.tif" \
  "$OUTPUT_FOLDER/tmp_G.tif" \
  "$OUTPUT_FOLDER/tmp_B.tif"

# Convert VRT to 8-bit Cloud Optimized GeoTIFF
gdal_translate -of COG -co COMPRESS=LZW -co BIGTIFF=IF_SAFER \
  -co TILING_SCHEME=GoogleMapsCompatible -ot Byte \
  "$OUTPUT_FOLDER/tmp_RGB.vrt" "$OUTPUT_FOLDER/sentinel2_RGB_cog.tif"

# Optional clipping if GeoJSON + filter are provided
if [[ -n "$GEOJSON" && -n "$CWHERE" ]]; then
  echo "Clipping to feature: $CWHERE"
  gdalwarp -cutline "$GEOJSON" -cwhere "$CWHERE" -crop_to_cutline -of COG \
    -co COMPRESS=LZW -co BIGTIFF=IF_SAFER -co TILING_SCHEME=GoogleMapsCompatible \
    "$OUTPUT_FOLDER/sentinel2_RGB_cog.tif" "$OUTPUT_FOLDER/sentinel2_RGB_cog_clipped.tif"
  echo "Clipped raster created: $OUTPUT_FOLDER/sentinel2_RGB_cog_clipped.tif"
fi

# Clean up temporary files
rm -f "$OUTPUT_FOLDER/tmp_R.tif" \
      "$OUTPUT_FOLDER/tmp_G.tif" \
      "$OUTPUT_FOLDER/tmp_B.tif" \
      "$OUTPUT_FOLDER/tmp_RGB.vrt"

echo "Done! Created $OUTPUT_FOLDER/sentinel2_RGB_cog.tif"
