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

namespace eval ::9pm::shell {
    proc open {alias} {
        global spawn_id
        variable data
        variable active

        # Write console output to logfile
        log_file ;#Stop any old logging
        log_file -a "$::9pm::output::log_path/${alias}_console.log"

        if {[info exists data($alias)]} {
            ::9pm::output::debug "Now looking at shell: $alias"
            set spawn_id [dict get $data($alias) "spawn_id"]
        } else {
            ::9pm::output::debug "Spawning new shell: \"$alias\""
            set ::env(HISTFILE) "/dev/null"
            set pid [spawn "/bin/bash"]

            if {$pid == 0} {
                ::9pm::fatal ::9pm::output::error "Failed to spawn shell \"$alias\""
            }

            dict append data($alias) "spawn_id" $spawn_id
            dict append data($alias) "pid" $pid
        }

        set active $alias
        return TRUE
    }

    proc close {alias} {
        variable data
        variable active

        if {![info exists data($alias)]} {
            ::9pm::fatal ::9pm::output::user_error "Trying to close shell \"$alias\" that doesn't exist"
        }

        # Unset active shell if that is the one we are closing
        if {[info exists active] && ($active == $alias)} {
            ::9pm::output::debug "Closing active shell: $alias"
            unset active
        } else {
            ::9pm::output::debug "Closing shell: $alias"
        }

        ::close -i [dict get $data($alias) "spawn_id"]

        # Remove it from internal data structure and stop logging
        unset data($alias)
        log_file
    }

    proc push {alias} {
        variable active
        variable stack

        if {![info exists active]} {
            ::9pm::fatal ::9pm::output::user_error "You need to have a shell in order to push it"
        }
        lappend stack $active
        return [::9pm::shell::open $alias]
    }

    proc pop { } {
        variable active
        variable stack

        if {[llength $stack] == 0} {
            ::9pm::fatal ::9pm::output::user_error "Can't pop shell, stack is empty"
        }
        set alias [lindex $stack end]
        set stack [lreplace $stack [set stack end] end]
        return [::9pm::shell::open $alias]
    }
}
