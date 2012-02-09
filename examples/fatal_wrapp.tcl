#!/usr/bin/tclsh
package require 9pm

int::error "This in an example of an internal framework error"
fatal int::error "This in an example of an _fatal_ internal framework error"
puts "This is not printed"
