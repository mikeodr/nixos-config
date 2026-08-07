{
  config,
  pkgs,
  ...
}: {
  # Keep Tailscale's advertised relay static endpoints in sync with luna's
  # current public addresses, since both can change (DHCP lease renewal /
  # SLAAC renumbering).
  systemd.services.tailscale-relay-endpoints = {
    description = "Update Tailscale relay static endpoints with luna's current public addresses";
    after = ["network-online.target" "tailscaled.service"];
    wants = ["network-online.target"];
    path = [pkgs.iproute2 pkgs.gawk pkgs.curl];
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail

      # luna is behind NAT, so the address on ens18 isn't the public one -
      # ask an external echo service what address we're actually seen from.
      ipv4=$(curl -4 -fsS https://ipv4.canhazip.com/ | tr -d '[:space:]')

      # Only the mngtmpaddr (DHCPv6-managed) address is stable enough to use
      # here - the plain SLAAC address rotates as a temporary privacy address.
      ipv6=$(ip -6 -o addr show dev ens18 scope global mngtmpaddr | awk '{print $4}' | cut -d/ -f1 | head -n1)

      if [ -z "$ipv4" ]; then
        echo "Could not determine public IPv4 address via ipv4.canhazip.com" >&2
        exit 1
      fi
      if [ -z "$ipv6" ]; then
        echo "Could not determine mngtmpaddr IPv6 address on ens18" >&2
        exit 1
      fi

      exec ${config.services.tailscale.package}/bin/tailscale set \
        --relay-server-port=41642 \
        --relay-server-static-endpoints="$ipv4:1194,[$ipv6]:1194"
    '';
  };

  systemd.timers.tailscale-relay-endpoints = {
    description = "Periodically refresh Tailscale relay static endpoints";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "12h";
      Persistent = true;
    };
  };
}
