#!/usr/bin/tclsh

# Example of how to open a local shell, ssh into a machine and print its hostname
# Execute this with $ ./ssh.tcl -c conf.yaml

# Source the 9pm library
package require 9pm

# Plan for one test
9pm::output::plan 1

# Open a shell with a name of our choice, lets call it "foobar"
9pm::shell::open "foobar"

# Move the active shell (foobar) to the remote machine "machine" present in the configuration file
9pm::ssh::connect [9pm::conf::get "machine"]

# Execute the command "hostname" on the remote machine and capture the output
set hostname [9pm::cmd::execute "hostname" 0]

9pm::output::ok "Hostname of remote machine: $hostname"
