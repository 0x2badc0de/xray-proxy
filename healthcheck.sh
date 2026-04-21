#!/bin/sh
set -eu

HTTP_PORT="${HTTP_PORT:-8080}"
PROXY="http://127.0.0.1:${HTTP_PORT}"
HEALTHCHECK_URLS="${HEALTHCHECK_URLS:-https://connectivitycheck.gstatic.com/generate_204 https://www.google.com/generate_204 http://clients3.google.com/generate_204}"

for url in $HEALTHCHECK_URLS; do
  code="$(
    curl --silent --show-error \
      --output /dev/null \
      --write-out '%{http_code}' \
      --proxy "$PROXY" \
      --connect-timeout 5 \
      --max-time 10 \
      "$url" || true
  )"

  [ "$code" = "204" ] && exit 0
done

exit 1
