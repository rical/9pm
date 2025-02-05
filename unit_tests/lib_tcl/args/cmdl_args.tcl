#!/usr/bin/tclsh

package require 9pm

9pm::output::plan 1

if {[dict get $9pm::conf::data "config"] == "cmdl"} {
    9pm::output::ok "Got config passed from cmdl"
} else {
    9pm::output::fail "Invalid configuration passed"
}
