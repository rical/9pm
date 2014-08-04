#!/usr/bin/tclsh
package require 9pm

proc check_active {expected} {

    if {$int::active_shell == $expected} {
        result OK "Active check for $expected"
    } else {
        result FAIL "Active check failed for $expected"
    }
}

proc check_unset {} {
    if {![info exists int::active_shell]} {
        result OK "No active shell"
    } else {
        result FAIL "Active shell is set"
    }
}

output INFO "Spawn 3 new shells and verify active follows"
shell "base"
check_active "base"
shell "sub1"
check_active "sub1"
shell "sub2"
check_active "sub2"

output INFO "Switch to an existing shell and verify active follow"
shell "sub1"
check_active "sub1"

output INFO "Close active shell and verify active is unset"
close_shell "sub1"
check_unset

output INFO "Switch to an existing shell then close other shell and verify active stays"
shell "base"
check_active "base"
close_shell "sub2"
check_active "base"

output INFO "Close shell with no active shell set"
shell "foo"
shell "bar"
shell "foo"
close_shell "foo"
close_shell "bar"
result OK "Can close shell when no active shell is set"
