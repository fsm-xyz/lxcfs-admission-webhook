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

echo "Uninstalling from namespace: $NAMESPACE"

# Delete cluster-scoped resource (ignoring namespace)
if [ -f "deployment/mutatingwebhook-ca-bundle.yaml" ]; then
    kubectl delete -f deployment/mutatingwebhook-ca-bundle.yaml
else
    # Fallback if the bundle file was deleted or not generated, try to delete by name if possible, 
    # or use the original template file (though name must match).
    # The name is fixed in the yaml: mutating-lxcfs-admission-webhook-cfg
    kubectl delete MutatingWebhookConfiguration mutating-lxcfs-admission-webhook-cfg --ignore-not-found
fi

kubectl delete -f deployment/service.yaml -n ${NAMESPACE} --ignore-not-found
kubectl delete -f deployment/deployment.yaml -n ${NAMESPACE} --ignore-not-found
kubectl delete secret lxcfs-admission-webhook-certs -n ${NAMESPACE} --ignore-not-found
kubectl delete -f deployment/daemonset.yaml -n ${NAMESPACE} --ignore-not-found
