#!/usr/bin/env bash
set -ex

# デフォルトディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="/data"
OUTPUT_DIR="/data/tiles"
# OUTPUT_DIR が存在しない場合は作成
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

echo "Processing directory: $TARGET_DIR"

# Zipファイルを解凍
. "$SCRIPT_DIR/unzip.sh" "$TARGET_DIR"


find "$TARGET_DIR" -iname "*.shp" | while read -r shpfile; do
    echo "Processing: $shpfile"

    base=$(basename "$shpfile" .shp)

    tmp_ndjson="/tmp/${base}.ndjson"
    mbtiles_file="${OUTPUT_DIR}/${base}.mbtiles"

    echo "Converting .shp to .ndjson with ogr2ogr (GeoJSONSeq)..."
    ogr2ogr -f GeoJSONSeq -t_srs EPSG:4326 "$tmp_ndjson" "$shpfile"

    echo "Generating MBTiles with Tippecanoe..."
    tippecanoe -o "$mbtiles_file" "$tmp_ndjson"

    rm -f "$tmp_ndjson"

    echo "Finished: $mbtiles_file"
done
