package provide 9pm::scp 1.0

# Wee need Expect TODO: Check if it exists (gracefull error-out)
package require Expect

proc scp {direction node files dest args} {
    set IP      [get_req_node_info $node SSH_IP]
    set PROMPT  [get_req_node_info $node PROMPT]
    set PORT    [get_node_info $node SSH_PORT]
    set USER    [get_node_info $node SSH_USER]
    set KEYFILE [get_node_info $node SSH_KEYFILE]

    set opts [dict get $int::rc "ssh_opts"]
    set cmd "scp $opts"

    if {$PORT != ""} {
        append cmd " -P $PORT"
    }
    if {$KEYFILE != ""} {
        append cmd " -i $KEYFILE"
    }
    if {$args != ""} {
        append cmd " $args"
    }

    set host [expr {($USER != "") ? "$USER@$IP" : "$IP"}]

    if {$direction == "from"} {
        append cmd " $host:\"$files\" $dest"
    } elseif {$direction == "to"} {
        append cmd " $files $host:$dest"
    } else {
        fatal int::user_error "Unsupported scp direction \"$direction\""
    }

    output DEBUG "Scp \"$files\" $direction $host"

    start "$cmd"
    expect {
        -nocase "password" {
            send "[get_req_node_info $node SSH_PASS]\n"
            exp_continue
        }
        -re {(\S+)\s+100%} {
            output DEBUG "File \"$expect_out(1,string)\" transfered $direction $host"
            exp_continue -continue_timer
        }
        timeout {
            fatal result FAIL "Scp transfer of \"$files\" $direction $host (timeout)"
        }
        eof {
            fatal result FAIL "Scp transfer of \"$files\" $direction $host (eof)"
        }
    }
    set code [finish]
    if {$code != 0} {
        fatal result FAIL "Scp transfer $direction $IP (got non-zero return code ($code))"
    }
}
