#!/usr/bin/python3

# Copyright (C) 2011-2017 Richard Alpe <rical@highwind.se>
#
# This file is part of 9pm.
#
# 9pm is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# 9pm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

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

TEST_CNT=0
ROOT_PATH = os.path.dirname(os.path.realpath(__file__))
# TODO: proper argument strucutre
DATABASE = ""
SCRATCHDIR = ""

if "TCLLIBPATH" in os.environ:
    os.environ["TCLLIBPATH"] = os.environ["TCLLIBPATH"] + " " + ROOT_PATH
else:
    os.environ["TCLLIBPATH"] = ROOT_PATH

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

def cprint(color, *args, **kwargs):
    sys.stdout.write(color)
    print(*args, **kwargs)
    sys.stdout.write(pcolor.reset)

def execute(args, test):
    proc = subprocess.Popen([test['case']] + args, stdout=subprocess.PIPE)
    skip = False
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

        if plan:
            cprint(pcolor.purple, '{} {}'.format(stamp, string))
            test['plan'] = plan.group(2)
        elif skip:
            cprint(pcolor.yellow, '{} {}'.format(stamp, string))
            test['executed'] = skip.group(1)
            skip = True
        elif skip_suite:
            cprint(pcolor.yellow, '{} {}'.format(stamp, string))
            test['executed'] = skip.group(1)
            skip_suite = True
            skip = True
        elif ok:
            cprint(pcolor.green, '{} {}'.format(stamp, string))
            test['executed'] = ok.group(1)
        elif not_ok:
            cprint(pcolor.red, '{} {}'.format(stamp, string))
            err = True
            test['executed'] = not_ok.group(1)
        else:
            print("{}{}".format(stamp, string))

        if (ok or not_ok) and 'plan' not in test:
            print("test error, test started before plan")
            err = True

    out, error = proc.communicate()
    exitcode = proc.returncode

    if exitcode != 0:
        err = True

    return skip_suite, skip, err

def run_onfail(cmdline, test):
    args = []
    if 'options' in test:
        args.extend(test['options'])

    onfail = {}
    onfail['case'] = os.path.join(test['path'], test['onfail'])
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
        return False, True

    if 'executed' not in test:
        print("test error, no tests executed")
        return False, True

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
    return str(TEST_CNT).zfill(4) + "-" + name

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

def parse(fpath, options, name=None):
    suite = {}
    suite['fpath'] = fpath
    suite['suite'] = []
    suite['result'] = "pending"
    cur = os.path.dirname(fpath)

    if name:
        suite['name'] = name
    else:
        suite['name'] = gen_name(fpath)

    data = parse_yaml(fpath)
    for entry in data:
        if 'suite' in entry:
            fpath = os.path.join(cur, entry['suite'])
            if 'opts' in entry:
                opts = lmerge(entry['opts'], options)
            else:
                opts = options.copy()

            if 'name' in entry:
                suite['suite'].append(parse(fpath, opts, prefix_name(entry['name'])))
            else:
                suite['suite'].append(parse(fpath, opts))

        elif 'case' in entry:
            case = {}

            if 'name' in entry:
                name = entry['name']
            else:
                name = os.path.basename(entry['case'])

            if 'opts' in entry:
                opts = [o.replace('<base>', cur) for o in entry['opts']]
                case['options'] = lmerge(opts, options)
            else:
                case['options'] = options

            if 'onfail' in entry:
                case['onfail'] = entry['onfail']

            if 'mask' in entry:
                case['mask'] = entry['mask']

            case['case'] = os.path.join(cur, entry['case'])
            case['path'] = cur
            case['name'] = prefix_name(name)
            suite['suite'].append(case)
        else:
            print("error, missing suite/case in suite {}".format(suite['name']))
            sys.exit(1)
    return suite

def print_tree(data, base):
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
            print_tree(test, nextbase)
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

def setup_env(cmdline):
    os.environ["NINEPM_TAP"] = "1"

    if cmdline.debug:
        os.environ["NINEPM_DEBUG"] = "1"

    os.environ["NINEPM_DATABASE"] = DATABASE
    os.environ["NINEPM_SCRATCHDIR"] = SCRATCHDIR

    if cmdline.config:
        os.environ["NINEPM_CONFIG"] = cmdline.config

def main():
    global DATABASE
    global SCRATCHDIR
    cprint(pcolor.yellow, "9PM - Simplicity is the ultimate sophistication")

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
            cmdl['suite'].append(parse(fpath, args.option))
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
    print_tree(cmdl, "")

    db.close()
    sys.exit(err)

if __name__ == '__main__':
    main()
