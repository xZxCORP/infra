#!/bin/bash
export KUBECONFIG=$(pwd)/kubeconfig
kubectl config use-context default
echo "KUBECONFIG set to $KUBECONFIG_PATH and context switched to 'default'"
