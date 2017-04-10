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

set TESTDATA_LINE_CNT 500

output::plan 9

shell::open "localhost"

output::info "Checking line count for execute"

set lines [cmd::execute "cat [misc::get::running_script_path]/testdata"]
if {[llength $lines] == $TESTDATA_LINE_CNT} {
    output::ok "Execute line count"
} else {
    output::fail "Execute line count"
}

output::info "Checking line count for start, capture and finish"

cmd::start "cat [misc::get::running_script_path]/testdata"
set lines [cmd::capture]
cmd::finish
if {[llength $lines] == $TESTDATA_LINE_CNT} {
    output::ok "Start, capture and finish line count"
} else {
    output::fail "Start, capture and finish line count"
}

output::info "Testing user expect block releasing"

cmd::start "cat [misc::get::running_script_path]/testdata"
expect {
    default {
        fatal output::fail "User expect block did not release for inner cmd"
    }
}
cmd::finish
if {[llength $lines] == $TESTDATA_LINE_CNT} {
    output::ok "User expect block release"
} else {
    output::fail "User expect block release"
}

output::info "Testing command nesting"

cmd::start "/bin/bash -norc"
set lines [cmd::execute "cat [misc::get::running_script_path]/testdata"]
send "exit\n"
cmd::finish

if {[llength $lines] == $TESTDATA_LINE_CNT} {
    output::ok "Execute line count for nested command"
} else {
    output::fail "Execute line count for nested command"
}

# Do a "manual" return code check
set lines [cmd::execute "ls /" 0]
output::ok "Got zero return for \"ls /\""

cmd::execute "true"
if {${?} != 0} {
    fatal output::fail "\$? not set to 0 for command \"true\""
}
cmd::execute "false"
if {${?} == 0} {
    fatal output::fail "\$? set to 0 for command \"false\""
}
output::ok "Execute return code variable \$? has sane values"

output::info "Testing command abort"
cmd::start "sleep 1337"
cmd::abort
# Check that shell still works
cmd::execute "true" 0
output::ok "Sleep command aborted"

output::info "Testing command discard"
cmd::start "true"
cmd::discard
# Check that shell still works
cmd::execute "true" 0
output::ok "Started command discarded"

# We use the existing shell to start a command that self terminates.
# This is to test that the expect_after is unregistered when swapping spawn,
# if not, the second spawn will see the return from the first and terminate.

output::info "Testing simultaneous commands that terminates"
cmd::start "echo \"ASTRING\""

shell::open "localhost2"
cmd::execute "ls /" 0

shell::open "localhost"
set output [cmd::capture]
if {$output != "ASTRING"} {
    fatal output::fail "Didn't see output of previously started command"
}
cmd::finish
output::ok "Simultaneous commands on different shells (expect_after)"
