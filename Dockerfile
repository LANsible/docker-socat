ARG ARCHITECTURE
FROM multiarch/alpine:${ARCHITECTURE}-v3.12 as builder

RUN apk add --no-cache socat


FROM scratch

COPY --from=builder /usr/bin/socat /usr/bin/socat

ENTRYPOINT ["/usr/bin/socat"]
