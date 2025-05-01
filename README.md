# tilebuilder-docker

- Shapeファイル を Tippecanoe を使って MBTiles（Mapbox Vector Tile形式） に変換する Docker 環境です。  

### 使い方

下記のテンプレートを使用して下さい。
- https://github.com/geolonia/tilebuilder/

### 開発者向け

#### 環境構築
- Docker Desktop をインストールしておいてください。

```bash
$ git clone git@github.com:geolonia/tilebuilder-docker.git
$ cd tilebuilder-docker
$ npm install
```

#### ビルド

- Dockerfile をビルドします。

```bash
$ npm run build
```

#### 実行

- `./data` 以下にある Shapeファイルを MBTiles に変換します。

```bash
$ npm run create:mbtiles
```

## バージョン管理とデプロイ

新しいバージョンをリリースするには：

```bash
git tag v1.2.0
git push origin v1.2.0
```

GitHub Actions により、`ghcr.io/geolonia/tilebuilder:1.2.0` と `:latest` タグが自動的に push されます。
