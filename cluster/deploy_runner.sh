#!/bin/bash
source config.sh
source core.sh


CONFIGURE_RUNNER_SCRIPT=$(cat << 'EOF'
#!/bin/bash

GITHUB_URL="$1"
RUNNER_TOKEN="$2"
GITHUB_RUNNER_VERSION="$3"
ARCH="$4"

mkdir -p actions-runner && cd actions-runner

curl -o actions-runner-linux-${ARCH}-${GITHUB_RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-${ARCH}-${GITHUB_RUNNER_VERSION}.tar.gz

tar xzf ./actions-runner-linux-${ARCH}-${GITHUB_RUNNER_VERSION}.tar.gz

./config.sh --unattended --url $GITHUB_URL --token $RUNNER_TOKEN

sudo ./svc.sh install
sudo ./svc.sh start
EOF
)

ssh_exec $RUNNER_IP "echo '$CONFIGURE_RUNNER_SCRIPT' > configure_runner.sh"
echo "Script de configuration copié sur le serveur distant."


ssh_exec $RUNNER_IP "chmod +x configure_runner.sh"
echo "Script de configuration rendu exécutable."


ssh_exec $RUNNER_IP "bash configure_runner.sh $GITHUB_URL $RUNNER_TOKEN $GITHUB_RUNNER_VERSION $ARCH"
echo "Script de configuration exécuté sur le serveur distant."

echo "Configuration du runner GitHub Actions sur $RUNNER_IP terminée avec succès."