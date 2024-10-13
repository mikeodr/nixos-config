{ config
, lib
, pkgs
, ...
}: {
  programs.home-manager.enable = true;

  home.username = "mikeodr";
  home.homeDirectory = lib.mkForce "/Users/mikeodr";

  home.stateVersion = "24.05";

  programs = {
    neovim = import ../home/neovim.nix { };
    git = import ../home/git.nix { };
    zsh = import ../home/zsh.nix { inherit config pkgs; };
  };

  # programs.zoxide = {
  #   enable = true;
  #   enableZshIntegration = true;
  #   options = [ "--cmd cd" ];
  # };
}
