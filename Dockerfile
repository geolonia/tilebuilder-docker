FROM ubuntu:22.04

# 必要パッケージのインストール
RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    g++ \
    make \
    libsqlite3-dev \
    zlib1g-dev \
    gdal-bin \
  && rm -rf /var/lib/apt/lists/*

# Tippecanoe のインストール
ENV TIPPECANOE_VERSION=2.66.0

RUN curl -L https://github.com/felt/tippecanoe/archive/refs/tags/${TIPPECANOE_VERSION}.tar.gz -o tippecanoe.tar.gz && \
    tar -xzf tippecanoe.tar.gz && \
    cd tippecanoe-${TIPPECANOE_VERSION} && \
    make -j && \
    make install && \
    cd .. && rm -rf tippecanoe* 

# バージョン確認
RUN tippecanoe --version && ogr2ogr --version
