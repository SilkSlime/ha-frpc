#!/usr/bin/env bashio
set -e

CONFIG_PATH="/share/frpc.toml"
OPTIONS_PATH="/data/options.json"

mkdir -p "$(dirname "$CONFIG_PATH")"

bashio::log.info "▶ Checking if options file exists..."
if [ ! -f "$OPTIONS_PATH" ]; then
  bashio::log.error "❌ Options file not found at $OPTIONS_PATH"
  exit 1
fi

bashio::log.info "▶ Dumping options.json:"
cat "$OPTIONS_PATH"

# === Читаем параметры в переменные
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

# === [common]
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

# === TLS
if [ "$TLS_ENABLE" = "true" ]; then
  cat <<EOF >>"$CONFIG_PATH"
tls.enable        = true
tls.certFile      = "$TLS_CERT"
tls.keyFile       = "$TLS_KEY"
tls.trustedCaFile = "$TLS_CA"
EOF
fi

# === Proxies
bashio::log.info "▶ Appending proxies"
if bashio::config.has_value 'proxies'; then
  for i in $(bashio::config 'proxies|keys'); do
    NAME=$(bashio::config "proxies[${i}].name")
    TYPE=$(bashio::config "proxies[${i}].type")
    LOCAL_IP=$(bashio::config "proxies[${i}].localIP")
    LOCAL_PORT=$(bashio::config "proxies[${i}].localPort")
    REMOTE_PORT=$(bashio::config "proxies[${i}].remotePort")
    ENC=$(bashio::config "proxies[${i}].useEncryption")
    COMP=$(bashio::config "proxies[${i}].useCompression")

    echo -e "\n[[proxies]]" >>"$CONFIG_PATH"
    echo "name = \"$NAME\"" >>"$CONFIG_PATH"
    echo "type = \"$TYPE\"" >>"$CONFIG_PATH"
    echo "localIP = \"$LOCAL_IP\"" >>"$CONFIG_PATH"
    echo "localPort = $LOCAL_PORT" >>"$CONFIG_PATH"
    echo "remotePort = $REMOTE_PORT" >>"$CONFIG_PATH"

    # customDomains
    if bashio::config.has_value "proxies[${i}].customDomains"; then
      DOMAINS=$(bashio::config "proxies[${i}].customDomains" | jq -r '. | map("\""+.+"\"") | join(", ")')
      echo "customDomains = [${DOMAINS}]" >>"$CONFIG_PATH"
    fi

    echo "transport.useEncryption = $ENC" >>"$CONFIG_PATH"
    echo "transport.useCompression = $COMP" >>"$CONFIG_PATH"
  done
else
  bashio::log.warning "⚠️ No proxies configured — FRP will start without tunnels."
fi

# === Финальный вывод и запуск
bashio::log.info "▶ Final generated config:"
cat "$CONFIG_PATH"

bashio::log.info "▶ Starting FRPC client"
/usr/src/frpc -c "$CONFIG_PATH"
