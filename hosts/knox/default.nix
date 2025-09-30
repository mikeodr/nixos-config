{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/server.nix
    ./alby.nix
  ];

  boot = {
    loader.grub.device = "/dev/sda";
    tmp.cleanOnBoot = true;
  };

  services.qemuGuest.enable = true;

  # Generate ACME Certs in custom module
  acmeCertGeneration.enable = true;

  networking = {
    hostName = "knox";
    interfaces = {
      "ens18" = {
        useDHCP = true;
      };
    };
  };

  services.prometheus.exporters.node.openFirewall = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
  };

  system.stateVersion = "24.05";
}
