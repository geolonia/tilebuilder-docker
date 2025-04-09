#!/usr/bin/env bash
set -ex

# 再帰的にzipを解凍する関数
unzip_recursively() {
    local target_dir=$1

    # 現在のディレクトリ内のすべてのzipファイルを探して解凍
    find "$target_dir" -name '*.zip' | while read zip_file; do
        # 解凍する
        unzip -u -O sjis "$zip_file" -d "${zip_file%.*}"

        # 解凍後にzipファイルを削除
        rm "$zip_file"

        # 解凍したディレクトリにさらにzipがあれば再帰的に解凍
        unzip_recursively "${zip_file%.*}"
    done
}

# 引数が指定されていない場合はエラーを表示して終了
if [ $# -eq 0 ]; then
    echo "Usage: $0 <target_dir>"
    exit 1
fi

# 引数で渡されたディレクトリを使用
target_dir=$1
unzip_recursively "$target_dir"