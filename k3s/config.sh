#!/bin/bash

MASTER_IP="89.168.55.153"
WORKER_IPS=("89.168.44.126" "89.168.40.199")
NODES=($MASTER_IP "${WORKER_IPS[@]}")
USER="ubuntu"
SSH_KEY_PATH="~/.ssh/gpe-vm"
SCRIPT_PATH="~/"


GIT_REPO="git@your-private-repo.git"
GIT_BRANCH="main"
GIT_REPO_PATH="path/to/your/argo/cd/config"