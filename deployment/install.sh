#!/bin/bash

# Check if a specific namespace is provided as an argument
if [ -n "$1" ]; then
    export NAMESPACE="$1"
else
    # Try to get the namespace from the current context
    export NAMESPACE=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    # If no namespace is set in the current context, default to "default"
    if [ -z "$NAMESPACE" ]; then
        export NAMESPACE="default"
    fi
fi

# Default values for images if not set
export LXCFS_IMAGE=${LXCFS_IMAGE:-lxcfs:6.0.5}
export WEBHOOK_IMAGE=${WEBHOOK_IMAGE:-lxcfs-admission-webhook:v1}

echo "Deploying to namespace: $NAMESPACE"
echo "Using LXCFS Image:      $LXCFS_IMAGE"
echo "Using Webhook Image:    $WEBHOOK_IMAGE"

./deployment/webhook-create-signed-cert.sh --namespace ${NAMESPACE}
kubectl get secret lxcfs-admission-webhook-certs -n ${NAMESPACE}

# Deploy with image substitution
if command -v envsubst >/dev/null 2>&1; then
    envsubst < deployment/daemonset.yaml | kubectl apply -f - -n ${NAMESPACE}
    envsubst < deployment/deployment.yaml | kubectl apply -f - -n ${NAMESPACE}
else
    sed -e "s|\${LXCFS_IMAGE}|${LXCFS_IMAGE}|g" deployment/daemonset.yaml | kubectl apply -f - -n ${NAMESPACE}
    sed -e "s|\${WEBHOOK_IMAGE}|${WEBHOOK_IMAGE}|g" deployment/deployment.yaml | kubectl apply -f - -n ${NAMESPACE}
fi

kubectl apply -f deployment/service.yaml -n ${NAMESPACE}
cat ./deployment/mutatingwebhook.yaml | ./deployment/webhook-patch-ca-bundle.sh > ./deployment/mutatingwebhook-ca-bundle.yaml
kubectl apply -f deployment/mutatingwebhook-ca-bundle.yaml
