{
  user,
  email,
  signingkey,
  ...
}: {
  pkgs,
  lib,
  ...
}: let
  homeDir =
    if isDarwin
    then "/Users/${user}"
    else "/home/${user}";
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  programs.home-manager.enable = true;

  home.username = user;
  home.homeDirectory = lib.mkForce homeDir;
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    direnv
    git
    hack-font
    jq
    mtr
    nerd-fonts.hack
    zsh
  ];

  programs.zsh = import ./zsh.nix {
    homeDir = homeDir;
    isDarwin = isDarwin;
    lib = lib;
    pkgs = pkgs;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraConfig = ''
      let mapleader = ","
      let maplocalleader = ","
    '';

    plugins = with pkgs.vimPlugins; [
      nerdtree
      vim-easymotion
    ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = ["--cmd cd"];
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = pkgs.lib.importTOML ./starship/starship.toml;
  };

  xdg.enable = true;
  xdg.configFile =
    {
    }
    // (
      if isDarwin
      then {
        # Rectangle.app. This has to be imported manually using the app.
        "rectangle/RectangleConfig.json".text = builtins.readFile ./RectangleConfig.json;
        "ghostty/config".text = builtins.readFile ./ghostty.darwin;
      }
      else {}
    )
    // (
      if isLinux
      then {
      }
      else {}
    );

  programs.git = {
    enable = true;
    userName = "Mike O'Driscoll";
    userEmail = email;
    aliases = {
      amend = "commit --amend";
      autosq = "rebase -i --autosquash";
      br = "branch";
      cdiff = "diff --cached";
      cm = "commit";
      co = "checkout";
      cob = "checkout -b";
      com = "!f() { git checkout main 2>/dev/null || git checkout master; }; f";
      credit = "commit --amend --author \"$1 <$2>\" -C HEAD";
      fpush = "push --force-with-lease";
      lg = "log -p";
      lsd = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
      ol = "log --oneline";
      pushb = "push -u origin";
      st = "status -sb -uall";
      undo = "reset --soft HEAD^";
      unstage = "reset HEAD";
    };

    extraConfig = {
      core.autocrlf = "input";
      # Sign all commits using ssh key
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = signingkey;
      push.autoSetupRemote = true;
    };
  };
}
