#!/usr/bin/env python3

import argparse
import os
import yaml
import subprocess
import sys
import time
import tempfile
import shutil
import re
import atexit
import hashlib
from datetime import datetime

TEST_CNT=0
ROOT_PATH = os.path.dirname(os.path.realpath(__file__))
LIB_TCL_PATH = ROOT_PATH + "/lib_tcl/"
# TODO: proper argument strucutre
DATABASE = ""
SCRATCHDIR = ""
LOGDIR = None
VERBOSE = False
NOEXEC = False

if "TCLLIBPATH" in os.environ:
    os.environ["TCLLIBPATH"] = os.environ["TCLLIBPATH"] + " " + LIB_TCL_PATH
else:
    os.environ["TCLLIBPATH"] = LIB_TCL_PATH

class pcolor:
    purple = '\033[95m'
    blue = '\033[94m'
    green = '\033[92m'
    yellow = '\033[93m'
    yellow_u = '\033[4;33m'
    red = '\033[91m'
    red_u ='\033[4;31m'
    cyan = '\033[96m'
    reset = '\033[0m'
    orange = '\033[33m'
    faint = '\033[2m'

def cprint(color, *args, **kwargs):
    sys.stdout.write(color)
    print(*args, **kwargs)
    sys.stdout.write(pcolor.reset)

def vcprint(color, *args, **kwargs):
    global VERBOSE

    if VERBOSE:
        cprint(color, *args, **kwargs)

def rootify_path(path):
    path = os.path.join(ROOT_PATH, path)
    path = os.path.expanduser(path)
    path = os.path.normpath(path)
    return path

def execute(args, test, output_log):
    proc = subprocess.Popen([test['case']] + args, stdout=subprocess.PIPE)
    skip_suite = False
    test_skip = False
    err = False

    if args:
        output_log.write(f"Starting with arguments: {args}\n\n")

    while True:
        line = proc.stdout.readline().decode('utf-8')
        if line == '':
            break

        string = line.rstrip()
        stamp = time.strftime("%Y-%m-%d %H:%M:%S")

        plan = re.search('^(\d+)..(\d+)$', string)
        ok = re.search('^ok (\d+) -', string)
        not_ok = re.search('^not ok (\d+) -', string)
        skip = re.search('^ok (\d+) # skip', string)
        skip_suite = re.search('^ok (\d+) # skip suite', string)
        comment = re.search('^\w*#', string)

        output_log.write(f"{stamp} {string}\n")

        if plan:
            cprint(pcolor.purple, '{} {}'.format(stamp, string))
            test['plan'] = plan.group(2)
        elif skip:
            cprint(pcolor.yellow, '{} {}'.format(stamp, string))
            test['executed'] = skip.group(1)
            test_skip = True
        elif skip_suite:
            cprint(pcolor.yellow, '{} {}'.format(stamp, string))
            test['executed'] = skip.group(1)
            skip_suite = True
            test_skip = True
        elif ok:
            cprint(pcolor.green, '{} {}'.format(stamp, string))
            test['executed'] = ok.group(1)
        elif not_ok:
            cprint(pcolor.red, '{} {}'.format(stamp, string))
            err = True
            test['executed'] = not_ok.group(1)
        elif comment:
            cprint(pcolor.faint, '{} {}'.format(stamp, string))
        else:
            print("{} {}".format(stamp, string))

    out, error = proc.communicate()
    exitcode = proc.returncode

    if exitcode != 0:
        err = True

    return skip_suite, test_skip, err

def calculate_sha1sum(path):
    sha1 = hashlib.sha1()
    with open(path, "rb") as file:
        for chunk in iter(lambda: file.read(4096), b""):
            sha1.update(chunk)
    return sha1.hexdigest()

def run_onfail(args, test):
    opts = []
    if 'options' in test:
        opts.extend(test['options'])

    dirname = os.path.dirname(test['case'])

    onfail = {}
    onfail['case'] = os.path.join(dirname, test['onfail'])
    onfail['name'] = 'onfail'

    print("\n{}Running onfail \"{}\" for test {}{}" . format(pcolor.cyan, test['onfail'],
        test['name'], pcolor.reset))

    vcprint(pcolor.faint, f"Executing onfail {onfail['case']} for test {test['case']}")

    with open(os.path.join(LOGDIR, "on-fail.log"), 'a') as log:
        log.write(f"\n\nON FAIL START")
        if not NOEXEC:
            execute(opts, onfail, log)

