{pkgs-unstable, ...}: {
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "aspnetcore-runtime-6.0.36"
    "aspnetcore-runtime-wrapped-6.0.36"
    "dotnet-sdk-6.0.428"
    "dotnet-sdk-wrapped-6.0.428"
  ];

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
