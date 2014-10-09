#!/usr/bin/tclsh
package require 9pm
namespace path ::9pm

output::plan 8

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
    shell::close $name
}

shell::open "base"
cmd::execute "export name=base" 0

check_name "base"
inject "subshell" 5
check_name "base"
