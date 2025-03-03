{pkgs, ...}: let
  userName = "mikeodr";
in {
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./common.nix
    ../home
  ];

  homeConfig.homeUser = userName;
  homeConfig.homeDir = "/Users/${userName}";
  homeConfig.gitEmail = "mikeo@tailscale.com";
  homeConfig.gitSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBU0iEDDQKTyGr91x3hK93fG79WIARtg8XgvDWbSg0LT";

  homeConfig.extraEnvVars = {};

  homeConfig.additionalPkgs = with pkgs; [
    ansible
    awscli2
    direnv
    gh
    graphviz
    flamegraph
    go
    utm
  ];
}
