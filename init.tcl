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
    proc parse_rc {} {
        variable rc

        # Only keys in this dict are allowed in the 9pm rc
        lappend allowed "ssh_opts" "console_opts" "log_path"

        if {[file exists "~/.9pm.rc"]} {
            set rc_raw [parse_yaml "~/.9pm.rc"]
        } else {
            set rc_raw [parse_yaml "$::9pm::root_path/etc/9pm.rc"]
        }

        set rc {}
        foreach {key val} $rc_raw {
            set key [string tolower $key]

            if {[lsearch -nocase $allowed $key] < 0} {
                puts "ERROR:: Invalid 9pm.rc option \"$key\""
                exit 2
            }
            dict set rc $key $val
        }
    }
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

    parse_rc

    # Parse command line
    set options {
        {b.arg "" "Runtime database path"}
        {c.arg "" "Configuration file"}
        {l.arg "" "Logging base path"}
        {s.arg "" "Scratch dir path"}
        {d "Output debug info and write exp_internal logfile"}
        {dd "Output debug2 info"}
        {t "Output TAP"}
    }
    if {[catch {array set cmdl [::cmdline::getoptions argv $options]}]} {
        puts [::cmdline::usage $options "- usage:"]
        exit 1
    }

    if {[::info exists ::env(NINEPM_DATABASE)] && $cmdl(b) == ""} {
        array set cmdl [list "b" $::env(NINEPM_DATABASE)]
    }
    if {[::info exists ::env(NINEPM_CONFIG)] && $cmdl(c) == ""} {
        array set cmdl [list "c" $::env(NINEPM_CONFIG)]
    }
    if {[::info exists ::env(NINEPM_LOG_PATH)] && $cmdl(l) == ""} {
        array set cmdl [list "l" $::env(NINEPM_LOG_PATH)]
    }
    if {[::info exists ::env(NINEPM_SCRATCHDIR)] && $cmdl(s) == ""} {
        array set cmdl [list "s" $::env(NINEPM_SCRATCHDIR)]
    }
    if {[::info exists ::env(NINEPM_DEBUG)]} {
        array set cmdl [list "d" TRUE]
    }
    if {[::info exists ::env(NINEPM_DEBUG2)]} {
        array set cmdl [list "dd" TRUE]
    }
    if {[::info exists ::env(NINEPM_TAP)]} {
        array set cmdl [list "t" TRUE]
    }

    if {[dict exists $rc "log_path"] && $cmdl(l) == ""} {
        array set cmdl [list "l" [dict get $rc "log_path"]]
    }
}

