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

# Write a checksum (as INFO) to the logfile
set checksum [misc::get::rand_str 20]
output::info $checksum

# Here is the logfiles and links we want to check
lappend files "$::9pm::output::log_path/run.log"
lappend files "$::9pm::output::log_base/last/run.log"
lappend files "$::9pm::output::log_script/last/run.log"

# Now check that the info we wrote is in the logfile(s)
foreach f $files {
    set fp [open $f r]
    set data [read $fp]
    close $fp

    set result FALSE
    foreach line [split $data "\n"] {
        if {[string match "*$checksum*" $line]} {
            set result TRUE
        }
    }

    if {$result} {
        output::ok "Logifile: $f"
    } else {
        output::fail "Logifile $f"
    }
}

