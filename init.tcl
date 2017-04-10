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

package require yaml
package require cmdline
package provide 9pm::init 1.0

namespace eval ::9pm {
    set root_path [file normalize [file dirname [info script]]]
}
# We can't call other procedures in the 9pm:: namespace here
# as this is running early.
namespace eval ::9pm::core {
    proc parse_yaml {filename} {

        # Check that configuration file exists
        if {![file exists $filename]} {
            puts "ERROR:: Can't parse configuration \"$filename\" (file not found)"
            exit 2
        }

        set fp [open $filename r]
        set data [read $fp]
        close $fp

        return [::yaml::yaml2dict $data]
    }



    # Parse command line
    set options {
        {b.arg "" "Runtime database path"}
        {c.arg "" "Configuration file"}
        {l.arg "./log" "Logging base path"}
        {d "Output debug info and write exp_internal logfile"}
        {dd "Output debug2 info"}
        {t "Output TAP"}
    }
    if {[catch {array set cmdl [::cmdline::getoptions argv $options]}]} {
        puts [::cmdline::usage $options "- usage:"]
        exit 1
    }

    # Only keys in this dict are allowed in the 9pm rc. The values here are default values.
    dict set rc "ssh_opts" ""

    if {[file exists "~/.9pm.rc"]} {
        set rc [parse_yaml "~/.9pm.rc"]
    } else {
        set rc [parse_yaml "$::9pm::root_path/etc/9pm.rc"]
    }

    foreach {key val} $rc {
        set key [string tolower $key]

        if {[lsearch -nocase [dict keys $rc] $key] < 0} {
            puts "ERROR:: Invalid 9pm.rc option \"$key\""
            exit 2
        }
        dict set rc $key $val
    }
}

