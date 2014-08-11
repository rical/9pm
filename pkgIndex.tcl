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

# We need tcl 8.5
if {![package vsatisfies [package provide Tcl] 8.5]} {
    puts "FATAL: 9pm needs TCL 8.5"
    return
}

# Library namespaces
namespace eval ::lib {namespace export *}

# The internal namespace
namespace eval ::int {namespace export *}

package ifneeded 9pm            1.0 [list source [file join $dir pkgAll.tcl]]
package ifneeded 9pm::output    1.0 [list source [file join $dir output.tcl]]
package ifneeded 9pm::setup     1.0 [list source [file join $dir setup.tcl]]
package ifneeded 9pm::config    1.0 [list source [file join $dir config.tcl]]
package ifneeded 9pm::execute   1.0 [list source [file join $dir execute.tcl]]
package ifneeded 9pm::helpers   1.0 [list source [file join $dir helpers.tcl]]
package ifneeded 9pm::scp       1.0 [list source [file join $dir scp.tcl]]
package ifneeded 9pm::ssh       1.0 [list source [file join $dir ssh.tcl]]
package ifneeded 9pm::init      1.0 [list source [file join $dir init.tcl]]
package ifneeded 9pm::shell     1.0 [list source [file join $dir shell.tcl]]
