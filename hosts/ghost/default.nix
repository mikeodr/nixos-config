{config, ...}: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../modules/server.nix
  ];

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

  sops.secrets.ups_mon_secret = {};

  # UPS client
  power.ups = {
    enable = true;
    mode = "netclient";

    # UPS Monitor
    #MONITOR ups@172.16.0.1:3493 1 monuser secret slave
    upsmon = {
      # Connection
      monitor.main = {
        system = "ups@172.16.0.1:3493";
        powerValue = 1;
        user = "monuser";
        passwordFile = config.sops.secrets.ups_mon_secret.path;
        type = "slave";
      };
    };
  };

  services.tailscale.useRoutingFeatures = "client";

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001"];
    firewall = {
      enable = true;
      allowedTCPPorts = [config.services.bitcoind.port config.services.lnd.port];
    };
  };

  nix-bitcoin.nodeinfo.enable = true;
  nix-bitcoin.generateSecrets = true;
  services.bitcoind = {
    enable = true;
    address = "0.0.0.0";
    listen = true;
    extraConfig = ''
      dbcache=4096
      bind=::
    '';
    tor.enforce = false;
    tor.proxy = false;
  };
  nix-bitcoin.operator = {
    enable = true;
    name = "specter";
  };

  services.electrs = {
    enable = true;
    address = "100.85.56.69";
  };

  # services.lnd.enable = true;

  system.stateVersion = "24.11";
}
