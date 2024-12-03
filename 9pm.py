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
from datetime import datetime

TEST_CNT=0
ROOT_PATH = os.path.dirname(os.path.realpath(__file__))
LIB_TCL_PATH = ROOT_PATH + "/lib_tcl/"
# TODO: proper argument strucutre
DATABASE = ""
SCRATCHDIR = ""
LOGDIR = None

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

def execute(args, test):
    proc = subprocess.Popen([test['case']] + args, stdout=subprocess.PIPE)
    skip_suite = False
    test_skip = False
    err = False

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

def run_onfail(cmdline, test):
    args = []
    if 'options' in test:
        args.extend(test['options'])

    dirname = os.path.dirname(test['case'])

    onfail = {}
    onfail['case'] = os.path.join(dirname, test['onfail'])
    onfail['name'] = 'onfail'

    print("\n{}Running onfail \"{}\" for test {}{}" . format(pcolor.cyan, test['onfail'],
        test['name'], pcolor.reset))

    if cmdline.debug:
        print("Executing onfail {} for test {}" . format(onfail['case'], test['case']))

    execute(args, onfail)

def run_test(cmdline, test):
    args = []
    if 'options' in test:
        args.extend(test['options'])

    print(pcolor.blue + "\nStarting test", test['name'] + pcolor.reset)

    if test['result'] == "skip":
        print("{}Skip test {} (suite skip){}" . format(pcolor.yellow, test['name'], pcolor.reset))
        return True, True, False

    if cmdline.debug:
        print("Executing:", [test['case']] + args)

    skip_suite, skip, err = execute(args, test)

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

def parse_suite(fpath, pname, options, name=None):
    suite = {}
    suite['fpath'] = fpath
    suite['suite'] = []
    suite['result'] = "pending"
    cur = os.path.dirname(fpath)

    if name:
        suite['name'] = name
    else:
        suite['name'] = gen_name(fpath)

    if not os.path.isfile(fpath):
        print("error, test suite not found {}" . format(fpath))
        print("(referenced from {})" . format(pname))
        sys.exit(1)

    data = parse_yaml(fpath)
    pname = fpath

    # Pre parse suite
    for entry in data:
        if 'settings' in entry:
            if entry['settings'] is None:
                print(f"error, empty \"settings\" in suite {suite['fpath']}, invalid indent?")
                sys.exit(1)

            suite['settings'] = entry['settings']

    for entry in data:
        if 'suite' in entry:
            fpath = os.path.join(cur, entry['suite'])
            if 'opts' in entry:
                opts = [o.replace('<base>', cur) for o in entry['opts']]
                opts = [o.replace('<scratch>', SCRATCHDIR) for o in opts]
                opts = lmerge(opts, options)
            else:
                opts = options.copy()
            if 'name' in entry:
                suite['suite'].append(parse_suite(fpath, pname, opts, prefix_name(entry['name'])))
            else:
                suite['suite'].append(parse_suite(fpath, pname, opts))

        elif 'case' in entry:
            case = {}

            if 'name' in entry:
                case['name'] = prefix_name(entry['name'])
            else:
                case['name'] = gen_name(entry['case'])

            if 'opts' in entry:
                opts = [o.replace('<base>', cur) for o in entry['opts']]
                opts = [o.replace('<scratch>', SCRATCHDIR) for o in opts]
                case['options'] = lmerge(opts, options)
            else:
                case['options'] = options

            if 'onfail' in entry:
                case['onfail'] = entry['onfail']

            if 'mask' in entry:
                case['mask'] = entry['mask']

            case['case'] = os.path.join(cur, entry['case'])
            if not os.path.isfile(case['case']):
                print("error, test case not found {}" . format(case['case']))
                print("(referenced from {})" . format(fpath))
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

def get_github_emoji(result):
    if result == "pass":
        return ":white_check_mark:"
    if result == "fail":
        return ":red_circle:"
    if result == "skip":
        return ":large_orange_diamond:"
    if result == "masked-fail":
        return ":o:"
    if result == "masked-skip":
        return ":small_orange_diamond:"

    return result

def write_result_md_tree(md, gh, data, base):
    for test in data['suite']:
        with open(md, 'a') as file:
            file.write("{}- {} : {}\n".format(base, test['result'].upper(), test['name']))

        with open(gh, 'a') as file:
            mark = get_github_emoji(test['result'])
            file.write("{}- {} : {}\n".format(base, mark, test['name']))

        if 'suite' in test:
            write_result_md_tree(md, gh, test, base + "  ")

def write_result_files(data):
    md = os.path.join(LOGDIR, 'result.md')
    gh = os.path.join(LOGDIR, 'result-gh.md')

    with open(md, 'a') as file:
        file.write("# Test Result\n")

    with open(gh, 'a') as file:
        file.write("# Test Result\n")

    write_result_md_tree(md, gh, data, "")

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

