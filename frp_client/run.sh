#!/usr/bin/env bashio
set -e

CONFIG_PATH="/share/frpc.toml"
OPTIONS_PATH="/data/options.json"

# Гарантируем папку для конфига
mkdir -p "$(dirname "$CONFIG_PATH")"

bashio::log.info "▶ Checking for options file…"
[ -f "$OPTIONS_PATH" ] || { bashio::log.error "Options file not found at $OPTIONS_PATH"; exit 1; }

bashio::log.info "▶ Dump /data/options.json:"
cat "$OPTIONS_PATH"

# --- Читаем через jq все настройки ---
SERVER_ADDR=$(jq -r '.serverAddr'    "$OPTIONS_PATH")
SERVER_PORT=$(jq -r '.serverPort'    "$OPTIONS_PATH")
AUTH_METHOD=$(jq -r '.authMethod'    "$OPTIONS_PATH")
AUTH_TOKEN=$(jq -r '.authToken'     "$OPTIONS_PATH")
TLS_ENABLE=$(jq -r 'if .tlsEnable then "true" else "false" end' "$OPTIONS_PATH")
TLS_CERT=$(jq -r '.tlsCertFile'   "$OPTIONS_PATH")
TLS_KEY=$(jq -r '.tlsKeyFile'    "$OPTIONS_PATH")
TLS_CA=$(jq -r '.tlsCaFile'     "$OPTIONS_PATH")

bashio::log.info "▶ Parsed values: serverAddr=$SERVER_ADDR, serverPort=$SERVER_PORT, authMethod=$AUTH_METHOD, tlsEnable=$TLS_ENABLE"

# --- Генерируем секцию [common] ---
cat <<EOF >"$CONFIG_PATH"
[common]
serverAddr  = "$SERVER_ADDR"
serverPort  = $SERVER_PORT
auth.method = "$AUTH_METHOD"
auth.token  = "$AUTH_TOKEN"
log.to      = "/share/frpc.log"
log.level   = "info"
log.maxDays = 3
EOF

# --- TLS, если включён ---
if [ "$TLS_ENABLE" = "true" ]; then
  cat <<EOF >>"$CONFIG_PATH"
tls.enable        = true
tls.certFile      = "$TLS_CERT"
tls.keyFile       = "$TLS_KEY"
tls.trustedCaFile = "$TLS_CA"
EOF
fi

# --- Прокси-блоки из массива ---
bashio::log.info "▶ Appending proxies"
if jq -e '.proxies | length > 0' "$OPTIONS_PATH" >/dev/null; then
  jq -c '.proxies[]' "$OPTIONS_PATH" | while read -r proxy; do
    NAME=$(echo "$proxy" | jq -r '.name')
    TYPE=$(echo "$proxy" | jq -r '.type')
    LOCAL_IP=$(echo "$proxy" | jq -r '.localIP')
    LOCAL_PORT=$(echo "$proxy" | jq -r '.localPort')
    REMOTE_PORT=$(echo "$proxy" | jq -r '.remotePort')
    USE_ENC=$(echo "$proxy" | jq -r '.useEncryption')
    USE_COMP=$(echo "$proxy" | jq -r '.useCompression')
    DOMAINS=$(echo "$proxy" | jq -r '.customDomains | map("\""+.+"\"") | join(", ")')

    cat <<EOF >>"$CONFIG_PATH"

[[proxies]]
name                 = "$NAME"
type                 = "$TYPE"
localIP              = "$LOCAL_IP"
localPort            = $LOCAL_PORT
remotePort           = $REMOTE_PORT
custom_domains       = [${DOMAINS}]
transport.useEncryption   = $USE_ENC
transport.useCompression  = $USE_COMP
EOF
  done
else
  bashio::log.warning "⚠️ No proxies configured."
fi

# --- Лог финального конфига и запуск ---
bashio::log.info "▶ Final generated config:"
cat "$CONFIG_PATH"

bashio::log.info "▶ Starting FRPC client"
/usr/src/frpc -c "$CONFIG_PATH"
