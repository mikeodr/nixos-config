{
  config,
  system,
  pkgs,
  ...
}: {
  time.timeZone = "America/Toronto";

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
