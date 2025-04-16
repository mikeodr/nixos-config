{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.homeConfig;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
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

      additionalPkgs = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        description = "List of additional per system package to install";
        default = [];
      };

      extraEnvVars = lib.mkOption {
        default = {};
        description = "extra env vars";
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

        home.packages = with pkgs;
          [
            git
            jq
            mtr
            zsh
          ]
          ++ cfg.additionalPkgs;

        imports = [
          ./git.nix
          ./zsh.nix
        ];

        gitconfig.enable = true;
        gitconfig.userEmail = cfg.gitEmail;
        gitconfig.signingKey = cfg.gitSigningKey;

        zshConfig.extraEnvVars = cfg.extraEnvVars;
        zshConfig.homeDir = cfg.homeDir;

        programs = {
          neovim = import ../home/neovim.nix {};
          zoxide = import ../home/zoxide.nix {inherit pkgs;};
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
      };
    };
  };
}
