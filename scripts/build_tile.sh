#!/usr/bin/env bash
set -e

CONFIG_FILE="/data/kata.yml"
OUTPUT_DIR="/data/tiles"
mkdir -p "$OUTPUT_DIR"

MAX_JOBS=$(nproc)

default_cpg=$(yq e '.default.cpg // "UTF-8"' "$CONFIG_FILE")
default_prj=$(yq e '.default.prj // "EPSG:4326"' "$CONFIG_FILE")
merge_minzoom=$(yq e '.default.minzoom // 8' "$CONFIG_FILE")
merge_maxzoom=$(yq e '.default.maxzoom // 14' "$CONFIG_FILE")

mapfile -t source_layers < <(yq e 'keys | .[]' "$CONFIG_FILE" | grep -v '^default$')

# === dstat でシステム計測（バックグラウンド） ===
DSTAT_LOG="/tmp/dstat.csv"
dstat -cdmnyt --output "$DSTAT_LOG" 1 > /dev/null &
DSTAT_PID=$!

# === 全体処理の開始時間 ===
start_time_all=$(date +%s)

generate_layer() {
  local source_layer=$1
  echo "==== Source Layer: $source_layer ===="

  local mbtiles_file="${OUTPUT_DIR}/${source_layer}.mbtiles"
  if [[ -f "$mbtiles_file" ]]; then
    echo "MBTiles exists, skip: $mbtiles_file"
    return
  fi

  local start_time_layer=$(date +%s)
  local minzoom=$(yq e ".\"$source_layer\".minzoom" "$CONFIG_FILE")
  local maxzoom=$(yq e ".\"$source_layer\".maxzoom" "$CONFIG_FILE")
  local sources_length=$(yq e ".\"$source_layer\".source | length" "$CONFIG_FILE")
  local tmp_ndjson_list=()

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

  rm -f "${tmp_ndjson_list[@]}"
  local end_time_layer=$(date +%s)
  local elapsed=$((end_time_layer - start_time_layer))
  echo "  → $source_layer done in $((elapsed/60))m $((elapsed%60))s"
}

for source_layer in "${source_layers[@]}"; do
  generate_layer "$source_layer" &

  if [[ $(jobs -r -p | wc -l) -ge $MAX_JOBS ]]; then
    wait -n
  fi
done

wait

echo "Merging all .mbtiles..."
TILEJOIN_OPTS=(
  "--overzoom" "--no-tile-size-limit"
  "-Z" "$merge_minzoom" "-z" "$merge_maxzoom" "--force"
)
mapfile -t mbtiles_files < <(find "$OUTPUT_DIR" -name "*.mbtiles" ! -name "all.mbtiles")
tile-join -o "${OUTPUT_DIR}/all.mbtiles" "${TILEJOIN_OPTS[@]}" "${mbtiles_files[@]}"

end_time_all=$(date +%s)
elapsed_all=$((end_time_all - start_time_all))
echo "All tiles generated and merged at ${OUTPUT_DIR}/all.mbtiles"
echo "===> Total time: $((elapsed_all/60))m $((elapsed_all%60))s"

# dstat 終了
kill "$DSTAT_PID"
echo "dstat log written to $DSTAT_LOG"
