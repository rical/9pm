package provide 9pm::spawn 1.0

namespace eval ::9pm::spawn {
    namespace eval int {
        proc pop_fail { } {
            ::9pm::fatal ::9pm::output::error "Can't pop to an expired spawn"
        }
    }

    proc open {alias create} {
        global spawn_id
        variable data
        variable active

        # Write console output to logfile
        log_file ;#Stop any old logging
        log_file -a "$::9pm::output::log_path/${alias}_console.log"

        # Unregister any running command catchers for the previous spawn
        ::9pm::cmd::int::unreg_exp_after

        if {[info exists data($alias)]} {
            ::9pm::output::debug "Now looking at spawn: $alias"
            set spawn_id [dict get $data($alias) "spawn_id"]
        } else {
            ::9pm::output::debug "Creating new spawn: \"$alias\""

            # Create a new spawn by calling the implementation specific
            # `create`. The `create` call shall return a list in the format of
            # [spawn_id, pid] where pid is non-zero on success.
            set metadata [{*}$create]
            set spawn_id [lindex $metadata 0]
            set pid [lindex $metadata 1]

            if {$pid == 0} {
                ::9pm::fatal ::9pm::output::error "Failed to spawn \"$alias\""
            }

            dict append data($alias) "spawn_id" $spawn_id
            dict append data($alias) "pid" $pid
        }

        set active $alias
        ::9pm::cmd::int::reg_exp_after
        return TRUE
    }

    proc close {alias} {
        variable data
        variable active

        if {![info exists data($alias)]} {
            ::9pm::fatal ::9pm::output::user_error "Trying to close spawn \"$alias\" that doesn't exist"
        }

        # Unset active spawn if that is the one we are closing
        if {[info exists active] && ($active == $alias)} {
            ::9pm::output::debug "Closing active spawn: $alias"
            unset active
        } else {
            ::9pm::output::debug "Closing spawn: $alias"
        }

        ::close -i [dict get $data($alias) "spawn_id"]

        # Remove it from internal data structure and stop logging
        unset data($alias)
        log_file
    }

    proc push {alias create} {
        variable active
        variable stack

        if {![info exists active]} {
            ::9pm::fatal ::9pm::output::user_error "You need to have a spawn in order to push it"
        }
        lappend stack $active
        return [::9pm::spawn::open $alias $create]
    }

    proc pop { } {
        variable active
        variable stack

        if {[llength $stack] == 0} {
            ::9pm::fatal ::9pm::output::user_error "Can't pop spawn, stack is empty"
        }
        set alias [lindex $stack end]
        set stack [lreplace $stack [set stack end] end]
        return [::9pm::spawn::open $alias "::9pm::spawn::int::pop_fail"]
    }
}
