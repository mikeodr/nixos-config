{ config, pkgs, ... }:
let
  sessionVariables =
    if pkgs.system == "x86_64-darwin" || pkgs.system == "aarch64-darwin" then {
      SSH_AUTH_SOCK = "/Users/mikeodr/.1password/agent.sock";
    }
    else { };
in
{
  enable = true;

  history.size = 10000;
  history.path = "${config.xdg.dataHome}/zsh/history";

  shellAliases = {
    rm = "rm -i";
    cp = "cp -v";
    mv = "mv -v";
    df = "df -h";
    top = "htop";
    pgrep = "pgrep -l";

    vim = "nvim";
    ls = "ls --color";
    ctrl-l = "clear";
    C-l = "ctrl-l";
    control-l = "clear";
    clean = "clear";
  };

  sessionVariables = sessionVariables;

  oh-my-zsh = {
    enable = true;
    theme = "robbyrussell";
    plugins = [
      "git"
      "sudo"
      "golang"
      "rust"
      "command-not-found"
      "pass"
    ];
  };
}
