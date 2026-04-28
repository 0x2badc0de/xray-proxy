# xray-proxy

Docker-образ для запуска локального proxy на базе **Xray**, где outbound-конфиг автоматически генерируется из VPN URI.

Поддерживаются ссылки формата:

- `vless://...`
- `vmess://...`
- `ss://...`

Для разбора URI используется [`vpnparser`](https://github.com/gvcgo/vpnparser), а сам `xray` берется из официального образа `ghcr.io/xtls/xray-core`.

## Что делает контейнер

При старте контейнер:

1. Берет значение переменной окружения `VPN_URI`
2. Прогоняет его через `vpnparser`
3. Генерирует `outbound` для Xray
4. Создает временный конфиг Xray
5. Поднимает два локальных proxy:
   - `SOCKS5` на порту `1080`
   - `HTTP` на порту `8080`

## Требования

- Docker

## Переменные окружения

| Переменная      | Обязательная | По умолчанию | Описание |
|----------------|--------------|--------------|----------|
| `VPN_URI`      | да           | —            | URI подключения (`vless://`, `vmess://`, `ss://` и т.д.) |
| `SOCKS_PORT`   | нет          | `1080`       | Порт SOCKS5 proxy |
| `HTTP_PORT`    | нет          | `8080`       | Порт HTTP proxy |
| `XRAY_LOGLEVEL`| нет          | `none`       | Уровень логов Xray (`none`, `error`, `warning`, `info`, `debug`) |
| `HEALTHCHECK_URLS`| нет          | `https://connectivitycheck.gstatic.com/generate_204 https://www.google.com/generate_204 http://clients3.google.com/generate_204`       | Список ссылок разделенных пробелом, возвращающих `204 No content` для проверки состояния туннеля |

## Быстрый старт

### Сборка

```bash
docker build -t xray-proxy .
```

### Запуск

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

### Через compose

Пример [`compose.yml`](https://raw.githubusercontent.com/0x2badc0de/xray-proxy/refs/heads/main/compose.yml):

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
