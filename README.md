# xray-proxy

A Docker image for running a local proxy powered by **Xray**, where the outbound configuration is generated automatically from a VPN URI.

Supported URI formats:

- `vless://...`
- `vmess://...`
- `ss://...`

The URI is parsed with [`vpnparser`](https://github.com/gvcgo/vpnparser), and `xray` itself is taken from the official `ghcr.io/xtls/xray-core` image.

## What the container does

On startup, the container:

1. Reads the `VPN_URI` environment variable
2. Parses it with `vpnparser`
3. Generates an Xray `outbound` configuration
4. Creates a temporary Xray configuration
5. Starts two local proxies:
   - `SOCKS5` on port `1080`
   - `HTTP` on port `8080`

## Requirements

- Docker

## Environment variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `VPN_URI` | yes | — | Connection URI (`vless://`, `vmess://`, `ss://`, etc.) |
| `SOCKS_PORT` | no | `1080` | SOCKS5 proxy port |
| `HTTP_PORT` | no | `8080` | HTTP proxy port |
| `XRAY_LOGLEVEL` | no | `none` | Xray log level (`none`, `error`, `warning`, `info`, `debug`) |
| `HEALTHCHECK_URLS` | no | `https://connectivitycheck.gstatic.com/generate_204 https://www.google.com/generate_204 http://clients3.google.com/generate_204` | Space-separated list of URLs that return `204 No Content` and are used to check tunnel health |

## Quick start

### Build

```bash
docker build -t xray-proxy .
```

### Run

```bash
docker run -d \
  --name xray-proxy \
  -p 127.0.0.1:1080:1080 \
  -p 127.0.0.1:8080:8080 \
  -e VPN_URI='vless://...' \
  -e SOCKS_PORT=1080 \
  -e HTTP_PORT=8080 \
  -e XRAY_LOGLEVEL=warning \
  -e HEALTHCHECK_URLS='https://cp.cloudflare.com/generate_204 http://edge-http.microsoft.com/captiveportal/generate_204' \
  xray-proxy
```

### Docker Compose

Example [`compose.yml`](https://raw.githubusercontent.com/0x2badc0de/xray-proxy/refs/heads/main/compose.yml):

```yaml
services:
  xray-proxy:
    image: ghcr.io/0x2badc0de/xray-proxy:latest
    ports:
      - "127.0.0.1:1080:1080"
      - "127.0.0.1:8080:8080"
    environment:
      VPN_URI: "vless://..."
      SOCKS_PORT: "1080"
      HTTP_PORT: "8080"
      XRAY_LOGLEVEL: "none"
      HEALTHCHECK_URLS: "https://cp.cloudflare.com/generate_204 http://edge-http.microsoft.com/captiveportal/generate_204"
    restart: unless-stopped
```
