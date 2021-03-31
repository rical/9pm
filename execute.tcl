# Copyright (C) 2011-2014 Richard Alpe <rical@highwind.se>
#
# This file is part of 9pm.
#
# 9pm is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# 9pm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

package provide 9pm::execute 1.0

# Wee need Expect TODO: Check if it exists (gracefull error-out)
package require Expect

namespace eval ::9pm::cmd {
    # Datastructe looks like:
    # data(<shell>) cmd {{cmd cmd1 checksum 1234} {cmd cmd2 checksum 4321}}
    namespace eval int {
        set ABORT_RESET_ATTEMPTS 3
        set ABORT_GRACE_MS 10
        set ABORT_RESET_GRACE_MS 100

        proc gen_checksum {} {
            return "[::9pm::misc::get::rand_str 10][::9pm::misc::get::rand_int 1000]"
        }

        proc msleep { time } {
            after $time set end 1
            vwait end
        }

        proc unreg_exp_after {} {
            if {![info exists ::9pm::shell::active]} {
                return
            }
            # Unregister any existing expect_after clause for the current shell (spawn)
            expect_after
        }

        proc reg_exp_after {} {
            if {![cmd::is_running]} {
                return
            }
            set checksum [dict get [cmd::get_last] "checksum"]
            # Register expect after handler that will match the end checksum and break any expect
            # block upon command completion (after first handling the users expect blocks hence,
            # "after"). This is what a users expect code might look like:
            #
            # start "command"
            # expect {
            #   "foo*" { lappend out $expect_out(0,string) }
            #   default { ::9pm::output::fail "Got eof or timeout" }
            # }
            # output::info "Got $out before command completion"
            # finish
            expect_after {
                # It's important to note that we are in the caller scope here, so we need to be
                # careful not to corrupt or pollute. This also means we need to use variables that
                # are globally accessible.
                -notransfer -re "$checksum (\[0-9]+)\r\n" {
                    ::9pm::output::debug "Got $expect_out(1,string) as return code for\
                        [dict get [::9pm::cmd::int::cmd::get_last] "cmd"]"
                }
            }
        }
        namespace eval cmd {
            proc is_running {} {
                return [dict exists $::9pm::shell::data($::9pm::shell::active) "cmd"]
            }
            proc get_last {} {
                return [lindex [dict get $::9pm::shell::data($::9pm::shell::active) "cmd"] end]
            }
            proc cnt {} {
                return [llength [dict get $::9pm::shell::data($::9pm::shell::active) "cmd"]]
            }
            proc push {cmd checksum} {
                dict lappend ::9pm::shell::data($::9pm::shell::active) "cmd" \
                    [dict create "cmd" $cmd "checksum" $checksum]
            }
            proc pop {} {
                if {[cnt] == 1} {
                    dict unset ::9pm::shell::data($::9pm::shell::active) "cmd"
                } else {
                    dict set ::9pm::shell::data($::9pm::shell::active) "cmd"\
                        [lrange [dict get $::9pm::shell::data($::9pm::shell::active) "cmd"] 0 end-1]
                }
            }
        }
    }
    proc start {cmd args} {
        set opts [9pm::misc::getopts $args]

        if {![info exists ::9pm::shell::active]} {
            ::9pm::fatal ::9pm::output::user_error "You need a spawn to start \"$cmd\""
        }
        set checksum(start) [int::gen_checksum]
        set checksum(end) [int::gen_checksum]

        int::cmd::push $cmd $checksum(end)

        if {[int::cmd::cnt] == 1} {
            ::9pm::output::debug "Starting command \"$cmd\""
        } else {
            ::9pm::output::debug "Starting nested command \"$cmd\""
        }

        expect *
        set sendcmd "echo $checksum(start) \$\$; $cmd; echo $checksum(end) \$?\n"
        if {[dict exists $opts "send_slow"]} {
            set send_slow [dict get $opts "send_slow"]
            send -s $sendcmd
        } else {
            send $sendcmd
        }

        expect {
            -timeout 10
            -re "$checksum(start) (\[0-9]+)\r\n" {
                ::9pm::output::debug2 "\"$cmd\" started"
                ::9pm::output::debug2 "\"$cmd\" start checksum $checksum(start)"
                ::9pm::output::debug2 "\"$cmd\" end checksum $checksum(end)"
            }
            timeout {
                ::9pm::fatal ::9pm::output::fail "Timeout starting \"$cmd\""
            }
            eof {
                ::9pm::fatal ::9pm::output::fail "Got EOF while starting \"$cmd\""
            }
        }

        int::reg_exp_after
    }

