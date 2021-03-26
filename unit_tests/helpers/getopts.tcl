#!/usr/bin/tclsh
#
# Copyright (C) 2021 Richard Alpe <rical@highwind.se>
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

9pm::output::plan 3

proc foo {args} {
    set opts [9pm::misc::getopts $args "default" "abc" "timeout" 99]

    if {[dict get $opts "force"]} {
        output::ok "Bool test: force is set to true"
    } else {
        fatal output::fail "Bool test: force is not set to true"
    }

    if {[dict get $opts "timeout"] == 10} {
        output::ok "Value test: timeout set correctly"
    } else {
        fatal output::fail "Value test: timeout not set correctly"
    }

    if {[dict get $opts "default"] == "abc"} {
        output::ok "Default value test: set correctly"
    } else {
        fatal output::fail "Default value test: not set correctly"
    }
}

foo "timeout" "10" "force" TRUE

