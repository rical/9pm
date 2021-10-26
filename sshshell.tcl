# Copyright (C) 2021 Niklas Söderlund <niklas.soderlund@ragnatech.se>
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
#
package provide 9pm::sshshell 1.0
package require 9pm::spawn

namespace eval ::9pm::sshshell {
    proc create {node} {
        set hostname [::9pm::misc::dict::require $node hostname]
        set prompt   [::9pm::misc::dict::require $node prompt]
        set password [::9pm::misc::dict::get $node password]

        set pid [spawn "ssh" "$hostname"]
        if {$pid == 0} {
            ::9pm::fatal ::9pm::output::fail "Failled to connect to $hostname"
        }

        # Wait for prompt
        expect {
            $prompt {
                ::9pm::output::info "Connected to \"$hostname\""
                send "unset HISTFILE\n"
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

        return [list $spawn_id $pid]
    }

    proc open {alias node} {
        return [::9pm::spawn::open $alias "::9pm::sshshell::create {$node}"]
    }

    proc close {alias} {
        return [::9pm::spawn::close $alias]
    }

    proc push {alias node} {
        return [::9pm::spawn::push $alias "::9pm::sshshell::create {$node}"]
    }

    proc pop { } {
        return [::9pm::spawn::pop]
    }
}
