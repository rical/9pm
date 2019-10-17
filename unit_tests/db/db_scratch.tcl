#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm

output::plan 2

output::info "Checking that we have a scratch dir set up"

if {[info exists 9pm::db::scratch]} {
    output::ok "Scratch dir is set ($9pm::db::scratch)"
} else {
    fatal output::fail "Scratch dir not set"
}

if {[file isdirectory $9pm::db::scratch]} {
    output::ok "Scratch directory actually exists"
} else {
    fatal output::ok "Scratch directory missing"
}
