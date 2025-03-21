{
  config,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./ip_forwarding.nix
  ];

  sops.secrets.tailscaleAuthKey = {
    sopsFile = ../secrets/secrets.yaml;
  };

  services = {
    tailscale = {
      enable = true;
      package = pkgs-unstable.tailscale;
      openFirewall = true;
      extraUpFlags = ["--ssh"];
      authKeyFile = config.sops.secrets.tailscaleAuthKey.path;
    };
  };
}
