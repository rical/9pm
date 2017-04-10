# Copyright (C) 2011-2017 Richard Alpe <rical@highwind.se>
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

package provide 9pm::db 1.0

namespace eval ::9pm::db {
    set dict {}

    namespace eval int {
        proc read {name1 name2 op} {
            variable enabled

            if {!$enabled} {
                9pm::output::warning "Database not configured, can't read $name1"
            }
        }

        proc update {name1 name2 op} {
            variable enabled

            if {!$enabled} {
                ::9pm::fatal 9pm::output::error "Database not configured, can't write $name1"
            }
            ::9pm::misc::write_file $::9pm::db::dict $::9pm::core::cmdl(b)
        }
    }

    if {$::9pm::core::cmdl(b) != ""} {
        set int::enabled TRUE
        if {![file exists $::9pm::core::cmdl(b)]} {
            ::9pm::fatal 9pm::output::error "Database file not found: $::9pm::core::cmdl(b)"
        }
        set dict [::9pm::misc::slurp_file $::9pm::core::cmdl(b)]
    } else {
        set int::enabled FALSE
    }

    trace add variable dict read 9pm::db::int::read
    trace add variable dict write 9pm::db::int::update
}