def run_suite(cmdline, data, skip_suite):
    skip = False
    err = False

    for test in data['suite']:
        if 'suite' in test:
            subskip, suberr = run_suite(cmdline, test, skip_suite)
            if subskip:
                skip = True
            if suberr:
                err = True
            if err and cmdline.abort:
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

            skip_suite, subskip, suberr = run_test(cmdline, test)
            if suberr:
                if 'mask' in test and test['mask'] == "fail":
                    print("{}Test failure is masked in suite{}" . format(pcolor.red, pcolor.reset))
                    test['result'] = "masked-fail"
                    err = False
                else:
                    test['result'] = "fail"
                    err = True

                if 'onfail' in test:
                    run_onfail(cmdline, test)

                if err and cmdline.abort:
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

def parse_rc(root_path):
    required = {"LOG_PATH"}
    rc = {}

    home_path = os.path.expanduser("~/.9pm.rc")
    default_path = os.path.join(root_path, 'etc', '9pm.rc')
    if os.path.exists(home_path):
        rc_path = home_path
    elif os.path.exists(default_path):
        rc_path = default_path
    else:
        print("error, can't find 9pm.rc file")
        sys.exit(1)

    with open(rc_path, 'r') as file:
        for line in file:
            line = line.strip()
            if not line.startswith('#') and ':' in line:
                key, value = [item.strip() for item in line.split(':', 1)]
                value = value.split('"')[1]
                rc[key] = value

    for req in required:
        if not rc.get(req):
            print("error, required key \"{}\" missing from 9pm.rc" .format(req))
            sys.exit(1)

    return rc

def parse_cmdline():
    parser = argparse.ArgumentParser()
    parser.add_argument('-a', '--abort', action='store_true',
            help='Abort suite if test failes')
    parser.add_argument('-c', '--config', metavar='FILE', action='store',
            help='Use config file')
    parser.add_argument('-d', '--debug', action='store_true',
            help='Enable debug mode')
    parser.add_argument('-o', '--option', action='append', default=[],
            help='Option to pass to tests and suites (use multiple -o for multiple options)')
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

    last_link =os.path.join(log_path, "last")
    if os.path.islink(last_link):
        os.unlink(last_link)
    os.symlink(dir_name, last_link)

    return log_dir

def setup_env(cmdline):
    os.environ["NINEPM_TAP"] = "1"

    if cmdline.debug:
        os.environ["NINEPM_DEBUG"] = "1"

    os.environ["NINEPM_ROOT_PATH"] = ROOT_PATH
    os.environ["NINEPM_DATABASE"] = DATABASE
    os.environ["NINEPM_SCRATCHDIR"] = SCRATCHDIR
    os.environ["NINEPM_LOG_PATH"] = LOGDIR

    if cmdline.config:
        os.environ["NINEPM_CONFIG"] = cmdline.config

def get_git_sha():
    if not os.path.isdir(os.path.join(ROOT_PATH, '.git')):
        return ""

    try:
        sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'],
                stderr=subprocess.STDOUT).decode('utf-8').strip()
        return sha
    except FileNotFoundError:
        return ""
    except subprocess.CalledProcessError:
        return ""

def main():
    global DATABASE
    global SCRATCHDIR
    global LOGDIR

    sha = ""
    if (sha := get_git_sha()):
        sha = "({})" . format(sha[:10])
    cprint(pcolor.yellow, "9PM - Simplicity is the ultimate sophistication {}" . format(sha))

    rc = parse_rc(ROOT_PATH)

    LOGDIR = setup_log_dir(rc['LOG_PATH'])

    args = parse_cmdline()

    scratch = tempfile.mkdtemp(suffix='', prefix='9pm_', dir='/tmp')
    if args.debug:
        print("Created scratch dir:", scratch)
    SCRATCHDIR = scratch
    atexit.register(shutil.rmtree, SCRATCHDIR)

    db = tempfile.NamedTemporaryFile(suffix='_db', prefix='9pm_', dir=scratch)
    if args.debug:
        print("Created databasefile: {}".format(db.name))
    DATABASE = db.name

    cmdl = {'name': 'cmdl', 'suite': []}
    for filename in args.suites:
        fpath = os.path.join(os.getcwd(), filename)
        if filename.endswith('.yaml'):
            cmdl['suite'].append(parse_suite(fpath, "command line", args.option))
        else:
            test = {"case": fpath, "name": gen_name(filename)}

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
    write_result_files(cmdl)

    db.close()
    sys.exit(err)

if __name__ == '__main__':
    main()
