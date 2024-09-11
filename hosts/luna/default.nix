{
  pkgs,
  nixpkgs,
  pkgs-unstable,
  home-manager,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/server.nix
    ../../modules/jellyfin.nix
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

  # Jellyfin Media Mounts
  fileSystems."/mnt/media" = {
    device = "172.16.0.3:/volume2/Media";
    fsType = "nfs4";
    options = ["auto"];
  };

  environment.systemPackages = with pkgs; [
    colmena
  ];

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
        reverse_proxy https://plexserver.unusedbytes.ca:32400
      '';
      useACMEHost = "unusedbytes.ca";
    };
    # virtualHosts."obsidian-livesync.unusedbytes.ca" = {
    #   extraConfig = ''
    #     reverse_proxy http://localhost:5984
    #   '';
    #   useACMEHost = "unusedbytes.ca";
    # };
    virtualHosts.":443" = {
      extraConfig = ''
        respond "Not Found" 404
      '';
      useACMEHost = "unusedbytes.ca";
    };
  };

  services = {
    # freshrss = {
    #   enable = true;
    #   package = unstable.freshrss;
    #   passwordFile = /home/specter/.secrets/freshrss;
    #   baseUrl = "https://luna.unusedbytes.ca/rss";
    #   #virtualHost = null;
    # };

    sonarr = {
      enable = false;
      package = pkgs.unstable.sonarr;
      openFirewall = true;
    };

    # # Obsidian Livesync
    # couchdb = {
    #   enable = true;
    #   bindAddress = "0.0.0.0";
    #   configFile = obsidianEnvFile;
    #   # https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_own_server.md#configure
    #   extraConfig = ''
    #     [couchdb]
    #     single_node=true
    #     max_document_size = 50000000

    #     [chttpd]
    #     require_valid_user = true
    #     max_http_request_size = 4294967296
    #     enable_cors = true

    #     [chttpd_auth]
    #     require_valid_user = true
    #     authentication_redirect = /_utils/session.html

    #     [httpd]
    #     WWW-Authenticate = Basic realm="couchdb"

    #     [cors]
    #     origins = app://obsidian.md, capacitor://localhost, http://localhost
    #     credentials = true
    #     headers = accept, authorization, content-type, origin, referer
    #     methods = GET,PUT,POST,HEAD,DELETE
    #     max_age = 3600
    #   '';
    # };
  };

  networking = {
    hostName = "luna";
    useDHCP = false;
    interfaces.ens18.ipv4.addresses = [
      {
        address = "172.16.0.11";
        prefixLength = 24;
      }
    ];
    defaultGateway = "172.16.0.1";
    nameservers = ["172.16.0.1"];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
  };
}
