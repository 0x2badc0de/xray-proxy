#!/bin/sh
set -eu

: "${VPN_URI:?VPN_URI env var is required}"

CONF_DIR="/app/xray"
RAW_OUT="/tmp/vpnparser.txt"
TMP_OUT="/tmp/outbound.json"

vpnparser x "$VPN_URI" > "$RAW_OUT"

awk '
  /^\{/ {json=1}
  json {print}
' "$RAW_OUT" > "$TMP_OUT"

jq -e . "$TMP_OUT" >/dev/null

cat > "${CONF_DIR}/00_log.json" <<EOF
{
  "log": {
    "loglevel": "${XRAY_LOGLEVEL:-none}"
  }
}
EOF

cat > "${CONF_DIR}/05_inbounds.json" <<EOF
{
  "inbounds": [
    {
      "tag": "socks-in",
      "listen": "0.0.0.0",
      "port": ${SOCKS_PORT:-1080},
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"]
      }
    },
    {
      "tag": "http-in",
      "listen": "0.0.0.0",
      "port": ${HTTP_PORT:-8080},
      "protocol": "http",
      "settings": {}
    }
  ]
}
EOF

jq -n \
  --slurpfile outbound "$TMP_OUT" \
  '{
    "outbounds": [
      $outbound[0],
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ]
  }' > "${CONF_DIR}/06_outbounds.json"

exec /usr/local/bin/xray run -confdir="${CONF_DIR}"