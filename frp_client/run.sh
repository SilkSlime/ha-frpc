#!/usr/bin/env bashio
set -e

CONFIG_PATH="/share/frpc.toml"
OPTIONS_PATH="/data/options.json"

mkdir -p "$(dirname "$CONFIG_PATH")"

bashio::log.info "▶ Checking if options file exists…"
[ -f "$OPTIONS_PATH" ] || { bashio::log.error "Options not found"; exit 1; }

bashio::log.info "▶ Dumping options.json:"
cat "$OPTIONS_PATH"

# — Правильное чтение в переменные (без пробелов вокруг =)
SERVER_ADDR=$(bashio::config 'serverAddr')
SERVER_PORT=$(bashio::config 'serverPort')
AUTH_METHOD=$(bashio::config 'authMethod')
AUTH_TOKEN=$(bashio::config 'authToken')
TLS_ENABLE=$(bashio::config 'tlsEnable')
TLS_CERT=$(bashio::config 'tlsCertFile')
TLS_KEY=$(bashio::config 'tlsKeyFile')
TLS_CA=$(bashio::config 'tlsCaFile')

bashio::log.info "▶ Parsed values:"
bashio::log.info "serverAddr  = $SERVER_ADDR"
bashio::log.info "serverPort  = $SERVER_PORT"
bashio::log.info "authMethod  = $AUTH_METHOD"
bashio::log.info "authToken   = $AUTH_TOKEN"
bashio::log.info "tlsEnable   = $TLS_ENABLE"

# — [common]
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

# — TLS
if [ "$TLS_ENABLE" = "true" ]; then
  cat <<EOF >>"$CONFIG_PATH"
tls.enable        = true
tls.certFile      = "$TLS_CERT"
tls.keyFile       = "$TLS_KEY"
tls.trustedCaFile = "$TLS_CA"
EOF
fi

# — proxies
bashio::log.info "▶ Appending proxies"
if jq -e '.proxies | length>0' "$OPTIONS_PATH" >/dev/null 2>&1; then
  jq -c '.proxies[]' "$OPTIONS_PATH" | while read -r proxy; do
    NAME=$(echo "$proxy" | jq -r '.name')
    TYPE=$(echo "$proxy" | jq -r '.type')
    LOCAL_IP=$(echo "$proxy" | jq -r '.localIP')
    LOCAL_PORT=$(echo "$proxy" | jq -r '.localPort')
    REMOTE_PORT=$(echo "$proxy" | jq -r '.remotePort')
    DOMAINS=$(echo "$proxy" | jq -r '.customDomains | map("\""+.+"\"") | join(", ")')
    USE_ENC=$(echo "$proxy" | jq -r '.useEncryption')
    USE_COMP=$(echo "$proxy" | jq -r '.useCompression')

    cat <<EOF >>"$CONFIG_PATH"

[[proxies]]
name                 = "$NAME"
type                 = "$TYPE"
localIP              = "$LOCAL_IP"
localPort            = $LOCAL_PORT
remotePort           = $REMOTE_PORT
customDomains        = [${DOMAINS}]
transport.useEncryption   = $USE_ENC
transport.useCompression  = $USE_COMP
EOF
  done
else
  bashio::log.warning "⚠️ No proxies configured."
fi

# — финальный вывод и запуск
bashio::log.info "▶ Final generated config:"
cat "$CONFIG_PATH"

bashio::log.info "▶ Starting FRPC client"
/usr/src/frpc -c "$CONFIG_PATH"
