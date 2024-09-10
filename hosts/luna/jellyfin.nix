{
  pkgs,
  nixpkgs,
  ...
}: {
  # Jellyfin Media Mounts
  fileSystems."/mnt/media" = {
    device = "172.16.0.3:/volume2/Media";
    fsType = "nfs4";
    options = ["auto"];
  };

  services = {
    jellyfin = {
      enable = true;
      openFirewall = true;
    };
  };
}
