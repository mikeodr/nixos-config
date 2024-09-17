{
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

  services.uptime-kuma.enable = true;

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
