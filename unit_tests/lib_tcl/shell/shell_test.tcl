#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm

output::plan 3

set MAX_SHELLS 10

proc check_pid {alias} {
    expect *
    send "echo \$\$\n"

    expect {
        -re {([0-9]+)\r\n} {
           if {[dict get $9pm::spawn::data($alias) "pid"] != $expect_out(1,string)} {
                fatal output::fail "Got different pid from shell then 9pm thinks it has" }
           }
        default { fatal output::fail "Did not see any pid from shell" }
    }
}

output::info "Creating $MAX_SHELLS shells before closing them"
for {set i 0} {$i < $MAX_SHELLS} {incr i} {
    shell::open $i
    check_pid $i
}
for {set i 0} {$i < $MAX_SHELLS} {incr i} {
    shell::close $i
}
output::ok "Having $MAX_SHELLS shells open at one time"

output::info "Creating $MAX_SHELLS again, reusing the old names"
for {set i 0} {$i < $MAX_SHELLS} {incr i} {
    shell::open $i
    check_pid $i
}
output::ok "Reusing all $MAX_SHELLS shells"

output::info "Trying to swap back to all $MAX_SHELLS open shells again"
for {set i 0} {$i < $MAX_SHELLS} {incr i} {
    shell::open $i
    check_pid $i
}
output::ok "Swapping back to all $MAX_SHELLS open shells"

