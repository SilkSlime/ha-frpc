#!/usr/bin/env bashio
set -e

CONFIG_PATH="/share/frpc.toml"
mkdir -p "$(dirname "$CONFIG_PATH")"

bashio::log.info "▶ Generating FRPC config"

# === [common] section ===
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

# === TLS section ===
if bashio::config.true 'tlsEnable'; then
  cat <<EOF >>"$CONFIG_PATH"
tls.enable        = true
tls.certFile      = "$(bashio::config 'tlsCertFile')"
tls.keyFile       = "$(bashio::config 'tlsKeyFile')"
tls.trustedCaFile = "$(bashio::config 'tlsCaFile')"
EOF
fi

# === Proxies ===
bashio::log.info "▶ Appending proxies"

for i in $(bashio::config 'proxies|keys'); do
  name=$(bashio::config "proxies[${i}].name")
  type=$(bashio::config "proxies[${i}].type")
  localIP=$(bashio::config "proxies[${i}].localIP")
  localPort=$(bashio::config "proxies[${i}].localPort")
  remotePort=$(bashio::config "proxies[${i}].remotePort" || echo "")
  useEnc=$(bashio::config "proxies[${i}].useEncryption")
  useComp=$(bashio::config "proxies[${i}].useCompression")

  echo -e "\n[[proxies]]" >>"$CONFIG_PATH"
  echo "name = \"$name\"" >>"$CONFIG_PATH"
  echo "type = \"$type\"" >>"$CONFIG_PATH"
  echo "localIP = \"$localIP\"" >>"$CONFIG_PATH"
  echo "localPort = $localPort" >>"$CONFIG_PATH"

  if [ -n "$remotePort" ]; then
    echo "remotePort = $remotePort" >>"$CONFIG_PATH"
  fi

  # customDomains (optional)
  if bashio::config.has_value "proxies[${i}].customDomains"; then
    echo -n "customDomains = [" >>"$CONFIG_PATH"
    first=1
    for domain in $(bashio::config "proxies[${i}].customDomains"); do
      [ "$first" -eq 0 ] && echo -n ", " >>"$CONFIG_PATH"
      echo -n "\"$domain\"" >>"$CONFIG_PATH"
      first=0
    done
    echo "]" >>"$CONFIG_PATH"
  fi

  echo "transport.useEncryption = $useEnc" >>"$CONFIG_PATH"
  echo "transport.useCompression = $useComp" >>"$CONFIG_PATH"
done

# === Start FRPC ===
bashio::log.info "▶ Starting FRPC client"
/usr/src/frpc -c "$CONFIG_PATH"
