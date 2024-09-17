{
  config,
  lib,
  pkgs,
  nixpkgs,
  pkgs-unstable,
  home-manager,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ../../modules/server.nix
  ];

  autoUpdate.enable = true;
  isVM = true;

  zramSwap.enable = true;
  networking.hostName = "caddy-tor1-01";
  networking.domain = "";
  services.openssh.enable = true;

  # Generate ACME Certs in custom module
  acmeCertGeneration.enable = true;

  # Ensure cert renewals reload caddy
  security.acme.certs."unusedbytes.ca".reloadServices = ["caddy"];

  services.uptime-kuma = {
    enable = true;
  };
  # Override the path to include tailscale
  # from https://github.com/NixOS/nixpkgs/blob/6afb255d976f85f3359e4929abd6f5149c323a02/nixos/modules/services/monitoring/uptime-kuma.nix#L50
  systemd.services.uptime-kuma.path = [pkgs.unixtools.ping pkgs-unstable.tailscale] ++ lib.optional config.services.uptime-kuma.appriseSupport pkgs.apprise;

  services.caddy = {
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

        header {
        Content-Security-Policy "default-src 'none'; prefetch-src 'self'; script-src 'unsafe-eval' 'report-sample'; script-src-elem https://www.gstatic.com 'self' 'unsafe-inline'; style-src 'report-sample' 'self' 'unsafe-inline' https://fonts.googleapis.com; object-src 'none'; base-uri 'self'; connect-src 'self' https://*.plex.direct:32400 https://*.plex.tv https://plex.tv wss://*.plex.tv wss://*.plex.direct:32400; font-src 'self' https://fonts.gstatic.com; frame-src 'self' https://*.plex.direct:32400; frame-ancestors 'none'; img-src 'self' blob: data: https://*.plex.tv https://*.plex.direct:32400; manifest-src 'self'; media-src 'self' data: blob: https://*.plex.direct:32400; worker-src 'none'; form-action 'self'; upgrade-insecure-requests"
          Strict-Transport-Security max-age=31536000
          Referrer-Policy "no-referrer, strict-origin-when-cross-origin"
          X-Content-Type-Options nosniff
          X-Frame-Options DENY
          X-XSS-Protection 1
          Access-Control-Allow-Origin https://plex.unusedbytes.ca
        }
      '';
      useACMEHost = "unusedbytes.ca";
    };
    virtualHosts."oink.unusedbytes.ca" = {
      extraConfig = ''
        reverse_proxy http://kirby:5055
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

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
  };

  system.stateVersion = "23.11";
}
