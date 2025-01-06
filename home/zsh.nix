{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.zshConfig;

  sshSessionVariables =
    if pkgs.system == "x86_64-darwin" || pkgs.system == "aarch64-darwin"
    then {
      SSH_AUTH_SOCK = "${cfg.homeDir}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    }
    else {};
in {
  options = {
    zshConfig = {
      homeDir = lib.mkOption {
        type = lib.types.str;
        description = "home directory path";
      };
      extraEnvVars = lib.mkOption {
        default = {};
        description = "extra env vars";
      };
    };
  };

  config = {
    programs.zsh = {
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

      sessionVariables = lib.mkMerge [sshSessionVariables cfg.extraEnvVars];

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
    };
  };
}
