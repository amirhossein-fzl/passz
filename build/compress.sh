#!/usr/bin/env sh
set -euxo pipefail

mkdir -p $OUTPUT_PATH/compressed

jq -c '.artifacts[]' dist/manifest.json | while read i; do
    os=$(echo $i | jq -c '.os' | awk 'gsub(/"/, "")')
    arch=$(echo $i | jq -c '.arch' | awk 'gsub(/"/, "")')
    path=$(echo $i | jq -c '.binary_path' | awk 'gsub(/"/, "")')

    if [[ $os == "windows" ]]; then
        cp $path $(dirname $path)/$BINARY_NAME.exe
        zip -j -9 "$OUTPUT_PATH/compressed/$BINARY_NAME-$os-$arch.zip" "$(dirname $path)/$BINARY_NAME.exe" README.md
    else
        GZIP=-9 tar -cvzf "$OUTPUT_PATH/compressed/$BINARY_NAME-$os-$arch.tar.gz" --transform="s|$path|$BINARY_NAME|" "$path" README.md 
    fi
done
