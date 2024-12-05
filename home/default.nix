{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.homeConfig;
in {
  options = {
    homeConfig = {
      homeUser = lib.mkOption {
        type = lib.types.str;
        description = "Username";
      };

      homeDir = lib.mkOption {
        type = lib.types.str;
        description = "home directory path";
      };

      gitEmail = lib.mkOption {
        type = lib.types.str;
        description = "Email for git signature";
      };

      gitSigningKey = lib.mkOption {
        type = lib.types.str;
        description = "Git signing key";
      };
    };
  };

  config = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      verbose = true;
      users.${cfg.homeUser} = {
        programs.home-manager.enable = true;

        home.username = cfg.homeUser;
        home.homeDirectory = lib.mkForce cfg.homeDir;
        home.stateVersion = "24.05";

        home.packages = with pkgs; [
          git
          jq
          mtr
          zsh
        ];

        imports = [
          ./git.nix
        ];

        gitconfig.enable = true;
        gitconfig.userEmail = cfg.gitEmail;
        gitconfig.signingKey = cfg.gitSigningKey;

        programs = {
          neovim = import ../home/neovim.nix {};
          zoxide = import ../home/zoxide.nix {inherit pkgs;};
          zsh = import ./zsh.nix {inherit config pkgs;};
        };
      };
    };
  };
}
