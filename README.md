# gt-tilebuild

Shapefile（.shp）を Tippecanoe を使って `.mbtiles` に変換する Docker 環境です。

## 使い方

```bash
docker pull ghcr.io/geolonia/gt-tilebuild:latest
docker run --rm -v $(pwd)/<YOUR-DIR>:/data ghcr.io/geolonia/gt-tilebuild:latest
```

- `<YOUR-DIR>` に Shapeファイルを配置してください
- `.mbtiles` `<YOUR-DIR>/tiles` に出力されます

### 実行例

```bash
mkdir input
cp ./your-shape.shp input/
cp ./your-shape.shx input/
cp ./your-shape.dbf input/

docker run --rm -v $(pwd)/input:/data ghcr.io/geolonia/gt-tilebuild:latest
```

実行後、`data/tiles` ディレクトリに `roads.mbtiles` が出力されます。
