package provide 9pm::ssh 1.0

# Wee need Expect TODO: Check if it exists (gracefull error-out)
package require Expect


namespace eval ::9pm::ssh {
    proc connect {node args} {
        set IP      [::9pm::misc::dict::require $node hostname]
        set PROMPT  [::9pm::misc::dict::require $node prompt]
        set PORT    [::9pm::misc::dict::get $node port]
        set USER    [::9pm::misc::dict::get $node username]
        set PASS    [::9pm::misc::dict::get $node password]
        set KEYFILE [::9pm::misc::dict::get $node keyfile]

        set opts [dict get $::9pm::core::rc "ssh_opts"]

        set ssh_cmd "ssh $opts $IP"
        if {$USER != ""} {
            append ssh_cmd " -l $USER"
        }
        if {$PORT != ""} {
            append ssh_cmd " -p $PORT"
        }
        if {$KEYFILE != ""} {
            append ssh_cmd " -i $KEYFILE"
        }
        if {$args != ""} {
            append ssh_cmd " $args"
        }

        ::9pm::output::debug "Connecting to \"$IP\" (as \"$USER\")"

        expect *
        send "$ssh_cmd\n"
        expect {
            $PROMPT {
                ::9pm::output::debug "Connected to \"$IP\" (as \"$USER\")"
            }
            -nocase "password" {
                if {$PASS == ""} {
                    ::9pm::fatal ::9pm::output::fail \
                        "SSH got password prompt but no password is provided in config"
                }
                send "$PASS\n"
                exp_continue -continue_timer
            }
            timeout {
                ::9pm::fatal ::9pm::output::fail "SSH connection to \"$IP\" failed (timeout)"
            }
            eof {
                ::9pm::fatal ::9pm::output::fail "SSH connection to \"$IP\" failed (eof)"
            }
        }
    }
}
