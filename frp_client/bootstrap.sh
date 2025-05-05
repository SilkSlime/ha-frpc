#!/usr/bin/env bashio
build_arch=$1
frp_version=$2

frp_url="https://github.com/fatedier/frp/releases/download"
app_path="/usr/src"

select_machine() {
  case "$build_arch" in
    aarch64)    echo "arm64" ;;
    amd64)      echo "amd64" ;;
    armhf|armv7) echo "arm" ;;
    i386)       echo "386" ;;
  esac
}

install() {
  machine=$(select_machine)
  file="frp_${frp_version}_linux_${machine}.tar.gz"
  url="${frp_url}/v${frp_version}/${file}"
  work="/tmp/frp_${frp_version}_${machine}"

  mkdir -p "$work" "$app_path"
  curl -sSL "$url" -o "/tmp/$file"
  tar -xzf "/tmp/$file" -C /tmp
  cp "/tmp/frp_${frp_version}_${machine}/frpc" "$app_path/"
  chmod +x "$app_path/frpc"
  rm -rf "/tmp/$file" "$work"
}

install
