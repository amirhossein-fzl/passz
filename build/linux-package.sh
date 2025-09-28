jq -c '.artifacts[] | select(.os == "linux")' dist/manifest.json | while read i; do
    os=$(echo $i | jq -c '.os' | awk 'gsub(/"/, "")')
    arch=$(echo $i | jq -c '.arch' | awk 'gsub(/"/, "")')
    path=$(echo $i | jq -c '.binary_path' | awk 'gsub(/"/, "")')

    STAGING_DIR="$OUTPUT_PATH/staging-$os-$arch"
    rm -rf $STAGING_DIR
    mkdir -p $STAGING_DIR/usr/bin
    mkdir -p $STAGING_DIR/usr/share/doc/$BINARY_NAME

    cp $path $STAGING_DIR/usr/bin/$BINARY_NAME
    cp README.md $STAGING_DIR/usr/share/doc/$BINARY_NAME/

    DEB_ARCH=$arch
    RPM_ARCH=$arch
    [[ $arch == "amd64" ]] && DEB_ARCH="amd64" && RPM_ARCH="x86_64"
    [[ $arch == "arm64" ]] && DEB_ARCH="arm64" && RPM_ARCH="aarch64"

    pkg_version=$(echo $VERSION | awk 'sub(/v/, "")')

    mkdir -p $OUTPUT_PATH/linux-pkgs

    echo "Building .deb package for $os/$arch"
    fpm -s dir -t deb \
        --name "$BINARY_NAME" \
        --version "$pkg_version" \
        --architecture "$DEB_ARCH" \
        --description "$DESCRIPTION" \
        --maintainer "$MAINTAINER" \
        --url "$HOMEPAGE_URL" \
        --license "$LICENSE" \
        --package "$OUTPUT_PATH/linux-pkgs/${BINARY_NAME}_${DEB_ARCH}_${pkg_version}.deb" \
        --chdir $STAGING_DIR \
        .

    echo "Building .rpm package for $os/$arch"
    fpm -s dir -t rpm \
        --name "$BINARY_NAME" \
        --version "$pkg_version" \
        --architecture "$RPM_ARCH" \
        --description "$DESCRIPTION" \
        --maintainer "$MAINTAINER" \
        --url "$HOMEPAGE_URL" \
        --license "$LICENSE" \
        --package "$OUTPUT_PATH/linux-pkgs/${BINARY_NAME}_${DEB_ARCH}_${pkg_version}.rpm" \
        --chdir $STAGING_DIR \
        .

    # Clean up staging directory
    rm -rf $STAGING_DIR
done

