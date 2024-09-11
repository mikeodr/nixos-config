{
  pkgs,
  nixpkgs,
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

  autoUpdate.enable = true;
  isVM = true;

  networking = {
    hostName = "thor";
  };

  system.stateVersion = "24.05";
}
