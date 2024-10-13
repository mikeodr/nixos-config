{ config
, pkgs
, ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/server.nix
    ./containers.nix
    ./obsidian.nix
    ./wireguard.nix
  ];

  boot = {
    loader.grub.device = "/dev/sda";
    tmp.cleanOnBoot = true;
  };

  # Enable intel acceleration in custom module
  intelAcceleration.enable = true;

  # Enable Dynamic Downloaded Binary linking in custom module
  ldDynamicLink.enable = true;

  # Enable system auto updates in custom module
  autoUpdate.enable = true;

  # Is a VM enable QEMU guest agent in custom module
  isVM = true;

  # Generate ACME Certs in custom module
  acmeCertGeneration.enable = true;

  # Custom module enable UDP GRO forwarding and IP forwarding
  ip_forwarding.enable = true;

  # Jellyfin Media Mounts
  fileSystems."/mnt/media" = {
    device = "172.16.0.3:/volume2/Media";
    fsType = "nfs4";
    options = [ "auto" ];
  };

  environment.systemPackages = with pkgs; [
    colmena
  ];

  services = {
    jellyfin = {
      enable = true;
      openFirewall = true;
    };
  };

  # Ensure cert renewals reload caddy
  security.acme.certs."unusedbytes.ca".reloadServices = [ "caddy" ];

  services.caddy = {
    enable = true;
    virtualHosts."jellyfin.unusedbytes.ca" = {
      extraConfig = ''
        reverse_proxy http://localhost:8096
      '';
      useACMEHost = "unusedbytes.ca";
    };
    virtualHosts."oink.unusedbytes.ca" = {
      extraConfig = ''
        reverse_proxy https://overseerr.unusedbytes.ca {
          header_up Host "overseerr.unusedbytes.ca"
        }
      '';
      useACMEHost = "unusedbytes.ca";
    };
    virtualHosts."plex.unusedbytes.ca" = {
      extraConfig = ''
        reverse_proxy https://thor.unusedbytes.ca:32400
      '';
      useACMEHost = "unusedbytes.ca";
    };
    virtualHosts."freshrss.unusedbytes.ca" = {
      extraConfig = ''
        reverse_proxy http://localhost:8080 {
          header_up Host "freshrss.unusedbytes.ca"
        }
      '';
      useACMEHost = "unusedbytes.ca";
    };
    virtualHosts."obsidian-livesync.unusedbytes.ca" = {
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString config.services.couchdb.port}

        @allowedOrigin expression `
          {http.request.header.Origin}.matches('^app://obsidian.md$') ||
          {http.request.header.Origin}.matches('^capacitor://localhost$') ||
          {http.request.header.Origin}.matches('^http://localhost$')
        `

        header {
          Access-Control-Allow-Origin {http.request.header.Origin}
          Access-Control-Allow-Methods "GET, PUT, POST, HEAD, DELETE"
          Access-Control-Allow-Headers "accept, authorization, content-type, origin, referer"
          Access-Control-Allow-Credentials "true"
          Access-Control-Max-Age "3600"
          Vary "Origin"
          defer
        }
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

  services.borgbackup.jobs = {
    jellyfin = {
      paths = [
        "/var/lib/jellyfin/config"
        "/var/lib/jellyfin/data"
      ];
      doInit = false;
      encryption.mode = "none";
      repo = "/mnt/media/borgBackup/jellyfin";
      compression = "auto,zstd";
      startAt = "daily";
      environment = {
        BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "yes";
      };
    };
    freshrss = {
      paths = [
        "/var/lib/freshrss"
      ];
      doInit = false;
      encryption.mode = "none";
      repo = "/mnt/media/borgBackup/freshrss";
      compression = "auto,zstd";
      startAt = "daily";
      environment = {
        BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "yes";
      };
    };
  };

  networking = {
    hostName = "luna";
    interfaces = {
      "ens18" = {
        useDHCP = true;
      };
    };
  };

  services.prometheus.exporters.node.openFirewall = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
  };

  system.stateVersion = "24.05";
}
