#!/bin/bash
set -e

echo "Setting up Argo CD application..."

# Create a temporary directory for Argo CD config
TEMP_CONFIG_DIR="$(mktemp -d)"
echo "Using temporary config directory: $TEMP_CONFIG_DIR"
export ARGOCD_CONFIG="$TEMP_CONFIG_DIR"

# Check if argocd CLI is installed
if ! command -v argocd &> /dev/null; then
  echo "argocd CLI not found. Installing..."
  
  # Check OS type and install accordingly
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    brew install argocd || {
      echo "Failed to install via Homebrew. Please install the argocd CLI manually."
      echo "Visit: https://argo-cd.readthedocs.io/en/stable/cli_installation/"
      exit 1
    }
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
  else
    echo "Unsupported OS. Please install the argocd CLI manually."
    echo "Visit: https://argo-cd.readthedocs.io/en/stable/cli_installation/"
    exit 1
  fi
fi

# Variables
ARGOCD_SERVER="localhost:8083"
REPO_URL=""
APP_NAME="hello-world-nginx"
NAMESPACE="default"

# Get the ArgoCD password
if [ -f argocd-password.txt ]; then
  ARGOCD_PASSWORD=$(grep "Admin password:" argocd-password.txt | cut -d' ' -f3)
else
  ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
fi

echo "For this script to work, you need:"
echo "1. A Git repository containing your Kubernetes manifests"
echo "2. ArgoCD CLI installed and ArgoCD server running"
echo ""

# Prompt for Git repository URL
read -p "Enter your Git repository URL (e.g., https://github.com/username/repo): " REPO_URL
if [ -z "$REPO_URL" ]; then
  echo "Repository URL is required. Exiting."
  exit 1
fi

# Remove /tree/master or /tree/main if included in the URL
REPO_URL=$(echo "$REPO_URL" | sed -E 's/\/tree\/(master|main)$//')

# Prompt for the path to the Kubernetes manifests in the repository
read -p "Enter the path to your Kubernetes manifests in the repository (default: k8s): " REPO_PATH
REPO_PATH=${REPO_PATH:-k8s}

# Login to ArgoCD with environment variable to specify config path
echo "Logging in to Argo CD..."
ARGOCD_HOME="$TEMP_CONFIG_DIR" argocd login "$ARGOCD_SERVER" --username admin --password "$ARGOCD_PASSWORD" --insecure

# Create application
echo "Creating Argo CD application..."
ARGOCD_HOME="$TEMP_CONFIG_DIR" argocd app create "$APP_NAME" \
  --repo "$REPO_URL" \
  --path "$REPO_PATH" \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace "$NAMESPACE" \
  --sync-policy automated \
  --auto-prune \
  --self-heal

echo "Syncing application..."
ARGOCD_HOME="$TEMP_CONFIG_DIR" argocd app sync "$APP_NAME"

echo "Application setup complete!"
echo "You can view your application in the Argo CD UI: https://$ARGOCD_SERVER"

# Clean up temporary directory
echo "Cleaning up temporary config directory..."
rm -rf "$TEMP_CONFIG_DIR" 