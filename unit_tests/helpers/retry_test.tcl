#!/usr/bin/tclsh
#
# Copyright (C) 2015 Niklas Söderlund <niso@kth.se>
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

proc count {val times} {
    set i 0
    return [9pm::misc::retry $times 1 {
        incr i
        expr {$i == $val}
    }]
}

proc test_count {val times expected} {
    if {$expected} {
        set msg "Count to $val in $times cycles"
    } else {
        set msg "Fail to count to $val in $times cycles"
    }

    if {[count $val $times] != $expected} {
        fatal output::fail "$msg"
    }

    output::ok $msg
}

proc runtime {wait times delay} {
    set end [expr {[::9pm::misc::get::unix_time] + $wait}]
    return [9pm::misc::retry $times $delay {
        expr {[::9pm::misc::get::unix_time] >= $end}
    }]
}

proc test_runtime {wait times delay expected} {
    if {$expected} {
        set msg "Run $wait seconds in $times cycles and $delay second delay"
    } else {
        set msg "Fail to run $wait seconds in $times cycles and $delay second delay"
    }

    if {[runtime $wait $times $delay] != $expected} {
        fatal output::fail $msg
    }

    output::ok $msg
}

output::plan 6

shell::open "localhost"

test_count 1 5 TRUE
test_count 4 5 TRUE
test_count 9 5 FALSE

test_runtime 3 5 1 TRUE
test_runtime 10 3 5 TRUE
test_runtime 10 5 1 FALSE
