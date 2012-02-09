#!/usr/bin/tclsh
package require 9pm

set MAX_SHELLS 256

proc open_and_close_shell {alias} {
    expect *
    send "echo \$\$\n"

    expect {
        -re {\r\n([0-9]+)\r\n} {
           if {![dict get $int::shell($int::active_shell) "pid"] == $expect_out(0,string)} {
                fatal result FAIL "Got different pid from shell then 9pm thinks it has" }
           }
        default { fatal result FAIL "Did not see any pid from shell" }
    }
}

output INFO "Creating $MAX_SHELLS shells before closing them"
for {set i 0} {$i < $MAX_SHELLS} {incr i} {
    shell $i
    open_and_close_shell $i
}
for {set i 0} {$i < $MAX_SHELLS} {incr i} {
    close_shell $i
}
result OK "Having $MAX_SHELLS shells open at one time"

output INFO "Creating $MAX_SHELLS again, reusing the old names"
for {set i 0} {$i < $MAX_SHELLS} {incr i} {
    shell $i
    open_and_close_shell $i
}
result OK "Reusing all $MAX_SHELLS shells"

output INFO "Trying to swap back to all $MAX_SHELLS open shells again"
for {set i 0} {$i < $MAX_SHELLS} {incr i} {
    shell $i
    open_and_close_shell $i
}
result OK "Swapping back to all $MAX_SHELLS open shells"

