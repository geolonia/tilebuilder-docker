#!/usr/bin/env bash
set -ex

PRJ_CONTENT='GEOGCS["GCS_JGD_2000",DATUM["D_JGD_2000",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]]'

# デフォルトディレクトリ
TARGET_DIR="/data"

echo "Processing directory: $TARGET_DIR"

# Zipファイルを解凍
./unzip.sh

find "$TARGET_DIR" -iname "*.shp" | while read -r shpfile; do
    echo "Processing: $shpfile"

    base=$(basename "$shpfile" .shp)

    cpg_file="${shpfile%.shp}.cpg"
    if [ ! -f "$cpg_file" ]; then
        echo "UTF-8" > "$cpg_file"
        echo "Created .cpg: $cpg_file"
    fi

    prj_file="${shpfile%.shp}.prj"
    if [ ! -f "$prj_file" ]; then
        echo "$PRJ_CONTENT" > "$prj_file"
        echo "Created .prj: $prj_file"
    fi

    tmp_ndjson="/tmp/${base}.ndjson"
    mbtiles_file="${TARGET_DIR}/${base}.mbtiles"

    echo "Converting .shp to .ndjson with ogr2ogr (GeoJSONSeq)..."
    ogr2ogr -f GeoJSONSeq -t_srs EPSG:4326 "$tmp_ndjson" "$shpfile"

    echo "Generating MBTiles with Tippecanoe..."
    tippecanoe -o "$mbtiles_file" "$tmp_ndjson"

    rm -f "$tmp_ndjson"

    echo "Finished: $mbtiles_file"
done
