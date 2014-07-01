#!/usr/bin/tclsh
package require yaml
package require 9pm

if {![info exists int::config]} {
    fatal int::error "Can't test configurations, no configuration given"
}

set fp [open $int::cmdl(c) r]
set config_data [read $fp]
close $fp

# Parse the YAML file.
set config [::yaml::yaml2dict $config_data]

set msg "Checking the integrity for the parsed configuration"
if {$int::config == $config} {
    result OK $msg
} else {
    result FATAL $msg
}

# Test the get_node info functions
set fail FALSE
foreach elem [dict keys $config] {
    foreach {dkey dval} [dict get $config $elem] {
        set node_info [get_node_info $elem $dkey]
        if {$node_info != $dval} {
            set fail TRUE
        }
    }
}
set msg "Iterating all node configurations and testing: get_node_info"
if {$fail} {
    result FAIL $msg
} else {
    result OK $msg
}

# Test the get_req_node info functions (note: this is a fatal proc)
foreach elem [dict keys $config] {
    foreach {dkey dval} [dict get $config $elem] {
        get_req_node_info $elem $dkey
    }
}
result OK "Iterating all node configurations and testing: get_req_node_info"
