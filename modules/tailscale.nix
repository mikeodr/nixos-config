{
  config,
  lib,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./ip_forwarding.nix
  ];

  services = {
    tailscale = {
      enable = true;
      package = pkgs-unstable.tailscale;
      openFirewall = true;
    };
  };
}
