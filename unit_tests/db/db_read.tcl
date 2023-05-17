#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm

output::plan 2

output::info "Checking database content"
if {[dict get $9pm::db::dict "spoon"] == "There is no spoon"} {
    output::ok "Database content: There is no spoon"
} else {
    output::fail "Database content: There is no spoon"
}

if {[dict get $9pm::db::dict "pill"] == "Take the red pill"} {
    output::ok "Database content: Take the red pill"
} else {
    output::fail "Database content: Take the red pill"
}
