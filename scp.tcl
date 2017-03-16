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

package provide 9pm::scp 1.0

# Wee need Expect TODO: Check if it exists (gracefull error-out)
package require Expect

namespace eval ::9pm::scp {
    proc put {node files dest args} {
        transfer "to" $node $files $dest {*}$args
    }

    proc get {node files dest args} {
        transfer "from" $node $files $dest {*}$args
    }

    proc transfer {direction node files dest args} {
        set IP      [::9pm::conf::get_req $node SSH_IP]
        set PROMPT  [::9pm::conf::get_req $node PROMPT]
        set PORT    [::9pm::conf::get $node SSH_PORT]
        set USER    [::9pm::conf::get $node SSH_USER]
        set PASS    [::9pm::conf::get $node SSH_PASS]
        set KEYFILE [::9pm::conf::get $node SSH_KEYFILE]

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
