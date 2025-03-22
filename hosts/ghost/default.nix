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
    # loader.grub.configurationLimit = 1;
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
  # Generate ACME Certs in custom module
  # acmeCertGeneration.enable = true;

  # Override the path to include tailscale
  # from https://github.com/NixOS/nixpkgs/blob/6afb255d976f85f3359e4929abd6f5149c323a02/nixos/modules/services/monitoring/uptime-kuma.nix#L50
  # systemd.services.uptime-kuma.path = [pkgs.unixtools.ping pkgs-unstable.tailscale] ++ lib.optional config.services.uptime-kuma.appriseSupport pkgs.apprise;

  # services = {};

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1"];
    firewall = {
      enable = true;
      # allowedTCPPorts = [80 443];
    };
  };

  system.stateVersion = "23.05";
}
