#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm::

output::plan [llength $argv]
foreach out $argv {
    output::$out "This is a $out TAP test point"
}
