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
  };

  zramSwap.enable = true;
  networking.hostName = "beaker";
  networking.domain = "";
  services.openssh.enable = true;

  # Custom module enable UDP GRO forwarding and IP forwarding
  ip_forwarding.enable = true;

  services.tailscale.permitCertUid = "caddy";

  services.caddy = {
    enable = true;

    virtualHosts = {
      "beaker.cerberus-basilisk.ts.net" = {
        extraConfig = ''
          reverse_proxy http://immich-ml.ktz.ts.net:3003
        '';
      };
    };
  };

  networking = {
    useDHCP = true;
    dhcpcd.IPv6rs = true;
    dhcpcd.wait = "ipv4";
  };

  system.stateVersion = "24.11";
}
