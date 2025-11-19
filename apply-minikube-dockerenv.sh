#!/bin/bash

# Set variables
NAMESPACE=default  # Change if using a different namespace
DOCKER_IMAGE_TAG=latest  # You can change the image tag here if needed
K8S_DIR="./k8s"  # Path to the directory containing your Kubernetes manifests

# Force Docker to use Minikube's Docker daemon
eval $(minikube docker-env)
sleep 3s

# Build Docker images in Minikube's Docker daemon
echo "Building Docker images inside Minikube's Docker daemon..."
docker build -t nginx:$DOCKER_IMAGE_TAG .
docker build -t backend:$DOCKER_IMAGE_TAG ./backend
docker build -t transactions:$DOCKER_IMAGE_TAG ./transactions
docker build -t studentportfolio:$DOCKER_IMAGE_TAG ./studentportfolio

# Verify that images are built inside Minikube's Docker daemon
echo "Verifying the images in Minikube's Docker daemon..."
docker images

# Apply Kubernetes manifests from the k8s directory
echo "Applying Kubernetes manifests from the k8s directory..."
kubectl apply -f ./k8s/  # Apply all YAML files in the 'k8s' directory

# Restart deployments to pick up the newly built images
echo "Restarting deployments to pick up the newly built images..."
kubectl rollout restart deployment/backend
kubectl rollout restart deployment/transactions
kubectl rollout restart deployment/studentportfolio
kubectl rollout restart deployment/nginx

# Wait for pods to be created
echo "Waiting for the pods to be created..."
kubectl get pods --watch &

wait