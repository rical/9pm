package require cmdline
package require 9pm::output
package provide 9pm::init 1.0

# Parse command line
set options {
    {c.arg "" "Configuration file"}
    {l.arg "./log" "Logging base path"}
    {d "Output debug info and write exp_internal logfile"}
    {dd "Output debug2 info"}
    {t "Output TAP"}
}
if {[catch {array set int::cmdl [ ::cmdline::getoptions argv $options]}]} {
    puts [cmdline::usage $options "- usage:"]
    exit 1
}

set log_base $int::cmdl(l)
file mkdir $log_base

set script_name [get_script_name]
file mkdir "$log_base/$script_name"

# Setup log paths, logfiles and create symlinks to last run
while TRUE {
    incr i
    set run_suffix [format {%04s} $i]

    if {![file isdirectory "$log_base/$script_name/$run_suffix"]} {
        file mkdir "$log_base/$script_name/$run_suffix"
        break
    }
}

# Create symlinks to latest
if {[file exists "$log_base/last"]} {
    file delete "$log_base/last"
}
exec ln -s -f "$script_name/$run_suffix" "$log_base/last"

if {[file exists "$log_base/$script_name/last"]} {
    file delete "$log_base/$script_name/last"
}
exec ln -s -f $run_suffix "$log_base/$script_name/last"

set int::root_path [file normalize [get_running_script_path]]

# Store the log path for later use
set int::log_base [file normalize $log_base]
set int::log_script [file normalize "$log_base/$script_name"]
set int::log_path [file normalize "$log_base/$script_name/$run_suffix"]

# Debug on/off, generate exp_internal?
if {$int::cmdl(d) || $int::cmdl(dd)} {
    puts "Printing debug"
    set int::print_debug TRUE
    exp_internal -f "$int::log_path/exp_internal.log" 0
} else {
    set int::print_debug FALSE
}

if {$int::cmdl(dd)} {
    set int::print_debug2 TRUE
} else {
    set int::print_debug2 FALSE
}

# TAP Output on/off, print output in TAP format?
if {$int::cmdl(t)} {
    set int::output_tap TRUE
    output DEBUG "TAP output switched on"
} else {
    set int::output_tap FALSE
}

# Read config file
if {$int::cmdl(c) != ""} {
    output DEBUG "Using configuration: $int::cmdl(c)"
    set int::config [int::parse_config $int::cmdl(c)]
} else {
    output DEBUG "Running without configuration"
}

# Only keys in this dict are allowed in the 9pm rc. The values here are default values.
dict set int::rc "ssh_opts" ""

if {[file exists "~/.9pm.rc"]} {
    set rc [int::parse_config "~/.9pm.rc"]
} else {
    set rc [int::parse_config "$int::root_path/etc/9pm.rc"]
}

foreach {key val} $rc {
    set key [string tolower $key]

    if {[lsearch -exact [dict keys $int::rc] $key] < 0} {
        puts "ERROR:: Invalid 9pm.rc option \"$key\""
        exit 2
    }
    dict set int::rc $key $val
}
# We should probably wrap the whole init code inside an init namespace to avoid accidentally
# polluting the global scope. For now we manually unset what we set.
unset rc
