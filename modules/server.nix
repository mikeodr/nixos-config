{
  config,
  system,
  pkgs,
  home-manager,
  ...
}: {
  imports = [
    ./base.nix
    ./certs.nix
    ./tailscale.nix
  ];

  programs.zsh.enable = true;
  users = {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.specter = {
      shell = pkgs.zsh;
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

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    users.specter = {
      imports = [
        ../home
      ];
      home.username = "specter";
      home.homeDirectory = "/home/specter";
      home.stateVersion = "24.05";
    };
  };
}
