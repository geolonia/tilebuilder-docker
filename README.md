# gt-tilebuild

Shapefile（.shp）を Tippecanoe を使って `.mbtiles` に変換する Docker 環境です。

## 使い方

以下を実行して Docker コンテナを pull して下さい。
```bash
docker pull ghcr.io/geolonia/gt-tilebuild:latest
```

### タイルの作成
`<YOUR-DIR>` に Shapeファイルを配置して、以下を実行すると `<YOUR-DIR>/tiles` に MBTiles が作成されます。

```bash
docker run --rm -v $(pwd)/<YOUR-DIR>:/data ghcr.io/geolonia/gt-tilebuild:latest
```


### 実行例

```bash
mkdir input
cp ./roads.shp input/
cp ./roads.shx input/
cp ./roads.dbf input/

docker run --rm -v $(pwd)/input:/data ghcr.io/geolonia/gt-tilebuild:latest
```

実行後、`input/tiles` ディレクトリに `roads.mbtiles` が出力されます。
