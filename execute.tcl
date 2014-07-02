package provide 9pm::execute 1.0

proc execute {cmd args} {
    set out [list]
    set checksum(start) "[get_rand_str 10][get_rand_int 1000]"
    set checksum(end) "[get_rand_str 10][get_rand_int 1000]"
    set active FALSE

    upvar ? "code"

    output DEBUG "Executing \"$cmd\" $args"

    expect *
    send "echo $checksum(start); $cmd; echo $checksum(end) \$?\n"
    expect {
        -re {([^\r\n]+)\r\n} {
            set line $expect_out(0,string)
            set content $expect_out(1,string)

            if [regexp "$checksum(end) (\[0-9]+)\r\n" $line unused code] {
                output DEBUG "Got $code as returncode for \"$cmd\""
            } elseif [regexp "$checksum(start)\r\n" $line unused] {
                output DEBUG "Activating for \"$content\""
                set active TRUE
                exp_continue -continue_timer
            } else {
                if {$active} {
                    output DEBUG "Got: \"$content\""
                    lappend out $content
                }
                exp_continue -continue_timer
            }
        }
        timeout {
            fatal result FAIL "Timeout waitning for return code for \"$cmd\""
        }
        eof {
            fatal result FAIL "Got eof while wating for return code for \"$cmd\""
        }
    }

    if {([llength $args] > 0) && ([lsearch -exact $args $code] < 0)} {
        fatal result FAIL "Got non-expected return code $code for \"$cmd\""
    }
    return $out
}

