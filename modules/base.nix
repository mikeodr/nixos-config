{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./auto_update.nix
    ./ld_link.nix
    ./remotebuild.nix
  ];

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    age.keyFile = "/home/specter/.config/sops/age/keys.txt";
  };

  time.timeZone = "America/Toronto";

  security.sudo.wheelNeedsPassword = false;

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["specter" "remotebuild"];
      warn-dirty = false;

      builders-use-substitutes = true;
      substituters = [
        "https://mikeodr.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "mikeodr.cachix.org-1:ZiNRnrFQikas3IRc+q9xdAvcZTSiKZ4gyLrRufOlHsM="
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d --keep 3";
    };
    optimise.automatic = true;
  };

  environment.systemPackages = with pkgs; [
    curl
    dig
    dua
    du-dust
    fastfetch
    fzf
    git
    gnutar
    gzip
    htop
    iftop
    iotop
    mtr
    neovim
    nixpkgs-fmt
    nmap
    pciutils
    rsync
    sops
    tcpdump
    tmux
    wget
    zoxide
    zstd
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;

  # Enable SSH agent
  programs.ssh.startAgent = true;

  sops.secrets.cachix_auth_token = {};
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

    cachix-watch-store = {
      enable = true;
      cacheName = "mikeodr";
      cachixTokenFile = config.sops.secrets.cachix_auth_token.path;
    };
  };
}
