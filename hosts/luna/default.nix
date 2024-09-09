{ pkgs, nixpkgs, pkgs-unstable, ... }: 
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    loader.grub.device = "/dev/sda";
    tmp.cleanOnBoot = true;
  };

  # Set your time zone.
  time.timeZone = "America/Toronto";

  users = {
    defaultUserShell = pkgs.zsh;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.specter = {
      isNormalUser = true;
      extraGroups = ["wheel"];
      initialPassword = "correcthorsestaplebattery";
      openssh.authorizedKeys.keyFiles = [
        (builtins.fetchurl {
          url = "https://github.com/mikeodr.keys";
          sha256 = "009zqghgzi5zs1ghpnxyrhr90xxzr5s8479paqgkj25rxn4nz887";
        })
      ];
    };
  };


  environment.systemPackages = with pkgs; [
    alejandra
    curl
    dig
    dua
    du-dust
    git
    gnutar
    gzip
    htop
    intel-gpu-tools
    mtr
    neofetch
    nh
    tcpdump
    vim
    wget
    zstd
  ];

  programs = {
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 7d --keep 3";
      flake = "/home/specter/nixos-config";
    };

    # Allow ld dynamic linking of downloaded binaries
    nix-ld = {
      enable = true;
      package = pkgs.nix-ld-rs;
    };

    zsh = {
      enable = true;
      ohMyZsh = {
        enable = true;
        plugins = ["git" "docker" "sudo" "extract"];
        theme = "robbyrussell";
      };
    };

    vim.defaultEditor = true;

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    mtr.enable = true;

    ssh.startAgent = true;
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "06:00";
    randomizedDelaySec = "45min";
    channel = "https://channels.nixos.org/nixos-24.05";
  };

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    # gc = {
    #   automatic = true;
    #   dates = "weekly";
    #   options = "--delete-older-than 7d";
    # };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "spry.frog6886@hidemail.ca";

    certs."unusedbytes.ca" = {
      domain = "unusedbytes.ca";
      extraDomainNames = ["*.unusedbytes.ca"];
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      credentialsFile = /home/specter/.secrets/cf;
    };
  };

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
    # Enable the OpenSSH daemon.
    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    qemuGuest.enable = true;

    # unbound = {
    #   enable = true;
    #   settings = {
    #     server = {
    #       interface = ["0.0.0.0"];
    #       access-control = ["0.0.0.0/0 allow"];
    #       local-data = [
    #         "\"obsidian-livesync.unusedbytes.ca CNAME luna.unusedbytes.ca\""
    #       ];
    #     };
    #     forward-zone = [
    #       {
    #         name = ".";
    #         forward-addr = [
    #           "172.16.0.1"
    #         ];
    #       }
    #     ];
    #   };
    # };

    tailscale = {
      enable = true;
      package = pkgs-unstable.tailscale;
      openFirewall = true;
    };

    jellyfin = {
      enable = true;
      openFirewall = true;
    };

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

  # Jellyfin Media Mounts
  fileSystems."/mnt/media" = {
    device = "172.16.0.3:/volume2/Media";
    fsType = "nfs4";
    options = ["auto"];
  };

  # Jellyfin acceleration configs
  nixpkgs.config = {
    packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
    };
  };

  # Jellyfin acceleration Mounts
  hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
        intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      ];
    };

  networking = {
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
