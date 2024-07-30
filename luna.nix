{
  config,
  pkgs,
  ...
}: let
  unstableTarball =
    fetchTarball
    https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
in {
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

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

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
    dua
    du-dust
    git
    gnutar
    gzip
    htop
    mtr
    neofetch
    vim
    wget
    zstd
  ];

  programs = {
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

  services = {
    # Enable the OpenSSH daemon.
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    qemuGuest.enable = true;

    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
    };

    jellyfin = {
      enable = true;
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
}
