#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="kata.yml"

# 出力ディレクトリ設定
OUTPUT_DIR="/data/tiles"
mkdir -p "$OUTPUT_DIR"

# source-layer をループ
source_layers=$(yq e 'keys | .[]' "$CONFIG_FILE")

for source_layer in $source_layers; do
  echo "==== Source Layer: $source_layer ===="

  source=$(yq e ".\"$source_layer\".source" "$CONFIG_FILE")
  minzoom=$(yq e ".\"$source_layer\".minzoom" "$CONFIG_FILE")
  maxzoom=$(yq e ".\"$source_layer\".maxzoom" "$CONFIG_FILE")

  echo "Source: $source"
  echo "MinZoom: $minzoom"
  echo "MaxZoom: $maxzoom"

  # Shapefile名から中間ファイルパスを生成
  base=$(basename "$source" .shp)
  tmp_ndjson="/tmp/${base}.ndjson"
  mbtiles_file="${OUTPUT_DIR}/${base}.mbtiles"

  echo "Converting .shp to .ndjson with ogr2ogr (GeoJSONSeq)..."
  ogr2ogr -f GeoJSONSeq -t_srs EPSG:4326 "$tmp_ndjson" "$source"

  echo "Generating MBTiles with Tippecanoe..."
  tippecanoe \
    -o "$mbtiles_file" \
    -l "$source_layer" \
    -z "$maxzoom" -Z "$minzoom" \
    "$tmp_ndjson"

  rm -f "$tmp_ndjson"
  echo "Finished: $mbtiles_file"
  echo ""
done
