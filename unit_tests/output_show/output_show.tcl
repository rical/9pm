#!/usr/bin/tclsh
#
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

package require 9pm

set outputs {
    INFO BLUE
    NOTE CYAN
    DEBUG GREY
    WARNING YELLOW
}

set results {
    OK GREEN
    FAIL RED
}

puts "This is a normal puts (no timestamp)"

puts "\nThis is some non fatal errors"
int::error "This is a RED error"
int::user_error "This is a RED user error"
#fatal int::error "This is a RED fatal user error"

puts "\nIterating outputs"
foreach {out color} $outputs {
    output $out "This is an $color \"$out\" message"
}

puts "\nIterating results"
foreach {res color} $results {
    result $res "This is an $color $res result"
}

