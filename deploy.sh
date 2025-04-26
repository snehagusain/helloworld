#!/bin/bash
set -e

echo "Starting deployment..."

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed. Aborting."; exit 1; }
command -v kind >/dev/null 2>&1 || { echo "Kind is required but not installed. Aborting."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed. Aborting."; exit 1; }

# Create Kind cluster if it doesn't exist
if ! kind get clusters | grep -q "hello-world-cluster"; then
  echo "Creating Kind cluster..."
  kind create cluster --name hello-world-cluster
fi

# Build the Docker image
echo "Building Docker image..."
docker build -t hello-world-nginx .

# Load the image into Kind
echo "Loading image into Kind..."
kind load docker-image hello-world-nginx --name hello-world-cluster

# Apply Kubernetes manifests
echo "Applying Kubernetes manifests..."
kubectl apply -f k8s/

# Give the deployment a moment to create pods
echo "Waiting for pods to be created..."
sleep 5

# Check if pods exist
echo "Checking pod status..."
kubectl get pods -l app=hello-world-nginx

# Wait for pod to be ready with a retry mechanism
echo "Waiting for pod to be ready..."
ATTEMPTS=0
MAX_ATTEMPTS=10
while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
  if kubectl wait --for=condition=ready pod --selector=app=hello-world-nginx --timeout=10s; then
    echo "Pod is ready!"
    break
  else
    ATTEMPTS=$((ATTEMPTS+1))
    if [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; then
      echo "Pod not ready yet. Attempt $ATTEMPTS/$MAX_ATTEMPTS. Waiting..."
      kubectl get pods -l app=hello-world-nginx
      sleep 5
    else
      echo "Pod did not become ready after $MAX_ATTEMPTS attempts."
      echo "Proceeding anyway, but port forwarding might not work immediately."
    fi
  fi
done

# Get pod name for debugging
POD_NAME=$(kubectl get pods -l app=hello-world-nginx -o jsonpath="{.items[0].metadata.name}" 2>/dev/null || echo "No pod found")
if [ "$POD_NAME" != "No pod found" ]; then
  echo "Pod name: $POD_NAME"
  
  # Check pod details if there are issues
  echo "Pod details:"
  kubectl describe pod $POD_NAME
fi

# Set up port forwarding with a different port (8081)
echo "Setting up port forwarding..."
echo "Access the application at http://localhost:8081"
echo "Press Ctrl+C to stop port forwarding when done."
kubectl port-forward service/hello-world-nginx 8081:80

echo "Done." 