def run_test(args, test):
    opts = []
    if 'options' in test:
        opts.extend(test['options'])

    print(pcolor.blue + "\nStarting test", test['name'] + pcolor.reset)

    if test['result'] == "skip":
        print("{}Skip test {} (suite skip){}" . format(pcolor.yellow, test['name'], pcolor.reset))
        # Delete outfile as this test won't have any output
        if 'outfile' in test:
            del test['outfile']

        return True, True, False

    vcprint(pcolor.faint, f"Test File: {test['case']}")
    vcprint(pcolor.faint, f"Test Cmdl: {opts}")

    with open(os.path.join(LOGDIR, test['outfile']), 'a') as output:
        if NOEXEC:
            print("Skipped because --no-exec", file=output)
            return False, True, False
        else:
            skip_suite, skip, err = execute(opts, test, output)

    if 'plan' not in test:
        print("test error, no plan")
        return False, False, True

    if 'executed' not in test:
        print("test error, no tests executed")
        return False, False, True

    if test['plan'] != test['executed']:
        print("test error, not conforming to plan ({}/{})".format(test['executed'], test['plan']))
        err = True

    return skip_suite, skip, err

# In this function, we generate an unique name for each case and suite. Both
# suites and cases can be passed an arbitrary amount of times and the same test
# can reside in different suites. We need something unique to identify them by.
def prefix_name(name):
    global TEST_CNT
    TEST_CNT += 1
    return str(TEST_CNT).zfill(4) + "-" + name.replace(" ", "-")

def gen_name(filename):
    return prefix_name(os.path.basename(filename))

def gen_outfile(name):
    return os.path.join("output", os.path.splitext(name)[0] + ".log")

def lmerge(a, b):
    new = a.copy()
    for item in b:
        if item not in a:
            new.append(item)
    return new

def parse_yaml(path):
    with open(path, 'r') as stream:
        try:
            data = yaml.load(stream, Loader=yaml.FullLoader)
        except yaml.YAMLError as exc:
            print(exc)
            return -1
    return data

def get_test_spec_path(case_path, test_spec):
    case_dirname = os.path.dirname(case_path)
    case_basename = os.path.basename(case_path)
    case_name = os.path.splitext(case_basename)[0]

    test_spec = test_spec.replace('<case>', case_name)

    return  os.path.join(case_dirname, test_spec)


def get_suite_settings(name, data, upstream_settings):
    for entry in data:
        if 'settings' in entry:
            if entry['settings'] is None:
                print(f"error, empty \"settings\" in suite {suite['suite_path']}, invalid indent?")
                sys.exit(1)

            vcprint(pcolor.faint, f"Suite {name} has settings: {entry['settings']}")
            return entry['settings']
    return upstream_settings

