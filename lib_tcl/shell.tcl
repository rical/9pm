package provide 9pm::shell 1.0
package require 9pm::spawn

namespace eval ::9pm::shell {
    proc create {shell} {
        set ::env(HISTFILE) "/dev/null"

        set pid [spawn {*}$shell]
        return [list $spawn_id $pid]
    }

    proc open {alias {shell "/bin/bash -norc"}} {
        return [::9pm::spawn::open $alias "::9pm::shell::create {$shell}"]
    }

    proc close {alias} {
        return [::9pm::spawn::close $alias]
    }

    proc push {alias} {
        set shell "/bin/bash -norc"
        return [::9pm::spawn::push $alias "::9pm::shell::create {$shell}"]
    }

    proc pop { } {
        return [::9pm::spawn::pop]
    }
}
