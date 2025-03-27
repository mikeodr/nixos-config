{...}: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../modules/server.nix
  ];

  autoUpdate.enable = true;
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
  networking.hostName = "ghost";
  networking.domain = "";
  services.openssh.enable = true;

  services.tailscale.useRoutingFeatures = "client";

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1"];
    firewall = {
      enable = true;
      # allowedTCPPorts = [80 443];
    };
  };

  system.stateVersion = "24.11";
}
