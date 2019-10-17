#!/usr/bin/tclsh

package require 9pm

9pm::output::info "Hi from onfail script"
9pm::output::info "Writing known string to database"
dict set 9pm::db::dict "onfail" "I'm a failure"
