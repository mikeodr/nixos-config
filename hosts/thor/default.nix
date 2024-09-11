{
  pkgs,
  nixpkgs,
  pkgs-unstable,
  home-manager,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/server.nix
  ];

  boot = {
    loader.grub.device = "/dev/sda";
    tmp.cleanOnBoot = true;
  };

  # Custom module settings
  autoUpdate.enable = true;
  isVM = true;
  intelAcceleration.enable = true;

  networking = {
    hostName = "thor";
  };

  fileSystems."/mnt/media" = {
    device = "172.16.0.3:/volume2/Media";
    fsType = "nfs4";
    options = ["auto"];
  };

  services = {
    plex = {
      enable = true;
      package = pkgs-unstable.plex;
      openFirewall = true;
    };

    cron = {
        enable = true;
        systemCronJobs = [
            # 5am daily clear out plex transcoder folder for storage saving
            "0 5 * * * find /var/lib/plex/Plex\ Media\ Server/Cache/PhotoTranscoder -name \"*.jpg\" -type f -mtime +5 -delete"
            # Reboot 6am Thrusdays
            #"0 6 * * 4 touch /forcefsck && reboot"
        ];
    };
  };

  system.stateVersion = "24.05";
}
