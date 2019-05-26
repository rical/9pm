#!/usr/bin/tclsh

package require 9pm

9pm::output::plan 3

9pm::shell::open "localhost"

# Execute a command that should succeed.
# This is useful when you just want to execute something and make sure it succeeds.
# NOTE: The last 0 is the expected return code of the executed command.
set hostname [9pm::cmd::execute "hostname" 0]
9pm::output::ok "Got hostname \"$hostname\""

# Execute a command and check the result.
# This is useful when you just want to test to execute something and check the return code.
9pm::cmd::execute "false"
if {${?} != 0} {
    9pm::output::ok "False failed as expected"
} else {
    9pm::fatal 9pm::output::fail "False did not return failure"
}

# Start, capture and finish.
# This might be useful if you for example want to start something, like a server or daemon,
# then do something else before finishing the execution and retrieving the return code.
9pm::cmd::start "hostname"
# NOTE: You can interact with the execution and do your own expect here.
set output [9pm::cmd::capture]
set result [9pm::cmd::finish]

if {$result == 0} {
    9pm::output::ok "Hostname started, captured and finished (\"$output\")"
} else {
    9pm::fatal 9pm::output::fail "Hostname start, capture and finish failed"
}
