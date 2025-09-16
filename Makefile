# We assume the user running this have 9pm set up with its defaults
# so that logs are generated to ~/.local/share/9pm/logs/
9PMPATH := $(shell pwd)
9PMPROJ := $(9PMPATH)/etc/9pm-proj.yaml
THEME   ?= $(9PMPATH)/report/theme.yml
LOGO    ?= $(9PMPATH)/logo.png[top=40%, align=right, pdfwidth=8cm]
LOGPATH := ~/.local/share/9pm/logs/
TEST    ?= last
TESTPATH:= $(LOGPATH)/$(TEST)

all: help

help:
	@echo "9pm Makefile - For developers of 9pm itself"
	@echo
	@echo "Available targets:"
	@echo "  check           - Run self-tests to verify 9pm functionality"
	@echo "  test            - Run unit tests with cmdl-supplied option"
	@echo "  report-github   - Generate GitHub markdown report from last test results"
	@echo "  report-markdown - Generate plain markdown report from last test results"
	@echo "  report-asciidoc - Generate AsciiDoc report from last test results"
	@echo "  report-pdf      - Generate PDF report from last test results"
	@echo "  report          - Alias for report-pdf (legacy)"
	@echo "  help            - Show this help message"
	@echo
	@echo "Variables:"
	@echo "  TEST=$(TEST)    - Specify test results to use for report (default: last)"
	@echo "  THEME=$(THEME) - PDF theme file"
	@echo
	@echo "9pm is intended to be used as a submodule in your project."
	@echo "For more information: https://github.com/rical/9pm"

# Self check
check:
	NINEPM_PROJ_CONFIG=$(9PMPROJ) python3 self_test/run.py

# Unit tests
test:
	python3 9pm.py --proj $(9PMPROJ)	\
	  --option cmdl-supplied 		\
	  unit_tests/all.yaml

report-github:
	./report.py github

report-markdown:
	./report.py markdown

report-asciidoc:
	./report.py asciidoc

report-pdf:
	./report.py pdf

report: report-pdf

.PHONY: all check test report report-github report-markdown report-asciidoc report-pdf help
