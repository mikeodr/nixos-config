{...}: let
in {
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  nixpkgs.config.allowUnfree = true;

  imports = [
    ../../darwin/common.nix
  ];

  homebrew = {
    casks = [
      "discord"
      "macfuse"
      "signal"
      "syncthing"
      "tailscale"
    ];
  };
}
