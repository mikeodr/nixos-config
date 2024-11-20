{...}: {
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
    hostName = "knox";
    interfaces = {
      "ens18" = {
        useDHCP = true;
      };
    };
  };

  services.prometheus.exporters.node.openFirewall = true;

  system.stateVersion = "24.05";
}
