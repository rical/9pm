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

if {[catch {package require yaml} result]} {
    puts "1..1"
    puts "not ok 1 - $result (please install it)"
    exit 1
}

output::plan 2

if {![info exists ::9pm::conf::data]} {
    fatal output::error "Can't test configurations, no configuration given"
}

set fp [open $::9pm::core::cmdl(c) r]
set config_data [read $fp]
close $fp

# Parse the YAML file.
set config [::yaml::yaml2dict $config_data]

set msg "Checking the integrity for the parsed configuration"
if {$::9pm::conf::data == $config} {
    output::ok $msg
} else {
    output::fatal $msg
}

# Test the get_node info functions
set fail FALSE
foreach elem [dict keys $config] {
    foreach {dkey dval} [dict get $config $elem] {
        set node_info [conf::get $elem $dkey]
        if {$node_info != $dval} {
            set fail TRUE
        }
    }
}
set msg "Iterating all node configurations and testing: get_node_info"
if {$fail} {
    output::fail $msg
} else {
    output::ok $msg
}
