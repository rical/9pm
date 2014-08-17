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
    proc start {cmd} {
        if {![info exists ::9pm::shell::active]} {
            ::9pm::fatal ::9pm::output::user_error "You need a spawn to start \"$cmd\""
        }
        if {[dict exists $::9pm::shell::data($::9pm::shell::active) "running"]} {
            ::9pm::fatal ::9pm::output::user_error "Can't start, shell has command still running"
        }
        set checksum(start) "[::9pm::misc::get::rand_str 10][::9pm::misc::get::rand_int 1000]"
        set checksum(end) "[::9pm::misc::get::rand_str 10][::9pm::misc::get::rand_int 1000]"
        dict set ::9pm::shell::data($::9pm::shell::active) "running" $cmd
        dict set ::9pm::shell::data($::9pm::shell::active) "checksum" $checksum(end)

        expect *
        send "echo $checksum(start); $cmd; echo $checksum(end) \$?\n"
        expect {
            -timeout 10
            -re "\r\n$checksum(start)\r\n" {
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

        # Register expect after handler that will match the end checksum and break any expect block
        # upon command completion (after first handling the users expect blocks hence, "after").
        # This is what a users expect code might look like:
        #
        # start "command"
        # expect {
        #   "foo*" { lappend out $expect_out(0,string) }
        #   default { ::9pm::output::fail "Got eof or timeout" }
        # }
        # output::info "Got $out before command completion"
        # finish
        expect_after {
            -notransfer -re "$checksum(end) (\[0-9]+)\r\n" {
                # It's important to note that we are in the caller scope here,
                # so we need to be careful not to corrupt or pollute.
                ::9pm::output::debug "Got $expect_out(1,string) as return code for\
                    \"[dict get $::9pm::shell::data($::9pm::shell::active) "running"]\""
            }
        }
    }

    proc capture {} {
        set out [list]

        if {![info exists ::9pm::shell::active]} {
            ::9pm::fatal ::9pm::output::user_error "You need a spawn to capture output"
        }
        if {![dict exists $::9pm::shell::data($::9pm::shell::active) "running"]} {
            ::9pm::fatal ::9pm::output::user_error "Can't capture output, nothing running on this shell"
        }

        set cmd [dict get $::9pm::shell::data($::9pm::shell::active) "running"]
        set checksum [dict get $::9pm::shell::data($::9pm::shell::active) "checksum"]

        ::9pm::output::debug2 "\"$cmd\" capturing output unitl checksum $checksum"
        expect {
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
                        ::9pm::fatal ::9pm::output::error "Something went wrong when flushing output from the exp buffer"
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
        if {![dict exists $::9pm::shell::data($::9pm::shell::active) "running"]} {
            ::9pm::fatal ::9pm::output::user_error "Can't finish, nothing running on this shell"
        }

        set cmd [dict get $::9pm::shell::data($::9pm::shell::active) "running"]
        set checksum [dict get $::9pm::shell::data($::9pm::shell::active) "checksum"]

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
        dict unset ::9pm::shell::data($::9pm::shell::active) "running"
        dict unset ::9pm::shell::data($::9pm::shell::active) "checksum"
        return $code

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
