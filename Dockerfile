ARG ARCHITECTURE
FROM multiarch/alpine:${ARCHITECTURE}-v3.12 as builder

# Socat version see:
# http://www.dest-unreach.org/socat/
ENV VERSION=1.7.4.1

# Add unprivileged user
RUN echo "socat:x:1000:1000:socat:/:" > /etc_passwd
# Add to tty as secondary group (5) for acccess to /dev/pts/ devices
# Also add dailout (20) for default permission for the serialport
RUN echo -e "tty:x:5:socat\ndialout:x:20:" > /etc_group

# Install build needs
RUN apk add --no-cache \
  build-base \
  linux-headers \
  openssl-dev \
  openssl-libs-static

RUN wget -qO- http://www.dest-unreach.org/socat/download/socat-${VERSION}.tar.gz | \
    tar -zxC "/tmp" --strip-components=1

WORKDIR /tmp

# Source: https://git.alpinelinux.org/aports/tree/main/socat/
RUN wget -qO- https://git.alpinelinux.org/aports/plain/main/socat/use-linux-headers.patch | patch

# NOTE: `NETDB_INTERNAL` is non-POSIX, and thus not defined by MUSL.
# We define it this way manually.
# libwrap not available on alpine
# readline not needed (and not working with the alpine provided packages)
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
    export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
    CFLAGS="-Wall -O3 -static" LDFLAGS="-static" CPPFLAGS="-DNETDB_INTERNAL=-1" ./configure \
      --disable-libwrap \
      --disable-readline && \
    make

# 'Install' upx from image since upx isn't available for aarch64 from Alpine
COPY --from=lansible/upx /usr/bin/upx /usr/bin/upx
# Minify binaries
# no upx: 13M
# upx: 4.7M
# --best: 4.6M
# --brute does not work
RUN upx --best socat && \
    upx -t socat


FROM scratch

# Add description
LABEL org.label-schema.description="Socat as single binary in a scratch container"

# Copy the unprivileged user/group
COPY --from=builder /etc_passwd /etc/passwd
COPY --from=builder /etc_group /etc/group

# Add socat binary
COPY --from=builder /tmp/socat /usr/bin/socat

# must run as root, otherwise not enough permission to create psuedo tty
ENTRYPOINT ["/usr/bin/socat"]