    proc capture {args} {
        set opts [::9pm::misc::getopts $args "timeout" 10]

        set out [list]

        if {![info exists ::9pm::shell::active]} {
            ::9pm::fatal ::9pm::output::user_error "You need a spawn to capture output"
        }
        if {![int::cmd::is_running]} {
            ::9pm::fatal ::9pm::output::user_error "Can't capture output, nothing running on this shell"
        }

        set cmd_data [lindex [dict get $::9pm::shell::data($::9pm::shell::active) "cmd"] end]
        set cmd [dict get $cmd_data "cmd"]
        set checksum [dict get $cmd_data "checksum"]

        ::9pm::output::debug2 "\"$cmd\" capturing output unitl checksum $checksum"
        expect {
            -timeout [dict get $opts "timeout"]
            # We use notransfer so that we leave the checksum for "finnish"
            -notransfer -re {([^\r\n]+)\r\n} {
                set line $expect_out(0,string)
                set content $expect_out(1,string)

                if [regexp "$checksum (\[0-9]+)\r\n" $line unused code] {
                    ::9pm::output::debug2 "Capture hit end checksum for \"$cmd\""
                    return $out
                }

                # Now that we know it's not the checksum, we flush it from the buffer
                expect {
                    -re {[^\r\n]+\r\n} { }
                    default {
                        ::9pm::fatal ::9pm::output::error\
                            "Something went wrong when flushing output from the exp buffer"
                    }
                }

                lappend out $content
                ::9pm::output::debug "Got: \"$content\""
                exp_continue -continue_timer
            }
            timeout {
                ::9pm::fatal ::9pm::output::fail "Timeout while capturing output for \"$cmd\""
            }
            eof {
                ::9pm::fatal ::9pm::output::fail "Got EOF while waiting on return code for \"$cmd\""
            }
        }
    }

    proc finish {} {
        if {![info exists ::9pm::shell::active]} {
            ::9pm::fatal ::9pm::output::user_error "Can't finish, no active spawn"
        }
        if {![int::cmd::is_running]} {
            ::9pm::fatal ::9pm::output::user_error "Can't finish, nothing running on this shell"
        }

        set last [int::cmd::get_last]
        set cmd [dict get $last "cmd"]
        set checksum [dict get $last "checksum"]

        expect {
            -re "$checksum (\[0-9]+)\r\n" {
                set code $expect_out(1,string)
            }
            timeout {
                ::9pm::fatal ::9pm::output::fail "Timeout waiting for return code for \"$cmd\""
            }
            eof {
                ::9pm::fatal ::9pm::output::fail "Got eof while wating for return code for \"$cmd\""
            }

        }

        int::cmd::pop
        return $code
    }

    # Discard a running command, usefull when for example rebooting
    proc discard {} {
        set last [int::cmd::get_last]
        set cmd [dict get $last "cmd"]
        set checksum [dict get $last "checksum"]

        ::9pm::output::debug "Discarding start of \"$cmd\" ($checksum)"
        int::cmd::pop
    }

    # Abort a running command by sending a ctrl key "key" and expecting a termination string "out"
    proc abort {{key "\003"} {out {\^C}}} {
        if {![info exists ::9pm::shell::active]} {
            ::9pm::fatal ::9pm::output::user_error "Can't abort, no active spawn"
        }
        if {![int::cmd::is_running]} {
            ::9pm::fatal ::9pm::output::user_error "Can't abort, nothing running on this shell"
        }
        set last [int::cmd::get_last]
        set cmd [dict get $last "cmd"]
        set checksum [dict get $last "checksum"]

        ::9pm::output::debug "Aborting \"$cmd\" (discarding $checksum)"

        set reset FALSE
        for {set i 0} {$i < $int::ABORT_RESET_ATTEMPTS} {incr i} {
            send $key
            expect {
                $out {
                    ::9pm::output::debug "Successfully aborted \"$cmd\" (got \"$out\")"
                }
                default {
                    ::9pm::fatal ::9pm::output::fail \
                        "Unable to abort \"$cmd\", didn't see \"$out\""
                }
            }
            int::msleep $int::ABORT_GRACE_MS

            send "echo ABORT-RESET$i\n"
            expect {
                -timeout 1
                "\r\nABORT-RESET$i" {
                    set reset TRUE
                    break
                }
                default {
                    ::9pm::output::debug "Console unresponsive, trying again"
                    int::msleep $int::ABORT_RESET_GRACE_MS
                }
            }
        }

        if {!$reset} {
            ::9pm::fatal ::9pm::output::fail "Unable to abort \"$cmd\", unable to reset"
        }

        int::cmd::pop
    }

    proc execute {cmd args} {
        upvar ? "code"

        ::9pm::output::debug "Executing \"$cmd\" $args"

        start $cmd
        set out [capture]
        set code [finish]

        ::9pm::output::debug "Execution of \"$cmd\" returned $code with [llength $out] lines of output"

        if {([llength $args] > 0) && ([lsearch -exact $args $code] < 0)} {
            ::9pm::fatal ::9pm::output::fail "Got non-expected return code $code for \"$cmd\""
        }
        return $out
    }
}
