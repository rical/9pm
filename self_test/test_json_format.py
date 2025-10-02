#!/usr/bin/env python3
"""Verify test_spec and test_spec_sha keys in JSON output"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from run import Test9pm

if __name__ == "__main__":
    tester = Test9pm()
    try:
        tester.test_spec_json_format()
        sys.exit(0)
    except AssertionError as e:
        print(f"\n✗ Test failed: {e}")
        sys.exit(1)
    finally:
        tester.cleanup()
