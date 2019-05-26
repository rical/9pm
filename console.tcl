# Support for conserver i.e. "console - console server client program"
package provide 9pm::console 1.0

package require Expect

namespace eval ::9pm::console {
    proc connect {node args} {
        set PROMPT  [::9pm::misc::dict::require $node prompt]
        set CONSOLE [::9pm::misc::dict::require $node console]

        set flags "-v"
        if {[dict exist $::9pm::core::rc "console_opts"]} {
            set flags [concat $flags [dict get $::9pm::core::rc "console_opts"]]
        }
        if {$args != ""} {
            set flags [concat $flags $args]
        }

        set console_cmd "console $flags $CONSOLE"

        ::9pm::output::debug "Connecting console \"$CONSOLE\" (\"$console_cmd\")"

        expect *
        send "$console_cmd\n"

        expect {
            {Enter * for help} {
                ::9pm::output::debug "Started console \"$CONSOLE\""
            }
            timeout {
                ::9pm::fatal ::9pm::output::fail "Starting console \"$CONSOLE\" failed (timeout)"
            }
            eof {
                ::9pm::fatal ::9pm::output::fail "Starting console \"$CONSOLE\" failed (eof)"
            }
        }

        expect {
            -re {\[no, (.*) is attached\]} {
                ::9pm::output::warning "Read only console ($expect_out(1,string) attached)"
                exp_continue
            }
            -re {\[bumped (.*)\]} {
                ::9pm::output::warning "Bumped $expect_out(1,string) from console $CONSOLE"
                exp_continue
            }
            {\[\^R\]} {
                ::9pm::output::info "Connected to console \"$CONSOLE\""
            }
            timeout {
                ::9pm::fatal ::9pm::output::fail "Console connection \"$CONSOLE\" failed (timeout)"
            }
            eof {
                ::9pm::fatal ::9pm::output::fail "Console connection \"$CONSOLE\" failed (eof)"
            }
        }
    }
    proc disconnect {node} {
        set CONSOLE [::9pm::misc::dict::require $node console]

        send "\005"
        send "c"
        send "."
        expect {
            "Console $CONSOLE closed." {
                ::9pm::output::info "Disconnected from console \"$CONSOLE\""
            }
            timeout {
                ::9pm::fatal ::9pm::output::fail "Unable to disconnect console \"$CONSOLE\" (timeout)"
            }
            eof {
                ::9pm::fatal ::9pm::output::fail "Unable to disconnect console \"$CONSOLE\" (eof)"
            }
        }
    }
}
