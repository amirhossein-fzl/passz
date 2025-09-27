#!/usr/bin/env sh
set -euxo pipefail

mkdir -p $OUTPUT_PATH
manifest_file=$OUTPUT_PATH/manifest.json

cat > "$manifest_file" << EOF
{
  "version": "$VERSION",
  "commit": "$COMMIT",
  "build_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "go_version": "$(go version | awk 'sub(/go/, "", $3) {print $3}')",
  "artifacts": []
}
EOF

platforms=(
    "linux/amd64"
    "linux/arm64"
    "windows/amd64"
    "windows/arm64"
    "darwin/amd64"
    "darwin/arm64"
)

for platform in "${platforms[@]}"; do
    GOOS=$(echo $platform | cut -d/ -f1)
    GOARCH=$(echo $platform | cut -d/ -f2)
    output_folder=$OUTPUT_PATH/$GOOS
    binary_path=$output_folder/$BINARY_NAME-$GOARCH

    mkdir -p $output_folder

    CGO_ENABLED=0 GOOS=$GOOS GOARCH=$GOARCH go build -trimpath \
        -ldflags="-s -w -X main.version=$VERSION -X main.commit=$COMMIT -X main.date=$BUILD_DATE" \
        -gcflags="all=-l -B -wb=false" \
        -o $output_folder/$BINARY_NAME-$GOARCH ./cmd/main.go

    checksum=$(sha256sum "$binary_path" | awk '{print $1}')
    
    jq --arg os "$GOOS" \
        --arg arch "$GOARCH" \
        --arg binary_path "$binary_path" \
        --arg checksum "sha256:$checksum" \
        --arg size "$(stat -f%z "$binary_path" 2>/dev/null || stat -c%s "$binary_path")" \
        '.artifacts += [{
            "os": $os,
            "arch": $arch,
            "binary_path": $binary_path,
            "checksum": $checksum,
            "size": ($size | tonumber)
        }]' "$manifest_file" > "${manifest_file}.tmp" && mv "${manifest_file}.tmp" "$manifest_file"
done
