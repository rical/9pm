#!/bin/bash
#TODO: Handle arguments (like debug and log)

cd $(dirname $(readlink -f $0))

find . -mindepth 1 -maxdepth 1 -type d -name "*test" | while read DIR;
do
    echo "### Running tests in $DIR ###"
    cd "$DIR"
    "${DIR}.tcl" -d #TODO: Check return code and act appropriate
    cd ..
    echo ""
done

