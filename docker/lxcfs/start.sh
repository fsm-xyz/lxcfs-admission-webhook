#!/busybox/sh

exec /usr/bin/lxcfs /var/lib/lxcfs/ -u -l --enable-cfs --enable-pidfd --enable-cgroup
