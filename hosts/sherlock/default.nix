{config, ...}: {
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

  services.qemuGuest.enable = true;

  networking = {
    hostName = "sherlock";
    useDHCP = true;
    dhcpcd.IPv6rs = true;
    dhcpcd.wait = "ipv4";
  };

  networking.firewall = {
    enable = true;
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
