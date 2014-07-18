package provide 9pm::ssh 1.0

proc ssh {node args} {
    set IP      [get_req_node_info $node SSH_IP]
    set PROMPT  [get_req_node_info $node PROMPT]
    set PORT    [get_node_info $node SSH_PORT]
    set USER    [get_node_info $node SSH_USER]
    set PASS    [get_node_info $node SSH_PASS]
    set KEYFILE [get_node_info $node SSH_KEYFILE]

    set opts [dict get $int::rc "ssh_opts"]

    set ssh_cmd "ssh $opts $IP"
    if {$USER != ""} {
        append ssh_cmd " -l $USER"
    }
    if {$PORT != ""} {
        append ssh_cmd " -p $PORT"
    }
    if {$KEYFILE != ""} {
        append ssh_cmd " -i $KEYFILE"
    }
    if {$args != ""} {
        append ssh_cmd " $args"
    }

    output DEBUG "Connecting to \"$IP\" (as \"$USER\")"

    expect *
    send "$ssh_cmd\n"
    expect {
        $PROMPT {
            output INFO "Connected to \"$IP\" (as \"$USER\")"
        }
        -nocase "password" {
            send "$PASS\n"
            exp_continue -continue_timer
        }
        timeout {
            fatal result FAIL "SSH connection to \"$IP\" failed (timeout)"
        }
        eof {
            fatal result FAIL "SSH connection to \"$IP\" failed (eof)"
        }
    }
}
