package provide 9pm::shell 1.0

proc shell {alias} {
    global spawn_id

    # Write console output to logfile
    log_file ;#Stop any old logging
    log_file -a "$int::log_path/${alias}_console.log"

    if {[info exists int::shell($alias)]} {
        output DEBUG "Now looking at shell: $alias"
        set spawn_id [dict get $int::shell($alias) "spawn_id"]
    } else {
        output DEBUG "Spawning new shell: \"$alias\""
        set pid [spawn "/bin/bash"]

        if {$pid == 0} {
            fatal int::error "Failed to spawn shell \"$alias\""
            return FALSE
        }

        set int::active_shell $alias
        dict append int::shell($alias) "spawn_id" $spawn_id
        dict append int::shell($alias) "pid" $pid
    }
    return TRUE
}

proc close_shell {alias} {
    if {![info exists int::shell($alias)]} {
        int::user_error "Trying to close shell \"$alias\" that doesn't exist"
        return FALSE
    }

    output DEBUG "Closing shell: $alias"
    close -i [dict get $int::shell($alias) "spawn_id"]

    # Remove it from internal data structure and stop logging
    unset int::shell($alias)
    log_file
}

