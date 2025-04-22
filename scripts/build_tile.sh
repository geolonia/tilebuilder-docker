#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="kata.yml"

# レイヤー名 = source-layer として取得
source_layers=$(yq e 'keys | .[]' "$CONFIG_FILE")

for source_layer in $source_layers; do
  echo "==== Source Layer: $source_layer ===="

  source=$(yq e ".\"$source_layer\".source" "$CONFIG_FILE")
  minzoom=$(yq e ".\"$source_layer\".minzoom" "$CONFIG_FILE")
  maxzoom=$(yq e ".\"$source_layer\".maxzoom" "$CONFIG_FILE")

  echo "Source: $source"
  echo "MinZoom: $minzoom"
  echo "MaxZoom: $maxzoom"

  echo "Properties:"
  yq e ".\"$source_layer\".properties" "$CONFIG_FILE"
  echo ""
done
