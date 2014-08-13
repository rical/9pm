#!/usr/bin/tclsh
package require 9pm

proc check_name {expected} {
    if {$expected == [execute "echo \$name" 0]} {
        result OK "Base check for $expected"
    } else {
        result FAIL "Base check failed for $expected"
    }
}

proc inject {base depth} {
    set name "$base$depth"
    push_shell $name
    execute "export name=$name" 0
    if { $depth > 0 } {
        inject $base [expr $depth - 1]
    }
    check_name $name
    pop_shell
}

shell "base"
execute "export name=base" 0

check_name "base"
inject "subshell" 10
check_name "base"
