{config, ...}: let
  dataDir = "/var/lib/freshrss";
in {
  sops.secrets.mealie = {
    sopsFile = ./secrets.yaml;
    owner = config.users.users.specter.name;
    group = config.users.users.nobody.group;
    mode = "0440";
  };

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

      mealie = {
        image = "ghcr.io/mealie-recipes/mealie:v2.2.0";
        autoStart = true;
        volumes = ["/var/lib/pods/mealie/data:/app/data"];
        environmentFiles = [
          config.sops.secrets.mealie.path
        ];
        environment = {
          TZ = "America/Toronto";
          PUID = "1000";
          PGID = "1000";
          ALLOW_SIGNUP = "false";
          DB_ENGINE = "sqlite";
          BASE_URL = "mealie.unusedbytes.ca";
        };
        ports = ["9000:9000/tcp"];
      };
    };
  };
}
