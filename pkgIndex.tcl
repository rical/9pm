# We need tcl 8.5
if {![package vsatisfies [package provide Tcl] 8.5]} {
    puts "FATAL: 9pm needs TCL 8.5"
    return
}

package ifneeded 9pm            1.0 [list source [file join $dir pkgAll.tcl]]
package ifneeded 9pm::output    1.0 [list source [file join $dir output.tcl]]
package ifneeded 9pm::location  1.0 [list source [file join $dir location.tcl]]
package ifneeded 9pm::config    1.0 [list source [file join $dir config.tcl]]
package ifneeded 9pm::db        1.0 [list source [file join $dir db.tcl]]
package ifneeded 9pm::execute   1.0 [list source [file join $dir execute.tcl]]
package ifneeded 9pm::helpers   1.0 [list source [file join $dir helpers.tcl]]
package ifneeded 9pm::scp       1.0 [list source [file join $dir scp.tcl]]
package ifneeded 9pm::ssh       1.0 [list source [file join $dir ssh.tcl]]
package ifneeded 9pm::init      1.0 [list source [file join $dir init.tcl]]
package ifneeded 9pm::spawn     1.0 [list source [file join $dir spawn.tcl]]
package ifneeded 9pm::shell     1.0 [list source [file join $dir shell.tcl]]
package ifneeded 9pm::console   1.0 [list source [file join $dir console.tcl]]
package ifneeded 9pm::login     1.0 [list source [file join $dir login.tcl]]
package ifneeded 9pm::arg       1.0 [list source [file join $dir arg.tcl]]
