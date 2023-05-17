#!/usr/bin/tclsh

package require 9pm

9pm::output::plan 1

if {[llength $argv] == 0} {
    9pm::output::ok "No options passed by default"
} elseif {[lindex $argv 0] == "cmdl-supplied"} {
    9pm::output::ok "No options passed by default (only cmdl-supplied)"
} else {
    9pm::output::fail "Command line polluted: \"$argv\""
}
