#!/usr/bin/env bash


case "$1" in
zip)
    # https://extensionworkshop.com/documentation/publish/package-your-extension/#package-linux
    # TODO(akavel): use nix for generating the .zip/.xpi package
    zip -r -FS bookwin.zip \
        manifest.json \
        tmm.js \
        $( grep -oE ': ".*\..*"' manifest.json |
            sed -E 's#: "(.*)"#./\1#' |
            awk '0==system("test -e "$0)' )  # finds all files listed in manifest.json...
    ;;
src)
    zip -r -FS bookwin-src.zip \
        manifest.json \
        src/ \
        *.nimble \
        r \
        r.bat \
        README.md \
        $( grep -oE ': ".*\..*"' manifest.json |
            sed -E 's#: "(.*)"#./\1#' |
            awk '0==system("test -e "$0)' )  # finds all files listed in manifest.json...
    ;;
*)
    nimble build && mv tmm tmm.js
    ;;
esac
