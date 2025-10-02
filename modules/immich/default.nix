{pkgs-master, ...}
: {
  services.immich = {
    enable = true;
    package = pkgs-master.immich;
    openFirewall = true;
    mediaLocation = "/mnt/immich";
    port = 3001;

    redis = {
      enable = true;
      host = "127.0.0.1";
      port = 6379;
    };
  };
}
