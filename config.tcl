package require yaml
package require 9pm::output
package provide 9pm::config 1.0

proc int::parse_config {filename} {

    # Check that configuration file exists
    if {![file exists $filename]} {
        int::error "Can't parse configuration \"$filename\" (file not found)" FATAL-USER
    }

    set fp [open $filename r]
    set config_data [read $fp]
    close $fp

    set config [::yaml::yaml2dict $config_data]
    return $config
}

proc get_req_node_info {node what} {
    set info [get_node_info $node $what]

    if {$info == ""} {
        int::error "Required configuration data \"$what\" for node \"$node\" missing" FATAL
    } else {
        return $info
    }
}

proc get_node_info {node what} {

    # Extract info about the node
    if {[dict exists $int::config $node]} {
        set node_info [dict get $int::config $node]
    } else {
        int::error "No configuration data found for node \"$node\"" FATAL
    }

    # Try to return the info we want for this node
    if {[dict exists $node_info $what]} {
        return [dict get $node_info $what]
    } else {
        output DEBUG "Configuration data \"$what\" not found for node \"$node\""
        return ""
    }
}
