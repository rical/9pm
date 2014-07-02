#!/usr/bin/tclsh
package require 9pm

shell "localhost"

# Manually get the number of files in /
set checksum [get_rand_str 10]
send "echo \"$checksum \$(ls -1 / | wc -l)\"\n"
expect {
    -re "$checksum (\[0-9]+)\r\n" {
        set count $expect_out(1,string)
    }
    default {
        fatal result FAIL "Didn't get return code"
    }
}

# Get all the files into a list using execute
set lines [execute "ls -1 /"]

set msg "Capturing execute output"
if {[llength $lines] == $count} {
    result OK $msg
} else {
    result FAIL $msg
}

# Do a "manual" return code check
set lines [execute "ls /" 0]
result OK "Got zero return for \"ls /\""


execute "true"
if {${?} != 0} {
    fatal result FAIL "\$? not set to 0 for command \"true\""
}
execute "false"
if {${?} == 0} {
    fatal result FAIL "\$? set to 0 for command \"false\""
}
result OK "Execute return code variable \$? has sane values"
