#!/bin/bash

set -e

usage() {
    cat <<EOF
Generate certificate suitable for use with an sidecar-injector webhook service.

This script uses k8s' CertificateSigningRequest API to a generate a
certificate signed by k8s CA suitable for use with sidecar-injector webhook
services. This requires permissions to create and approve CSR. See
https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster for
detailed explantion and additional instructions.

The server key/cert k8s CA cert are stored in a k8s secret.

usage: ${0} [OPTIONS]

The following flags are required.

       --service          Service name of webhook.
       --namespace        Namespace where webhook service and secret reside.
       --secret           Secret name for CA certificate and server certificate/key pair.
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case ${1} in
        --service)
            service="$2"
            shift
            ;;
        --secret)
            secret="$2"
            shift
            ;;
        --namespace)
            namespace="$2"
            shift
            ;;
        *)
            usage
            ;;
    esac
    shift
done

[ -z ${service} ] && service=lxcfs-admission-webhook
[ -z ${secret} ] && secret=lxcfs-admission-webhook-certs
if [ -z ${namespace} ]; then
    namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    if [ -z ${namespace} ]; then
        namespace=default
    fi
fi

if [ ! -x "$(command -v openssl)" ]; then
    echo "openssl not found"
    exit 1
fi


# create certs in tmpdir
csrName=${service}.${namespace}
tmpdir=$(mktemp -d)
echo "creating certs in tmpdir ${tmpdir} "

cat <<EOF >> ${tmpdir}/csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${service}
DNS.2 = ${service}.${namespace}
DNS.3 = ${service}.${namespace}.svc
EOF

# 1. Generate CA
openssl genrsa -out ${tmpdir}/ca.key 2048
openssl req -x509 -new -nodes -key ${tmpdir}/ca.key -days 36500 -out ${tmpdir}/ca.crt -subj "/CN=Admission Webhook CA"

# 2. Generate Server Key/CSR
openssl genrsa -out ${tmpdir}/server.key 2048
openssl req -new -key ${tmpdir}/server.key -subj "/CN=${service}.${namespace}.svc" -out ${tmpdir}/server.csr -config ${tmpdir}/csr.conf

# 3. Sign Server Cert with CA
openssl x509 -req -in ${tmpdir}/server.csr -CA ${tmpdir}/ca.crt -CAkey ${tmpdir}/ca.key -CAcreateserial -out ${tmpdir}/server.crt -days 36500 -extensions v3_req -extfile ${tmpdir}/csr.conf

# 4. Create Secret
# We include ca-cert.pem so we can fetch it later for the bundle
kubectl create secret generic ${secret} \
        --from-file=key.pem=${tmpdir}/server.key \
        --from-file=cert.pem=${tmpdir}/server.crt \
        --from-file=ca-cert.pem=${tmpdir}/ca.crt \
        --dry-run=client -o yaml |
    kubectl -n ${namespace} apply -f -

