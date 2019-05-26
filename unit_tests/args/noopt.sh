#!/bin/sh

echo "0..1"
if [ $# -eq 0 ]; then
    echo "ok 1 - No options passed by default"
elif [ $1 = "cmdl-supplied" ]; then
    echo "ok 1 - No options passed by default (only cmdl-supplied)"
else
    echo "not ok 1 - Command line polluted: \"$*\""
fi
