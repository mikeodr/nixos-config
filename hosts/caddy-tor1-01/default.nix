{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ../../modules/server.nix
  ];

  autoUpdate.enable = true;
  isVM = true;
  ip_forwarding.enable = true;
  ip_forward_interfaces = ["eth0"];

  zramSwap.enable = true;
  networking.hostName = "caddy-tor1-01";
  networking.domain = "";
  services.openssh.enable = true;

  # Generate ACME Certs in custom module
  acmeCertGeneration.enable = true;

  # Ensure cert renewals reload caddy
  security.acme.certs."unusedbytes.ca".reloadServices = ["caddy"];

  # Override the path to include tailscale
  # from https://github.com/NixOS/nixpkgs/blob/6afb255d976f85f3359e4929abd6f5149c323a02/nixos/modules/services/monitoring/uptime-kuma.nix#L50
  systemd.services.uptime-kuma.path = [pkgs.unixtools.ping pkgs-unstable.tailscale] ++ lib.optional config.services.uptime-kuma.appriseSupport pkgs.apprise;

  services = {
    uptime-kuma = {
      enable = true;
    };

    caddy = {
      enable = true;
      virtualHosts."jf.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://luna:8096
        '';
        useACMEHost = "unusedbytes.ca";
      };
      virtualHosts."plex.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://thor:32400
        '';
        useACMEHost = "unusedbytes.ca";
      };
      virtualHosts."oink.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://luna:5055
        '';
        useACMEHost = "unusedbytes.ca";
      };
      virtualHosts."status.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3001
        '';
        useACMEHost = "unusedbytes.ca";
      };

      virtualHosts.":443" = {
        extraConfig = ''
          respond "Not Found" 404
        '';
        useACMEHost = "unusedbytes.ca";
      };
    };
    cron = {
      enable = true;
      systemCronJobs = [
        "0 5 * * * systemctl restart caddy-api.service caddy.service"
      ];
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
  };

  system.stateVersion = "23.11";
}
