#!/bin/bash
set -e

echo "Cleaning up resources..."

# Delete Kind cluster
if kind get clusters | grep -q "hello-world-cluster"; then
  echo "Deleting Kind cluster..."
  kind delete cluster --name hello-world-cluster
fi

# Remove Docker image
if docker images | grep -q "hello-world-nginx"; then
  echo "Removing Docker image..."
  docker rmi hello-world-nginx --force
fi

echo "Cleanup complete." 