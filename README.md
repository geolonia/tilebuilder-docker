# gt-tilebuild

Shapefile（.shp）を Tippecanoe を使って `.mbtiles` に変換する Docker 環境です。  
GitHub Actions を使って自動ビルドし、GitHub Container Registry (GHCR) にイメージを公開しています。

---

## 主な機能

- `.shp` → `.ndjson`（GeoJSONSeq）→ `.mbtiles` に変換
- `.cpg`（UTF-8）と `.prj`（JGD2000）ファイルがなければ自動生成
- 出力は `.shp` と同じディレクトリに `.mbtiles` を生成
- `.ndjson` は一時的に `/tmp` に生成され、処理後に削除されます
- GitHub Actions により `git tag v1.2.3` で Docker イメージが GHCR に自動 push

---

## 使い方

以下のコマンドで最新バージョンを pullして下さい。

```bash
docker pull ghcr.io/geolonia/gt-tilebuild:latest
```

実行：

```bash
docker run --rm -v $(pwd)/.:/data ghcr.io/geolonia/gt-tilebuild:latest
```

---

## 開発者向け

### ビルド

```bash
docker build -t gt-tilebuild .
```

### 実行

```bash
docker run --rm -v $(pwd)/data:/data gt-tilebuild
```

## バージョン管理とデプロイ

新しいバージョンをリリースするには：

```bash
git tag v1.2.0
git push origin v1.2.0
```

GitHub Actions により、`ghcr.io/geolonia/gt-tilebuild:v1.2.0` と `:latest` タグが自動的に push されます。