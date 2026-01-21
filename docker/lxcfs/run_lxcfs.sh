#!/bin/bash

./build.sh

# Run with privileged access to allow fuse mounting
# We mount /var/lib/lxcfs to host so we can see the result if needed, 
# or just let it run to verify it starts.
echo "Starting lxcfs container..."
docker run --rm -it \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  lxcfs:latest
