{ config, ... }: {
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
