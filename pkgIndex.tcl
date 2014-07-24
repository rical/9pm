# We need tcl 8.5
if {![package vsatisfies [package provide Tcl] 8.5]} {
    puts "FATAL: 9pm needs TCL 8.5"
    return
}

# Library namespaces
namespace eval ::lib {namespace export *}

# The internal namespace
namespace eval ::int {namespace export *}

package ifneeded 9pm            1.0 [list source [file join $dir pkgAll.tcl]]
package ifneeded 9pm::output    1.0 [list source [file join $dir output.tcl]]
package ifneeded 9pm::setup     1.0 [list source [file join $dir setup.tcl]]
package ifneeded 9pm::config    1.0 [list source [file join $dir config.tcl]]
package ifneeded 9pm::execute   1.0 [list source [file join $dir execute.tcl]]
package ifneeded 9pm::expect    1.0 [list source [file join $dir expect.tcl]]
package ifneeded 9pm::helpers   1.0 [list source [file join $dir helpers.tcl]]
package ifneeded 9pm::scp       1.0 [list source [file join $dir scp.tcl]]
package ifneeded 9pm::ssh       1.0 [list source [file join $dir ssh.tcl]]
package ifneeded 9pm::init      1.0 [list source [file join $dir init.tcl]]
package ifneeded 9pm::shell     1.0 [list source [file join $dir shell.tcl]]
