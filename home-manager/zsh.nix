{
  homeDir,
  isDarwin,
  lib,
  pkgs,
}: let
  sshSessionVariables =
    if pkgs.system == "x86_64-darwin" || pkgs.system == "aarch64-darwin"
    then {
      SSH_AUTH_SOCK = "${homeDir}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    }
    else {};

  extraShellAliases =
    if isDarwin
    then {
      tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
    }
    else {};

  shellAliases = {
    cp = "cp -v";
    df = "df -h";
    du = "dust";
    mv = "mv -v";
    rm = "rm -i";
    pgrep = "pgrep -l";
    top = "htop";

    vim = "nvim";
    ls = "ls --color";
    ctrl-l = "clear";
    C-l = "ctrl-l";
    control-l = "clear";
    clean = "clear";
  };

  envs = {
    TERM = "xterm";
  };
in {
  enable = true;

  history.size = 10000;

  shellAliases = lib.mkMerge [shellAliases extraShellAliases];

  sessionVariables = lib.mkMerge [envs sshSessionVariables];

  oh-my-zsh = {
    enable = true;
    theme = "robbyrussell";
    plugins = [
      "1password"
      "command-not-found"
      "direnv"
      "git"
      "golang"
      "pass"
      "rust"
      "sudo"
    ];
  };
}
