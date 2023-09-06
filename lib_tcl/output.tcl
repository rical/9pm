package require 9pm::init
package require 9pm::helpers
package provide 9pm::output 1.0

if {[catch {package require Expect} result]} {
    puts "1..1"
    puts "not ok 1 - $result (please install it)"
    exit 1
}

namespace eval ::9pm::output {
    # Default output behaviour
    set print_info TRUE
    set print_warning TRUE
    set print_note TRUE
    set print_debug FALSE
    set print_debug2 FALSE
    set print_tap FALSE

    # Disable expect stdout logging
    ::log_user 0

    set testnum 0
    set planned 0

    proc colorize {color msg} {
        variable print_tap

        set color [string tolower $color]
        set colors(gray)    "\033\[90m"
        set colors(red)     "\033\[91m"
        set colors(green)   "\033\[92m"
        set colors(yellow)  "\033\[93m"
        set colors(blue)    "\033\[34m"
        set colors(purple)  "\033\[95m"
        set colors(cyan)    "\033\[96m"
        set colors(endc)    "\033\[0m"

        # No colors for TAP output
        if {$print_tap} {
            return $msg
        }

        if {[::info exists colors($color)]} {
            return "$colors($color)${msg}$colors(endc)"
        } else {
            return $msg
        }
    }

    proc write {msg {color ""}} {
        variable log_path
        variable print_tap

        if {!$print_tap} {
            # Add a timestamp
            set msg "[::9pm::misc::get::time] - $msg"
        }

        # Log it to generic out.log file
        set fd [open $log_path/run.log a]
        puts $fd $msg
        close $fd

        # Add bash color if any
        if {$color != ""} {
            set msg [colorize $color $msg]
        }

        puts $msg
    }

    proc plan {cnt} {
        variable planned

        write "1..$cnt" GREEN
        set planned $cnt
        return TRUE
    }

    proc ok {msg} {
        variable testnum

        incr testnum
        write "ok $testnum - $msg" GREEN
        return TRUE
    }

    proc fail {msg} {
        variable testnum

        incr testnum
        write "not ok $testnum - $msg" RED
        return FALSE
    }

    proc skip {msg} {
        variable testnum

        incr testnum
        write "ok $testnum # skip $msg" YELLOW
        return TRUE
    }

    proc skip_test {msg} {
        variable planned

        if {$planned != 0} {
            user_error "skip_test needs to be called before output::plan"
            exit
        }

        9pm::output::plan 1
        skip $msg
        exit 0
    }

    proc skip_suite {msg} {
        skip_test "suite $msg"
    }

    proc error {msg} {
        write "# ERROR:: $msg" RED
        return FALSE
    }

    proc user_error {msg} {
        write "# USER ERROR:: $msg" RED
        return FALSE
    }

    proc warning {msg} {
        write "# WARNING - $msg" YELLOW
    }

    proc debug {msg} {
        variable print_debug

        if {$print_debug} {
            write "# DEBUG - $msg" GRAY
        }
    }

    proc debug2 {msg} {
        variable print_debug2

        if {$print_debug2} {
            write "# DEBUG2 - $msg" GRAY
        }
    }

    proc info {msg} {
        variable print_info

        if {$print_info} {
            write "# INFO - $msg" BLUE
        }
    }

    proc note {msg} {
        variable print_note

        if {$print_note} {
            write "# NOTE - $msg" CYAN
        }
    }

    proc test {test msg} {
        if {$test} {
            ok $msg
            return TRUE
        } else {
            fail $msg
            return FALSE
        }
    }

    # Output setup
    set log_base [file normalize $::9pm::core::cmdl(l)]
    file mkdir $log_base

    set script_name [::9pm::misc::get::script_name]
    set log_script "$log_base/$script_name"
    file mkdir "$log_script"

    # Setup log paths, logfiles and create symlinks to last run
    while TRUE {
        incr i
        set run_suffix [format {%04s} $i]

        if {![file isdirectory "$log_script/$run_suffix"]} {
            set log_path [file normalize "$log_script/$run_suffix"]
            file mkdir "$log_path"
            break
        }
    }

    # Create symlinks to latest
    if {[file exists "$log_base/last"]} {
        file delete "$log_base/last"
    }
    exec ln -s -f "$script_name/$run_suffix" "$log_base/last"

    if {[file exists "$log_script/last"]} {
        file delete "$log_script/last"
    }
    exec ln -s -f $run_suffix "$log_script/last"

    # Debug on/off, generate exp_internal?
    if {$::9pm::core::cmdl(d) || $::9pm::core::cmdl(dd)} {
        set print_debug TRUE
        exp_internal -f "$log_path/exp_internal.log" 0
    }

    if {$::9pm::core::cmdl(dd)} {
        set print_debug2 TRUE
    }

    # TAP Output on/off, print output in TAP format?
    if {$::9pm::core::cmdl(t)} {
        set print_tap TRUE
        debug "TAP output switched on"
    }
}

# TODO: move this to a separate file as it has nothing to do with output?
namespace eval ::9pm:: {
    proc fatal {args} {
        # Store a copy of the passed args in the callers variable scope as
        # "9pm::fatal_args" to be able to access it in the uplevel below.
        upvar 1 ::9pm::fatal_args tmp
        set tmp $args

        # Upevel to caller scope and execute from there. This means that the
        # call chain for things we run will be the same as they would without
        # the fatal wrap. I.e. upvar and uplevel will work as expected.
        uplevel 1 {
            if {![{*}$::9pm::fatal_args]} {
                exit 2
            }
        }
        unset tmp
    }
}
