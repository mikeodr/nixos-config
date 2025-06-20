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
          CRON_MIN = "*/10";
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
        image = "ghcr.io/mealie-recipes/mealie:v2.5.0";
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
          OIDC_AUTH_ENABLED = "true";
          OIDC_CONFIGURATION_URL = "https://idp.cerberus-basilisk.ts.net/.well-known/openid-configuration";
          OIDC_AUTO_REDIRECT = "true";
          OIDC_CLIENT_ID = "unused";
          OIDC_CLIENT_SECRET = "unused";
          OIDC_PROVIDER_NAME = "Tailscale";
          OIDC_NAME_CLAIM = "username";
        };
        ports = ["9000:9000/tcp"];
      };

      nzbget = {
        autoStart = true;
        image = "lscr.io/linuxserver/nzbget:latest";
        ports = ["127.0.0.1:6789:6789"];
        environment = {
          TZ = "America/Toronto";
          PUID = "1000";
          PGID = "100";
        };
        extraOptions = ["--pull=always"];
        volumes = [
          "/var/lib/nzbget:/config"
          "/mnt/media/downloads:/downloads"
        ];
      };

      sonarr = {
        autoStart = true;
        image = "lscr.io/linuxserver/sonarr:latest";
        ports = ["127.0.0.1:8989:8989"];
        environment = {
          TZ = "America/Toronto";
          PUID = "1000";
          PGID = "100";
        };
        extraOptions = ["--pull=always"];
        volumes = [
          "/var/lib/sonarr:/config"
          "/mnt/media/TV:/tv"
          "/mnt/media/downloads:/downloads"
        ];
      };

      radarr = {
        autoStart = true;
        image = "lscr.io/linuxserver/radarr:latest";
        ports = ["127.0.0.1:7878:7878"];
        environment = {
          TZ = "America/Toronto";
          PUID = "1000";
          PGID = "100";
        };
        extraOptions = ["--pull=always"];
        volumes = [
          "/var/lib/radarr:/config"
          "/mnt/media/Movies:/movies"
          "/mnt/media/downloads:/downloads"
        ];
      };

      prowlarr = {
        autoStart = true;
        image = "lscr.io/linuxserver/prowlarr:latest";
        ports = ["127.0.0.1:9696:9696"];
        environment = {
          TZ = "America/Toronto";
          PUID = "1000";
          PGID = "100";
        };
        extraOptions = ["--pull=always"];
        volumes = [
          "/var/lib/prowlarr:/config"
        ];
      };

      overseerr = {
        autoStart = true;
        image = "sctx/overseerr:latest";
        ports = ["5055:5055"];
        environment = {
          LOG_LEVEL = "info";
          TZ = "America/Toronto";
        };
        volumes = [
          "/var/lib/overseerr:/app/config"
        ];
      };

      stirlingpdf = {
        autoStart = true;
        image = "frooodle/s-pdf:latest";
        ports = ["127.0.0.1:8082:8080"];
        volumes = [
          "/var/stirlingpdf/trainingData:/usr/share/tessdata" # Required for extra OCR languages
          "/var/stirlingpdf/extraConfigs:/configs"
          "/var/stirlingpdf/customFiles:/customFiles/"
          "/var/stirlingpdf/logs:/logs/"
          "/var/stirlingpdf/pipeline:/pipeline/"
        ];
        environment = {
          LANGS = "en_CA";
        };
      };
    };
  };

  systemd.services = {
    "docker-nzbget" = {
      after = ["mnt-media.mount"];
    };
    "docker-sonarr" = {
      after = ["mnt-media.mount"];
    };
    "docker-radarr" = {
      after = ["mnt-media.mount"];
    };
  };
}
