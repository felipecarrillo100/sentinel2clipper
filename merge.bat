@echo off
REM Sentinel-2 RGB batch converter producing a Cloud Optimized GeoTIFF (COG)
REM Usage: make_rgb_cog.bat "C:\input_folder" "C:\output_folder" [clip_geojson] [clip_where]

if "%1"=="" (
    echo ERROR: Please provide input folder
    exit /b 1
)

if "%2"=="" (
    echo ERROR: Please provide output folder
    exit /b 1
)

set INPUT_FOLDER=%~1
set OUTPUT_FOLDER=%~2
set GEOJSON=%~3
set CWHERE=%~4

REM Make sure output folder exists
if not exist "%OUTPUT_FOLDER%" mkdir "%OUTPUT_FOLDER%"

REM Find the JP2 files dynamically using wildcard *B??_10m.jp2
for %%f in ("%INPUT_FOLDER%\*B02_10m.jp2") do set BAND2=%%f
for %%f in ("%INPUT_FOLDER%\*B03_10m.jp2") do set BAND3=%%f
for %%f in ("%INPUT_FOLDER%\*B04_10m.jp2") do set BAND4=%%f

REM Check that all bands were found
if "%BAND2%"=="" echo ERROR: B02 file not found & exit /b 1
if "%BAND3%"=="" echo ERROR: B03 file not found & exit /b 1
if "%BAND4%"=="" echo ERROR: B04 file not found & exit /b 1

REM Convert each band to 8-bit with fixed scale 0-4000 + gamma 0.95
echo Converting bands to 8-bit with fixed gamma 0.95...
gdal_translate -scale 0 4000 0 255 -exponent 0.95 -ot Byte "%BAND4%" "%OUTPUT_FOLDER%\tmp_R.tif"
gdal_translate -scale 0 4000 0 255 -exponent 0.95 -ot Byte "%BAND3%" "%OUTPUT_FOLDER%\tmp_G.tif"
gdal_translate -scale 0 4000 0 255 -exponent 0.95 -ot Byte "%BAND2%" "%OUTPUT_FOLDER%\tmp_B.tif"

REM Build a VRT (virtual raster) with the three bands
gdalbuildvrt -separate "%OUTPUT_FOLDER%\tmp_RGB.vrt" ^
  "%OUTPUT_FOLDER%\tmp_R.tif" ^
  "%OUTPUT_FOLDER%\tmp_G.tif" ^
  "%OUTPUT_FOLDER%\tmp_B.tif"

REM Convert VRT to 8-bit Cloud Optimized GeoTIFF
gdal_translate -of COG -co COMPRESS=LZW -co BIGTIFF=IF_SAFER ^
  -co TILING_SCHEME=GoogleMapsCompatible -ot Byte ^
  "%OUTPUT_FOLDER%\tmp_RGB.vrt" "%OUTPUT_FOLDER%\sentinel2_RGB_cog.tif"

REM If GeoJSON + filter provided, clip the COG
if not "%GEOJSON%"=="" (
    echo Clipping to feature: %CWHERE%
    gdalwarp -cutline "%GEOJSON%" -cwhere "%CWHERE%" -crop_to_cutline -of COG ^
      -co COMPRESS=LZW -co BIGTIFF=IF_SAFER -co TILING_SCHEME=GoogleMapsCompatible ^
      "%OUTPUT_FOLDER%\sentinel2_RGB_cog.tif" "%OUTPUT_FOLDER%\sentinel2_RGB_cog_clipped.tif"
    echo Clipped raster created: "%OUTPUT_FOLDER%\sentinel2_RGB_cog_clipped.tif"
)

REM Clean up temporary files
del "%OUTPUT_FOLDER%\tmp_R.tif"
del "%OUTPUT_FOLDER%\tmp_G.tif"
del "%OUTPUT_FOLDER%\tmp_B.tif"
del "%OUTPUT_FOLDER%\tmp_RGB.vrt"

echo Done! Created "%OUTPUT_FOLDER%\sentinel2_RGB_cog.tif"
