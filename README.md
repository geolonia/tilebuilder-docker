# tilebuilder-docker

- Shapeファイル を Tippecanoe を使って `.mbtiles` に変換する Docker 環境です。  
- ファイルが配置されているディレクトリを指定して、Docker を実行すると MBTiles が作成されます。

### 使い方

下記のテンプレートを使用して下さい。
- https://github.com/geolonia/tilebuilder/

### 開発者向け

#### ビルド

```bash
$ docker build -t tilebuilder .
```

#### 実行

```bash
$ docker run --rm -v $(pwd)/data:/data tilebuilder
```

## バージョン管理とデプロイ

新しいバージョンをリリースするには：

```bash
git tag v1.2.0
git push origin v1.2.0
```

GitHub Actions により、`ghcr.io/geolonia/tilebuilder:v1.2.0` と `:latest` タグが自動的に push されます。
