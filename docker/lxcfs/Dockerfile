# Build stage
FROM debian:13-slim AS builder

# Use Aliyun mirror for Debian
# Debian 13 (Trixie) uses the new DEB822 format in /etc/apt/sources.list.d/debian.sources usually,
# or standard /etc/apt/sources.list. We try to catch both generic debian cases.
# For debian:13-slim it likely uses /etc/apt/sources.list.d/debian.sources
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources || sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    meson \
    ninja-build \
    build-essential \
    pkg-config \
    libfuse3-dev \
    fuse3 \
    python3-jinja2 \
    help2man \
    libsystemd-dev \
    systemd \
    systemd-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone and build lxcfs
WORKDIR /build
# Using the command from the user provided file
RUN git clone https://github.com/lxc/lxcfs.git
WORKDIR /build/lxcfs

# Configure and compile
ENV PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig
RUN meson setup -Dinit-script=systemd --prefix=/usr build/ \
    && meson compile -C build/ \
    && meson install -C build/ --destdir /build/install

# Identify and gather shared library dependencies
RUN mkdir -p /dist/usr/bin /dist/var/lib/lxcfs \
    && cp /build/install/usr/bin/lxcfs /dist/usr/bin/ \
    && cp -r /build/install/usr/lib /dist/usr/ \
    && cp /usr/bin/fusermount3 /dist/usr/bin/ \
    && ldd /build/install/usr/bin/lxcfs | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v --parents '{}' /dist/ \
    && ldd /build/install/usr/bin/lxcfs | grep "/lib64/ld-linux" | awk '{print $1}' | xargs -I '{}' cp -v --parents '{}' /dist/ \
    && cp /usr/bin/mount /dist/usr/bin/ \
    && ldd /usr/bin/mount | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v --parents '{}' /dist/ \
    && ldd /usr/bin/mount | grep "/lib64/ld-linux" | awk '{print $1}' | xargs -I '{}' cp -v --parents '{}' /dist/ \
    && cp /usr/bin/umount /dist/usr/bin/ \
    && ldd /usr/bin/umount | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v --parents '{}' /dist/ \
    && ldd /usr/bin/umount | grep "/lib64/ld-linux" | awk '{print $1}' | xargs -I '{}' cp -v --parents '{}' /dist/

# Final stage
FROM gcr.io/distroless/static-debian13:debug

# Copy all artifacts and dependencies from the builder
# Note: Copying a directory to / merges its contents into the root filesystem.
# This places /dist/usr/bin/lxcfs at /usr/bin/lxcfs, etc.
COPY --from=builder /dist /
COPY start.sh start.sh

# Note: Explicitly invoking the loader ensures the binary runs even if the kernel
# has trouble resolving the interpreter path in the minimal environment.
ENTRYPOINT ["./start.sh"]
