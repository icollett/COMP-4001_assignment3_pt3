#!/bin/bash

# Set variables for Kubernetes resources
DEPLOYMENTS=("backend" "nginx" "transactions" "mongo" "studentportfolio")
SERVICES=("backend" "kubernetes" "nginx" "transactions" "mongo" "studentportfolio")

# Delete all deployments
echo "Deleting all deployments..."
for dep in "${DEPLOYMENTS[@]}"; do
  kubectl delete deploy "$dep" --ignore-not-found
done

# Delete all services
echo "Deleting all services..."
for svc in "${SERVICES[@]}"; do
  kubectl delete service "$svc" --ignore-not-found
done

# Stop Minikube
echo "Stopping Minikube..."
minikube stop

# Delete Minikube
echo "Deleting Minikube..."
minikube delete

# Remove residual Docker images (force remove all Docker images)
echo "Removing all residual Docker images..."
sudo docker rmi $(docker images -aq)

# Clean up the Docker system (remove unused data, volumes, etc.)
echo "Cleaning up Docker system..."
sudo docker system prune -a -f

# Delete all Minikube clusters
echo "Deleting all Minikube clusters..."
minikube delete --all

# Purge Minikube configuration and data (deep clean)
echo "Purging Minikube..."
minikube delete --purge

# Final confirmation message
echo "Teardown complete! All resources have been cleaned up."
