ARG ARCHITECTURE
FROM multiarch/alpine:${ARCHITECTURE}-v3.12 as builder

# Add unprivileged user
RUN echo "socat:x:1000:1000:socat:/:" > /etc_passwd
# Add to dailout as secondary group (20)
RUN echo "dailout:x:20:socat" > /etc_group

# Install socat
RUN apk add --no-cache socat


FROM scratch

# Add description
LABEL org.label-schema.description="Socat as single binary in a scratch container"

# Copy the unprivileged user/group
COPY --from=builder /etc_passwd /etc/passwd
COPY --from=builder /etc_group /etc/group

# Add socat binary
COPY --from=builder /usr/bin/socat /usr/bin/socat

USER socat
ENTRYPOINT ["/usr/bin/socat"]
