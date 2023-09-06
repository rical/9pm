package provide 9pm::scp 1.0

if {[catch {package require Expect} result]} {
    puts "1..1"
    puts "not ok 1 - $result (please install it)"
    exit 1
}

namespace eval ::9pm::scp {
    proc put {node files dest args} {
        transfer "to" $node $files $dest {*}$args
    }

    proc get {node files dest args} {
        transfer "from" $node $files $dest {*}$args
    }

    proc transfer {direction node files dest args} {
        set IP      [::9pm::misc::dict::require $node hostname]
        set PORT    [::9pm::misc::dict::get $node port]
        set USER    [::9pm::misc::dict::get $node username]
        set PASS    [::9pm::misc::dict::get $node password]
        set KEYFILE [::9pm::misc::dict::get $node keyfile]

        set opts [dict get $::9pm::core::rc "ssh_opts"]
        set cmd "scp $opts"

        if {$PORT != ""} {
            append cmd " -P $PORT"
        }
        if {$KEYFILE != ""} {
            append cmd " -i $KEYFILE"
        }
        if {$args != ""} {
            append cmd " $args"
        }

        set host [expr {($USER != "") ? "$USER@$IP" : "$IP"}]

        if {$direction == "from"} {
            append cmd " $host:\"$files\" $dest"
        } elseif {$direction == "to"} {
            append cmd " $files $host:$dest"
        } else {
            ::9pm::fatal ::9pm::output::user_error "Unsupported scp direction \"$direction\""
        }

        ::9pm::output::debug "Scp \"$files\" $direction $host"

        ::9pm::cmd::start "$cmd"
        expect {
            -nocase "password" {
                if {$PASS == ""} {
                    ::9pm::fatal ::9pm::output::fail \
                        "SSH got password prompt but no password is provided in config"
                }
                send "$PASS\n"
                exp_continue
            }
            -re {(\S+)\s+(\d+)%\s+(\d+[^ ]+)\s+(\d+\.\d+)} {
                set progress $expect_out(2,string)
                set speed $expect_out(4,string)
                ::9pm::output::debug2 "File \"$expect_out(1,string)\" progress $progress%"
                if {$progress == 100} {
                    ::9pm::output::debug "File \"$expect_out(1,string)\" transfered $direction $host"
                    exp_continue -continue_timer
                } elseif {$speed > 0.0} {
                    exp_continue
                } else {
                    exp_continue -continue_timer
                }
            }
            timeout {
                ::9pm::fatal ::9pm::output::fail "Scp transfer of \"$files\" $direction $host (timeout)"
            }
            eof {
                ::9pm::fatal ::9pm::output::fail "Scp transfer of \"$files\" $direction $host (eof)"
            }
        }
        set code [::9pm::cmd::finish]
        if {$code != 0} {
            ::9pm::fatal ::9pm::output::fail "Scp transfer $direction $IP (got non-zero return code ($code))"
        }
    }
}
