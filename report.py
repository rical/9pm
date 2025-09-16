#!/usr/bin/env python3

import json
import argparse
import sys
import os
import subprocess
from datetime import datetime
from abc import ABC, abstractmethod


class BaseReporter(ABC):
    """Base class for all report generators."""

    def __init__(self, json_data):
        """Initialize with parsed JSON data."""
        self.data = json_data
        self.metadata = json_data.get('metadata', {})
        self.summary = json_data.get('summary', {})
        self.suite = json_data.get('suite', {})

    @abstractmethod
    def generate(self) -> str:
        """Generate the report content."""
        pass

    @abstractmethod
    def get_filename(self):
        """Get the output filename for this report type."""
        pass

    def _get_output_filename(self, json_file_path, output_filename):
        """Get the final output filename."""
        if output_filename:
            return output_filename
        json_dir = os.path.dirname(os.path.abspath(json_file_path))
        return os.path.join(json_dir, self.get_filename())

    def write(self, json_file_path, output_filename=None):
        """Generate content and write to file."""
        content = self.generate()
        filename = self._get_output_filename(json_file_path, output_filename)

        try:
            with open(filename, 'w') as f:
                f.write(content)
            print(f"Generated {filename}")
            return filename
        except IOError as e:
            print(f"Error writing {filename}: {e}", file=sys.stderr)
            sys.exit(1)

    def get_result_counts(self):
        """Get summary statistics for results."""
        return {
            'pass': self.summary.get('pass', 0),
            'fail': self.summary.get('fail', 0),
            'skip': self.summary.get('skip', 0),
            'masked_fail': self.summary.get('masked_fail', 0),
            'masked_skip': self.summary.get('masked_skip', 0),
            'total': self.summary.get('total', 0)
        }


