{
  config,
  lib,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./ip_forwarding.nix
  ];

  sops.secrets.tailscale_auth_key = {
    sopsFile = ./tailscale_key.yaml;
  };

  services = {
    tailscale = {
      enable = true;
      package = pkgs-unstable.tailscale;
      openFirewall = true;
    };
  };
}
