#!/usr/bin/tclsh

package require 9pm

9pm::output::plan 1

if {[dict get $9pm::conf::data "config"] == "env"} {
    9pm::output::ok "Got config passed from environment"
} else {
    9pm::output::fail "Invalid configuration passed"
}
