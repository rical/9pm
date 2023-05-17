#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm

output::plan 1

output::info "Writing to database"
dict set 9pm::db::dict spoon "There is no spoon"
dict set 9pm::db::dict pill "Take the red pill"
output::ok "Database written"
