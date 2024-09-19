{
  pkgs,
  nixpkgs,
  pkgs-unstable,
  home-manager,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/server.nix
  ];

  boot = {
    loader.grub.device = "/dev/sda";
    tmp.cleanOnBoot = true;
  };

  # Custom module settings
  autoUpdate.enable = true;
  isVM = true;

  networking = {
    hostName = "sherlock";
  };
  services.prometheus.exporters.node.openFirewall = true;

  system.stateVersion = "24.05"; # Did you read the comment?
}