def parse_suite(suite_path, parent_suite_path, options, settings, name=None):
    suite = {}
    suite['suite'] = []
    suite['result'] = "pending"
    suite_dirname = os.path.dirname(suite_path)

    if name:
        suite['name'] = prefix_name(name)
    else:
        suite['name'] = gen_name(suite_path)

    if not os.path.isfile(suite_path):
        print("error, test suite not found {}" . format(suite_path))
        print("(referenced from {})" . format(parent_suite_path))
        sys.exit(1)

    data = parse_yaml(suite_path)
    if not data:
        print(f"fatal, empty suite {suite['name']}")
        sys.exit(1)

    settings = get_suite_settings(suite['name'], data, settings)

    for entry in data:
        if 'suite' in entry:
            next_suite_path = os.path.join(suite_dirname, entry['suite'])
            if 'opts' in entry:
                opts = [o.replace('<base>', suite_dirname) for o in entry['opts']]
                opts = [o.replace('<scratch>', SCRATCHDIR) for o in opts]
                opts = lmerge(opts, options)
            else:
                opts = options.copy()
            if 'name' in entry:
                suite['suite'].append(parse_suite(next_suite_path, suite_path, opts, settings, entry['name']))
            else:
                suite['suite'].append(parse_suite(next_suite_path, suite_path, opts, settings))

        elif 'case' in entry:
            case = {}

            if 'name' in entry:
                case['name'] = prefix_name(entry['name'])
            else:
                case['name'] = gen_name(entry['case'])

            case['outfile'] = gen_outfile(case['name'])

            if 'opts' in entry:
                opts = [o.replace('<base>', suite_dirname) for o in entry['opts']]
                opts = [o.replace('<scratch>', SCRATCHDIR) for o in opts]
                case['options'] = lmerge(opts, options)
            else:
                case['options'] = options

            if 'onfail' in entry:
                case['onfail'] = entry['onfail']

            if 'mask' in entry:
                case['mask'] = entry['mask']

            case['case'] = os.path.join(suite_dirname, entry['case'])

            if 'test-spec' in settings:
                test_spec_path = get_test_spec_path(case['case'], settings['test-spec'])
                if os.path.exists(test_spec_path):
                    vcprint(pcolor.faint, f"Found test specification: {test_spec_path} for {case['case']}")
                    case['test-spec'] = test_spec_path
                    case['test-spec-sha'] = calculate_sha1sum(test_spec_path)
                else:
                        vcprint(pcolor.faint, f"No test specification for {case['case']} ({test_spec_path})")

            if not os.path.isfile(case['case']):
                print("error, test case not found {}" . format(case['case']))
                print("(referenced from {})" . format(suite_path))
                sys.exit(1)
            if not os.access(case['case'], os.X_OK):
                print("error, test case not executable {}".format(case['case']))
                sys.exit(1)
            suite['suite'].append(case)
        elif 'settings' in entry:
            pass # Handled by preparser
        else:
            print("error, missing suite/case/settings in suite {}".format(suite['name']))
            sys.exit(1)
    return suite

def write_report_result_tree(file, includes, data, depth):
    for test in data['suite']:
        indent = '  ' * depth
        stars = '*' + '*' * depth

        string = f"{indent}"
        string += f"{stars}"
        string += f" [.{test['result']}]#{test['result'].upper()}#"
        if 'outfile' in test:
            string += f" <<output-{test['name']},{test['name']}>>"
        else:
            string += f" {test['name']}"

        # Append (Spec) if there's a test specification
        if 'test-spec-sha' in test:
            string += f" <<incl-{test['test-spec-sha']},(Spec)>>"

        file.write(f"{string}\n")

        if 'suite' in test:
            write_report_result_tree(file, includes, test, depth + 1)

def write_report_output(file, data, depth):
    for test in data['suite']:

        if 'outfile' in test:
            file.write(f"\n=== {test['name']}\n")

            if 'test-spec-sha' in test:
                file.write(f"\n<<incl-{test['test-spec-sha']},Test Specification>>\n")

            file.write(f"\n[[output-{test['name']}]]\n")
            file.write(f"----\n")
            file.write(f"include::{test['outfile']}[]\n")
            file.write(f"----\n")

        if 'suite' in test:
            write_report_output(file, test, depth + 1)

def write_report_specifications(file, data, depth):
    for test in data['suite']:

        if 'test-spec-sha' in test:
            file.write(f"\n[[incl-{test['test-spec-sha']}]]\n")
            file.write("include::{}[]\n" . format(test['test-spec']))

        if 'suite' in test:
            write_report_specifications(file, test, depth + 1)

def write_report_project_info(file, config):
    if 'PROJECT-NAME' not in config or 'PROJECT-ROOT' not in config:
        return None

    name = config['PROJECT-NAME']
    root = config['PROJECT-ROOT']
    version = run_git_cmd(root, ["describe", "--tags", "--always"])
    sha = run_git_cmd(root, ['rev-parse', 'HEAD'])[:12]

    file.write(f"\n=== {name} Info\n\n")

    file.write('[cols="1h,2"]\n')
    file.write("|===\n")
    file.write(f"| Version | {version}\n")
    file.write(f"| SHA     | {sha}\n")

    file.write("|===\n")

