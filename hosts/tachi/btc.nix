{pkgs, ...}: let
  btc_server = "ghost.cerberus-basilisk.ts.net";
in {
  networking.firewall.allowedTCPPorts = [8333 9735];

  systemd.services."btc-proxy-8333" = {
    description = "Bitcoin node TCP proxy";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat TCP6-LISTEN:8333,ipv6only=0,fork,reuseaddr TCP:${btc_server}:8333";
      Restart = "always";
      RestartSec = "5s";
      DynamicUser = true;
    };
  };

  systemd.services."btc-proxy-9735" = {
    description = "Lightning node TCP proxy";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat TCP6-LISTEN:9735,ipv6only=0,fork,reuseaddr TCP:${btc_server}:9735";
      Restart = "always";
      RestartSec = "5s";
      DynamicUser = true;
    };
  };
}
