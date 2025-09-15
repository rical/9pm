
<img align="left" src="logo.png" alt="9pm Logo" width=400>

9pm is a flexible and efficient framework for running test cases or suites defined in YAML files or specified via command-line arguments. It supports nested suites, detailed logging, and robust error handling, making it ideal for simply managing complex test setups.

---

## Features

- **Arbitrary Test Execution**: Run individual tests or entire suites from the command line.
- **YAML-Defined Suites**: Organize tests in structured, nested YAML files for reusability.
- **Color-Coded Terminal Output**: Easily identify test statuses with intuitive colors.
- **"On-Fail" Logic**: Define custom actions for failed tests to improve debugging.
- **Masked Failures**: Optionally ignore specific test failures or skips without halting the suite.
- **Rich Reporting**: Generate markdown summaries for easy sharing and tracking.
- **Isolated Environment**: Use temporary directories and files for scratch area. Ensuring nothing is left after test execution, even if the test itself crashes.

---

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd 9pm
   ```
2. Install dependencies:
   ```bash
   pip install pyyaml
   gem install --user-install asciidoctor-pdf rouge
   ```

> [!NOTE]
> On Debian/Ubuntu systems you can use standard packages for the requirements:
> `sudo apt install python3-yaml ruby-asciidoctor-pdf ruby-rouge`

---

## Usage

Run the framework with:
```bash
./9pm.py [OPTIONS] SUITE | TEST ...
```

### Harness Command-Line Options

| Option           | Description                                          |
|------------------|------------------------------------------------------|
| `-a, --abort`    | Stop execution after the first failure.              |
| `-v, --verbose`  | Enable verbose output.                               |
| `-p, --proj`     | Specify an explicit project configuration.           |

### Test Case Command-Line Options (Passed to Test Cases)

| Option           | Description                                          |
|------------------|------------------------------------------------------|
| `-c, --config`   | Test Case config.                                    |
| `-d, --debug`    | Enable test case debug.                              |
| `-o, --option`   | Test case options (repeatable).                      |

Example:
```bash
./9pm.py -o "ssh" suites/main.yaml cases/cleanup.sh
```

---

## Writing Test Suites

Test suites are YAML files that organize individual test cases or reference nested suites. Test cases must be executable files.

### Simple Test Suite Example
```yaml
- case: "tests/smoke.sh"
- case: "tests/hammer.pl"
- case: "tests/cleanup.py"
```

### Nested Test Suite Example

```yaml
- case: "tests/smoke.sh"
- case: "tests/unit_test.tcl"
- suite: "suites/integration.yaml"
  name: "Integration-Tests"
- suite: "suites/regression.yaml"
  name: "Regression-Tests"
```

### Option Naming
Name can be used effectivly when passing different options to the same test case.


```yaml
- case: "tests/scp.sh"
  opts:
    - "192.168.1.1"
    - "bootloader.bin"
  name: "upload-bootloader"
- case: "tests/scp.sh"
  opts:
    - "192.168.1.1"
    - "linux.sqfs"
  name: "upload-os"
```
Resulting in the following:
```
o Execution
|-- o 0001-upload-bootloader
`-- o 0002-upload-os.sh
```

## Test Results

9pm generates detailed reports:

1. **Human-Readable Markdown**: `result.md`
2. **GitHub-Compatible Markdown**: `result-gh.md`

### GitHub Emoji Legend

| Status          | Emoji                  |
|------------------|------------------------|
| Passed           | `:white_check_mark:`  |
| Failed           | `:red_circle:`        |
| Skipped          | `:large_orange_diamond:` |
| Masked Failure   | `:o:`                 |
| Masked Skip      | `:small_orange_diamond:` |

---

## Logging and Environment

- **Logs**: Stored in timestamped directories under the configured `LOG_PATH`. A symlink `last` points to the latest log directory.
- **Scratch Directory**: Temporary directories are created for each test run and cleaned up automatically.
- **Temporary Database File**: A temporary database file is used during the test lifecycle.

---

## Writing Test Cases

Tests must output results in [TAP (Test Anything Protocol)](https://testanything.org/) format.

### Example Test Case

```bash
#!/bin/bash
echo "1..1"
echo "ok 1 - Sample test case"
```

---

## License

This project is licensed under GPL-2.0 license. For contributions or issues, open a pull request or issue on GitHub.
