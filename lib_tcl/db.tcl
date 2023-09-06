package provide 9pm::db 1.0

namespace eval ::9pm::db {
    set dict {}

    namespace eval int {
        proc read {name1 name2 op} {
            variable enabled

            if {!$enabled} {
                9pm::output::warning "Database not configured, can't read $name1"
            }
        }

        proc update {name1 name2 op} {
            variable enabled

            if {!$enabled} {
                ::9pm::fatal 9pm::output::error "Database not configured, can't write $name1"
            }
            ::9pm::misc::write_file $::9pm::db::dict $::9pm::core::cmdl(b)
        }
    }

    if {$::9pm::core::cmdl(b) != ""} {
        set int::enabled TRUE
        if {![file exists $::9pm::core::cmdl(b)]} {
            ::9pm::fatal 9pm::output::error "Database file not found: $::9pm::core::cmdl(b)"
        }
        set dict [::9pm::misc::slurp_file $::9pm::core::cmdl(b)]
    } else {
        set int::enabled FALSE
    }

    if {$::9pm::core::cmdl(s) != ""} {
        set scratch $::9pm::core::cmdl(s)
    }

    trace add variable dict read 9pm::db::int::read
    trace add variable dict write 9pm::db::int::update
}
