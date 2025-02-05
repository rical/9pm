#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm::

output::plan 1

proc test_hgtg { var } {
    return [expr $var == 42]
}

output::test [test_hgtg 42] "This is a TAP from a test result"
