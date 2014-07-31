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

proc shell {alias} {
    global spawn_id

    # Write console output to logfile
    log_file ;#Stop any old logging
    log_file -a "$int::log_path/${alias}_console.log"

    if {[info exists int::shell($alias)]} {
        output DEBUG "Now looking at shell: $alias"
        set spawn_id [dict get $int::shell($alias) "spawn_id"]
    } else {
        output DEBUG "Spawning new shell: \"$alias\""
        set pid [spawn "/bin/bash"]

        if {$pid == 0} {
            fatal int::error "Failed to spawn shell \"$alias\""
        }

        dict append int::shell($alias) "spawn_id" $spawn_id
        dict append int::shell($alias) "pid" $pid
    }

    set int::active_shell $alias
    return TRUE
}

proc close_shell {alias} {
    if {![info exists int::shell($alias)]} {
        fatal int::user_error "Trying to close shell \"$alias\" that doesn't exist"
    }

    output DEBUG "Closing shell: $alias"
    close -i [dict get $int::shell($alias) "spawn_id"]

    # Remove it from internal data structure and stop logging
    unset int::shell($alias)
    if {$alias == $int::active_shell} {
        output DEBUG "Closing active shell, have no new active shell"
        unset int::active_shell
    }
    log_file
}

proc push_shell {alias} {
    lappend int::shellstack $int::active_shell
    return [shell $alias]
}

proc pop_shell { } {
    if {[llength $int::shellstack] == 0} {
        fatal int::user_error "Can not pop shell stack, it is empty!"
    }
    set alias [lindex $int::shellstack end]
    set int::shellstack [lreplace $int::shellstack [set int::shellstack end] end]
    return [shell $alias]
}

