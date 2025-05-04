#!/usr/bin/env bashio

CONFIG_PATH="/share/frpc.toml"
bashio::log.info "▶ Generating FRPC config"

# [common] section
cat <<EOF >"$CONFIG_PATH"
[common]
serverAddr   = "$(bashio::config 'serverAddr')"
serverPort   = $(bashio::config 'serverPort')
auth.method  = "$(bashio::config 'authMethod')"
auth.token   = "$(bashio::config 'authToken')"
log.to       = "/share/frpc.log"
log.level    = "info"
log.maxDays  = 3
EOF

# TLS block
if bashio::config.true 'tlsEnable'; then
  cat <<EOF >>"$CONFIG_PATH"
tls.enable          = true
tls.certFile        = "$(bashio::config 'tlsCertFile')"
tls.keyFile         = "$(bashio::config 'tlsKeyFile')"
tls.trustedCaFile   = "$(bashio::config 'tlsCaFile')"
EOF
fi

# Append user-defined proxies
bashio::log.info "▶ Appending user proxies"
echo "" >>"$CONFIG_PATH"
cat <<EOF >>"$CONFIG_PATH"
$(bashio::config 'frpcConfig')
EOF

# Start FRP client
bashio::log.info "▶ Starting FRP client"
trap 'bashio::log.info "⏹ Stopping FRP client"; kill 0' SIGINT SIGTERM
/usr/src/frpc -c "$CONFIG_PATH" &
wait
