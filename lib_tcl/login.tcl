package provide 9pm::login 1.0

if {[catch {package require Expect} result]} {
    puts "1..1"
    puts "not ok 1 - $result (please install it)"
    exit 1
}

namespace eval ::9pm::login {
    proc check {node args} {
        set PROMPT  [::9pm::misc::dict::require $node prompt]

        send "\n"
        expect {
            -notransfer -nocase {username} {
                ::9pm::output::debug "Not logged in (got $expect_out(0,string))"
                return FALSE
            }
            -notransfer -nocase {login} {
                ::9pm::output::debug "Not logged in (got $expect_out(0,string))"
                return FALSE
            }
            $PROMPT {
                ::9pm::output::debug "Got prompt $expect_out(0,string)"
                return TRUE
            }
            timeout {
                ::9pm::fatal ::9pm::output::fail "Didn't see login prompt or prompt (timeout)"
                return FALSE
            }
            eof {
                ::9pm::fatal ::9pm::output::fail "Didn't see login prompt or prompt (eof)"
                return FALSE
            }
        }
    }

    proc login {node args} {
        set PROMPT      [::9pm::misc::dict::require $node prompt]
        set USERNAME    [::9pm::misc::dict::require $node username]
        set PASSWORD    [::9pm::misc::dict::require $node password]
        set BANNER      [::9pm::misc::dict::get $node loginbanner]
        set HOSTNAME    [::9pm::misc::dict::get $node hostname]

        if {[check $node $args]} {
            if {$HOSTNAME != ""} {
                ::9pm::output::info "Already logged in to $HOSTNAME"
            } else {
                ::9pm::output::info "Already logged in"
            }
            return TRUE
        }

        expect {
            -nocase {username} {
                send "$USERNAME\n"
                ::9pm::output::debug "Sent username $USERNAME in resp to $expect_out(0,string))"
            }
            -notransfer -nocase {login} {
                send "$USERNAME\n"
                ::9pm::output::debug "Sent username $USERNAME in resp to $expect_out(0,string))"
            }
            timeout {
                ::9pm::fatal ::9pm::output::fail "Didn't see login prompt (timeout)"
            }
            eof {
                ::9pm::fatal ::9pm::output::fail "Didn't see login prompt (eof)"
            }
        }

        expect {
            -nocase {password} {
                send "$PASSWORD\n"
                ::9pm::output::debug "Sent password $PASSWORD in resp to $expect_out(0,string))"
            }
            timeout {
                ::9pm::fatal ::9pm::output::fail "Didn't see password prompt (timeout)"
            }
            eof {
                ::9pm::fatal ::9pm::output::fail "Didn't see password prompt (eof)"
            }
        }

        if {$BANNER != "" } {
            expect {
                $BANNER {
                    9pm::output::debug "Got login banner"
                }
                timeout {
                    ::9pm::fatal ::9pm::output::fail "Didn't see login banner (timeout)"
                }
                eof {
                    ::9pm::fatal ::9pm::output::fail "Didn't see login banner (eof)"
                }
            }
        }

        if {$HOSTNAME != ""} {
            ::9pm::output::info "Now logged in to $HOSTNAME"
        } else {
            ::9pm::output::info "Now logged in"
        }
    }
}
