#!/usr/bin/env bash

set -e

PACKAGE_NAME="bsc-full-node"
PACKAGE_VERSION="0.2.0"
BUILD_VERSION="0"
TARGET_DIR="target"
DEBIAN_DIR="$TARGET_DIR/debian"
DIST_DIR="$TARGET_DIR/dist"

prepare_file_structure() {
    rm -rf "$DEBIAN_DIR"
    mkdir -vp "$DIST_DIR" \
        "$DEBIAN_DIR/usr/bin" \
        "$DEBIAN_DIR/etc/systemd/system" \
        "$DEBIAN_DIR/usr/share/bsc_full_node"
    chmod -R 0755 "$TARGET_DIR"
}

copy_distribution_file() {
    cp -r bin/* "$DEBIAN_DIR/usr/bin/"
    cp data/* "$DEBIAN_DIR/usr/share/bsc_full_node"
    cp systemd/bsc_full_node.service \
        "$DEBIAN_DIR/etc/systemd/system/$PACKAGE_NAME.service"
}

copy_package_specification() {
    cp -r debian "$DEBIAN_DIR/DEBIAN"
}

make_package() {
    local file_name="${PACKAGE_NAME}_${PACKAGE_VERSION}-${BUILD_VERSION}"

    dpkg-deb --build \
        -D "$DEBIAN_DIR" \
        "$DIST_DIR/${file_name}_amd64.deb"
}

main() {
    prepare_file_structure
    copy_distribution_file
    copy_package_specification
    make_package
}

main
