#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm

set TESTDATA_LINE_CNT 500
set ABORT_CNT 100 ;# Arbitrary chosen to provoke an exotic race condition
set EXECUTE_CNT 1000 ;# Arbitrary chosen

output::plan 10

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

# This is intended to run a simple command as fast as possible to provoke
# a "prompt race", where a command is started before the prompt is ready
output::info "Testing fast looped execution ($EXECUTE_CNT times)"
for {set i 0} {$i < $ABORT_CNT} {incr i} {
    cmd::execute "true" 0
}
output::ok "Command executed $EXECUTE_CNT times"

# This loop intends to provoke a race. Even doing puts
# inside the loop can hide the potential race.
output::info "Testing command abort ($ABORT_CNT times)"
for {set i 0} {$i < $ABORT_CNT} {incr i} {
    cmd::start "sleep 1337"
    misc::msleep 10
    cmd::abort
    # Check that shell still works
    cmd::execute "true" 0
}
output::ok "Sleep command aborted $ABORT_CNT"

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
