{...}: {
  programs.git = {
    enable = true;
    userName = "Mike O'Driscoll";
    userEmail = "mike@unusedbytes.ca";
    aliases = {
      st = "status -sb -uall";
      cm = "commit";
      br = "branch";
      co = "checkout";
      lg = "log -p";
      lsd = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
      # in = "! ${pkgs.git}/bin/git fetch && ${pkgs.git}/bin/git log --pretty=short HEAD..origin";
      # out = "log --pretty=short origin..HEAD";
      unstage = "reset HEAD";
      undo = "reset --soft HEAD^";
      credit = "commit --amend --author \"$1 <$2>\" -C HEAD";
      amend = "commit --amend";
      pushb = "push -u origin";
      cob = "checkout -b";
      fpush = "push --force-with-lease";
    };
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILOkkbCny2gXw85T1CEUdMIyizGrmDx9CqxzyLCu9WLk";
      signByDefault = true;
    };

    extraConfig = {
      core = {
        autocrlf = "input";
        # excludesfile = /home/modriscoll/.gitignore_global
      };
      gpg = {
        format = "ssh";
      };
    };
  };
}
