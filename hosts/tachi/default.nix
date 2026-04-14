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
    ../../modules/ipset-firewall.nix
  ];

  ip_forwarding.enable = true;
  ip_forward_interfaces = ["enp0s6"];
  gro_forwarding.enable = true;
  gro_forwarding.interfaces = ["enp0s6"];

  boot = {
    tmp.cleanOnBoot = true;
    loader.grub = {
      # no need to set devices, disko will add all devices that have a EF02 partition to the list already
      # devices = [ ];
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

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

    ipsetFirewall = {
      enable = true;
      defaultDrop = true;
      allowedSets = {
        can_ips = {
          uptimerobotIps = true;
          asns = [
            # Rogers Communications
            "AS812" # Primary cable/internet ASN (~5.7M IPs)
            "AS3602" # Rogers Telecom backbone
            "AS19835" # Transit/peering ASN
            "AS26788" # Secondary ASN
            "AS40383" # Rogers subsidiary (RCC-CCTL)

            # Shaw Communications (acquired by Rogers 2023)
            "AS6327" # Primary Shaw ASN (~5.4M IPs)
            "AS10482" # Now under Rogers OrgId
            "AS19075" # Additional block
            "AS25983" # Envision/legacy cable

            # Bell Canada
            "AS577" # Primary wireline/internet ASN (~7M IPs)
            "AS601" # Secondary Bell ASN (BACOM4)
            "AS855" # Legacy Bell/CANET (~1M IPs)
            "AS6539" # Bell wireline (GT-BELL)
            "AS684" # Formerly MTS Manitoba (acquired by Bell)
            "AS7122" # Formerly MTS Manitoba (MTS-ASN)
            "AS36522" # Bell Mobility wireless

            # TELUS
            "AS852" # Primary wireline/internet ASN (~21M IPs)
            "AS14663" # TELUS Mobility wireless
            "AS54719" # Secondary/datacenter (TACE-MCC1320)

            # TekSavvy
            "AS5645" # Primary ASN (~733K IPs)
            "AS20375" # Western Canada operations

            # Oxio (reseller over Cogeco infrastructure)
            "AS398721" # Primary ASN (OXIO-ASN-01)
            "AS400424" # Secondary ASN

            # Cogeco Connexion (Oxio's upstream; Ontario/QC cable)
            "AS7992" # Primary Cogeco ASN
            "AS11290" # Secondary Cogeco ASN

            # Videotron (Quebec; owns Freedom Mobile)
            "AS5769" # Primary Videotron ASN

            # Eastlink (Atlantic Canada cable)
            "AS11260" # Primary Eastlink ASN

            # Distributel (national wholesale reseller)
            "AS11814" # Primary Distributel ASN

            # Beanfield Technologies (Toronto fibre)
            "AS21949" # Primary Beanfield ASN
            "AS40191" # Secondary Beanfield ASN

            # Starlink
            "AS14593"
          ];
        };
      };
    };
  };

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1"];
    firewall = {
      enable = true;
      # allowedTCPPorts = [80 443];
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
