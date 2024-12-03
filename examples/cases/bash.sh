#!/bin/bash

# Output TAP (Test Anything Protocol) Plan
echo "1..2"

# Handle any passed options
if [ $# -ne 0 ]; then
    echo "Got options: $*"
fi

# Run something
if true; then
    # Print a TAP OK message
    echo "ok 1 - True is indeed true"
fi

# Note: If we would die here, 9pm would flag the test as fail as it will not
# have completed the test plan.
#exit

# Run something
if [ 1 ]; then
    # Print a TAP OK message
    echo "ok 2 - One is also true"
fi
