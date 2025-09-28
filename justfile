export BINARY_NAME := "passz"
export VERSION := `git describe --tags --always`
export COMMIT := `git rev-parse HEAD`
export BUILD_DATE := datetime("%Y-%m-%d")
export OUTPUT_PATH := "dist"
export DESCRIPTION := "Simple CLI tool for generate random and secure passwords."
export MAINTAINER := "Amirhossein Fazli <amirhossein95b@gmail.com>"
export HOMEPAGE_URL := "https://github.com/amirhossein-fzl/passz"
export LICENSE := "GPL"

default:
    @just --list

prepare:
    go mod tidy
    mkdir -p $OUTPUT_PATH

build: prepare clean
    ./build/build.sh

compress: build
    ./build/compress.sh

calculate_hash: compress
    sha256sum $OUTPUT_PATH/compressed/*.tar.gz $OUTPUT_PATH/compressed/*.zip > $OUTPUT_PATH/compressed/checksums.txt
    sed -i $OUTPUT_PATH/compressed/checksums.txt -e 's/dist\/compressed\///g'

linux-release: build
    ./build/linux-package.sh

release: build compress calculate_hash

clean:
    rm -rf $OUTPUT_PATH
