{
  config,
  inputs,
  pkgs,
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
      package = inputs.tailscale.packages."${pkgs.system}".default;
      openFirewall = true;
      extraUpFlags = ["--ssh"];
      authKeyFile = config.sops.secrets.tailscaleAuthKey.path;
    };
  };
}
