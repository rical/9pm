#!/usr/bin/tclsh

package require 9pm

9pm::output::plan 2

if {[info exists 9pm::root_path]} {
    9pm::output::ok "\$9pm::root_path exists"
} else {
    9pm::fatal 9pm::output::fail "bla"
}

if {[file exists "$9pm::root_path/9pm.py"]} {
    9pm::output::ok "Root path looks sane"
} else {
    9pm::output::fail "$9pm::root_path/9pm.py missing"
}
