# Argo CD Integration Guide

This guide explains how to set up Argo CD for GitOps-based deployment of the Hello World NGINX application.

## What is Argo CD?

Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes. It follows the GitOps pattern where the desired state of your application is stored in Git, and Argo CD ensures the actual state in your Kubernetes cluster matches it.

## Prerequisites

- A running Kubernetes cluster (created with Kind in our case)
- kubectl configured to interact with your cluster
- A Git repository to store your Kubernetes manifests
- Git credentials if using a private repository

## Setup Process

We've provided two scripts to simplify the Argo CD setup:

1. `argocd-setup.sh` - Installs Argo CD in your Kubernetes cluster
2. `argocd-app-setup.sh` - Configures a Git-based application in Argo CD

### Step 1: Install Argo CD

Run the setup script:

```bash
chmod +x argocd-setup.sh
./argocd-setup.sh
```

This script will:
- Create an `argocd` namespace
- Install all Argo CD components
- Retrieve the initial admin password
- Set up port forwarding to access the Argo CD UI

Keep this terminal window open to maintain the port forwarding, or use the following command to restart it later:

```bash
kubectl port-forward svc/argocd-server -n argocd 8083:443
```

### Step 2: Push Your Kubernetes Manifests to Git

Before configuring the application in Argo CD, you need to push your Kubernetes manifests to a Git repository:

1. Create a Git repository (if you don't have one already)
2. Copy the `k8s` directory to your repository
3. Commit and push the files

Example:
```bash
# Clone your repository
git clone https://github.com/yourusername/your-repo.git
cd your-repo

# Copy the k8s directory
cp -r /path/to/hello2/k8s .

# Commit and push
git add k8s
git commit -m "Add Kubernetes manifests for Hello World NGINX"
git push
```

### Step 3: Configure the Application in Argo CD

Run the application setup script:

```bash
chmod +x argocd-app-setup.sh
./argocd-app-setup.sh
```

This script will:
- Install the Argo CD CLI if needed
- Prompt for your Git repository URL
- Configure a GitOps application in Argo CD
- Set up automatic synchronization

### Step 4: Access the Argo CD UI

The Argo CD UI is available at https://localhost:8083

Login credentials:
- Username: admin
- Password: (saved in argocd-password.txt)

Note: Your browser may warn about an invalid certificate. This is expected for the local deployment. You can proceed safely.

## How GitOps Works with Argo CD

1. You make changes to the Kubernetes manifests in your Git repository
2. You commit and push those changes
3. Argo CD detects the changes in the repository
4. Argo CD automatically applies the changes to your Kubernetes cluster

This creates a continuous delivery pipeline where Git becomes the single source of truth for your deployment configuration.

## Cleanup

When you're done with Argo CD, you can uninstall it using:

```bash
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
```

## Further Resources

- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Guide](https://www.gitops.tech/)
- [Argo CD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/) 