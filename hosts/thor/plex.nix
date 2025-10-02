{
pkgs,
...
}: let
  plex-version = {
    version = "1.42.2.10156-f737b826c";
    sha256 = "sha256-1ieh7qc1UBTorqQTKUQgKzM96EtaKZZ8HYq9ILf+X3M=";
  };
  plex-package = pkgs.plex.override {
    plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
      version = plex-version.version;
      src = pkgs.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        sha256 = plex-version.sha256;
      };
    });
  };
in {
    services.plex = {
      enable = true;
      package = plex-package;
      openFirewall = true;
    };
}
