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

  time.timeZone = "America/Toronto";

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d --keep 3";
    };
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

  programs.vim.defaultEditor = true;

  environment.systemPackages = with pkgs; [
    curl
    dig
    dua
    du-dust
    git
    gnutar
    gzip
    htop
    iftop
    iotop
    mtr
    neofetch
    nh
    rsync
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

  system.stateVersion = "24.05";
}