class AsciiDocReporter(BaseReporter):
    """Generates AsciiDoc format reports."""

    def get_filename(self):
        """Get the output filename for this report type."""
        return 'report.adoc'

    def generate(self) -> str:
        """Generate AsciiDoc report."""
        content = []

        # Header and metadata
        current_date = self.metadata.get('date', datetime.now().strftime("%Y-%m-%d"))
        project = self.metadata.get('project', {})
        name = project.get('name', '9pm')
        version = project.get('version', '')
        topdoc = project.get('topdoc', '') + "/" if project.get('topdoc') else ""

        # AsciiDoc header
        content.extend([
            ":title-page:",
            f":topdoc: {topdoc}",
            "ifdef::logo[]",
            ":title-logo-image: {logo}",
            "endif::[]",
            ":toc:",
            ":toclevels: 2",
            ":sectnums:",
            ":sectnumlevels: 2",
            ":pdfmark:",
            ":pdf-page-size: A4",
            ":pdf-page-layout: portrait",
            ":pdf-page-margin: [1in, 0.5in]",
            f":keywords: regression, test, testing, 9pm, {name}",
            ":subject: Regression testing",
            ":autofit-option:",
            "",
            f"= Test Report",
            f"{name} {version}",
            f"{current_date}",
            "",
            "<<<",
            "",
            "== Test Summary",
            ""
        ])

        # Project info
        if project.get('name') and project.get('root'):
            content.extend([
                f"=== {name} Info",
                "",
                '[cols="1h,2", width=30%]',
                "|===",
                f"| Version | {version}",
                f"| SHA     | {project.get('sha', '')[:12]}",
                "|===",
                ""
            ])

        # Test overview
        counts = self.get_result_counts()
        content.extend([
            "=== Test Overview",
            "",
            '[cols="1h,2", width=30%]',
            "|===",
            f"| {self._resultfmt('pass')} | {counts['pass']}",
            f"| {self._resultfmt('fail')} | {counts['fail']}",
            f"| {self._resultfmt('skip')} | {counts['skip']}",
            f"| {self._resultfmt('masked-fail')} | {counts['masked_fail']}",
            f"| {self._resultfmt('masked-skip')} | {counts['masked_skip']}",
            f"| *TOTAL* | *{counts['total']}*",
            "|===",
            ""
        ])

        # Result tree
        content.extend(self._write_result_tree(self.suite, 0))

        # Test results with output
        content.extend([
            "",
            "<<<",
            "",
            "== Test Result",
            ""
        ])

        content.extend(self._write_output_sections(self.suite, 0))

        return "\n".join(content)

    def _resultfmt(self, result):
        """Format result for AsciiDoc."""
        if result == 'masked-fail':
            return "[.fail line-through]#FAIL#"
        elif result == 'masked-skip':
            return "[.skip line-through]#SKIP#"
        else:
            return f"[.{result}]#{result.upper()}#"

    def _write_result_tree(self, data, depth):
        """Write the result tree structure."""
        content = []
        if not data.get('suite'):
            return content

        for test in data['suite']:
            indent = '  ' * depth
            stars = '*' + '*' * depth

            line = f"{indent}{stars} {self._resultfmt(test.get('result', 'unknown'))}"
            if 'outfile' in test:
                line += f" <<output-{test.get('unix_name')},{test.get('uniq_id')} {test.get('name')}>>"
            else:
                line += f" {test.get('uniq_id')} {test.get('name')}"

            content.append(line)

            if 'suite' in test:
                content.extend(self._write_result_tree(test, depth + 1))

        return content

    def _write_output_sections(self, data, depth, is_first=True):
        """Write detailed output sections for each test."""
        content = []
        if not data.get('suite'):
            return content

        for test in data['suite']:
            if 'outfile' in test and 'logs' in test:
                # Page break before each test except first
                if not is_first:
                    content.append("\n<<<")
                is_first = False

                # Test heading
                content.extend([
                    f"\n[[output-{test.get('unix_name')}]]",
                    f"\n=== {self._resultfmt(test.get('result', 'unknown'))} {test.get('name')}"
                ])

                # Test spec inclusion
                if test.get('test_spec'):
                    content.append(f"include::{test['test_spec']}[lines=2..-1]")

                # Test information table
                content.extend([
                    "\n==== Test Information",
                    '[cols="1h,3"]',
                    "|===",
                    f"| ID   | `{test.get('uniq_id')}`",
                    f"| Name | `{test.get('name')}`"
                ])

                if test.get('case'):
                    # Calculate relative path from project root
                    project_root = self.metadata.get('project', {}).get('root', '')
                    if project_root and test['case'].startswith('/'):
                        rel_path = os.path.relpath(test['case'], project_root)
                    else:
                        rel_path = test['case']
                    content.append(f"| File | `{rel_path}`")

                if test.get('options'):
                    args_str = ', '.join(test['options'])
                    content.append(f"| Arguments | `{args_str}`")
                else:
                    content.append("| Arguments | `None`")

                content.extend([
                    "|===",
                    "\n==== Output",
                    "----",
                    test.get('logs', ''),
                    "----"
                ])

            if 'suite' in test:
                content.extend(self._write_output_sections(test, depth + 1, is_first))

        return content


class GitHubMarkdownReporter(BaseReporter):
    """Generates GitHub-flavored Markdown with emoji icons."""

    def get_filename(self):
        """Get the output filename for this report type."""
        return 'result-gh.md'

    def generate(self) -> str:
        """Generate GitHub Markdown report."""
        content = ["# Test Result", ""]
        content.extend(self._write_tree(self.suite, 0))
        return "\n".join(content)

    def _write_tree(self, data, depth):
        """Write result tree with GitHub emoji icons."""
        content = []
        if not data.get('suite'):
            return content

        icon_map = {
            "pass": ":white_check_mark:",
            "fail": ":red_circle:",
            "skip": ":large_orange_diamond:",
            "masked-fail": ":o:",
            "masked-skip": ":small_orange_diamond:",
        }

        for test in data['suite']:
            mark = icon_map.get(test.get('result', ''), "")
            line = f"{'  ' * depth}- {mark} : {test.get('uniq_id')} {test.get('name')}"
            content.append(line)

            if 'suite' in test:
                content.extend(self._write_tree(test, depth + 1))

        return content