def write_report(data, config):
    with open(os.path.join(LOGDIR, 'report.adoc'), 'a') as file:
        current_date = datetime.now().strftime("%Y-%m-%d")
        name = config['PROJECT-NAME'] if 'PROJECT-NAME' in config else "9pm"
        topdoc = config['PROJECT-TOPDOC'] + "/" if 'PROJECT-TOPDOC' in config else ""

        file.write(f"= {name} Test Report\n")
        file.write("Author: 9pm Test Framework\n")
        file.write(f"Date: {current_date}\n")
        file.write(":toc: left\n")
        file.write(":toc-title: INDEX\n")
        file.write(f":topdoc: {topdoc}\n")
        file.write(":sectnums:\n")
        file.write(":pdf-page-size: A4\n")

        file.write("\n<<<\n")
        file.write("\n== Test Summary\n\n")
        write_report_project_info(file, config)

        file.write("\n<<<\n")
        file.write("\n== Test Result\n\n")

        includes = []
        write_report_result_tree(file, includes, data, 0)

        file.write("\n<<<\n")
        file.write("\n== Test Output\n")
        write_report_output(file, data, 0)

        file.write("\n<<<\n")
        file.write("\n== Test Specification\n")
        write_report_specifications(file, data, 0)


def write_github_result_tree(file, data, depth):
    icon_map = {
        "pass": ":white_check_mark:",
        "fail": ":red_circle:",
        "skip": ":large_orange_diamond:",
        "masked-fail": ":o:",
        "masked-skip": ":small_orange_diamond:",
    }
    for test in data['suite']:
        mark = icon_map.get(test['result'], "")
        file.write("{}- {} : {}\n".format('  ' * depth, mark, test['name']))

        if 'suite' in test:
            write_github_result_tree(file, test, depth + 1)

def write_github_result(data):
    with open(os.path.join(LOGDIR, 'result-gh.md'), 'a') as file:
        file.write("# Test Result\n")
        write_github_result_tree(file, data, 0)

def write_md_result_tree(file, data, depth):
    for test in data['suite']:
        file.write("{}- {} : {}\n".format('  ' * depth, test['result'].upper(), test['name']))

        if 'suite' in test:
            write_md_result_tree(file, test, depth + 1)

def write_md_result(data):
    with open(os.path.join(LOGDIR, 'result.md'), 'a') as file:
        file.write("# Test Result\n")
        write_md_result_tree(file, data, 0)

def print_result_tree(data, base):
    i = 1
    llen = len(data['suite'])

    for test in data['suite']:
        if i < llen:
            prefix = "|-- "
            nextbase = base + "|   "
        else:
            prefix = "`-- "
            nextbase = base + "    "

        if test['result'] == "pass":
            sign = "o"
            color = pcolor.green
        elif test['result'] == "fail":
            sign = "x"
            color = pcolor.red
        elif test['result'] == "masked-fail":
            sign = "m"
            color = pcolor.red_u
        elif test['result'] == "masked-skip":
            sign = "m"
            color = pcolor.yellow_u
        elif test['result'] == "skip":
            sign = "s"
            color = pcolor.yellow
        else:
            sign = "?"
            color = pcolor.yellow

        print("{}{}{}{} {}{}".format(base, prefix, color, sign, test['name'], pcolor.reset))

        if 'suite' in test:
            print_result_tree(test, nextbase)
        i += 1

def probe_suite(data):
    for test in data['suite']:
        if 'suite' in test:
            probe_suite(test)
        elif 'case' in test:
                test['result'] = "noexec"
        else:
            print("error, garbage in suite")
            sys.exit(1)

    data['result'] = "noexec"

def run_suite(args, data, skip_suite):
    skip = False
    err = False

    if data['name'] != "command-line":
        print(pcolor.blue + f"\nRunning suite {data['name']}" + pcolor.reset)

    for test in data['suite']:
        if 'suite' in test:
            subskip, suberr = run_suite(args, test, skip_suite)
            if subskip:
                skip = True
            if suberr:
                err = True
            if err and args.abort:
                break;

        elif 'case' in test:
            if not os.path.isfile(test['case']):
                print("error, test case not found {}".format(test['case']))
                sys.exit(1)
            if not os.access(test['case'], os.X_OK):
                print("error, test case not executable {}".format(test['case']))
                sys.exit(1)

            if skip_suite:
                test['result'] = "skip"

            skip_suite, subskip, suberr = run_test(args, test)
            if suberr:
                if 'mask' in test and test['mask'] == "fail":
                    print("{}Test failure is masked in suite{}" . format(pcolor.red, pcolor.reset))
                    test['result'] = "masked-fail"
                    err = False
                else:
                    test['result'] = "fail"
                    err = True

                if 'onfail' in test:
                    run_onfail(args, test)

                if err and args.abort:
                    print("Aborting execution")
                    break
            elif subskip:
                if 'mask' in test and test['mask'] == "skip":
                    print("{}Test skip is masked in suite{}" . format(pcolor.orange, pcolor.reset))
                    test['result'] = "masked-skip"
                else:
                    skip = True
                    test['result'] = "skip"
            else:
                test['result'] = "pass"

    if err:
        data['result'] = "fail"
    elif skip:
        data['result'] = "skip"
    else:
        data['result'] = "pass"

    return skip, err

