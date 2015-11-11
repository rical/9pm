#!/usr/bin/tclsh

# Simple example of how to open a shell, execute a command and print its output
# Execute this like $ ./local.tcl

package require 9pm

9pm::shell::open "myhost"

set hostname [9pm::cmd::execute "hostname"]

puts "My hostname is: $hostname"
