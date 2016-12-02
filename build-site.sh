#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

if [[ "$#" -ne 2 ]]; then
    echo "Usage: $0 <git sha or tag of Onyx core> <onyx version>"
    echo "Example: $0 0.8.4 0.8.4"
else

    coderay -h >/dev/null 2>&1 || { echo >&2 "I require coderay but it's not installed. Please insall with 'gem install coderay'. Aborting."; exit 1; }

    # Ensure we're in the project's dir before we start
    cd "$(dirname "$0")"

    # Build user guide
    rm -rf onyx
    git clone https://github.com/onyx-platform/onyx.git
    git -C onyx checkout $1

    mkdir -p docs/user-guide/latest
    mkdir -p docs/user-guide/$2
    rm -rf docs/user-guide/$2/*
    cp -R onyx/doc/user-guide/* docs/user-guide/$2/
    rm -rf docs/user-guide/latest/*
    cp -R onyx/doc/user-guide/* docs/user-guide/latest/

    # Convert ADOC to HTML.
    asciidoctor docs/user-guide/$2/index.adoc
    asciidoctor docs/user-guide/latest/index.adoc

    rm -rf docs/user-guide/$2/*.adoc
    rm -rf docs/user-guide/latest/*.adoc

    # Build API docs
    mkdir -p docs/api/$2/
    rm -rf docs/api/$2/*
    cp -R onyx/doc/api/* docs/api/$2/

    mkdir -p docs/api/latest/
    rm -rf docs/api/latest/*
    cp -R onyx/doc/api/* docs/api/latest/

    rm -rf onyx

    # Build cheat sheet
    rm -rf onyx-cheat-sheet
    git clone https://github.com/onyx-platform/onyx-cheat-sheet.git
    rm onyx-cheat-sheet/resources/public/js/app.js || true
    mkdir -p docs/cheat-sheet/$2
    rm -rf docs/cheat-sheet/$2/*
    cd onyx-cheat-sheet && lein update-dependency org.onyxplatform/onyx $1 && lein with-profile -dev,+uberjar cljsbuild once
    cd ..

    echo "Working dir before copy " $PWD 
    cp onyx-cheat-sheet/resources/public/js/app.js docs/cheat-sheet/$2
    cp onyx-cheat-sheet/resources/public/css/style.css css/cheat-sheet-style.css
    cp onyx-cheat-sheet/resources/index.html docs/cheat-sheet/$2

    mkdir -p docs/user-guide/latest
    rm -rf docs/cheat-sheet/latest/*
    cp onyx-cheat-sheet/resources/public/js/app.js docs/cheat-sheet/latest
    cp onyx-cheat-sheet/resources/index.html docs/cheat-sheet/latest

    rm -rf onyx-cheat-sheet

    git add docs

    # Update Onyx version
    sed -i.bak "s/.*onyx_version.*/onyx_version: $2/g" _config.yml
    git add _config.yml
    rm _config.yml.bak
    git commit -a -m "Stage "$1
    git push
fi
