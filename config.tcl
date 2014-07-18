package require yaml
package require 9pm::output
package provide 9pm::config 1.0

# We can't call other procedures in the int:: namespace here
# as this might be running early.
proc int::parse_config {filename} {

    # Check that configuration file exists
    if {![file exists $filename]} {
        puts "ERROR:: Can't parse configuration \"$filename\" (file not found)"
        exit 2
    }

    set fp [open $filename r]
    set config_data [read $fp]
    close $fp

    return [::yaml::yaml2dict $config_data]
}

proc get_req_node_info {node what} {
    set info [get_node_info $node $what]

    if {$info == ""} {
        fatal int::error "Required configuration data \"$what\" for node \"$node\" missing"
    } else {
        return $info
    }
}

proc get_node_info {node what} {
    if {![info exists ::int::config]} {
        fatal result FAIL "\"[info level -2]\" requires an configuration"
    }

    # Extract info about the node
    if {[dict exists $::int::config $node]} {
        set node_info [dict get $::int::config $node]
    } else {
        fatal int::error "No configuration data found for node \"$node\""
    }

    # Try to return the info we want for this node
    if {[dict exists $node_info $what]} {
        return [dict get $node_info $what]
    } else {
        output DEBUG "Configuration data \"$what\" not found for node \"$node\""
        return ""
    }
}
