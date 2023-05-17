package provide 9pm::helpers 1.0

namespace eval ::9pm::misc {

    namespace eval dict {
        proc isdict {value} {
            return [expr {[string is list $value] && ([llength $value]&1) == 0}]
        }
        proc get {data name} {
            # Try to return the info we want for this node
            if {[dict exists $data $name]} {
                return [dict get $data $name]
            } else {
                ::9pm::output::debug2 "Dictionary key \"$name\" not found in data \"$data\""
                return ""
            }
        }

        proc require {data name} {
            set info [get $data $name]

            if {$info == ""} {
                ::9pm::fatal ::9pm::output::error "Required dictionary key \"$name\" not found in data \"$data\""
            } else {
                return $info
            }
        }
    }

    namespace eval get {
        # Get and return the current time in human readable form
        proc time {} {
            return [clock format [clock seconds] -format {%Y %m %d - %H:%M:%S}]
        }

        # Get and return the current unix time-stamp
        proc unix_time {} {
            return [clock format [clock seconds] -format {%s}]
        }

        # Return a random number between 0 and <max>
        proc rand_int {max} {
            return [expr int(rand()*$max)]
        }

        # Return a random string with length <length>
        proc rand_str {length} {
            return [subst [string repeat {[format %c [expr {97 + int(rand() * 26)}]]} $length]]
        }

        # This gets the path of the running script
        proc running_script_path {} {
            return [file dirname [info script]]
        }

        # This gets the running scripts name
        proc running_script_name {} {
            return [lindex [split [info script] "/"] [expr [llength [split [info script] "/"]] -1]]
        }

        # Get the called script path
        proc script_path {} {
            global argv0
            set old_pwd [pwd]
            cd [file dirname $argv0]
            set script_path [pwd]
            cd $old_pwd
            return $script_path
        }

        # Get the called script name
        proc script_name {} {
            global argv0
            return [lindex [split $argv0 "/"] [expr [llength [split $argv0 "/"]] -1]]
        }
    }

    proc slurp_file {file} {
        set data {}
        if {[file exists $file]} {
            set fd [open $file r]
            set data [read $fd]
            close $fd
        }
        return $data
    }

    proc write_file {data file} {
        set fd [open $file w]
        puts -nonewline $fd $data
        close $fd
    }

    # This will prepend a path to a list of files
    proc prepend_path {path filelist} {
        foreach elem $filelist {
            lappend result [file join $path $elem]
        }
        return $result
    }

    # opts = args from fucntion (as dict)
    # args = default arguments
    proc getopts {opts args} {
        if {![dict::isdict $opts]} {
            ::9pm::fatal ::9pm::output::error "Options needs to be a dict, for bool use \"foo TRUE\""
        }
        foreach {key val} $args {
            if {![dict exists $opts $key]} {
                ::9pm::output::debug2 "getopts default value for \"$key\" set to \"$val\""
                dict set opts $key $val
            }
        }
        return $opts
    }

    # Retry 'body' until it evaulates to true, but maximum 'times' number of
    # times with 'delay' seconds between attempts.
    # The function specified by args if any will be called on failure
    proc retry {times delay body} {
        for {} {$times > 0} {incr times -1; sleep $delay} {
            if {[uplevel 1 $body]} {
                return TRUE
            }
        }
        return FALSE
    }

    proc msleep { time } {
        after $time set end 1
        vwait end
    }
}
