{...}: let
  userName = "mikeodr";
in {
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./config.nix
    ../home
  ];

  homeConfig.homeUser = userName;
  homeConfig.homeDir = "/Users/${userName}";
  homeConfig.gitEmail = "mike@unusedbytes.ca";
  homeConfig.gitSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILOkkbCny2gXw85T1CEUdMIyizGrmDx9CqxzyLCu9WLk";
}
