{
  config,
  lib,
  ...
}: let
  cfg = config.gitconfig;
in {
  options = {
    gitconfig = {
      enable =
        lib.mkEnableOption "Enable setting git config";

      userEmail = lib.mkOption {
        type = lib.types.str;
        description = "User email to set for git config";
      };

      signingKey = lib.mkOption {
        type = lib.types.str;
        description = "Signing key to use for gitconfig";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = "Mike O'Driscoll";
      userEmail = cfg.userEmail;
      aliases = {
        st = "status -sb -uall";
        cm = "commit";
        br = "branch";
        co = "checkout";
        com = "!f() { git checkout main 2>/dev/null || git checkout master; }; f";
        lg = "log -p";
        lsd = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
        unstage = "reset HEAD";
        undo = "reset --soft HEAD^";
        credit = "commit --amend --author \"$1 <$2>\" -C HEAD";
        amend = "commit --amend";
        pushb = "push -u origin";
        cob = "checkout -b";
        fpush = "push --force-with-lease";
        autosq = "rebase -i --autosquash";
      };

      extraConfig = {
        core.autocrlf = "input";
        # Sign all commits using ssh key
        commit.gpgsign = true;
        gpg.format = "ssh";
        user.signingkey = cfg.signingKey;
        push.autoSetupRemote = true;
      };
    };
  };
}
