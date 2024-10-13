{ config
, pkgs
, ...
}: {
  programs.home-manager.enable = true;

  home.username = "specter";
  home.homeDirectory = "/home/specter";
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    git
    jq
    zsh
  ];

  programs = {
    neovim = import ../home/neovim.nix { };
    git = import ./git.nix { };
    zsh = import ./zsh.nix { inherit config; };
  };
}
