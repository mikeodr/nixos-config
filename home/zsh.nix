{
  config,
  pkgs,
  ...
}: let
  sessionVariables =
    if pkgs.system == "x86_64-darwin" || pkgs.system == "aarch64-darwin"
    then {
      SSH_AUTH_SOCK = "${config.homeConfig.homeDir}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    }
    else {};
in {
  enable = true;

  history.size = 10000;

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

  sessionVariables = sessionVariables;

  oh-my-zsh = {
    enable = true;
    theme = "robbyrussell";
    plugins = [
      "command-not-found"
      "direnv"
      "git"
      "golang"
      "rust"
      "pass"
      "sudo"
    ];
  };
}
