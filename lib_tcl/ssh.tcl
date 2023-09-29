package provide 9pm::ssh 1.0

if {[catch {package require Expect} result]} {
    puts "1..1"
    puts "not ok 1 - $result (please install it)"
    exit 1
}

namespace eval ::9pm::ssh {
    proc connect {node args} {
        set hostname [::9pm::misc::dict::require $node hostname]
        set prompt   [::9pm::misc::dict::require $node prompt]
        set port     [::9pm::misc::dict::get $node port]
        set username [::9pm::misc::dict::get $node username]
        set password [::9pm::misc::dict::get $node password]
        set keyfile  [::9pm::misc::dict::get $node keyfile]

        set opts [dict get $::9pm::core::rc "ssh_opts"]

        set ssh_cmd "ssh $opts $hostname"
        if {$username != ""} {
            append ssh_cmd " -l $username"
        }
        if {$port != ""} {
            append ssh_cmd " -p $port"
        }
        if {$keyfile != ""} {
            append ssh_cmd " -i $keyfile"
        }
        foreach arg $args {
            append ssh_cmd " $arg"
        }

        ::9pm::output::debug "Connecting to \"$hostname\""
        ::9pm::output::debug "Running: \"$ssh_cmd\""

        expect *
        send "$ssh_cmd\n"
        expect {
            $prompt {
                ::9pm::output::debug "Connected to \"$hostname\""
            }
            -nocase "password" {
                if {$password == ""} {
                    ::9pm::fatal ::9pm::output::fail \
                        "SSH got password prompt but no password is provided in config"
                }
                send "$password\n"
                exp_continue -continue_timer
            }
            timeout {
                ::9pm::fatal ::9pm::output::fail "SSH connection to \"$hostname\" failed (timeout)"
            }
            eof {
                ::9pm::fatal ::9pm::output::fail "SSH connection to \"$hostname\" failed (eof)"
            }
        }
    }
}
