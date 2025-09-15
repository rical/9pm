#!/bin/bash

while getopts "r:" opt; do
    case $opt in
        r)
            result="$OPTARG"
            ;;
        *)
            exit 1
            ;;
    esac
done

echo "1..1"

echo "# Lorem ipsum dolor sit amet, consectetur adipiscing elit."
echo "Integer felis purus, tincidunt a metus sed, dapibus sodales felis."

case "$result" in
    pass)
        echo "ok 1 - I can pass"
        ;;
    skip)
        echo "ok 1 # skip I can skip"
        ;;
    fail)
        echo "not ok 1 - I can fail"
        ;;
    *)
        exit 1
        ;;
esac

echo "# Phasellus finibus vehicula eros condimentum mattis."
echo "# Donec quis interdum ligula. Integer leo elit, placerat lobortis fermentum nec"
echo "Ultricies sit amet ligula. Pellentesque iaculis tincidunt ligula"
