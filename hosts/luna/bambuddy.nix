{...}: let
  dataDir = "/var/lib/bambuddy";
in {
  virtualisation.oci-containers.containers = {
    bambuddy-app = {
      image = "ghcr.io/maziggy/bambuddy:latest";
      autoStart = true;
      environment = {
        TZ = "America/Toronto";
        PUID = "1000";
        PGID = "1000";
        PORT = "8000";
        # Required for FTP passive mode when using bridge networking.
        # Set to the Docker host IP if virtual printer FTP passive transfers fail.
        VIRTUAL_PRINTER_PASV_ADDRESS = "172.16.0.11";
      };
      extraOptions = ["--network=host"];
      volumes = [
        "${dataDir}/data:/app/data"
        "${dataDir}/logs:/app/logs"
      ];
    };
  };
}
