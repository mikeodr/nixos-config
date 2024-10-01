{...}: let
  dataDir = "/var/lib/freshrss";
in {
  virtualisation = {
    docker.enable = true;
    oci-containers.backend = "docker";

    oci-containers.containers = {
      freshrss = {
        image = "freshrss/freshrss:latest";
        environment = {
          BASE_URL = "freshrss.unusedbytes.ca";
          TZ = "America/Toronto";
          CRON_MIN = "*/15";
        };
        ports = [
          "8080:80"
        ];
        volumes = [
          "${dataDir}/data:/var/www/FreshRSS/data"
          "${dataDir}/extensions:/var/www/FreshRSS/extensions"
        ];
      };
    };
  };
}
