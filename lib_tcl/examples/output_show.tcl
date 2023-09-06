#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm::

set outputs {
    info BLUE
    note CYAN
    debug GREY
    warning YELLOW
}

set results {
    ok GREEN
    fail RED
    skip YELLOW
}

puts "This is a normal puts (no timestamp)"

puts "\nThis is some non fatal errors"
output::error "This is a RED error"
output::user_error "This is a RED user error"
#fatal output::user_error "This is a RED fatal user error"

puts "\nIterating outputs"
foreach {out color} $outputs {
    output::$out "This is an $color \"$out\" message"
}

puts "\nIterating results"
foreach {res color} $results {
    output::$res "This is an $color $res message"
}

