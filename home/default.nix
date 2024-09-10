{pkgs, ...}: {
  imports = [
    ./git.nix
    ./zsh.nix
  ];

  programs.vim.defaultEditor = true;

  home.packages = with pkgs; [
    git
    jq
    alejandra
  ];
}
