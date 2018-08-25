#!/bin/bash

function get_random_port {
    read lower_port upper_port < /proc/sys/net/ipv4/ip_local_port_range
    while :; do
        for (( port = lower_port ; port <= upper_port ; port++ )); do
            echo "$port"
            break 2;
        done
    done
}


# Add stuff to mention the fact that copy-id must be done.
function invoke_mothership {

    # Set some useful variables
    local REMOTEPORT=$1
    local LOCALPORT=$2
    local MOTHERSHIP=$3
    local USER=$(whoami)

    if [ $LOCALPORT -eq 0 ]; then
        LOCALPORT = $(get_random_port)
    fi

    echo "Will dial back to user \"${USER}\""
    echo "Port in use: ${LOCALPORT}"

    # Start the tmux server locally, and create two windows.
    tmux start-server
    tmux new-session -d -s mothership -n SSHuttle
    tmux new-window -t mothership:1 -n control

    # Open reverse tunnel and forward traffic from remote box through local box.
    tmux send-keys -t mothership:0 "ssh -R $LOCALPORT:localhost:$REMOTEPORT $MOTHERSHIP" C-m
    sleep 2
    tmux send-keys -t mothership:0 'arr=($SSH_CONNECTION)' C-m
    tmux send-keys -t mothership:0 'ORIGIN_SSH=${arr[0]}' C-m
    tmux send-keys -t mothership:0 'DEST_SSH=${arr[2]}' C-m
    tmux send-keys -t mothership:0 "sshuttle -x 127.0.0.1 -x \$ORIGIN_SSH -x \$DEST_SSH --dns -r $USER@localhost:$LOCALPORT 0/0" C-m

    # Open SSH Connection, then open regular terminal on second screen.
    tmux send-keys -t mothership:1 "ssh $MOTHERSHIP" C-m
    tmux send-keys -t mothership:1 "echo 'Mothership has arrived!'" C-m

    # Connect to second screen by default.
    tmux select-window -t mothership:1

    # Display connection.
    tmux attach-session -t mothership
}

function show_help {
    echo "usage: summon-mothership [-r remoteport] [-l localport] [-c] [user@]sshserver"
    echo ""
    echo "positional arguments:"
    echo "  user@sshserver          User and remote server to connect to"
    echo ""
    echo "optional arguments:"
    echo "  -h                      Shows this help and exit"
    echo "  -r REMOTE               Remote port to connect to on the remote box. Defaults to 22."
    echo "  -l LOCAL                Local port on the remote box to use in order to connect"
    echo "                          back to the local box. Default to a random port."
    echo "  -c                      Constructs the Mothership, making a key exchange and"
    echo "                          installing the dependencies.  Does not execute a connection."
}

function prepare_mothership {
    local REMOTEPORT=$1
    local LOCALPORT=$2
    local MOTHERSHIP=$3

    if [ $LOCALPORT -eq 0 ]; then
        LOCALPORT = $(get_random_port)
    fi

    echo "Preparing the mothership!"
    echo "Will dial back to user \"${USER}\""
    echo "Port in use: ${LOCALPORT}"

    # Copy local identity to mothership
    ssh-copy-id $MOTHERSHIP

    # Generate remote entity if necessary
    FILE_PATH='~/*.pub'
    ssh -q $MOTHERSHIP [[ -f $FILE_PATH ]] && echo "SSH Key already exists!" || ssh -q $MOTHERSHIP 'ssh-keygen';

    # Copy mothership user identity locally.
    REMOTE_COMMAND="ssh-copy-id -o StrictHostKeyChecking=no -p $LOCALPORT $USER@localhost"
    ssh -q -t -R $LOCALPORT:localhost:$REMOTEPORT $MOTHERSHIP "$REMOTE_COMMAND"

    # Install sshuttle - Our main dependency.
    # Is this Debian-based? Or Arch Linux-based?
    ssh $MOTHERSHIP -q [[ -x "/usr/bin/pacman" ]] && (ssh -q $MOTHERSHIP "pacman -Syy && pacman -S sshuttle" && exit 0) || echo "I am not Archlinux!"
    ssh $MOTHERSHIP -q [[ -x "/usr/bin/apt-get" ]] && (ssh -q $MOTHERSHIP "apt-get update && apt-get install sshuttle" && exit 0) || "I am not Debian-based!"

    echo "Not sure what the Mothership's OS is, so you'll have to install sshuttle yourself!"
    exit 0
}

function main {
    local OPTIND=1
    local PREPARE=0
    local REMOTEPORT=22
    local LOCALPORT=0

    while getopts "hr:l:c" opt; do
        case "$opt" in
            h)
                show_help
                exit 0
                ;;
            r) REMOTEPORT=$OPTARG
               ;;
            l) LOCALPORT=$OPTARG
               ;;
            c)
                PREPARE=1
                ;;

        esac
    done

    shift $((OPTIND-1))
    [ "${1:-}" = "--" ] && shift

    if [ $PREPARE -eq 1 ]; then
        prepare_mothership $REMOTEPORT $LOCALPORT $@
    else
        invoke_mothership $REMOTEPORT $LOCALPORT $@
    fi
}

main $@

