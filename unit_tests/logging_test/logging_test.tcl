#!/usr/bin/tclsh
package require 9pm

# Write a checksum (as INFO) to the logfile
set checksum [get_checksum]
output INFO $checksum

# Here is the logfiles and links we want to check
lappend files "$int::log_path/run.log"
lappend files "$int::log_base/last/run.log"
lappend files "$int::log_script/last/run.log"

# Now check that the info we wrote is in the logfile(s)
foreach f $files {
    set fp [open $f r]
    set data [read $fp]
    close $fp

    set result FALSE
    foreach line [split $data "\n"] {
        if {[string match "*$checksum*" $line]} {
            set result TRUE
        }
    }

    if {$result} {
        result OK "Logifile: $f"
    } else {
        result FAIL "Logifile $f"
    }
}

