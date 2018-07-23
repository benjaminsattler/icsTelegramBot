#!/bin/bash

USAGE=$(cat <<USAGEEND

Missing or invalid parameter.

Usage: $0 major|minor|patch

USAGEEND
)
BASE_DIR=`dirname $BASH_SOURCE`/../

if [ "$#" -ne 1 ]; then
  echo "$USAGE"
  exit
fi

if [ "$1" != "minor" ] && [ "$1" != "major" ] && [ "$1" != "patch" ]; then
  echo "$USAGE"
  exit
fi

pushd $BASE_DIR
git fetch --tags
LATEST_TAG=`git tag -l --sort=v:refname | tail -n 1`
if [ "$1" == "major" ]; then
  NEXT_TAG=`echo $LATEST_TAG | awk 'BEGIN{FS="."}{print ($1+1)"."$2"."$3}'`
fi
if [ "$1" == "minor" ]; then
  NEXT_TAG=`echo $LATEST_TAG | awk 'BEGIN{FS="."}{print $1"."($2+1)"."$3}'`
fi
if [ "$1" == "patch" ]; then
  NEXT_TAG=`echo $LATEST_TAG | awk 'BEGIN{FS="."}{print $1"."$2"."($3+1)}'`
fi
echo Latest tag is $LATEST_TAG
echo Next Version Tag is $NEXT_TAG

ACTIVE_BRANCH=`git status | head -n1 | awk '{print $3}'`
git stash -u --keep-index
git checkout master
git merge -S --no-ff origin/development
git tag -a -s -m "Release Version $NEXT_TAG" $NEXT_TAG
git push --tags origin master
git clean -df
git checkout $ACTIVE_BRANCH
git stash pop -q
popd
