#!/bin/bash

echo "🚀 Simple ArgoCD Setup for macOS"
echo "================================="

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS. For Linux, use the original argocd-setup.sh"
    exit 1
fi

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install required tools
echo "🔧 Installing required tools..."
brew install colima docker kind kubectl helm

# Start Colima (Docker runtime without Docker Desktop)
echo "🐳 Starting Colima (lightweight Docker runtime)..."
colima start --cpu 2 --memory 4

# Wait for Docker to start
echo "⏳ Waiting for Docker to start..."
while ! docker info &> /dev/null; do
    echo "Waiting for Docker..."
    sleep 5
done

# Create Kind cluster
echo "🏗️  Creating Kubernetes cluster with Kind..."
kind create cluster --name argocd-demo

# Install ArgoCD
echo "🎯 Installing ArgoCD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get ArgoCD password
echo "🔑 Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Port forward ArgoCD server
echo "🌐 Starting port forward to ArgoCD server..."
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
PORT_FORWARD_PID=$!

# Install ArgoCD CLI
echo "🛠️  Installing ArgoCD CLI..."
brew install argocd

echo ""
echo "✅ Setup Complete!"
echo "=================="
echo "🌐 ArgoCD UI: https://localhost:8080"
echo "👤 Username: admin"
echo "🔑 Password: $ARGOCD_PASSWORD"
echo ""
echo "📝 Next steps:"
echo "1. Open https://localhost:8080 in your browser"
echo "2. Login with admin / $ARGOCD_PASSWORD"
echo "3. Deploy your first app with:"
echo "   kubectl apply -f simple-demo/argocd-apps/simple-nginx-application.yaml"
echo ""
echo "🛑 To stop: kill $PORT_FORWARD_PID && kind delete cluster --name argocd-demo && colima stop"