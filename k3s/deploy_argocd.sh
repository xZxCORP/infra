NAMESPACE="argocd"
RELEASE_NAME="argocd"
CHART_NAME="argo/argo-cd"
SECRET_NAME="argocd-initial-admin-secret"

if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
  echo "Namespace $NAMESPACE does not exist. Creating..."
  kubectl create namespace $NAMESPACE
else
  echo "Namespace $NAMESPACE already exists. Skipping creation."
fi

if ! helm repo list | grep -q 'https://argoproj.github.io/argo-helm'; then
  echo "Adding Argo Helm repository..."
  helm repo add argo https://argoproj.github.io/argo-helm
else
  echo "Argo Helm repository already added. Skipping."
fi

echo "Updating Helm repositories..."
helm repo update

if ! helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
  echo "Argo CD is not installed. Installing..."
  helm install $RELEASE_NAME $CHART_NAME --namespace $NAMESPACE
else
  echo "Argo CD is already installed. Skipping installation."
fi

echo "Retrieving Argo CD initial admin password..."
kubectl -n $NAMESPACE get secret $SECRET_NAME -o jsonpath="{.data.password}" | base64 -d && echo