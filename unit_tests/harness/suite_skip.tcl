#!/usr/bin/tclsh

package require 9pm
namespace path ::9pm

output::debug "argv before ::arg:: $argv"

9pm::arg::require_or_skip_suite "require-value-foo" "foo"

#output::plan 1
#output::skip_test "Bla"

output::fail "This test should be skipped"
