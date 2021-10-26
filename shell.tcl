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

package provide 9pm::shell 1.0
package require 9pm::spawn

namespace eval ::9pm::shell {
    namespace eval spawn {
        proc create {shell} {
            set ::env(HISTFILE) "/dev/null"

            set pid [spawn {*}$shell]
            return [list $spawn_id $pid]
        }

        proc open {alias {shell "/bin/bash -norc"}} {
            return [::9pm::spawn::open $alias "::9pm::shell::spawn::create {$shell}"]
        }

        proc close {alias} {
            return [::9pm::spawn::close $alias]
        }

        proc push {alias shell} {
            return [::9pm::spawn::push $alias "::9pm::shell::spawn::create {$shell}"]
        }

        proc pop { } {
            return [::9pm::spawn::pop]
        }
    }

    proc open {alias {shell "/bin/bash -norc"}} {
        return [::9pm::shell::spawn::open $alias $shell]
    }

    proc close {alias} {
        return [::9pm::shell::spawn::close $alias]
    }

    proc push {alias} {
        return [::9pm::shell::spawn::push $alias "/bin/bash -norc"]
    }

    proc pop { } {
        return [::9pm::shell::spawn::pop]
    }
}
