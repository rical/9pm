#!/usr/bin/env python3

import subprocess
import os
import json
import sys
import tempfile
import argparse
import uuid


VERBOSE = False


# ANSI color codes
def print_green(msg):
    """Prints a message in green (pass)."""
    print(f"\033[92m{msg}\033[0m")


def print_red(msg):
    """Prints a message in red (fail)."""
    print(f"\033[91m{msg}\033[0m")


def print_cyan(msg):
    """Prints a message in yellow (info/warning)."""
    print(f"\033[96m{msg}\033[0m")


class Test9pm:
    def __init__(self, ninepm="../9pm.py"):
        self.ninepm = ninepm
        self.script_dir = os.path.dirname(os.path.abspath(__file__))
        self.temp_dir_base = (
            tempfile.TemporaryDirectory()
        )  # Creates a temporary directory
        self.env = os.environ.copy()
        self.env["NINEPM_TEST_DIR"] = self.temp_dir_base.name

    def create_unique_subdir(self):
        subdir = os.path.join(self.temp_dir_base.name, str(uuid.uuid4()))
        os.makedirs(subdir)
        return subdir

    def run(self, workers, args=None, expected_return=0, grep=None):
        """Run 9pm.py with a worker script and arguments, ensuring correct order.
        If 'grep' is provided, it ensures that the specified text appears in the output.
        """
        args = args or []  # Default to empty list if no args are provided
        command = ["python3", self.ninepm, "-v"] + workers + args

        if VERBOSE:
            print_cyan(f"Executing {command}")

        result = subprocess.run(
            command,
            cwd=self.script_dir,
            text=True,
            env=self.env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        if VERBOSE:
            print(result.stdout)
            print(result.stderr, file=sys.stderr)

        # Ensure the return code is as expected
        assert result.returncode == expected_return, f"Failed: Got unexpected return code {result.returncode}. stderr: {result.stderr}"

        # If grep is provided, ensure the output contains the specified text
        if grep:
            output = result.stdout + result.stderr  # Combine both streams for searching
            assert grep in output, f"Expected text '{grep}' not found in output!"

    def check(self, expected, descr):
        """Check if the worker script wrote the expected JSON result and print colored results."""
        file_name = f"{expected['name']}.log"
        file_path = os.path.join(self.env["NINEPM_TEST_DIR"], file_name)

        if not os.path.exists(file_path):
            print_red(
                f"[FAIL] {descr} - Missing output file: {file_name} {file_path} (name error?)"
            )
            assert False, f"Missing output file: {file_name}"

        with open(file_path, "r") as f:
            data = json.load(f)

        if data != expected:
            print_red(f"[FAIL] {descr} - Unexpected content in {file_name}")
            print_cyan("Expected:")
            print(json.dumps(expected, indent=4))
            print_cyan("Got:")
            print(json.dumps(data, indent=4))
            assert False, f"Unexpected content in {file_name}"

    def test(self, test):
        self.env = os.environ.copy()
        self.env["NINEPM_TEST_DIR"] = self.create_unique_subdir()
        # print(f"Test will write to {self.env["NINEPM_TEST_DIR"]}")

        self.run(test["tests"], test["args"])

        for expected in test["expected"]:
            self.check(expected, test["desc"])

        print_green(f"[PASS] {test['desc']} ({len(test['expected'])} tests)")

    def test_suites(self):
        """Verify various suite setups"""

        self.test(
            {
                "desc": "Basic suite",
                "args": [],
                "tests": ["suites/suite.yaml"],
                "expected": [
                    {"name": "0002-worker", "args": []},
                    {"name": "0003-worker", "args": []},
                    {"name": "0004-worker1", "args": []},
                ],
            }
        )

        self.test(
            {
                "desc": "Test case naming",
                "args": [],
                "tests": ["suites/names.yaml"],
                "expected": [
                    {"name": "0002-my-worker", "args": []},
                    {"name": "0003-worker", "args": []},
                    {"name": "0004-my-worker1", "args": []},
                ],
            }
        )
        self.test(
            {
                "desc": "Test case options",
                "args": ["-o", "cmdline"],
                "tests": ["suites/options.yaml"],
                "expected": [
                    {"name": "0002-worker", "args": ["cmdline"]},
                    {"name": "0003-worker", "args": ["opt1", "opt2", "cmdline"]},
                    {"name": "0004-worker", "args": [
                        f"{os.path.join(self.script_dir, 'suites/foo')}", "cmdline"]
                    },
                ],
            }
        )

        self.test(
            {
                "desc": "Nested test case options",
                "args": ["-o", "cmdline"],
                "tests": ["suites/top-options.yaml"],
                "expected": [
                    {"name": "0002-worker", "args": ["top1", "cmdline"]},
                    {"name": "0004-worker", "args": ["top2", "cmdline"]},
                    {
                        "name": "0005-worker",
                        "args": ["opt1", "opt2", "top2", "cmdline"],
                    },
                ],
            }
        )

        self.test(
            {
                "desc": "Nested suites",
                "args": [],
                "tests": ["suites/top-suite.yaml"],
                "expected": [
                    {"name": "0002-worker", "args": []},
                    {"name": "0004-worker", "args": []},
                    {"name": "0006-worker", "args": []},
                    {"name": "0007-worker", "args": []},
                    {"name": "0008-worker1", "args": []},
                    {"name": "0009-worker1", "args": []},
                    {"name": "0010-worker1", "args": []},
                ],
            }
        )

    def test_cmdline_options(self):
        """Verify that command line options (-o) are passed to test(s)"""

        self.test(
            {
                "desc": "No argument",
                "args": [],
                "tests": ["cases/worker.py"],
                "expected": [{"name": "0001-worker", "args": []}],
            }
        )

        self.test(
            {
                "desc": "One option (cmdline argument)",
                "args": ["-o", "foobar"],
                "tests": ["cases/worker.py"],
                "expected": [{"name": "0001-worker", "args": ["foobar"]}],
            }
        )

        self.test(
            {
                "desc": "Multiple options (cmdline argument)",
                "args": ["-o", "foo", "-o", "bar", "-o", "baz"],
                "tests": ["cases/worker.py"],
                "expected": [{"name": "0001-worker", "args": ["foo", "bar", "baz"]}],
            }
        )

        self.test(
            {
                "desc": "Two tests, no argument",
                "args": [],
                "tests": ["cases/worker.py", "cases/worker.py"],
                "expected": [
                    {"name": "0001-worker", "args": []},
                    {"name": "0002-worker", "args": []},
                ],
            }
        )

        self.test(
            {
                "desc": "Two tests, multiple arguments",
                "args": ["-o", "foo", "-o", "bar", "-o", "baz"],
                "tests": ["cases/worker.py", "cases/worker.py"],
                "expected": [
                    {"name": "0001-worker", "args": ["foo", "bar", "baz"]},
                    {"name": "0002-worker", "args": ["foo", "bar", "baz"]},
                ],
            }
        )

    def test_debug_flag(self):
        """Verify that the debug flag accessible from tests"""

        self.test(
            {
                "desc": "Pass debug flag to test cases",
                "args": ["-d"],
                "tests": ["cases/worker.py", "cases/worker.py"],
                "expected": [
                    {"name": "0001-worker", "args": [], "debug": "1"},
                    {"name": "0002-worker", "args": [], "debug": "1"},
                ],
            }
        )

    def test_config_file(self):
        """Verify that the config file is passed to all tests"""

        self.test(
            {
                "desc": "Pass config file (-c) to test cases",
                "args": ["-c", "conf.txt"],
                "tests": ["cases/worker.py", "cases/worker.py"],
                "expected": [
                    {"name": "0001-worker", "args": [], "config": "conf.txt"},
                    {"name": "0002-worker", "args": [], "config": "conf.txt"},
                ],
            }
        )

    def test_verbose_flag(self):
        """Verify that that 9pm verbose output works (-v)"""

        self.run(["cases/worker.py", "cases/worker.py"], ["-v"], 0, "Verbose output turned on")
        print_green(f"[PASS] Verbose flag works (-v)")

    def test_abort_flag(self):
        """Verify that that 9pm abort flag works (--abort)"""

        self.run(["cases/fail.sh", "cases/pass.sh"], ["--abort"], 1, "Aborting execution")
        print_green(f"[PASS] Abort flag works (-a --abort)")

    def test_proj_config(self):
        """Verify that that 9pm project config works (--proj)"""

        self.run(["cases/pass.sh"], ["-v"], 0, "Testing 9pm")

        self.run(["cases/pass.sh"], ["-v", "--proj", "configs/proj-test1.yaml"], 0, "Testing Self Test 1")

        self.env["NINEPM_PROJ_CONFIG"] = "configs/proj-test2.yaml"
        self.run(["cases/pass.sh"], ["-v"], 0, "Testing Self Test 2")
        # This shall have precedence over env
        self.run(["cases/pass.sh"], ["-v", "--proj", "configs/proj-test1.yaml"], 0, "Testing Self Test 1")
        del self.env["NINEPM_PROJ_CONFIG"]

        print_green(f"[PASS] Project Config works")

    def test_repeat_flag(self):
        """Verify that -r (--repeat) works"""

        self.test(
            {
                "desc": "Repeate two tests two times",
                "args": ["-r", "2"],
                "tests": ["cases/worker.py", "cases/worker1.py"],
                "expected": [
                    {"name": "0001-worker", "args": []},
                    {"name": "0002-worker1", "args": []},
                    {"name": "0003-worker", "args": []},
                    {"name": "0004-worker1", "args": []}
                ],
            }
        )
        self.test(
            {
                "desc": "Repeate suite and test two times",
                "args": ["-r", "2"],
                "tests": ["suites/suite.yaml", "cases/worker1.py"],
                "expected": [
                    {"name": "0002-worker", "args": []},
                    {"name": "0003-worker", "args": []},
                    {"name": "0004-worker1", "args": []},
                    {"name": "0007-worker", "args": []},
                    {"name": "0008-worker", "args": []},
                    {"name": "0009-worker1", "args": []},
                    {"name": "0010-worker1", "args": []}
                ],
            }
        )

    def cleanup(self):
        """Cleanup temp directory after tests"""
        self.temp_dir_base.cleanup()


# Command-line argument parsing
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run 9pm.py tests.")
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose output (show 9pm.py stdout/stderr).",
    )

    args = parser.parse_args()
    VERBOSE = args.verbose

    tester = Test9pm()

    try:
        tester.test_suites()
        tester.test_cmdline_options()
        tester.test_debug_flag()
        tester.test_config_file()
        tester.test_verbose_flag()
        tester.test_abort_flag()
        tester.test_repeat_flag()
        tester.test_proj_config()
        print_green("All tests passed.")
    finally:
        tester.cleanup()
