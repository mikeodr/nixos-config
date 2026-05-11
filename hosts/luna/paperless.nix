{
  config,
  pkgs,
  ...
}: let
  dataDir = "/var/lib/paperless";
  tsServeConfig = pkgs.writeText "ts-serve.json" ''
    {
      "TCP": {"443": {"HTTPS": true}},
      "Web": {"''${TS_CERT_DOMAIN}:443": {"Handlers": {"/": {"Proxy": "http://127.0.0.1:80"}}}},
      "AllowFunnel": {"''${TS_CERT_DOMAIN}:443": false}
    }
  '';
in {
  sops.secrets.paperless-tailscale = {
    sopsFile = ./secrets.yaml;
    mode = "0440";
  };

  sops.secrets.paperless-app = {
    sopsFile = ./secrets.yaml;
    mode = "0440";
  };

  sops.secrets.paperless-db = {
    sopsFile = ./secrets.yaml;
    mode = "0440";
  };

  systemd.services.init-paperless-network = {
    description = "Create paperless docker network";
    after = ["docker.service"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker network inspect paperless >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create paperless
    '';
  };

  # Containers directly attached to the paperless network must wait for it to exist
  systemd.services."docker-paperless-tailscale" = {
    after = ["init-paperless-network.service"];
    requires = ["init-paperless-network.service"];
  };
  systemd.services."docker-paperless-db" = {
    after = ["init-paperless-network.service"];
    requires = ["init-paperless-network.service"];
  };
  systemd.services."docker-paperless-broker" = {
    after = ["init-paperless-network.service"];
    requires = ["init-paperless-network.service"];
  };

  virtualisation.oci-containers.containers = {
    paperless-tailscale = {
      image = "tailscale/tailscale:latest";
      autoStart = true;
      hostname = "paperless";
      environment = {
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_SERVE_CONFIG = "/config/serve.json";
        TS_USERSPACE = "false";
        TS_ENABLE_HEALTH_CHECK = "true";
        TS_LOCAL_ADDR_PORT = "127.0.0.1:41234";
        TS_AUTH_ONCE = "true";
      };
      # Expects: TS_AUTHKEY
      environmentFiles = [config.sops.secrets.paperless-tailscale.path];
      volumes = [
        "${tsServeConfig}:/config/serve.json:ro"
        "${dataDir}/ts/state:/var/lib/tailscale"
      ];
      devices = ["/dev/net/tun:/dev/net/tun"];
      capabilities = {NET_ADMIN = true;};
      networks = ["paperless"];
      extraOptions = [
        "--health-cmd=wget --spider -q http://127.0.0.1:41234/healthz"
        "--health-interval=1m"
        "--health-timeout=10s"
        "--health-retries=3"
        "--health-start-period=10s"
      ];
    };

    paperless-app = {
      image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
      autoStart = true;
      dependsOn = ["paperless-tailscale" "paperless-db" "paperless-broker"];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Toronto";
        PAPERLESS_PORT = "80";
        PAPERLESS_PROXY_SSL_HEADER = ''["HTTP_X_FORWARDED_PROTO", "https"]'';
        PAPERLESS_REDIS = "redis://paperless-broker:6379";
        PAPERLESS_DBHOST = "paperless-db";
        PAPERLESS_OCR_LANGUAGE = "eng";
        PAPERLESS_ALLOWED_HOSTS = "*";
        PAPERLESS_ENABLE_ALLAUTH = "true";
      };
      # Expects: PAPERLESS_TIME_ZONE, PAPERLESS_OCR_LANGUAGE, PAPERLESS_SECRET_KEY,
      #          PAPERLESS_ADMIN_USER, PAPERLESS_ADMIN_PASSWORD
      environmentFiles = [config.sops.secrets.paperless-app.path];
      volumes = [
        "${dataDir}/data:/usr/src/paperless/data"
        "${dataDir}/media:/usr/src/paperless/media"
        "${dataDir}/export:/usr/src/paperless/export"
        "${dataDir}/consume:/usr/src/paperless/consume"
      ];
      # Share tailscale's network namespace (equivalent to network_mode: service:tailscale)
      extraOptions = [
        "--network=container:paperless-tailscale"
        "--health-cmd=pgrep -f paperless"
        "--health-interval=1m"
        "--health-timeout=10s"
        "--health-retries=3"
        "--health-start-period=30s"
      ];
    };

    paperless-db = {
      image = "docker.io/library/postgres:18";
      autoStart = true;
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Toronto";
        POSTGRES_DB = "paperless";
      };
      # Expects: POSTGRES_USER, POSTGRES_PASSWORD
      environmentFiles = [config.sops.secrets.paperless-db.path];
      volumes = [
        "${dataDir}/pgdata:/var/lib/postgresql"
      ];
      networks = ["paperless"];
      extraOptions = [
        "--health-cmd=pg_isready -d paperless -U $POSTGRES_USER"
        "--health-interval=1m"
        "--health-timeout=10s"
        "--health-retries=3"
        "--health-start-period=30s"
      ];
    };

    paperless-broker = {
      image = "docker.io/library/redis:8";
      autoStart = true;
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Toronto";
      };
      volumes = [
        "${dataDir}/redisdata:/data"
      ];
      networks = ["paperless"];
    };
  };
}
