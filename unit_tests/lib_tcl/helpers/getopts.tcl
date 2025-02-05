#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm

9pm::output::plan 3

proc foo {args} {
    set opts [9pm::misc::getopts $args "default" "abc" "timeout" 99]

    if {[dict get $opts "force"]} {
        output::ok "Bool test: force is set to true"
    } else {
        fatal output::fail "Bool test: force is not set to true"
    }

    if {[dict get $opts "timeout"] == 10} {
        output::ok "Value test: timeout set correctly"
    } else {
        fatal output::fail "Value test: timeout not set correctly"
    }

    if {[dict get $opts "default"] == "abc"} {
        output::ok "Default value test: set correctly"
    } else {
        fatal output::fail "Default value test: not set correctly"
    }
}

foo "timeout" "10" "force" TRUE

