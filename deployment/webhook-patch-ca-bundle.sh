#!/bin/bash

ROOT=$(cd $(dirname $0)/../../; pwd)

set -o errexit
set -o nounset
set -o pipefail


export CA_BUNDLE=$(kubectl get secret lxcfs-admission-webhook-certs -n ${NAMESPACE} -o jsonpath='{.data.ca-cert\.pem}')

if command -v envsubst >/dev/null 2>&1; then
    envsubst
else
    sed -e "s|\${CA_BUNDLE}|${CA_BUNDLE}|g" \
        -e "s|\${NAMESPACE}|${NAMESPACE}|g"
fi
