#!/usr/bin/env bash
set -e

CONFIG_FILE="/data/kata.yml"
OUTPUT_DIR="/data/tiles"
mkdir -p "$OUTPUT_DIR"

MAX_JOBS=$(nproc)
echo "MAX_JOBS: $MAX_JOBS"

# Read defaults from config
default_cpg=$(yq e '.default.cpg // "UTF-8"' "$CONFIG_FILE")
default_prj=$(yq e '.default.prj // "EPSG:4326"' "$CONFIG_FILE")
merge_minzoom=$(yq e '.default.minzoom // 8' "$CONFIG_FILE")
merge_maxzoom=$(yq e '.default.maxzoom // 14' "$CONFIG_FILE")

# Gather layer names
mapfile -t source_layers < <(yq e 'keys | .[]' "$CONFIG_FILE" | grep -v '^default$')

# 全体処理開始
start_time_all=$(date +%s)

generate_layer() {
  local source_layer=$1
  echo "==== Source Layer: $source_layer ===="

  local mbtiles_file="${OUTPUT_DIR}/${source_layer}.mbtiles"
  if [[ -f "$mbtiles_file" ]]; then
    echo "MBTiles exists, skip: $mbtiles_file"
    return
  fi

  # Read layer-specific parameters
  local minzoom=$(yq e ".\"$source_layer\".minzoom" "$CONFIG_FILE")
  local maxzoom=$(yq e ".\"$source_layer\".maxzoom" "$CONFIG_FILE")
  local sources_length=$(yq e ".\"$source_layer\".source | length" "$CONFIG_FILE")
  local tmp_ndjson_list=()

  # Start timer for ogr2ogr → tippecanoe
  local start_time_layer=$(date +%s)

  for i in $(seq 0 $((sources_length - 1))); do
    local source=$(yq e ".\"$source_layer\".source[$i]" "$CONFIG_FILE")
    local base=$(basename "$source" .shp)
    local tmp_ndjson="/tmp/${source_layer}_${i}_${base}.ndjson"
    echo "  Source: $source → $tmp_ndjson"

    ogr2ogr -f GeoJSONSeq \
      -s_srs "$default_prj" -t_srs "EPSG:4326" \
      --config SHAPE_ENCODING "$default_cpg" \
      "$tmp_ndjson" "$source"

    tmp_ndjson_list+=("$tmp_ndjson")
  done

  echo "  → tippecanoe generating $mbtiles_file"
  tippecanoe \
    -o "$mbtiles_file" \
    -l "$source_layer" \
    -Z "$minzoom" -z "$maxzoom" \
    --drop-densest-as-needed \
    "${tmp_ndjson_list[@]}"

  # Stop timer and report layer creation time
  local end_time_layer=$(date +%s)
  local elapsed_layer=$((end_time_layer - start_time_layer))
  echo "  → Layer creation time (ogr2ogr→tile): $((elapsed_layer/60))m $((elapsed_layer%60))s"

  # Report tile size
  local tile_size=$(du -h "$mbtiles_file" | cut -f1)
  echo "  → Size of $mbtiles_file: $tile_size"

  # Cleanup temporary files
  rm -f "${tmp_ndjson_list[@]}"
}

# Parallel generation of each layer
for source_layer in "${source_layers[@]}"; do
  generate_layer "$source_layer" &
  if [[ $(jobs -r -p | wc -l) -ge $MAX_JOBS ]]; then
    wait -n
  fi
done
wait

# Merge all tiles
echo "=== Merging all .mbtiles ==="
start_time_merge=$(date +%s)

tile-join \
  -o "${OUTPUT_DIR}/all.mbtiles" \
  --overzoom --no-tile-size-limit \
  -Z "$merge_minzoom" -z "$merge_maxzoom" --force \
  $(find "$OUTPUT_DIR" -name "*.mbtiles" ! -name "all.mbtiles")

# Stop merge timer and report
end_time_merge=$(date +%s)
elapsed_merge=$((end_time_merge - start_time_merge))
echo "  → Merge time: $((elapsed_merge/60))m $((elapsed_merge%60))s"

# Report merged file size
merged_size=$(du -h "${OUTPUT_DIR}/all.mbtiles" | cut -f1)
echo "  → Size of merged file: $merged_size"

# 全体処理終了／時間報告
end_time_all=$(date +%s)
elapsed_all=$((end_time_all - start_time_all))
echo "All tiles generated and merged at ${OUTPUT_DIR}/all.mbtiles"
echo "===> Total time: $((elapsed_all/60))m $((elapsed_all%60))s"

# 最終的なディスク使用量
echo "Disk usage of output directory:"
du -sh "$OUTPUT_DIR"
