#!/bin/bash

CGO_ENABLED=0 GOOS=linux go build -o lxcfs-admission-webhook

docker build -t lxcfs-admission-webhook:v1 .

rm -rf lxcfs-admission-webhook
