# gt-tilebuild

- Shapeファイル を Tippecanoe を使って `.mbtiles` に変換する Docker 環境です。  
- ファイルが配置されているディレクトリを指定して、Docker を実行すると MBTiles が作成されます。

### 使い方

以下を実行して Docker コンテナを pull して下さい。（初回のみ）
```bash
docker pull ghcr.io/geolonia/gt-tilebuild:latest
```

#### タイルの作成
Shapeファイルがあるディレクトリ`<YOUR-DIR>`を指定して、以下のコマンドを実行すると `<YOUR-DIR>/tiles` に MBTiles が作成されます。

```bash
docker run --rm -v $(pwd)/<YOUR-DIR>:/data ghcr.io/geolonia/gt-tilebuild:latest
```


#### 実行例

```bash
mkdir input
cp ./roads.shp input/
cp ./roads.shx input/
cp ./roads.dbf input/

docker run --rm -v $(pwd)/input:/data ghcr.io/geolonia/gt-tilebuild:latest
```

実行後、`input/tiles` ディレクトリに `roads.mbtiles` が出力されます。
