#!/usr/bin/tclsh

set version 1.0

set file_list {
    "config.tcl"
    "db.tcl"
    "execute.tcl"
    "helpers.tcl"
    "init.tcl"
    "output.tcl"
    "pkgAll.tcl"
    "pkgIndex.tcl"
    "scp.tcl"
    "shell.tcl"
    "ssh.tcl"
}

if {"$argc" != 1} {
    puts stderr "No install path provided, not installing!"
    exit 1
} else {
    set install_path [string trimright [lindex $argv 0] /]
}

if {[lsearch $auto_path "$install_path"] == -1} {
    puts stderr "$install_path is not in \$auto_path, needed for package loading"
    exit 1
}

set 9pm_install_dir "$install_path/9pm$version"

if [catch {file mkdir -path "$9pm_install_dir"}] {
    puts stderr "Could not create $9pm_install_dir, verify that you have write permissions"
    exit 1
}

foreach install_file "$file_list" {
    file copy "$install_file" "$9pm_install_dir"
}
