#!/usr/bin/tclsh
#
# Copyright (C) 2011-2017 Richard Alpe <rical@highwind.se>
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

output::plan 2

output::info "Checking database content"
if {[dict get $9pm::db::dict "spoon"] == "There is no spoon"} {
    output::ok "Database content: There is no spoon"
} else {
    output::fail "Database content: There is no spoon"
}

if {[dict get $9pm::db::dict "pill"] == "Take the red pill"} {
    output::ok "Database content: Take the red pill"
} else {
    output::fail "Database content: Take the red pill"
}
