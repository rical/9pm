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

package provide 9pm::helpers 1.0

# Get and return the current time in human readable form
proc get_time {} {
    return [clock format [clock seconds] -format {%Y %m %d - %H:%M:%S}]
}

# Get and return the current unix time-stamp
proc get_unix_time {} {
    return [clock format [clock seconds] -format {%s}]
}

# Return a random number between 0 and <max>
proc get_rand_int {max} {
    return [expr int(rand()*$max)]
}

# Return a random string with length <length>
proc get_rand_str {length} {
    return [subst [string repeat {[format %c [expr {97 + int(rand() * 26)}]]} $length]]
}

# This gets the path of the running script
proc get_running_script_path {} {
    return [file dirname [info script]]
}

# This gets the running scripts name
proc get_running_script_name {} {
    return [lindex [split [info script] "/"] [expr [llength [split [info script] "/"]] -1]]
}

# Get the called script path
proc get_script_path {} {
    global argv0
    set old_pwd [pwd]
    cd [file dirname $argv0]
    set script_path [pwd]
    cd $old_pwd
    return $script_path
}

# Get the called script name
proc get_script_name {} {
    global argv0
    return [lindex [split $argv0 "/"] [expr [llength [split $argv0 "/"]] -1]]
}

# This will prepend a path to a list of files
proc prepend_path {path filelist} {
    foreach elem $filelist {
        lappend result [file join $path $elem]
    }
    return $result
}
