#!/usr/bin/tclsh
package require 9pm
namespace path ::9pm

proc check_name {expected} {
    if {$expected == [cmd::execute "echo \$name" 0]} {
        output::ok "Base check for $expected"
    } else {
        output::fail "Base check failed for $expected"
    }
}

proc inject {base depth} {
    set name "$base$depth"
    shell::push $name
    cmd::execute "export name=$name" 0
    if { $depth > 0 } {
        inject $base [expr $depth - 1]
    }
    check_name $name
    shell::pop
}

shell::open "base"
cmd::execute "export name=base" 0

check_name "base"
# TODO: investigate why larger values here breaks the TCL interpreter on some machines
# alloc: invalid block: 0x1d630f0: 70 1
# Aborted
inject "subshell" 5
check_name "base"
