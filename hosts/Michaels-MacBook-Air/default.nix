{ pkgs, currentSystemUser, ... }:
let
in {
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  nixpkgs.config.allowUnfree = true;

  ids.gids.nixbld = 30000;

  imports = [
    ../../modules/darwin.nix
  ];

  home-manager.users.${currentSystemUser}.imports = [ ./ssh.nix ];

  homebrew = {
    casks = [
      "discord"
      "macfuse"
      "signal"
      "steam"
      "syncthing-app"
    ];
  };

  environment.systemPackages = with pkgs; [
    ansible
    ansible-lint
    oci-cli
  ];
}
