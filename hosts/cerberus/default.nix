{...}: let
  btc_server = "ghost.cerberus-basilisk.ts.net";
in {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../modules/server.nix
  ];

  isVM = true;

  boot = {
    tmp.cleanOnBoot = true;
    loader.grub = {
      # no need to set devices, disko will add all devices that have a EF02 partition to the list already
      # devices = [ ];
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  zramSwap.enable = true;

  networking = {
    hostName = "cerberus";
  };

  system.stateVersion = "25.05";
}
