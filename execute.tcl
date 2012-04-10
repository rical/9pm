package provide 9pm::execute 1.0

proc execute {cmd args} {
    set out [list]
    set checksum "[get_rand_str 10][get_rand_int 1000]"

    output DEBUG "Executing \"$cmd\" $args"
    send "$cmd; echo $checksum \$?\n"

    expect {
        -re {[^\r\n]+} {
            set line $expect_out(0,string)
            output DEBUG "Got line: \"$line\""

            if [regexp "$checksum (\[0-9]+)" $line unused code] {
                output DEBUG "Got $code as returncode for \"$cmd\""
            } elseif [string match "*echo $checksum*" $line] {
                exp_continue -continue_timer
            } else {
                lappend out $line
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

