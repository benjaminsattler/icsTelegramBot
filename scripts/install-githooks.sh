#!/bin/bash

echo "This script installs git hooks into your cloned git repository."

pushd . > /dev/null
SCRIPT_DIR=$(dirname $BASH_SOURCE)

GITHOOKS_TRGTDIR=$SCRIPT_DIR/../.git/hooks/
# this path needs to be relative to GITHOOKS_TRGTDIR
# because git is going to resolve relative filenames
# while it is cd'ed in the .git/hooks dir!
GITHOOKS_SRCDIR=../../scripts/githooks/

cd $GITHOOKS_TRGTDIR
echo "Looking for scripts in $GITHOOKS_SRCDIR and linking them into $GITHOOKS_TRGTDIR"

echo
echo "Scanning for available hooks"
for file in $GITHOOKS_SRCDIR*
do
    if [[ -f $file ]]; then
        echo "Found $file. If it exists already you will be asked to replace it."
        ln -si $file .
        if [ "$?" -eq "0" ]; then
            echo "Linked successfully"
        else
            echo "Failed to create link!"
        fi
    fi
done

popd > /dev/null