def parse_proj_config(root_path, args):
    files = [
        os.path.join(root_path, '..', '9pm-proj.yaml'),
        os.path.join(root_path, 'etc', '9pm-proj.yaml')
    ]

    if "NINEPM_PROJ_CONFIG" in os.environ:
        files.insert(0, os.environ["NINEPM_PROJ_CONFIG"])

    path = next((os.path.expanduser(f) for f in files if os.path.exists(os.path.expanduser(f))), None)

    if args.proj:
        if not os.path.exists(args.proj):
            print(f"error, config file \"{args.proj}\" not found.")
            sys.exit(1)

        path = args.proj

    if path:
        vcprint(pcolor.faint, f"Using project config: {path}")
        os.environ["NINEPM_PROJ_CONFIG"] = path
    else:
        print("error, can't find any 9pm project config")
        sys.exit(1)

    try:
        with open(path, 'r') as f:
            data = yaml.safe_load(f) or {}
    except yaml.YAMLError:
        print(f"error, parsing YAML {path} config.")
        sys.exit(1)

    if not '9pm' in data:
        return []

    if 'PROJECT-ROOT' in data['9pm']:
        data['9pm']['PROJECT-ROOT'] = rootify_path(data['9pm']['PROJECT-ROOT'])

    if 'PROJECT-TOPDOC' in data['9pm']:
        data['9pm']['PROJECT-TOPDOC'] = rootify_path(data['9pm']['PROJECT-TOPDOC'])

    return data['9pm']

def parse_rc(root_path, args):
    required_keys = ["LOG_PATH"]

    files = [
        os.path.join("~/.9pm.rc"),
        os.path.join(root_path, 'etc', '9pm.rc')
    ]
    path = next((os.path.expanduser(f) for f in files if os.path.exists(os.path.expanduser(f))), None)

    if path:
        vcprint(pcolor.faint, f"Using RC: {path}")
    else:
        print("error, can't find any 9pm.rc file")
        sys.exit(1)

    try:
        with open(path, 'r') as f:
            data = yaml.safe_load(f) or {}
    except yaml.YAMLError:
        print(f"error, parsing YAML {path} running config.")
        sys.exit(1)

    missing_keys = [key for key in required_keys if key not in data]
    if missing_keys:
        print(f"error, 9pm.rc is missing required keys: {', '.join(missing_keys)}")
        sys.exit(1)

    return data

def parse_cmdline():
    parser = argparse.ArgumentParser()
    parser.add_argument('-a', '--abort', action='store_true',
            help='(9PM) Abort execution if test fails')
    parser.add_argument('--no-exec', action='store_true',
            help='(9PM) Do not execute any tests')
    parser.add_argument('-p', '--proj', metavar='FILE', action='store',
            help='(9PM) Path to project configuration')
    parser.add_argument('-v', '--verbose', action='store_true',
            help='(9PM) Enable verbose output')
    parser.add_argument('-c', '--config', metavar='FILE', action='store',
            help='(TEST) Config file passed to test case')
    parser.add_argument('-d', '--debug', action='store_true',
            help='(TEST) Enable test case debug')
    parser.add_argument('-o', '--option', action='append', default=[],
            help='(TEST) Option(s) passed to all test cases (can be repeated)')
    parser.add_argument('suites', nargs='+', metavar='TEST|SUITE',
            help='Test or suite to run')
    if len(sys.argv) == 1:
        # Normally, argparse does not display the help message if the user
        # didn't explicitly invoke '-h' but we also want it shown if the user
        # didn't specify any arguments at all.
        parser.print_help()
        sys.exit(1)
    return parser.parse_args()

