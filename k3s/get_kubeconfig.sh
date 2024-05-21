#!/bin/bash

source common.sh
k3sup install \
    --ip $MASTER_IP \
    --user $USER \
    --ssh-key $SSH_KEY \
    --merge \
    --skip-install