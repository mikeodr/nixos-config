{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: {
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

  zramSwap.enable = true;
  networking.hostName = "tachi";
  networking.domain = "";
  services.openssh.enable = true;

  # Generate ACME Certs in custom module
  acmeCertGeneration.enable = true;

  # Ensure cert renewals reload caddy
  # security.acme.certs."unusedbytes.ca".reloadServices = ["caddy"];

  # Override the path to include tailscale
  # from https://github.com/NixOS/nixpkgs/blob/6afb255d976f85f3359e4929abd6f5149c323a02/nixos/modules/services/monitoring/uptime-kuma.nix#L50
  systemd.services.uptime-kuma.path = [pkgs.unixtools.ping pkgs-unstable.tailscale] ++ lib.optional config.services.uptime-kuma.appriseSupport pkgs.apprise;

  # The contents of this for mounting a taildrive with the
  # systemd mount below is as follows:
  # http://100.100.100.100:8080 guest guest
  sops.secrets."webdav" = {
    sopsFile = ./secrets.yaml;
    mode = "0600";
    path = "/etc/davfs2/secrets";
  };

  systemd.mounts = [
    {
      enable = true;
      description = "Mountpoint for borg backup";
      after = ["network-online.target"];
      wants = ["network-online.target"];

      what = "http://100.100.100.100:8080";
      where = "/mnt/borgbackup";
      options = "uid=1000,gid=1000,file_mode=0664,dir_mode=2775";
      type = "davfs";
      mountConfig.TimeoutSec = 15;
    }
  ];

  services = {
    davfs2 = {
      enable = true;
    };

    uptime-kuma = {
      enable = true;
    };

    caddy = {
      enable = true;
      virtualHosts."jf.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://luna:8096
        '';
        useACMEHost = "unusedbytes.ca";
      };
      virtualHosts."plex.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://thor:32400
        '';
        useACMEHost = "unusedbytes.ca";
      };
      virtualHosts."oink.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://luna:5055
        '';
        useACMEHost = "unusedbytes.ca";
      };
      virtualHosts."status.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3001
        '';
        useACMEHost = "unusedbytes.ca";
      };

      virtualHosts.":443" = {
        extraConfig = ''
          respond "Not Found" 404
        '';
        useACMEHost = "unusedbytes.ca";
      };
    };
    cron = {
      enable = true;
      systemCronJobs = [
        "0 5 * * * systemctl restart caddy-api.service caddy.service"
      ];
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
  };

  system.stateVersion = "23.05";
}
