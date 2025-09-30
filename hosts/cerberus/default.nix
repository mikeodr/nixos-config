{...}: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../modules/server.nix
  ];

  services.qemuGuest.enable = true;

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

  users.users.remotebuild = {
    isNormalUser = true;
    createHome = false;
    group = "remotebuild";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFbMIabPQ1F4qaWV54nTtGFbUK0xAJ0T5zGfLDhYL73Y"
    ];
  };

  users.groups.remotebuild = {};

  nix.settings.trusted-users = ["remotebuild"];

  system.stateVersion = "25.05";
}
