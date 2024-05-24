function ssh_exec {
    local IP=$1
    shift
    ssh -i $SSH_KEY_PATH $USER@$IP "$@"
}

function scp_files {
    local IP=$1
    local SRC=$2
    local DEST=$3
    scp -i $SSH_KEY_PATH -r $SRC $USER@$IP:$DEST
}
function rsync_files {
    local IP=$1
    local SRC=$2
    local DEST=$3
    rsync -avz -e "ssh -i $SSH_KEY_PATH" $SRC $USER@$IP:$DEST
}

function create_directory {
    local IP=$1
    local DIR=$2
    ssh_exec $IP "sudo mkdir -p $DIR && sudo chown -R $USER:$USER $DIR"
}