def setup_log_dir(log_path):
    log_path = os.path.expanduser(log_path)

    now = datetime.now()
    dir_name = now.strftime('%Y-%m-%d_%H-%M-%S-%f')
    log_dir = os.path.join(log_path, dir_name)
    os.makedirs(log_dir)
    os.makedirs(os.path.join(log_dir, "output"))

    last_link =os.path.join(log_path, "last")
    if os.path.islink(last_link):
        os.unlink(last_link)
    os.symlink(dir_name, last_link)

    return log_dir

def setup_env(args):
    os.environ["NINEPM_TAP"] = "1"

    os.environ["NINEPM_ROOT_PATH"] = ROOT_PATH
    os.environ["NINEPM_DATABASE"] = DATABASE
    os.environ["NINEPM_SCRATCHDIR"] = SCRATCHDIR
    os.environ["NINEPM_LOG_PATH"] = LOGDIR

    if args.debug:
        os.environ["NINEPM_DEBUG"] = "1"
    if args.config:
        os.environ["NINEPM_CONFIG"] = args.config

def run_git_cmd(path, command):
    gitdir = os.path.join(path, '.git')

    if not os.path.isdir(gitdir):
        vcprint(pcolor.orange, f"warning, no .git dir in path ({path})")
        return ""

    try:
        vcprint(pcolor.faint, f"Running: git --git-dir {gitdir} {command}")
        result = subprocess.check_output(
            ['git', '--git-dir', gitdir] + command,
            stderr=subprocess.STDOUT
        ).decode('utf-8').strip()
    except Exception as e:
        cprint(pcolor.orange, f"warning, git command failed ({e})")
        return ""

    return result

def pr_proj_info(proj):
    str = f"\nTesting"

    if 'PROJECT-NAME' in proj:
        str += f" {proj['PROJECT-NAME']}"

    if 'PROJECT-ROOT' in proj:
        git_sha = run_git_cmd(proj['PROJECT-ROOT'], ['rev-parse', 'HEAD'])[:12]

    if git_sha:
        str += f" ({git_sha})"

    cprint(pcolor.yellow, str)

def main():
    global DATABASE
    global SCRATCHDIR
    global LOGDIR
    global VERBOSE
    global NOEXEC

    sha = ""
    if (sha := run_git_cmd(ROOT_PATH, ['rev-parse', 'HEAD'])):
        sha = f"({sha[:10]})"
    cprint(pcolor.yellow, "9PM - Simplicity is the ultimate sophistication {}" . format(sha))

    args = parse_cmdline()
    VERBOSE = args.verbose
    NOEXEC = args.no_exec

    rc = parse_rc(ROOT_PATH, args)

    LOGDIR = setup_log_dir(rc['LOG_PATH'])

    vcprint(pcolor.faint, f"Logging to: {LOGDIR}")

    proj = parse_proj_config(ROOT_PATH, args)

    scratch = tempfile.mkdtemp(suffix='', prefix='9pm_', dir='/tmp')
    vcprint(pcolor.faint, f"Created scratch dir: {scratch}")
    SCRATCHDIR = scratch
    atexit.register(shutil.rmtree, SCRATCHDIR)

    db = tempfile.NamedTemporaryFile(suffix='_db', prefix='9pm_', dir=scratch)
    vcprint(pcolor.faint, f"Created databasefile: {db.name}")
    DATABASE = db.name

    pr_proj_info(proj)

    cmdl = {'name': 'command-line', 'suite': []}
    for filename in args.suites:
        fpath = os.path.join(os.getcwd(), filename)
        if filename.endswith('.yaml'):
            cmdl['suite'].append(parse_suite(fpath, "command-line", args.option, {}))
        else:
            test = {}
            test['case'] =  fpath
            test['name'] = gen_name(filename)
            test['outfile'] = gen_outfile(test['name'])

            if args.option:
                test["options"] = args.option

            cmdl['suite'].append(test)


    probe_suite(cmdl)

    setup_env(args)

    skip, err = run_suite(args, cmdl, False)
    if err:
        cprint(pcolor.red, "\nx Execution")
    elif skip:
        cprint(pcolor.yellow, "\ns Execution")
    else:
        cprint(pcolor.green, "\no Execution")

    print_result_tree(cmdl, "")
    write_md_result(cmdl)
    write_github_result(cmdl)
    write_report(cmdl, proj)

    db.close()
    sys.exit(err)

if __name__ == '__main__':
    main()
