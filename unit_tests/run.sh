#!/bin/bash

#TODO: Handle arguments (like debug and log)

base=$(dirname $(readlink -f $0))
tool=$base/../9pm.py

echo "* Running all automated test, all should be OK!"
$tool -v --option cmdl-supplied $base/auto.yaml
