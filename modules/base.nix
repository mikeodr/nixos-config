{
  config,
  system,
  pkgs,
  ...
}: {
  imports = [
    ./auto_update.nix
    ./qemu_guest.nix
    ./ld_link.nix
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
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      trusted-users = ["specter"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d --keep 3";
    };
  };

  programs.vim.defaultEditor = true;

  environment.systemPackages = with pkgs; [
    curl
    dig
    dua
    du-dust
    fastfetch
    git
    gnutar
    gzip
    htop
    iftop
    iotop
    mtr
    nh
    rsync
    sops
    tcpdump
    tmux
    vim
    wget
    zstd
  ];

  programs = {
    nh = {
      enable = true;
      flake = "/home/specter/nixos-config";
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;

  # Enable SSH agent
  programs.ssh.startAgent = true;

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
  };
}
