#!/usr/bin/tclsh
#
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

package require 9pm
namespace path ::9pm

output::plan 3

set MAX_SHELLS 10

proc check_pid {alias} {
    expect *
    send "echo \$\$\n"

    expect {
        -re {\r\n([0-9]+)\r\n} {
           if {[dict get $9pm::shell::data($alias) "pid"] != $expect_out(1,string)} {
                fatal output::fail "Got different pid from shell then 9pm thinks it has" }
           }
        default { fatal output::fail "Did not see any pid from shell" }
    }
}

output::info "Creating $MAX_SHELLS shells before closing them"
for {set i 0} {$i < $MAX_SHELLS} {incr i} {
    shell::open $i
    check_pid $i
}
for {set i 0} {$i < $MAX_SHELLS} {incr i} {
    shell::close $i
}
output::ok "Having $MAX_SHELLS shells open at one time"

output::info "Creating $MAX_SHELLS again, reusing the old names"
for {set i 0} {$i < $MAX_SHELLS} {incr i} {
    shell::open $i
    check_pid $i
}
output::ok "Reusing all $MAX_SHELLS shells"

output::info "Trying to swap back to all $MAX_SHELLS open shells again"
for {set i 0} {$i < $MAX_SHELLS} {incr i} {
    shell::open $i
    check_pid $i
}
output::ok "Swapping back to all $MAX_SHELLS open shells"

