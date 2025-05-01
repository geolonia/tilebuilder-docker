#!/usr/bin/env bash
set -e

CONFIG_FILE="/data/kata.yml"
OUTPUT_DIR="/data/tiles"
mkdir -p "$OUTPUT_DIR"

# 処理の開始時間を記録
start_time=$(date +%s)

# 全体 default 設定を取得
default_cpg=$(yq e '.default.cpg // "UTF-8"' "$CONFIG_FILE")
default_prj=$(yq e '.default.prj // "EPSG:4326"' "$CONFIG_FILE") # 入力側の指定に使う
merge_minzoom=$(yq e '.default.minzoom // 8' "$CONFIG_FILE")
merge_maxzoom=$(yq e '.default.maxzoom // 14' "$CONFIG_FILE")

# default を除いたレイヤー一覧
source_layers=$(yq e 'keys | .[]' "$CONFIG_FILE" | grep -v '^default$')

for source_layer in $source_layers; do
  echo "==== Source Layer: $source_layer ===="

  # 出力ファイル名はレイヤ名
  mbtiles_file="${OUTPUT_DIR}/${source_layer}.mbtiles"
  
  echo "  → MBTiles: $mbtiles_file"
  if [ -f "$mbtiles_file" ]; then
    echo "MBTiles がすでに存在しているので: $mbtiles_file の生成をスキップします"
  else

    # 個別のタイルを作るのにかかった時間を記録
    start_time_layer=$(date +%s)

    minzoom=$(yq e ".\"$source_layer\".minzoom" "$CONFIG_FILE")
    maxzoom=$(yq e ".\"$source_layer\".maxzoom" "$CONFIG_FILE")
    sources_length=$(yq e ".\"$source_layer\".source | length" "$CONFIG_FILE")

    # 一時 .ndjson リスト
    tmp_ndjson_list=()

    for i in $(seq 0 $((sources_length - 1))); do
      source=$(yq e ".\"$source_layer\".source[$i]" "$CONFIG_FILE")
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
    echo "MBTilesを生成: $mbtiles_file"
    tippecanoe \
      -o "$mbtiles_file" \
      -l "$source_layer" \
      -z "$maxzoom" -Z "$minzoom" \
      --drop-densest-as-needed \
      "${tmp_ndjson_list[@]}"

    # タイル生成にかかった時間を記録
    end_time_layer=$(date +%s)
    elapsed_time_layer=$((end_time_layer - start_time_layer))
    echo "  → $source_layer.mbtiles の生成にかかった時間: $((elapsed_time_layer / 60)) 分 $((elapsed_time_layer % 60)) 秒"
  fi
done

# 生成した .mbtiles をマージ
TILEJOIN_OPTS=(
    "--overzoom"
    "--no-tile-size-limit"
    "-Z" "$merge_minzoom"
    "-z" "$merge_maxzoom"
    "--force"
)

IFS=$'\n' #スペースを含むファイル名に対応
mbtiles_files=($(find . -name "*.mbtiles" ! -name "all.mbtiles"))
echo "マージする .mbtiles ファイル: ${mbtiles_files[@]}"
merged_file="${OUTPUT_DIR}/all.mbtiles"
tile-join -o "$merged_file" "${TILEJOIN_OPTS[@]}" "${mbtiles_files[@]}"

# クリーンアップ
rm -f "${tmp_ndjson_list[@]}"
echo "全てのタイルの生成が完了しました: $mbtiles_file"

# 処理の終了時間を記録
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
echo "全てのタイル生成にかかった時間: $((elapsed_time / 60)) 分 $((elapsed_time % 60)) 秒"
echo "タイル生成を終了します: $(date)"