{pkgs, ...}: let
in {
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  nixpkgs.config.allowUnfree = true;

  ids.gids.nixbld = 350;
  imports = [
    ../../modules/darwin.nix
  ];

  environment.systemPackages = with pkgs; [
    awscli2
    direnv
    flamegraph
    graphviz
    lnav
    utm
  ];
}
