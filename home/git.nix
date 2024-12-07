{
  config,
  pkgs,
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
      };

      extraConfig = {
        core.autocrlf = "input";
        # Sign all commits using ssh key
        commit.gpgsign = true;
        gpg.format = "ssh";
        user.signingkey = cfg.signingKey;
        push.autoSetupRemote = true;
      };

      hooks = {
        "prepare-commit-msg" = pkgs.writeShellScript "commit_msg.sh" ''
          COMMIT_MSG_FILE=$1
          COMMIT_SOURCE=$2
          SHA1=$3

          if [[ -z "$COMMIT_SOURCE" ]]
          then
            branch=$(git symbolic-ref --short HEAD)
            # If the branch contains a ticket number, proceed
            # $match is automatically populated with the capture groups for
            # the project and ticket number
            if [[ "$branch" =~ ^.+([A-Z]{3,5})[_-]([0-9]+).* ]]
            then
              # Format the ticket number
              ticket="''${BASH_REMATCH[1]:u}-''${BASH_REMATCH[2]}"
              # Get the message if passed in already
              gitMsg=$(cat "$COMMIT_MSG_FILE")
              # Format the message
              printf "[%s]" $ticket > "$COMMIT_MSG_FILE"
              printf "$gitMsg" >> "$COMMIT_MSG_FILE"
            fi
          fi
        '';
      };
    };
  };
}
