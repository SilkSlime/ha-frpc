# FRP Client Home Assistant Add-on

Use this add-on to expose Home Assistant remotely via Fast Reverse Proxy (FRP).

## Installation
1. Create a folder `\config\addons\frpc_addon` on your Home Assistant host.
2. Copy this repository into that folder.
3. In Home Assistant UI, go to Settings → Add-ons → Add-on Store → ⋮ → Repositories.
4. Add: `local` (your local addons) or your Git URL.
5. Find **FRP Client**, install, and configure options.
6. Start the add-on and check the logs.

## Usage
- Mount your own SSL certificates under `/ssl` if using TLS.

## Troubleshooting
- **Permission denied** on `/dev/net/tun`: Ensure `host_network: true`, `privileged: [ NET_ADMIN ]`, and `devices: [ /dev/net/tun ]` in `config.yaml`.
- **Connection refused**: Verify FRPS is reachable at `serverAddr:serverPort` and firewall allows it.
- **Log file not updating**: Check that `/share/frpc.log` is writable and tailing is active.
