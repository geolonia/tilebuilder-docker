#!/usr/bin/env bash
set -e

echo "Script started at: $(date)"

CONFIG_FILE="$1/kata.yml"
OUTPUT_DIR="$1/tiles"
TMPDIR="$1/tmp"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$TMPDIR"

MAX_JOBS=$(nproc)
echo "MAX_JOBS: $MAX_JOBS"

# Read defaults from config
default_cpg=$(yq e '.default.cpg // "UTF-8"' "$CONFIG_FILE")
default_prj=$(yq e '.default.prj // "EPSG:4326"' "$CONFIG_FILE")

# Gather tile names
mapfile -t target_tiles < <(yq e 'keys | .[]' "$CONFIG_FILE" | grep -v '^default$')

# 全体処理開始
start_time_all=$(date +%s)

generate_tile_layer() {
  local target_tile=$1
  local source_layer=$2
  echo "==== Target Tile: $target_tile, Source Layer: $source_layer ===="

  local mbtiles_file="${OUTPUT_DIR}/${target_tile}/${source_layer}.mbtiles"
  if [[ -f "$mbtiles_file" ]]; then
    echo "MBTiles exists, skip: $mbtiles_file"
    return
  fi

  # Read layer-specific parameters
  local minzoom=$(yq e ".\"$target_tile\".\"$source_layer\".minzoom" "$CONFIG_FILE")
  local maxzoom=$(yq e ".\"$target_tile\".\"$source_layer\".maxzoom" "$CONFIG_FILE")
  local sources_length=$(yq e ".\"$target_tile\".\"$source_layer\".source | length" "$CONFIG_FILE")
  local tmp_ndjson_list=()

  # Start timer for ogr2ogr → tippecanoe
  local start_time_layer=$(date +%s)

  for i in $(seq 0 $((sources_length - 1))); do
    local source=$(yq e ".\"$target_tile\".\"$source_layer\".source[$i]" "$CONFIG_FILE")
    local base=$(basename "$source" .shp)
    local tmp_ndjson="${TMPDIR}/${target_tile}_${source_layer}_${i}_${base}.ndjson"
    echo "  Source: $source → $tmp_ndjson"

    ogr2ogr -f GeoJSONSeq \
      -s_srs "$default_prj" -t_srs "EPSG:4326" \
      --config SHAPE_ENCODING "$default_cpg" \
      "$tmp_ndjson" "$source"

    tmp_ndjson_list+=("$tmp_ndjson")
  done

  echo "  → tippecanoe generating $mbtiles_file"
  
  # 大量のデータを扱う場合、容量の大きいストレージを --temporary-directory= で指定することでストレージ不足エラーを回避する
  tippecanoe \
    -o "$mbtiles_file" \
    -l "$source_layer" \
    -Z "$minzoom" -z "$maxzoom" \
    --drop-densest-as-needed \
    --temporary-directory="$TMPDIR" \
    "${tmp_ndjson_list[@]}"
    

  # Stop timer and report layer creation time
  local end_time_layer=$(date +%s)
  local elapsed_layer=$((end_time_layer - start_time_layer))
  echo "  → Each MBTiles creation time (shape→mbtiles): $((elapsed_layer/60))m $((elapsed_layer%60))s"

  # Report tile size
  local tile_size=$(du -h "$mbtiles_file" | cut -f1)
  echo "  → Size of $mbtiles_file: $tile_size"

  # Cleanup temporary files
  rm -f "${tmp_ndjson_list[@]}"
}

# Parallel generation of each tile/layer
for target_tile in "${target_tiles[@]}"; do
  mkdir -p "$OUTPUT_DIR/$target_tile"
  mapfile -t source_layers < <(yq e ".\"$target_tile\" | keys | .[]" "$CONFIG_FILE")
  for source_layer in "${source_layers[@]}"; do
    generate_tile_layer "$target_tile" "$source_layer" &
    if [[ $(jobs -r -p | wc -l) -ge $MAX_JOBS ]]; then
      wait -n
    fi
  done
done
wait

merge_tile_layers() {
  local target_tile=$1
  # Merge key tiles
  echo "=== Merging $target_tile mbtiles ==="
  start_time_merge=$(date +%s)

  tile-join \
    -o "${OUTPUT_DIR}/$target_tile.mbtiles" \
    --overzoom --no-tile-size-limit \
    --force \
    $(find "$OUTPUT_DIR/$target_tile/" -name "*.mbtiles")

  # Stop merge timer and report
  end_time_merge=$(date +%s)
  elapsed_merge=$((end_time_merge - start_time_merge))
  echo "  → Merge time: $((elapsed_merge/60))m $((elapsed_merge%60))s"

  # Report merged file size
  merged_size=$(du -h "${OUTPUT_DIR}/$target_tile.mbtiles" | cut -f1)
  echo "  → Size of merged file: $merged_size"
}

# Parallel merging each tile/layers
for target_tile in "${target_tiles[@]}"; do
  merge_tile_layers "$target_tile" &
  if [[ $(jobs -r -p | wc -l) -ge $MAX_JOBS ]]; then
    wait -n
  fi
done
wait

# 全体処理終了／時間報告
end_time_all=$(date +%s)
elapsed_all=$((end_time_all - start_time_all))
echo "All tiles generated and merged at ${OUTPUT_DIR}/*.mbtiles"
echo "===> Total time: $((elapsed_all/60))m $((elapsed_all%60))s"

# Cleanup temporary files
echo "Cleaning up temporary files..."
rm -rf "$TMPDIR"

echo "Script finished at: $(date)"
