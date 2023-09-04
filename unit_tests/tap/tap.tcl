#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm::


set states [list "skip" "ok"]

set plan 0
foreach state $argv {
    if {[lsearch $states $state] >= 0} {
        incr plan
    }
}

output::plan $plan

foreach state $argv {
    if {[lsearch -inline $states $state] < 0} {
        continue
    }
    output::$state "This is a $state TAP test point"
}
