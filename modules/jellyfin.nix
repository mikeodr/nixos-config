{
  pkgs,
  nixpkgs,
  ...
}: {
  imports = [
    ./intel_acceleration.nix
  ];

  services = {
    jellyfin = {
      enable = true;
      openFirewall = true;
    };
  };
}
