#!/usr/bin/tclsh
package require 9pm

set outputs {
    INFO BLUE
    NOTE CYAN
    DEBUG GREY
    WARNING YELLOW
}

set results {
    OK GREEN
    FAIL RED
    FATAL RED
}

puts "This is a normal puts (no timestamp)"

puts "\nThis is some non fatal errors"
int::error "This is a RED error"
int::error "This is a RED user error" USER
#int::error "This is a RED fatal user error" USER-FATAL

puts "\nIterating outputs"
foreach {out color} $outputs {
    output $out "This is an $color \"$out\" message"
}

puts "\nIterating results"
foreach {res color} $results {
    result $res "This is an $color $res result"
}

