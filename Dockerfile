ARG ARCHITECTURE
FROM multiarch/alpine:${ARCHITECTURE}-v3.12 as builder

# Add unprivileged user
RUN echo "socat:x:1000:1000:socat:/:" > /etc_passwd
# Add to tty as secondary group (5) for acccess to /dev/pts/ devices
# Also add dailout (20) for default permission for the serialport
RUN echo -e "tty:x:5:socat\ndialout:x:20:" > /etc_group

# Install socat
RUN apk add --no-cache socat


# TODO: fix this
# FROM scratch
FROM multiarch/alpine:${ARCHITECTURE}-v3.12

# Add description
LABEL org.label-schema.description="Socat as single binary in a scratch container"

# Copy the unprivileged user/group
COPY --from=builder /etc_passwd /etc/passwd
COPY --from=builder /etc_group /etc/group

# Add socat binary
COPY --from=builder /usr/bin/socat /usr/bin/socat

# Add needed libs
COPY --from=builder \
  /lib/libssl.so.1.1 \
  /lib/libcrypto.so.1.1 \
  /lib/
COPY --from=builder \
  /usr/lib/libreadline.so.8 \
  /usr/lib/libncursesw.so.6 \
  /usr/lib/

# must run as root, otherwise not enough permission to create psuedo tty
ENTRYPOINT ["/usr/bin/socat"]
