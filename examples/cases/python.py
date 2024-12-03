#!/usr/bin/env python3

import sys

# Simple TAP (Test Anything Protocol) Class
class Tap:
    def __init__(self):
        self.step = 0

    def plan(self,cnt):
        print(f"1..{cnt}")

    def ok(self, msg):
        self.step += 1
        print(f"ok {self.step} - {msg}")

    def skip(self, msg):
        self.step += 1
        print(f"ok {self.step} # skip - {msg}")

test = Tap()

# Output a test plan
test.plan(2)

if len(sys.argv) > 1:
    print(f"Got options: {sys.argv}")

if True:
    # Output a test OK message
    test.ok("True is true, makes sense")

# Note: If we would die here, 9pm would flag the test as fail as it will not
# have completed the test plan.
#sys.exit(0)

if len(sys.argv) > 1:
    test.skip("Skipping test with options")
else:
    test.ok("Got no options")

