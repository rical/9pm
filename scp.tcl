# Copyright (C) 2011-2014 Richard Alpe <rical@highwind.se>
#
# This file is part of 9pm.
#
# 9pm is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# 9pm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with 9pm.  If not, see <http://www.gnu.org/licenses/>.

package provide 9pm::scp 1.0

# Wee need Expect TODO: Check if it exists (gracefull error-out)
package require Expect

proc scp {direction node files dest args} {
    set IP      [get_req_node_info $node SSH_IP]
    set PROMPT  [get_req_node_info $node PROMPT]
    set PORT    [get_node_info $node SSH_PORT]
    set USER    [get_node_info $node SSH_USER]
    set KEYFILE [get_node_info $node SSH_KEYFILE]

    set opts [dict get $int::rc "ssh_opts"]
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
        fatal int::user_error "Unsupported scp direction \"$direction\""
    }

    output DEBUG "Scp \"$files\" $direction $host"

    start "$cmd"
    expect {
        -nocase "password" {
            send "[get_req_node_info $node SSH_PASS]\n"
            exp_continue
        }
        -re {(\S+)\s+100%} {
            output DEBUG "File \"$expect_out(1,string)\" transfered $direction $host"
            exp_continue -continue_timer
        }
        timeout {
            fatal result FAIL "Scp transfer of \"$files\" $direction $host (timeout)"
        }
        eof {
            fatal result FAIL "Scp transfer of \"$files\" $direction $host (eof)"
        }
    }
    set code [finish]
    if {$code != 0} {
        fatal result FAIL "Scp transfer $direction $IP (got non-zero return code ($code))"
    }
}
