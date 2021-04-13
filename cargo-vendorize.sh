#!/bin/bash
# Use this script to create a tar.gz with rav1e vendored crates
set -eo pipefail

if [ -z "$IS_DOCKER" ]; then
    PARTS=(`echo $1 | perl -ne 'print "$1 $2 $3\n" if /^(.*?)\-((?:[\d\.\w](?!\.t))*?.)\.(t.*?)$/'`)
    NAME="${PARTS[0]}"
    VER="${PARTS[1]}"
    EXT="${PARTS[2]}"
    DEPENDS_DIR=$(cd $(dirname $0) && pwd -P)

    if [ ! -e "$DEPENDS_DIR/$NAME-$VER.$EXT" ]; then
        >&2 echo "Usage: cargo-vendorize.sh PKG-VERSION.tar.gz"
        >&2 echo ""
        >&2 echo "Creates a tar.gz file with a vendor directory containing "
        >&2 echo "NAME's crate dependencies."
        exit 1
    fi

    docker run --rm \
        -v "$DEPENDS_DIR:/io" \
        -e "NAME=$NAME" \
        -e "VER=$VER" \
        -e "EXT=$EXT" \
        -e IS_DOCKER=1 \
        rustlang/rust:nightly-slim \
        /io/cargo-vendorize.sh
else
    cd /tmp
    tar -zxvf /io/$NAME-$VER.$EXT
    cd $NAME-$VER
    cargo vendor --versioned-dirs
    tar -a -cf /io/$NAME-vendor-$VER.tar.gz vendor
fi
