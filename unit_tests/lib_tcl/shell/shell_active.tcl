#!/usr/bin/tclsh
package require 9pm
namespace path ::9pm

output::plan 8

proc check_active {expected} {

    if {$::9pm::spawn::active == $expected} {
        output::ok "Active check for $expected"
    } else {
        output::fail "Active check failed for $expected"
    }
}

proc check_unset {} {
    if {![info exists ::9pm::spawn::active]} {
        output::ok "No active shell"
    } else {
        output::fail "Active shell is set"
    }
}

output::info "Spawn 3 new shells and verify active follows"
shell::open "base"
check_active "base"
shell::open "sub1"
check_active "sub1"
shell::open "sub2"
check_active "sub2"

output::info "Switch to an existing shell and verify active follow"
shell::open "sub1"
check_active "sub1"

output::info "Close active shell and verify active is unset"
shell::close "sub1"
check_unset

output::info "Switch to an existing shell then close other shell and verify active stays"
shell::open "base"
check_active "base"
shell::close "sub2"
check_active "base"

output::info "Close shell with no active shell set"
shell::open "foo"
shell::open "bar"
shell::open "foo"
shell::close "foo"
shell::close "bar"
output::ok "Can close shell when no active shell is set"
