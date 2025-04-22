#!/usr/bin/env bash
set -ex

CONFIG_FILE="kata.yml"
OUTPUT_DIR="/data/tiles"
mkdir -p "$OUTPUT_DIR"

# 全体 default 設定を取得
default_cpg=$(yq e '.default.cpg // "UTF-8"' "$CONFIG_FILE")
default_prj=$(yq e '.default.prj // "EPSG:4326"' "$CONFIG_FILE") # 入力側の指定に使う

# default を除いたレイヤー一覧
source_layers=$(yq e 'keys | .[]' "$CONFIG_FILE" | grep -v '^default$')

for source_layer in $source_layers; do
  echo "==== Source Layer: $source_layer ===="

  minzoom=$(yq e ".\"$source_layer\".minzoom" "$CONFIG_FILE")
  maxzoom=$(yq e ".\"$source_layer\".maxzoom" "$CONFIG_FILE")
  sources_length=$(yq e ".\"$source_layer\".sources | length" "$CONFIG_FILE")

  # 一時 .ndjson リスト
  tmp_ndjson_list=()

  for i in $(seq 0 $((sources_length - 1))); do
    source=$(yq e ".\"$source_layer\".sources[$i]" "$CONFIG_FILE")
    base=$(basename "$source" .shp)
    dir=$(dirname "$source")

    tmp_ndjson="/tmp/${source_layer}_${i}_${base}.ndjson"

    echo "  Source: $source"
    echo "  → Converting to GeoJSONSeq: $tmp_ndjson"
    ogr2ogr -f GeoJSONSeq -s_srs "$default_prj" -t_srs "EPSG:4326" \
      --config SHAPE_ENCODING "$default_cpg" \
      "$tmp_ndjson" "$source"

    tmp_ndjson_list+=("$tmp_ndjson")
  done

  # 出力ファイル名はレイヤ名
  mbtiles_file="${OUTPUT_DIR}/${source_layer}.mbtiles"
  echo "Generating MBTiles: $mbtiles_file"

  tippecanoe \
    -o "$mbtiles_file" \
    -l "$source_layer" \
    -z "$maxzoom" -Z "$minzoom" \
    --drop-densest-as-needed \
    "${tmp_ndjson_list[@]}"

  # クリーンアップ
  rm -f "${tmp_ndjson_list[@]}"
  echo "Finished: $mbtiles_file"
  echo ""
done
