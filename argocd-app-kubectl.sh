#!/bin/bash
set -e

echo "Setting up Argo CD application using kubectl..."

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

# Create an Application manifest
TEMPFILE=$(mktemp)
cat > "$TEMPFILE" << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hello-world-nginx
  namespace: argocd
spec:
  project: default
  source:
    repoURL: $REPO_URL
    targetRevision: HEAD
    path: $REPO_PATH
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

echo "Applying Application manifest to cluster..."
kubectl apply -f "$TEMPFILE"
rm "$TEMPFILE"

echo "Application created!"
echo "You can view your application in the Argo CD UI"
echo "The application will automatically sync with your Git repository" 