#!/bin/bash
# Default values
REGISTRY=${1:-registry.cn-hangzhou.aliyuncs.com}
NAMESPACE=${2:-denverdino}
LXCFS_TAG=${3:-3.1.2}
WEBHOOK_TAG=${4:-v1}

echo "Using REGISTRY: $REGISTRY"
echo "Using NAMESPACE: $NAMESPACE"

# Build and push lxcfs image
docker build -t ${REGISTRY}/${NAMESPACE}/lxcfs:${LXCFS_TAG} ./docker/lxcfs
docker push ${REGISTRY}/${NAMESPACE}/lxcfs:${LXCFS_TAG}

# Build webhook binary and image
./build.sh
docker tag lxcfs-admission-webhook:${WEBHOOK_TAG} ${REGISTRY}/${NAMESPACE}/lxcfs-admission-webhook:${WEBHOOK_TAG}
docker push ${REGISTRY}/${NAMESPACE}/lxcfs-admission-webhook:${WEBHOOK_TAG}
