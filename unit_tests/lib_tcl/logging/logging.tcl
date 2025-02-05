#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm

output::plan 3

# Write a checksum (as INFO) to the logfile
set checksum [misc::get::rand_str 20]
output::info $checksum

# Here is the logfiles and links we want to check
lappend files "$::9pm::output::log_path/run.log"
lappend files "$::9pm::output::log_base/last/run.log"
lappend files "$::9pm::output::log_script/last/run.log"

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
        output::ok "Logifile: $f"
    } else {
        output::fail "Logifile $f"
    }
}

