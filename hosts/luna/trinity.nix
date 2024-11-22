{pkgs-unstable, ...}: {
  nixpkgs.config.allowUnfree = true;
  services = {
    nzbget = {
      enable = true;
    };
    sonarr = {
      enable = true;
      package = pkgs-unstable.sonarr;
    };
    radarr = {
      enable = true;
      package = pkgs-unstable.radarr;
    };
    prowlarr = {
      enable = true;
      package = pkgs-unstable.prowlarr;
    };
  };
}
