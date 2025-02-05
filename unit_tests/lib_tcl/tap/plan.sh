#!/bin/sh

echo "$@"

case $1 in
    first)
	echo "0..1"
	echo "ok 1 - Supplying plan before test"
	;;
    last)
	echo "ok 1 - Supplying test before plan"
	echo "0..1"
	;;
    omit)
	echo "ok 1 - Omitting plan"
	;;
    *)
	exit 1
	;;
esac
