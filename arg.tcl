package provide 9pm::arg 1.0

# This functions helps a user to parse arguments in a test-case.
#
# All arguments on the format foo:bar (*:*) are removed from $argv when
# calling any of the 9pm::arg functions. This makes them position
# independent and should not break old style [lindex $argv 1] parsing
# (as long as the argument isn't on this format).
#
# Examples:
#   9pm::arg::require "foo"
#
#   This requires the option "foo" to be passed on the format "foo:bar",
#   where "bar" is the value. It's up to the test author to handle the
#   value, which is stored in $9pm::arg::foo. If "foo" is not passed
#   a fatal fail will be issued.
#
#   9pm::arg::optional "foo"
#
#   Does the same thing as 9pm::arg::require without throwing a fatal
#   fail if "foo" is not set.
#
#   9pm::arg::require_or_skip "foo" "bar"
#
#   Requires the option "foo" to be "bar", i.e.
#   "9pm.py -o 'foo:bar' test.tcl". If it's not passed at all or if its
#   value isn't 0, the test will output a 1 test plan and skip the test.
#   This can be useful when a user wants to run a test on a specific
#   hardware for example. Such as:
#   9pm::arg::require_or_skip "hardware" "ppc"

namespace eval ::9pm::arg {
    # Internal function
    proc _argset {name} {
        global argv

        set new_argv [list]

        foreach param $argv {
            if {[string match "$name:*" $param]} {
                set ::9pm::arg::$name [lindex [split $param ":"] 1]
            } else {
                lappend new_argv $param
            }
        }

        set argv $new_argv
    }

    proc require {name} {
        _argset $name
        if {![info exists "::9pm::arg::$name"]} {
            ::9pm::fatal ::9pm::output::fail "Required arguments \"$name\" missing"
        }
    }

    proc optional {name} {
        _argset $name
    }

    proc _require_or_skip {skip_func name value} {
        _argset $name
        if {![info exists "::9pm::arg::$name"]} {
            $skip_func "Required argument \"$name\" not set"
            exit
        } elseif {[set ::9pm::arg::$name] != $value} {
            $skip_func "Required argument \"$name\" != \"$value\""
            exit
        }
    }

    proc require_or_skip {name value} {
        _require_or_skip "::9pm::output::skip_test" $name $value
    }

    proc require_or_skip_suite {name value} {
        _require_or_skip "::9pm::output::skip_suite" $name $value
    }

}
