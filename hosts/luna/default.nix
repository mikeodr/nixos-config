{
  config,
  inputs,
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/server.nix
    ./containers.nix
    ./obsidian.nix
    ../../modules/immich
    inputs.tailscale-golink.nixosModules.default
    inputs.tsidp.nixosModules.default
  ];

  boot = {
    loader.grub.device = "/dev/sda";
    tmp.cleanOnBoot = true;
  };

  # Enable intel acceleration in custom module
  intelAcceleration.enable = true;

  # Enable Dynamic Downloaded Binary linking in custom module
  ldDynamicLink.enable = true;

  # Generate ACME Certs in custom module
  acmeCertGeneration.enable = true;

  # Custom module enable UDP GRO forwarding and IP forwarding
  ip_forwarding.enable = true;

  sops.secrets.golink = {
    owner = config.services.golink.user;
    group = config.services.golink.group;
    mode = "440";
    sopsFile = ./secrets.yaml;
  };

  services = {
    golink = {
      enable = true;
      tailscaleAuthKeyFile = config.sops.secrets.golink.path;
    };

    tsidp = {
      enable = true;
    };
  };

  # Jellyfin Media Mounts
  fileSystems = {
    "/mnt/media" = {
      device = "172.16.0.3:/volume2/Media";
      fsType = "nfs4";
      options = ["auto" "x-systemd.after=network-online.target"];
    };
    "/mnt/immich" = {
      device = "172.16.0.3:/volume2/immich";
      fsType = "nfs4";
      options = ["auto" "x-systemd.after=network-online.target"];
    };
  };

  environment.systemPackages = with pkgs; [
    colmena
  ];

  services = {
    jellyfin = {
      enable = true;
      openFirewall = true;
      package = pkgs-unstable.jellyfin;
    };
    audiobookshelf = {
      enable = true;
      package = pkgs-unstable.audiobookshelf;
      port = 8081;
    };
    ntfy-sh = {
      enable = true;
      package = pkgs-unstable.ntfy-sh;
      settings = {
        listen-http = ":8888";
        behind-proxy = true;
        base-url = "https://ntfy.unusedbytes.ca";
        upstream-base-url = "https://ntfy.sh";
      };
    };
  };

  systemd.services = {
    "jellyfin" = {
      after = ["mnt-media.mount"];
    };
  };

  # Ensure cert renewals reload caddy
  security.acme.certs."unusedbytes.ca".reloadServices = ["caddy"];

  services.tailscale.permitCertUid = "caddy";
  services.caddy = {
    enable = true;
    virtualHosts = {
      "luna.cerberus-basilisk.ts.net" = {
        extraConfig = ''
          reverse_proxy http://localhost:8096
        '';
      };
      "jellyfin.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:8096
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "oink.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy https://overseerr.unusedbytes.ca {
            header_up Host "overseerr.unusedbytes.ca"
          }
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "plex.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy https://thor.unusedbytes.ca:32400
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "freshrss.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:8080 {
            header_up Host "freshrss.unusedbytes.ca"
          }
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "obsidian-livesync.unusedbytes.ca" = {
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
      "mealie.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:9000
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "nzbget.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:6789
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "sonarr.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:8989
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "radarr.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:7878
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "prowlarr.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:9696
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "overseerr.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:5055
        '';
      };
      "abs.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:8081
        '';
      };
      "abs.cerberus-basilisk.ts.net" = {
        extraConfig = ''
          reverse_proxy http://localhost:8081
        '';
      };
      "pdf.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:8082
        '';
      };
      "photos.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:3001
        '';
      };
      "ntfy.unusedbytes.ca" = {
        serverAliases = ["ntfy.cerberus-basilisk.ts.net"];
        extraConfig = ''
          reverse_proxy http://localhost:8888

          # Redirect HTTP to HTTPS, but only for GET topic addresses, since we want
          # it to work with curl without the annoying https:// prefix
          @httpget {
              protocol http
              method GET
              path_regexp ^/([-_a-z0-9]{0,64}$|docs/|static/)
          }
          redir @httpget https://{host}{uri}
        '';
        useACMEHost = "unusedbytes.ca";
      };
      ":443" = {
        extraConfig = ''
          respond "Not Found" 404
        '';
      };
    };
  };

  services.borgbackup.jobs = {
    services = {
      paths = [
        "/var/lib/audiobookshelf/metadata/backups"
        "/var/lib/couchdb"
        "/var/lib/freshrss"
        "/var/lib/golink"
        "/var/lib/immich"
        "/var/lib/jellyfin/config"
        "/var/lib/jellyfin/data"
        "/var/lib/nzbget"
        "/var/lib/overseerr"
        "/var/lib/pods/mealie/data"
        "/var/lib/prowlarr"
        "/var/lib/radarr"
        "/var/lib/sonarr"
        "/var/lib/private/ntfy-sh"
      ];
      preHook = ''
        systemctl stop jellyfin.service
      '';
      postHook = ''
        systemctl start jellyfin.service
      '';
      doInit = false;
      encryption.mode = "none";
      repo = "/mnt/media/borgBackup/luna";
      compression = "auto,zstd";
      startAt = "daily";
      environment = {
        BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "yes";
      };
    };
  };

  networking = {
    hostName = "luna";
  };

  services.prometheus.exporters.node.openFirewall = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
    allowedUDPPorts = [41645];
  };

  system.stateVersion = "25.05";
}
