#!/bin/sh

SLEEP=2

echo "1..2"
echo "ok 1 - about to sleep ${SLEEP}s"
sleep "$SLEEP"
echo "ok 2 - slept ${SLEEP}s"
