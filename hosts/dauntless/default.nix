{...}: let
  btc_server = "ghost.cerberus-basilisk.ts.net";
in {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../modules/server.nix
  ];

  ip_forwarding.enable = true;
  ip_forward_interfaces = ["enp0s6"];
  remoteBuild.enable = true;

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

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1"];
    firewall = {
      enable = true;
      allowedTCPPorts = [
        8333
        9735
      ];
    };
  };

  services = {
    nginx = {
      enable = true;
      streamConfig = ''
        server {
          listen 0.0.0.0:8333;
          listen [::]:8333;
          proxy_pass ${btc_server}:8333;
        }

        server {
          listen 0.0.0.0:9735;
          listen [::]:9735;
          proxy_pass ${btc_server}:9735;
        }
      '';
    };
  };

  system.stateVersion = "23.05";
}
