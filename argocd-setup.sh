#!/bin/bash
set -e

echo "Setting up Argo CD..."

# Check if the Kubernetes cluster is running
if ! kind get clusters | grep -q "hello-world-cluster"; then
  echo "Kind cluster 'hello-world-cluster' not found. Please run './deploy.sh' first."
  exit 1
fi

# Create namespace for Argo CD
echo "Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install Argo CD
echo "Installing Argo CD (this might take a few minutes)..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD server to be ready
echo "Waiting for Argo CD server to be ready (this might take a few minutes)..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get the initial admin password
echo "Retrieving initial admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD admin password: $ARGOCD_PASSWORD"
echo "Please save this password for logging into the Argo CD UI."

# Create a file with the password for reference
echo "Admin password: $ARGOCD_PASSWORD" > argocd-password.txt
echo "Password also saved to argocd-password.txt"

# Set up port forwarding for Argo CD UI
echo "Setting up port forwarding for Argo CD UI..."
echo "Access the Argo CD UI at https://localhost:8082"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD (also saved in argocd-password.txt)"
echo "Press Ctrl+C to stop port forwarding when done."
kubectl port-forward svc/argocd-server -n argocd 8082:443 