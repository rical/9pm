#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm::

set states [lreplace $argv end end]

output::plan [llength $states]

foreach state $states {
    output::$state "This is a $state TAP test point"
}