class PlainMarkdownReporter(BaseReporter):
    """Generates plain Markdown format."""

    def get_filename(self):
        """Get the output filename for this report type."""
        return 'result.md'

    def generate(self) -> str:
        """Generate plain Markdown report."""
        content = ["# Test Result", ""]
        content.extend(self._write_tree(self.suite, 0))
        return "\n".join(content)

    def _write_tree(self, data, depth):
        """Write result tree in plain format."""
        content = []
        if not data.get('suite'):
            return content

        for test in data['suite']:
            result = test.get('result', 'UNKNOWN').upper()
            line = f"{'  ' * depth}- {result} : {test.get('uniq_id')} {test.get('name')}"
            content.append(line)

            if 'suite' in test:
                content.extend(self._write_tree(test, depth + 1))

        return content


class PDFReporter(BaseReporter):
    """Generates PDF reports via AsciiDoc conversion."""

    def get_filename(self):
        """Get the output filename for this report type."""
        return 'report.pdf'

    def generate(self) -> str:
        """Generate AsciiDoc content (same as AsciiDocReporter)."""
        return AsciiDocReporter(self.data).generate()

    def write(self, json_file_path, output_filename=None):
        """Generate AsciiDoc content and convert to PDF using temp file."""
        import tempfile

        content = self.generate()
        pdf_filename = self._get_output_filename(json_file_path, output_filename)

        with tempfile.NamedTemporaryFile(mode='w', suffix='.adoc', delete=False) as temp_adoc:
            temp_adoc.write(content)
            temp_adoc_path = temp_adoc.name

        try:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            cmd = ['asciidoctor-pdf',
                   '--theme', os.path.join(script_dir, 'report', 'theme.yml'),
                   '-a', f'pdf-fontsdir={os.path.join(script_dir, "report", "fonts")}',
                   '-a', f'logo=image:{os.path.join(script_dir, "logo.png")}[top=40%, align=right, pdfwidth=8cm]',
                   '-o', pdf_filename, temp_adoc_path]

            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                print(f"Generated {pdf_filename}")
                return pdf_filename
            else:
                print(f"Error generating PDF: {result.stderr}", file=sys.stderr)
                sys.exit(1)

        except FileNotFoundError:
            print("Error: asciidoctor-pdf not found. Install with: gem install asciidoctor-pdf", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Error running asciidoctor-pdf: {e}", file=sys.stderr)
            sys.exit(1)
        finally:
            os.unlink(temp_adoc_path)


def load_json_data(json_file):
    """Load and parse the JSON result file."""
    try:
        with open(json_file, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: JSON file '{json_file}' not found", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in '{json_file}': {e}", file=sys.stderr)
        sys.exit(1)


def main():
    """Main CLI interface."""
    parser = argparse.ArgumentParser(description='Generate test reports from JSON data')
    parser.add_argument('format', choices=['github', 'markdown', 'asciidoc', 'pdf'],
                        help='Report format to generate')
    parser.add_argument('json_file', nargs='?', help='Path to the JSON result file (auto-find if omitted)')
    parser.add_argument('-o', '--output', help='Output filename (auto-generate if omitted)')

    args = parser.parse_args()

    # Auto-find JSON file if not provided
    if args.json_file is None:
        args.json_file = os.path.expanduser('~/.local/share/9pm/logs/last/result.json')

    # Load JSON data
    json_data = load_json_data(args.json_file)

    # Generate report based on format
    try:
        if args.format == 'github':
            GitHubMarkdownReporter(json_data).write(args.json_file, args.output)
        elif args.format == 'markdown':
            PlainMarkdownReporter(json_data).write(args.json_file, args.output)
        elif args.format == 'asciidoc':
            AsciiDocReporter(json_data).write(args.json_file, args.output)
        elif args.format == 'pdf':
            PDFReporter(json_data).write(args.json_file, args.output)
    except Exception as e:
        print(f"Error generating report: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()