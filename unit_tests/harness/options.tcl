#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm

output::debug "argv before ::arg:: $argv"

9pm::arg::require "mode"
9pm::arg::require "scratch"
9pm::arg::require "base"
9pm::arg::optional "optional-negative"
9pm::arg::optional "optional-positive"
9pm::arg::require_or_skip "skip-positive" "yes"

output::plan 6

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

output::info "got scratch option = $9pm::arg::scratch"
if {$9pm::arg::scratch == $9pm::db::scratch} {
    output::ok "<scratch> in suite evaluated to SCRATCHDIR"
} else {
    output::fail "<scratch> in suite did not evaluate to SCRATCHDIR"
}

output::info "got base option = $9pm::arg::base"
if {[string index $9pm::arg::base 0] == "/"} {
    output::ok "<base> in suite evaluated to some path"
} else {
    output::fail "<base> in suite did not evaluate to some path"
}
