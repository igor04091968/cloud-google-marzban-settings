#!/bin/bash
# This script resets the Marzban database in the Kubernetes deployment.
# WARNING: This will delete all users and settings.

set -e

echo "--> Finding marzban-controller pod..."
POD_NAME=$(kubectl get pods -n marzban -l app=marzban-controller -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "Error: marzban-controller pod not found."
    exit 1
fi

echo "Found pod: $POD_NAME"

echo "--> Deleting database file (db.sqlite3)..."
kubectl exec -n marzban $POD_NAME -- rm /var/lib/marzban/db.sqlite3

echo "--> Restarting marzban-controller pod..."
kubectl delete pod -n marzban $POD_NAME

echo "--> Waiting for new pod to be ready..."
sleep 5
kubectl wait --for=condition=ready pod -l app=marzban-controller -n marzban --timeout=60s

echo "--> Reset complete. A new pod is running:"
kubectl get pods -n marzban -l app=marzban-controller

echo "You can now access the web UI to create a new admin user."
