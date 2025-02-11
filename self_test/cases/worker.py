#!/usr/bin/env python3

import sys
import os
import json

test_dir = os.environ.get("NINEPM_TEST_DIR") or sys.exit(
    "Fatal: NINEPM_TEST_DIR is not set."
)
test_name = os.environ.get("NINEPM_TEST_NAME") or sys.exit(
    "Fatal: NINEPM_TEST_NAME is not set."
)


test_name = test_name.rsplit(".", 1)[0]

log_path = os.path.join(test_dir, f"{test_name}.log")
print(f'Hello from "{test_name}"')
print(f'Log to: "{log_path}"')

data = {
    "name": test_name,
    "args": sys.argv[1:],
}
if "NINEPM_DEBUG" in os.environ:
    data["debug"] = os.environ["NINEPM_DEBUG"]
if "NINEPM_CONFIG" in os.environ:
    data["config"] = os.environ["NINEPM_CONFIG"]

with open(log_path, "w") as f:
    json.dump(data, f)

print(f"Wrote data to log path")
print("1..1")
print(f"ok 1 - All done ({test_name})")
