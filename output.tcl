package require 9pm::setup
package provide 9pm::output 1.0

set int::testnum 1

proc int::add_bash_color {color msg} {
    set colors(GRAY)    "\033\[90m"
    set colors(RED)     "\033\[91m"
    set colors(GREEN)   "\033\[92m"
    set colors(YELLOW)  "\033\[93m"
    set colors(BLUE)    "\033\[34m"
    set colors(PURPLE)  "\033\[95m"
    set colors(CYAN)    "\033\[96m"
    set colors(ENDC)    "\033\[0m"

    # No colors for TAP output
    if {$int::output_tap} {
        return $msg
    }

    if {[info exists colors($color)]} {
        return "$colors($color)${msg}$colors(ENDC)"
    } else {
        return $msg
    }
}

proc int::out {type msg {color ""}} {

    if {!$int::output_tap} {
        # Add a timestamp
        set msg "[get_time] - $msg"
    }

    # Log it to generic out.log file
    set fd [open $int::log_path/run.log a]
    puts $fd $msg
    close $fd

    # Add bash color if any
    if {$color != ""} {
        set msg [int::add_bash_color $color $msg]
    }

    puts $msg
}

proc fatal {args} {
    if {![{*}$args]} {
        exit 2
    }
}

proc int::error {msg} {
    int::out ERROR "ERROR:: $msg" RED
    return FALSE
}

proc int::user_error {msg} {
    int::out ERROR "USER ERROR:: $msg" RED
    return FALSE
}

proc result {type msg} {
     switch -regexp -- $type {
        PLAN {
            int::out RESULT "1..$msg" GREEN
            return TRUE
        }
        OK {
            int::out RESULT "ok $int::testnum - $msg" GREEN
            incr int::testnum
            return TRUE
        }
        FAIL {
            int::out RESULT "not ok $int::testnum - $msg" RED
            incr int::testnum
            return FALSE
        }
        SKIP {
            int::out RESULT "ok $int::testnum - # skip $msg" YELLOW
            incr int::testnum
            return TRUE
        }
        default {
            int::error "There is no \"$type\" result type" USER-FATAL
            return FALSE
        }
    }
}

proc output {level msg} {
    switch -exact $level {
        WARNING {
            int::out OUTPUT "# $level - $msg" YELLOW
        }
        DEBUG {
            if {$int::print_debug} {
                int::out OUTPUT "# $level - $msg" GRAY
            }
        }
        INFO {
            if {$int::print_info} {
                int::out OUTPUT "# $level - $msg" BLUE
            }
        }
        NOTE {
            if {$int::print_note} {
                int::out OUTPUT "# $level - $msg" CYAN
            }
        }
        default {
            int::error "There is no \"$level\" output level" FATAL-USER
        }
    }
}

