{ ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/server.nix
    ./prometheus.nix
    ./alertmanager.nix
    ./grafana.nix
    ./caddy.nix
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

  networking.firewall = {
    enable = true;
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
