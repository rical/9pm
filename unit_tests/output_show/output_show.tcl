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
namespace path ::9pm::

set outputs {
    info BLUE
    note CYAN
    debug GREY
    warning YELLOW
}

set results {
    ok GREEN
    fail RED
    skip YELLOW
}

puts "This is a normal puts (no timestamp)"

puts "\nThis is some non fatal errors"
output::error "This is a RED error"
output::user_error "This is a RED user error"
#fatal output::user_error "This is a RED fatal user error"

puts "\nIterating outputs"
foreach {out color} $outputs {
    output::$out "This is an $color \"$out\" message"
}

puts "\nIterating results"
foreach {res color} $results {
    output::$res "This is an $color $res message"
}

