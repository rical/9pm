package provide 9pm::ssh 1.0

# Wee need Expect TODO: Check if it exists (gracefull error-out)
package require Expect

namespace eval ::9pm::ssh {
    namespace eval spawn {
        proc create {node} {
            set pid [spawn {*}[::9pm::ssh::build_cmd $node]]
            if {$pid == 0} {
                ::9pm::fatal ::9pm::output::fail "Failled to connect to spawn for ssh"
            }

            ::9pm::ssh::login $node $spawn_id
            send "unset HISTFILE\n"

            return [list $spawn_id $pid]
        }

        proc open {alias node} {
            return [::9pm::spawn::open $alias "::9pm::ssh::spawn::create {$node}"]
        }

        proc close {alias} {
            return [::9pm::spawn::close $alias]
        }

        proc push {alias node} {
            return [::9pm::spawn::push $alias "::9pm::ssh::spawn::create {$node}"]
        }

        proc pop { } {
            return [::9pm::spawn::pop]
        }
    }

    proc build_cmd {node args} {
        set hostname [::9pm::misc::dict::require $node hostname]
        set port     [::9pm::misc::dict::get $node port]
        set username [::9pm::misc::dict::get $node username]
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
        if {$args != "" && $args != "{}"} {
            append ssh_cmd " $args"
        }

        return $ssh_cmd
    }

    proc login {node spawnid} {
        set hostname [::9pm::misc::dict::require $node hostname]
        set prompt   [::9pm::misc::dict::require $node prompt]
        set password [::9pm::misc::dict::get $node password]

        ::9pm::output::debug "Connecting to \"$hostname\""

        expect {
            -i $spawnid
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

    proc connect {node args} {
        global spawn_id

        expect *
        send "[::9pm::ssh::build_cmd $node $args]\n"
        ::9pm::ssh::login $node $spawn_id
    }
}
