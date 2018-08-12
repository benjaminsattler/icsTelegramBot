#!/bin/bash

echo "This script installs git hooks into your cloned git repository."

pushd . > /dev/null
SCRIPT_DIR=$(dirname $BASH_SOURCE)

GITHOOKS_TRGTDIR=$SCRIPT_DIR/../.git/hooks/
# this path needs to be relative to GITHOOKS_TRGTDIR
# because git is going to resolve relative filenames
# while it is cd'ed in the .git/hooks dir!
GITHOOKS_SRCDIR=../../scripts/githooks/

function getAnswer {
	while true; do
		echo "$1 (y/n)"
		answer=0
		read -r line
		case "$line" in
			y)
				answer=1
				break
				;;
			n)
				break 
				;;
			*)
				echo "I did not understand your input... Try again"
				;;
		esac
	done
}

pushd . > /dev/null
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

popd

echo "Now that the git hools are installed you need to execute the script 'scripts/compile-docker.sh' to build the required docker images for the hooks."
echo
getAnswer "Do you want to do that now?"
if [ "$answer" -eq "1" ]; then
    echo "Executing 'scripts/compile-docker.sh'..."
    cd $BASH_SOURCE
    $SCRIPT_DIR/compile-docker.sh
else
    echo "Okay. Not executing script."
fi
popd > /dev/null
