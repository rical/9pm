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

package require yaml
package require 9pm

if {![info exists int::config]} {
    fatal int::error "Can't test configurations, no configuration given"
}

set fp [open $int::cmdl(c) r]
set config_data [read $fp]
close $fp

# Parse the YAML file.
set config [::yaml::yaml2dict $config_data]

set msg "Checking the integrity for the parsed configuration"
if {$int::config == $config} {
    result OK $msg
} else {
    result FATAL $msg
}

# Test the get_node info functions
set fail FALSE
foreach elem [dict keys $config] {
    foreach {dkey dval} [dict get $config $elem] {
        set node_info [get_node_info $elem $dkey]
        if {$node_info != $dval} {
            set fail TRUE
        }
    }
}
set msg "Iterating all node configurations and testing: get_node_info"
if {$fail} {
    result FAIL $msg
} else {
    result OK $msg
}

# Test the get_req_node info functions (note: this is a fatal proc)
foreach elem [dict keys $config] {
    foreach {dkey dval} [dict get $config $elem] {
        get_req_node_info $elem $dkey
    }
}
result OK "Iterating all node configurations and testing: get_req_node_info"
