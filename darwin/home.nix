{pkgs, ...}: let
  userName = "mikeodr";
in {
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./common.nix
    ../home
  ];

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    # age.keyFile = "/Users/mikeodr/Library/ApplicationSupport/sops/age/keys.txt";
    age.keyFile = "/Users/${userName}/.config/sops/age/keys.txt";
  };

  homeConfig.homeUser = userName;
  homeConfig.homeDir = "/Users/${userName}";
  homeConfig.gitEmail = "mike@unusedbytes.ca";
  homeConfig.gitSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILOkkbCny2gXw85T1CEUdMIyizGrmDx9CqxzyLCu9WLk";

  homeConfig.additionalPkgs = with pkgs; [
    direnv
    terraform
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
