#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm

output::debug "argv before ::arg:: $argv"

9pm::arg::require "mode"
9pm::arg::optional "optional-negative"
9pm::arg::optional "optional-positive"
9pm::arg::require_or_skip "skip-positive" "yes"

output::plan 4

output::debug "argv after ::arg:: $argv"

if {[llength $argv] == 2} {
    output::ok "correct number of arguments"
} else {
    output::fail "unexpected number of arguments ([llength $argv])"
}

if {[lindex $argv 0] == "suite-supplied"} {
    output::ok "argument from suite"
} else {
    output::fail "no argument from suite"
}

if {[lindex $argv 1] == "cmdl-supplied"} {
    output::ok "argument from command line"
} else {
    output::fail "no argument from command line"
}

if {[info exists 9pm::arg::optional-positive]} {
    output::ok "got optional argument"
} else {
    output::fail "didn't get optional argument"
}


