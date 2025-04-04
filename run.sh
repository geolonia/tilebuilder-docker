#!/usr/bin/env bash
set -e

PRJ_CONTENT='GEOGCS["GCS_JGD_2000",DATUM["D_JGD_2000",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]]'

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <directory1> [directory2 ...]"
    exit 1
fi

# 出力ディレクトリ（ルートの tiles）
ROOT_TILES_DIR="/data/tiles"
mkdir -p "$ROOT_TILES_DIR"

for dir in "$@"; do
    echo "Processing directory: $dir"

    find "$dir" -iname "*.shp" | while read -r shpfile; do
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

        ndjson_file="${ROOT_TILES_DIR}/${base}.ndjson"
        mbtiles_file="${ROOT_TILES_DIR}/${base}.mbtiles"

        echo "Converting .shp to .ndjson with ogr2ogr (GeoJSONSeq)..."
        ogr2ogr -f GeoJSONSeq -t_srs EPSG:4326 "$ndjson_file" "$shpfile"

        echo "Generating MBTiles with Tippecanoe..."
        tippecanoe -o "$mbtiles_file" "$ndjson_file"

        rm -f "$ndjson_file"

        echo "Finished: $mbtiles_file"
    done
done
