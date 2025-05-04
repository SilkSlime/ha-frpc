#!/usr/bin/env bashio
set -e

CONFIG_PATH="/share/frpc.toml"
mkdir -p /share
bashio::log.info "▶ Generating FRPC config"

# [common]
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
bashio::log.info "▶ Appending user proxies"
echo "" >>"$CONFIG_PATH"
bashio::config 'frpcConfig' >>"$CONFIG_PATH"

# Replace shell with FRPC so FRPC is PID 1 (no s6-overlay error)
bashio::log.info "▶ Starting FRPC client"
/usr/src/frpc -c "$CONFIG_PATH"
