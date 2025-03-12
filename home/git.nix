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
        user.signingkey = cfg.signingKey;
        push.autoSetupRemote = true;
      };
    };
  };
}
