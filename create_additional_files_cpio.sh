#!/bin/bash
FILENAME=$1
DIR=$2
CURDIR=$PWD
TARNAME="fs_overlay.tar"
cd "$DIR" || exit
tar -zcvf "$CURDIR"/"$TARNAME" .
cd "$CURDIR" || exit
echo ./"$TARNAME" | cpio -o -H newc | gzip -4 > "$FILENAME"
rm "$TARNAME"
