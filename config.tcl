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

package provide 9pm::config 1.0
package require 9pm::helpers
package require 9pm::output

namespace eval ::9pm::conf {

    # Read config file upon sourcing
    if {$::9pm::core::cmdl(c) != ""} {
        ::9pm::output::debug "Using configuration: $::9pm::core::cmdl(c)"
        set data [::9pm::core::parse_yaml $::9pm::core::cmdl(c)]
    } else {
        ::9pm::output::debug "Running without configuration"
    }

    proc expand {var} {
        # Define substitution $variables
        set config [file normalize [file dirname $::9pm::core::cmdl(c)]]

        set var [string map [list "<config>" $config] $var]

        return $var
    }

    proc get {args} {
        variable data

        if {![info exists data]} {
            ::9pm::fatal ::9pm::output::fail "Requires an configuration"
        }

        set node $data
        foreach arg $args {
            if {[dict exists $node $arg]} {
                set node [dict get $node $arg]
            } else {
                ::9pm::fatal ::9pm::output::error "No configuration data found for node \"$arg\""
            }
        }
        return $node
    }
}
