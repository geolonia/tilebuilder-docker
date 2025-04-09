#!/usr/bin/env bash
set -ex

# デフォルトディレクトリ
TARGET_DIR="/data"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Processing directory: $TARGET_DIR"

# Zipファイルを解凍
. "$SCRIPT_DIR/unzip.sh" "$TARGET_DIR"

find "$TARGET_DIR" -iname "*.shp" | while read -r shpfile; do
    echo "Processing: $shpfile"

    base=$(basename "$shpfile" .shp)

    cpg_file="${shpfile%.shp}.cpg"
    if [ ! -f "$cpg_file" ]; then
        echo "UTF-8" > "$cpg_file"
        echo "Created .cpg: $cpg_file"
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
