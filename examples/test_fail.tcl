#!/usr/bin/tclsh

# Simple example that outputs a failure

package require 9pm

9pm::output::plan 1

9pm::shell::open "myhost"

set hostname [9pm::cmd::execute "hostname"]

9pm::output::fail "the hostname \"$hostname\" is lame"
