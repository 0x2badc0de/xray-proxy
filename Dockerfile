## args

ARG XRAY_VERSION=26.4.17

## compile vpnparser

FROM golang:1.26-alpine AS vpnparser-builder

RUN apk add --no-cache git ca-certificates
RUN go install github.com/gvcgo/vpnparser@latest


## precompiled xray

FROM ghcr.io/xtls/xray-core:${XRAY_VERSION} AS xray-src


## final image

FROM alpine:3.21

RUN apk add --no-cache ca-certificates jq tzdata \
    && addgroup -S xray \
    && adduser -S -D -H -h /var/lib/xray -s /sbin/nologin -G xray xray \
    && mkdir -p /app/xray /usr/local/etc/xray /usr/local/share/xray /var/log/xray /var/lib/xray

COPY --from=xray-src /usr/local/bin/xray /usr/local/bin/xray
COPY --from=xray-src /usr/local/share/xray /usr/local/share/xray
COPY --from=xray-src /usr/local/etc/xray /usr/local/etc/xray
COPY --from=vpnparser-builder /go/bin/vpnparser /usr/local/bin/vpnparser

COPY entrypoint.sh /app/entrypoint.sh
RUN sed -i 's/\r$//' /app/entrypoint.sh \
    && chown -R xray:xray /app /usr/local/etc/xray /usr/local/share/xray /var/log/xray /var/lib/xray \
    && chmod +x /app/entrypoint.sh

ENV SOCKS_PORT=1080 \
    HTTP_PORT=8080 \
    XRAY_LOGLEVEL=none

WORKDIR /app
USER xray
EXPOSE 1080 8080
ENTRYPOINT ["./entrypoint.sh"]
