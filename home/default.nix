{pkgs, ...}: {
  imports = [
    ./git.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    git
    jq
    alejandra
  ];
}
