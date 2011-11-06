package require cmdline
package require 9pm::output
package provide 9pm::init 1.0

# Parse command line
set options {
    {c.arg "./config.yaml" "Configuration file"}
    {l.arg "./log" "Logging base path"}
    {d "" "Output debug info and write exp_internal logfile"}
}
array set int::cmdl [ ::cmdline::getoptions argv $options "Options:" ]

# Setup logging base
set log_base $int::cmdl(l)
set log_script "$log_base/[get_script_name]"

file mkdir $log_base
file mkdir $log_script

# Setup log paths, logfiles and create symlinks to last run
while TRUE {
    incr i
    set run_suffix [format {%04s} $i]
    set log_path "$log_script/$run_suffix"

    if {![file isdirectory $log_path]} {
        file mkdir $log_path

        # Remove and create new global "last run" symlink
        if {[file exists "$log_base/last"]} {
            file delete "$log_base/last"
        }
        exec ln -s -f $log_path "$log_base/last"

        # Remove and create new script specific "last run" symlink
        if {[file exists "$log_script/last"]} {
            file delete "$log_script/last"
        }
        exec ln -s -f $run_suffix "$log_script/last"

        # Store the current log path for later use
        set int::log_base [get_full_path $log_base]
        set int::log_script [get_full_path $log_script]
        set int::log_path [get_full_path $log_path]
        break
    }
}

# Debug on/off, generate exp_internal?
if {$int::cmdl(d)} {
    set int::print_debug TRUE
    exp_internal -f "$int::log_path/exp_internal.log" 0
} else {
    set int::print_debug FALSE
}

# Read config file
if {[file exists $int::cmdl(c)]} {
    output DEBUG "Using configuration: $int::cmdl(c)"
    set int::config [int::parse_config $int::cmdl(c)]
} else {
    output DEBUG "No configuration file found"
}

