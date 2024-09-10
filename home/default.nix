{pkgs, ...}: {
  imports = [
    ./git.nix
    ./zsh.nix
  ];

  programs.vim.defaultEditor = true;

  home.packages = with pkgs; [
    alejandra
    git
    jq
    zsh
  ];
}
