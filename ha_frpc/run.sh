#!/usr/bin/env bashio
set -e

CONFIG_SRC="/defaults/frpc_template.toml"
CONFIG_DST="/data/frpc.toml"

trap 'bashio::log.info "Shutting down FRPC..."; kill ${FRPC_PID} ${TAIL_PID}; exit' SIGTERM SIGHUP

bashio::log.info "Preparing configuration..."
cp ${CONFIG_SRC} ${CONFIG_DST}

# Fill in global settings
bashio::config.require 'serverAddr'
sed -i "s|__SERVERADDR__|$(bashio::config 'serverAddr')|" ${CONFIG_DST}

bashio::config.require 'serverPort'
sed -i "s|__SERVERPORT__|$(bashio::config 'serverPort')|" ${CONFIG_DST}

bashio::config.require 'authMethod'
sed -i "s|__AUTHMETHOD__|$(bashio::config 'authMethod')|" ${CONFIG_DST}

bashio::config.require 'authToken'
sed -i "/__AUTHTOKEN_LINE__/c\auth.token = \"$(bashio::config 'authToken')\"" ${CONFIG_DST}

# TLS settings
if bashio::config.true 'tlsEnable'; then
  sed -i "s|__TLSENABLE__|true|" ${CONFIG_DST}
  sed -i "/__TLSCERT_LINE__/c\\tls.certFile = \"$(bashio::config 'tlsCertFile')\"" ${CONFIG_DST}
  sed -i "/__TLSKEY_LINE__/c\\tls.keyFile = \"$(bashio::config 'tlsKeyFile')\"" ${CONFIG_DST}
  sed -i "/__TLSCA_LINE__/c\\tls.trustedCaFile = \"$(bashio::config 'tlsCaFile')\"" ${CONFIG_DST}
else
  sed -i "s|__TLSENABLE__|false|" ${CONFIG_DST}
  sed -i "/__TLSCERT_LINE__/d" ${CONFIG_DST}
  sed -i "/__TLSKEY_LINE__/d" ${CONFIG_DST}
  sed -i "/__TLSCA_LINE__/d" ${CONFIG_DST}
fi

# Proxy settings (only first proxy supported)
bashio::config.require 'proxies/0/name'
for key in name type localIP localPort remotePort useEncryption useCompression; do
  val=$(bashio::config "proxies/0/${key}")
  sed -i "s|__${key^^}__|${val}|" ${CONFIG_DST}
done

domain=$(bashio::config 'proxies/0/customDomains/0')
sed -i "s|__CUSTOMDOMAINS__|\"${domain}\"|" ${CONFIG_DST}

bashio::log.info "Configuration:"
cat ${CONFIG_DST}

bashio::log.info "Starting FRPC client..."
/usr/bin/frpc -c ${CONFIG_DST} & FRPC_PID=$!

bashio::log.info "Tailing logs..."
tail -F /share/frpc.log & TAIL_PID=$!

wait ${FRPC_PID}