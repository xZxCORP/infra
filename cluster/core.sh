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
    rsync -r --ignore-times -e "ssh -i $SSH_KEY_PATH" $SRC $USER@$IP:$DEST
}

function create_directory {
    local IP=$1
    local DIR=$2
    ssh_exec $IP "sudo mkdir -p $DIR && sudo chown -R $USER:$USER $DIR"
}
function install_docker {
    local IP=$1
    echo "Checking if Docker is installed on $IP..."
    if ssh_exec $IP "docker --version" &>/dev/null; then
        echo "Docker is already installed on $IP."
    else
        echo "Installing Docker on $IP..."
        ssh_exec $IP "curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && sudo usermod -aG docker $USER"
    fi
}