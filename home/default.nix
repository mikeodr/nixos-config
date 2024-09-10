{pkgs, ...}: {
  imports = [
    ./git.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    alejandra
    git
    jq
    zsh
  ];
}
