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

  # Custom module settings
  autoUpdate.enable = true;
  isVM = true;

  networking = {
    hostName = "sherlock";
    useDHCP = true;
    dhcpcd.IPv6rs = true;
    dhcpcd.wait = "ipv4";
  };

  networking.firewall = {
    enable = true;
  };

  # sops.secrets."security/acme/plex_pkcs12_pass" = {};
  sops.secrets."nix/cache_priv_key" = {
    mode = "640";
    group = "nix-serve";
    sopsFile = ../../secrets/secrets.yaml;
  };

  services.nix-serve = {
    enable = true;
    secretKeyFile = config.sops.secrets."nix/cache_priv_key".path;
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
