FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TIPPECANOE_VERSION=2.66.0

# 必要パッケージのインストール
RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    g++ \
    make \
    libsqlite3-dev \
    zlib1g-dev \
    gdal-bin \
    nodejs \
    npm \
    nkf \
    jq \
  && rm -rf /var/lib/apt/lists/*

# Tippecanoe のインストール
RUN curl -L https://github.com/felt/tippecanoe/archive/refs/tags/${TIPPECANOE_VERSION}.tar.gz -o tippecanoe.tar.gz && \
    tar -xzf tippecanoe.tar.gz && \
    cd tippecanoe-${TIPPECANOE_VERSION} && \
    make -j && \
    make install && \
    cd .. && rm -rf tippecanoe*

# 実行スクリプトをコピー
WORKDIR /data

# scripts ディレクトリごとコピー
COPY scripts /usr/local/bin/
RUN chmod +x /usr/local/bin/build_tile.sh

CMD ["build_tile.sh", "/data"]
