{
  config,
  pkgs,
  ...
}: let
  unstableTarball =
    fetchTarball
    https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
in {
  imports = [<home-manager/nixos>];

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
      # Jellyfin hardware acceleration
      vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
    };
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

  home-manager.useGlobalPkgs = true;

  home-manager.users.specter = {pkgs, ...}: {
    home.stateVersion = "24.05";
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
    mtr
    neofetch
    tcpdump
    vim
    wget
    zstd
  ];

  programs = {
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
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
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
    virtualHosts."luna.unusedbytes.ca" = {
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

    unbound = {
      enable = true;
      settings = {
        server = {
          interface = ["0.0.0.0"];
          access-control = ["0.0.0.0/0 allow"];
          local-data = [
            "\"freshrss.unusedbytes.ca CNAME luna.unusedbytes.ca\""
            "\"sonarr.unusedbytes.ca CNAME luna.unusedbytes.ca\""
          ];
        };
      };
    };

    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
      openFirewall = true;
    };

    jellyfin = {
      enable = true;
    };

    sonarr = {
      enable = false;
      package = pkgs.unstable.sonarr;
      openFirewall = true;
    };
  };

  # Jellyfin Media Mounts
  fileSystems."/mnt/media" = {
    device = "172.16.0.3:/volume2/Media";
    fsType = "nfs4";
    options = ["auto"];
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
    allowedUDPPorts = [53];
  };
}
