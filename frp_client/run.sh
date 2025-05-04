#!/usr/bin/env bashio

CONFIG_PATH="/share/frpc.toml"
bashio::log.info "▶ Generating FRPC config"

# common section
cat <<EOF >"$CONFIG_PATH"
[common]
serverAddr  = "$(bashio::config 'serverAddr')"
serverPort  = $(bashio::config 'serverPort')
auth.method = "$(bashio::config 'authMethod')"
auth.token  = "$(bashio::config 'authToken')"
log.to      = "/share/frpc.log"
log.level   = "info"
log.maxDays = 3
EOF

# TLS
if bashio::config.true 'tlsEnable'; then
  cat <<EOF >>"$CONFIG_PATH"
tls.enable        = true
tls.certFile      = "$(bashio::config 'tlsCertFile')"
tls.keyFile       = "$(bashio::config 'tlsKeyFile')"
tls.trustedCaFile = "$(bashio::config 'tlsCaFile')"
EOF
fi

# user proxies
bashio::log.info "▶ Appending [[proxies]]"
echo "" >>"$CONFIG_PATH"
bashio::config 'frpcConfig' >>"$CONFIG_PATH"

# start client
bashio::log.info "▶ Starting FRPC"
trap 'bashio::log.info "⏹ Stopping FRPC"; kill 0' SIGINT SIGTERM
/usr/src/frpc -c "$CONFIG_PATH" &
wait
