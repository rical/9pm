# About
This directory contains some test suites and test cases written in different
script languages. The idea is to illustrate one of 9pm's predominant features,
namely the ability to run arbitrary tests and harness there result and output.

All the code in this example directory is pseudo code intended to be ease to
understand in the context of 9pm.

# Execution
Start the all.yaml test suite with

`./9pm.py examples/all.yaml examples/bash.sh`

The end result tree should look something like:

```
s Execution
|-- s 0001-all.yaml
|   |-- o 0002-bash.sh
|   |-- o 0003-python.py
|   |-- o 0004-bash-with-no-options
|   |-- o 0005-bash-with-options
|   `-- s 0006-nested-suite
|       |-- o 0007-bash-in-nested
|       `-- s 0008-python-in-nested
`-- o 0009-bash.sh
```

This code illustrates the following abilities:

* Pass test and suite as argument to 9pm (arbitrary)
* Tests in suite
* Nested suite in suite
* Named test in suite (extremely useful together with options)
* Options to test in suite
* Options to all tests in a nested suite
