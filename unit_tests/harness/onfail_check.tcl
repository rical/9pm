#!/usr/bin/tclsh

package require 9pm

9pm::output::plan 1

9pm::output::info "Checking if onfail script wrote to database"

if {[dict get $9pm::db::dict "onfail"] == "I'm a failure"} {
    9pm::output::ok "Database content checks out, onfail as executed"
} else {
    9pm::output::ok "Database content from onfail missing"
}
