package provide 9pm::execute 1.0

proc start {cmd} {
    if {![info exists int::active_shell]} {
        fatal int::user_error "You need a spawn to start \"$cmd\""
    }
    if {[dict exists $int::shell($int::active_shell) "running"]} {
        fatal int::user_error "Can't start, shell has command still running"
    }
    set checksum(start) "[get_rand_str 10][get_rand_int 1000]"
    set checksum(end) "[get_rand_str 10][get_rand_int 1000]"
    dict set int::shell($int::active_shell) "running" $cmd
    dict set int::shell($int::active_shell) "checksum" $checksum(end)

    expect *
    send "echo $checksum(start); $cmd; echo $checksum(end) \$?\n"
    expect {
        -timeout 10
        -re "\r\n$checksum(start)\r\n" {
            output DEBUG2 "\"$cmd\" started"
            output DEBUG2 "\"$cmd\" start checksum $checksum(start)"
            output DEBUG2 "\"$cmd\" end checksum $checksum(end)"
        }
        timeout {
            fatal result FAIL "Timeout starting \"$cmd\""
        }
        eof {
            fatal result FAIL "Got EOF while starting \"$cmd\""
        }
    }

    # Register expect after handler that will match the end checksum and break any expect block
    # upon command completion (after first handling the users expect blocks hence, "after").
    # This is what a users expect code might look like:
    #
    # start "command"
    # expect {
    #   "foo*" { lappend out $expect_out(0,string) }
    #   default { result FAIL "Got eof or timeout" }
    # }
    # output INFO "Got $out before command completion"
    # finish
    expect_after {
        -notransfer -re "$checksum(end) (\[0-9]+)\r\n" {
            # It's important to note that we are in the caller scope here,
            # so we need to be careful not to corrupt or pollute.
            output DEBUG "Got $expect_out(1,string) as return code for\
                \"[dict get $int::shell($int::active_shell) "running"]\""
        }
    }
}

proc capture {} {
    set out [list]

    if {![info exists int::active_shell]} {
        fatal int::user_error "You need a spawn to capture output"
    }
    if {![dict exists $int::shell($int::active_shell) "running"]} {
        fatal int::user_error "Can't capture output, nothing running on this shell"
    }

    set cmd [dict get $int::shell($int::active_shell) "running"]
    set checksum [dict get $int::shell($int::active_shell) "checksum"]

    output DEBUG2 "\"$cmd\" capturing output unitl checksum $checksum"
    expect {
        # We use notransfer so that we leave the checksum for "finnish"
        -notransfer -re {([^\r\n]+)\r\n} {
            set line $expect_out(0,string)
            set content $expect_out(1,string)

            if [regexp "$checksum (\[0-9]+)\r\n" $line unused code] {
                output DEBUG2 "Capture hit end checksum for \"$cmd\""
                return $out
            }

            # Now that we know it's not the checksum, we flush it from the buffer
            expect {
                -re {[^\r\n]+\r\n} { }
                default {
                    fatal int::error "Something went wrong when flushing output from the exp buffer"
                }
            }

            lappend out $content
            output DEBUG "Got: \"$content\""
            exp_continue -continue_timer
        }
        timeout {
            fatal result FAIL "Timeout while capturing output for \"$cmd\""
        }
        eof {
            fatal result FAIL "Got EOF while waiting on return code for \"$cmd\""
        }
    }
}

proc finish {} {
    if {![info exists int::active_shell]} {
        fatal int::user_error "Can't finish, no active spawn"
    }
    if {![dict exists $int::shell($int::active_shell) "running"]} {
        fatal int::user_error "Can't finish, nothing running on this shell"
    }

    set cmd [dict get $int::shell($int::active_shell) "running"]
    set checksum [dict get $int::shell($int::active_shell) "checksum"]

    expect {
        -re "$checksum (\[0-9]+)\r\n" {
            set code $expect_out(1,string)
        }
        timeout {
            fatal result FAIL "Timeout waiting for return code for \"$cmd\""
        }
        eof {
            fatal result FAIL "Got eof while wating for return code for \"$cmd\""
        }

    }
    dict unset int::shell($int::active_shell) "running"
    dict unset int::shell($int::active_shell) "checksum"
    return $code

}

proc execute {cmd args} {
    upvar ? "code"

    output DEBUG "Executing \"$cmd\" $args"

    start $cmd
    set out [capture]
    set code [finish]

    output DEBUG "Execution of \"$cmd\" returned $code with [llength $out] lines of output"

    if {([llength $args] > 0) && ([lsearch -exact $args $code] < 0)} {
        fatal result FAIL "Got non-expected return code $code for \"$cmd\""
    }
    return $out
}

