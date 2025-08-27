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
  security.acme.certs."unusedbytes.ca".reloadServices = ["caddy"];

  # Override the path to include tailscale
  # from https://github.com/NixOS/nixpkgs/blob/6afb255d976f85f3359e4929abd6f5149c323a02/nixos/modules/services/monitoring/uptime-kuma.nix#L50
  systemd.services.uptime-kuma.path = [pkgs.unixtools.ping pkgs-unstable.tailscale] ++ lib.optional config.services.uptime-kuma.appriseSupport pkgs.apprise;

  services = {
    davfs2 = {
      enable = true;
    };

    uptime-kuma = {
      enable = true;
      appriseSupport = true;
    };

    ntfy-sh = {
      enable = true;
      package = pkgs-unstable.ntfy-sh;
      settings = {
        listen-http = ":8888";
        behind-proxy = true;
        base-url = "http://tachi.cerberus-basilisk.ts.net:8888";
        upstream-base-url = "https://ntfy.sh";
      };
    };

    caddy = {
      enable = true;
      virtualHosts."jf.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://luna.cerberus-basilisk.ts.net:8096
        '';
        useACMEHost = "unusedbytes.ca";
      };
      virtualHosts."plex.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://thor.cerberus-basilisk.ts.net:32400
        '';
        useACMEHost = "unusedbytes.ca";
      };
      virtualHosts."oink.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://luna.cerberus-basilisk.ts.net:5055
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

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1"];
    firewall = {
      enable = true;
      allowedTCPPorts = [80 443];
    };
  };

  sops.secrets."borgbackup_key" = {
    sopsFile = ./secrets.yaml;
  };

  sops.secrets."borg_ssh_key" = {
    sopsFile = ./secrets.yaml;
    owner = "root";
    path = "/root/.ssh/id_ed25519";
  };

  programs.ssh.knownHosts = {
    "cubxc6s9.repo.borgbase.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMS3185JdDy7ffnr0nLWqVy8FaAQeVh1QYUSiNpW5ESq";
  };

  services.borgbackup.jobs = {
    # for a local backup
    uptimekuma = {
      paths = "/var/lib/private/uptime-kuma";
      repo = "ssh://cubxc6s9@cubxc6s9.repo.borgbase.com/./repo";
      compression = "auto,lzma";
      startAt = "daily";
      doInit = true;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${config.sops.secrets.borgbackup_key.path}";
      };
    };
  };

  system.stateVersion = "23.05";
}
