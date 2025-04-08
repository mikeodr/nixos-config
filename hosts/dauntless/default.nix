{...}: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../modules/server.nix
  ];

  autoUpdate.enable = true;
  isVM = true;
  ip_forwarding.enable = true;
  ip_forward_interfaces = ["enp0s6"];

  boot = {
    tmp.cleanOnBoot = true;
    # loader.grub.configurationLimit = 1;
    loader.grub = {
      # no need to set devices, disko will add all devices that have a EF02 partition to the list already
      # devices = [ ];
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  services.tailscale.useRoutingFeatures = "both";

  zramSwap.enable = true;
  networking.hostName = "dauntless";
  networking.domain = "";
  services.openssh.enable = true;

  # Generate ACME Certs in custom module
  # acmeCertGeneration.enable = true;

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1"];
    firewall = {
      enable = true;
    };
  };

  system.stateVersion = "23.05";
}
