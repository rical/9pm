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

shell "localhost"

# Manually get the number of files in /
set checksum [get_rand_str 10]
send "echo \"$checksum \$(ls -1 / | wc -l)\"\n"
expect {
    -re "$checksum (\[0-9]+)\r\n" {
        set count $expect_out(1,string)
    }
    default {
        fatal result FAIL "Didn't get return code"
    }
}

# Get all the files into a list using execute
set lines [execute "ls -1 /"]

set msg "Capturing execute output"
if {[llength $lines] == $count} {
    result OK $msg
} else {
    result FAIL $msg
}

# Do a "manual" return code check
set lines [execute "ls /" 0]
result OK "Got zero return for \"ls /\""


execute "true"
if {${?} != 0} {
    fatal result FAIL "\$? not set to 0 for command \"true\""
}
execute "false"
if {${?} == 0} {
    fatal result FAIL "\$? set to 0 for command \"false\""
}
result OK "Execute return code variable \$? has sane values"
