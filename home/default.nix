{
  config,
  pkgs,
  lib,
  userName,
  userHome,
  ...
}: {
  programs.home-manager.enable = true;

  home.username = userName;
  home.homeDirectory = lib.mkForce userHome;
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    git
    jq
    mtr
    zsh
  ];

  programs = {
    neovim = import ../home/neovim.nix {};
    git = import ./git.nix {inherit pkgs;};
    zoxide = import ../home/zoxide.nix {inherit pkgs;};
    zsh = import ./zsh.nix {inherit config pkgs;};
  };
}
