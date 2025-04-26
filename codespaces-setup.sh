#!/bin/bash
set -e

echo "Setting up Kubernetes and application in GitHub Codespaces..."

# Install required tools
echo "Installing necessary tools..."

# Install kubectl if not present
if ! command -v kubectl &> /dev/null; then
  echo "Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

# Install k3d (lightweight Kubernetes for Docker in Codespaces)
if ! command -v k3d &> /dev/null; then
  echo "Installing k3d..."
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# Create k3d cluster
echo "Creating Kubernetes cluster with k3d..."
k3d cluster create hello-world-cluster || {
  echo "Cluster may already exist, trying to continue..."
}

# Verify cluster
echo "Verifying cluster connection..."
kubectl cluster-info

# Build and load the Docker image
echo "Building Docker image..."
docker build -t hello-world-nginx .

# Load the image into k3d
echo "Loading image into k3d cluster..."
k3d image import hello-world-nginx -c hello-world-cluster

# Apply Kubernetes manifests
echo "Applying Kubernetes manifests..."
kubectl apply -f k8s/

# Wait for pod to be ready
echo "Waiting for pods to be ready..."
sleep 5
kubectl get pods -l app=hello-world-nginx
kubectl wait --for=condition=ready pod --selector=app=hello-world-nginx --timeout=60s || {
  echo "Warning: Pod may not be ready yet, but continuing..."
  kubectl get pods -l app=hello-world-nginx
}

# Install Argo CD
echo "Installing Argo CD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD server to be ready (this might take a few minutes)..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || {
  echo "Warning: ArgoCD server deployment not ready yet, but continuing..."
}

# Get the initial admin password
echo "Retrieving initial admin password..."
sleep 10  # Give some time for the secret to be created
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > argocd-password.txt
echo "Argo CD admin password saved to argocd-password.txt"

# Set up port forwarding for both applications
echo "Setting up port forwarding for applications..."
echo ""
echo "To access Argo CD UI, run in terminal 1:"
echo "kubectl port-forward svc/argocd-server -n argocd 8083:443"
echo ""
echo "To access Hello World app, run in terminal 2:"
echo "kubectl port-forward svc/hello-world-nginx 8085:80"
echo ""
echo "IMPORTANT: In GitHub Codespaces, make sure to forward these ports in the Ports tab"
echo "Remember to make the ports public or accessible as needed"
echo ""
echo "Setup complete! To connect Argo CD to your Git repo, run:"
echo "./argocd-app-kubectl.sh" 