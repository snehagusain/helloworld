# Hello World NGINX on Kubernetes

A simple demonstration of deploying an NGINX web server on a local Kubernetes cluster using Kind.

## Prerequisites

- Docker
- Kind (Kubernetes in Docker)
- kubectl

## Project Structure

```
.
├── app/
│   └── index.html              # Simple HTML page
├── k8s/
│   ├── deployment.yaml         # Kubernetes deployment manifest
│   └── service.yaml            # Kubernetes service manifest
├── Dockerfile                  # Docker image configuration
├── deploy.sh                   # Deployment script
├── cleanup

https://github.com/user-attachmen

https://github.com/user-attachments/assets/1aff8b3d-622e-4654-9a54-b5dab3568ac4

ts/assets/1b13ff95-a065-49a5-bc6d-759293e0dc39

p.sh                  # Cleanup script
└── README.md                   # This file
```

## Quick Start

1. Run the deployment script:

```bash
chmod +x deploy.sh
./deploy.sh
```

This will:
- Create a Kind cluster
- Build and load the Docker image
- Deploy the application to Kubernetes
- Set up port forwarding

2. Access the application at http://localhost:9090

3. When done, clean up:

```bash
chmod +x cleanup.sh
./cleanup.sh
```

## Manual Steps

If you prefer to run commands manually:

1. Create Kind cluster:
```bash
kind create cluster --name hello-world-cluster
```

2. Build Docker image:
```bash
docker build -t hello-world-nginx .
```

3. Load image into Kind:
```bash
kind load docker-image hello-world-nginx --name hello-world-cluster
```

4. Apply Kubernetes manifests:
```bash
kubectl apply -f k8s/
```

5. Set up port forwarding:
```bash
kubectl port-forward service/hello-world-nginx 8081:80
```

6. Access argo at https://localhost:8083/settings/repos?addRepo=false


