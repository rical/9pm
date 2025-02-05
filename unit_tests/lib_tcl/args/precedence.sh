#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
TCLLIBPATH="$DIR/../../../"

export TCLLIBPATH=$TCLLIBPATH

export NINEPM_CONFIG="$DIR/env_conf.yaml"

$DIR/env_args.tcl
$DIR/cmdl_args.tcl -c "$DIR/cmdl_conf.yaml"
