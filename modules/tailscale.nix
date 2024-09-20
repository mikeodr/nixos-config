{
  lib,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./ip_forwarding.nix
  ];

  sops.secrets."security/tailscale/auth_key" = {};

  services = {
    tailscale = {
      enable = true;
      package = pkgs-unstable.tailscale;
      openFirewall = true;
      authKeyFile = "/run/secrets/security/tailscale/auth_key";
      extraUpFlags = [
        "--ssh"
      ];
    };
  };
}
