#!/bin/bash

# Set variables
NAMESPACE=default  # Change if using a different namespace
DOCKER_IMAGE_TAG=latest  # You can change the image tag here if needed
K8S_DIR="./k8s"  # Path to the directory containing your Kubernetes manifests

# Force Docker to use Minikube's Docker daemon
eval $(minikube -p minikube docker-env)

# Build Docker images in Minikube's Docker daemon
echo "Building Docker images inside Minikube's Docker daemon..."
docker build -t backend:$DOCKER_IMAGE_TAG ./backend
docker build -t transactions:$DOCKER_IMAGE_TAG ./transactions
docker build -t studentportfolio:$DOCKER_IMAGE_TAG ./studentportfolio
docker build -t nginx:$DOCKER_IMAGE_TAG ./nginx

# Verify that images are built inside Minikube's Docker daemon
echo "Verifying the images in Minikube's Docker daemon..."
docker images

# Apply Kubernetes manifests from the k8s directory
echo "Applying Kubernetes manifests from the k8s directory..."
kubectl apply -f $K8S_DIR/mongo-service.yaml
kubectl apply -f $K8S_DIR/mongo-statefulset.yaml
kubectl apply -f $K8S_DIR/backend-deployment.yaml
kubectl apply -f $K8S_DIR/backend-service.yaml
kubectl apply -f $K8S_DIR/transactions-deployment.yaml
kubectl apply -f $K8S_DIR/transactions-service.yaml
kubectl apply -f $K8S_DIR/studentportfolio-deployment.yaml
kubectl apply -f $K8S_DIR/studentportfolio-service.yaml
kubectl apply -f $K8S_DIR/nginx-deployment.yaml
kubectl apply -f $K8S_DIR/nginx-service.yaml

# Restart deployments to pick up the newly built images
echo "Restarting deployments to pick up the newly built images..."
kubectl rollout restart deployment/backend
kubectl rollout restart deployment/transactions
kubectl rollout restart deployment/studentportfolio
kubectl rollout restart deployment/nginx

# Wait for pods to be created
echo "Waiting for the pods to be created..."
kubectl get pods --watch &

# Expose Nginx service with minikube
echo "Launching the application with minikube service nginx..."
minikube service nginx

# Stop the watch command (optional)
wait
