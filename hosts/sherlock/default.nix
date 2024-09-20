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
    ./prometheus.nix
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
    interfaces = {
      "ens18" = {
        useDHCP = true;
      };
    };
  };
  services.prometheus.exporters.node.openFirewall = true;
  networking.firewall = {
    enable = true;
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
