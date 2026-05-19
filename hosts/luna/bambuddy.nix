{
  config,
  pkgs,
  ...
}: let
  dataDir = "/var/lib/bambuddy";
  tsServeConfig = pkgs.writeText "ts-serve.json" ''
    {
      "TCP": {"443": {"HTTPS": true}},
      "Web": {"''${TS_CERT_DOMAIN}:443": {"Handlers": {"/": {"Proxy": "http://127.0.0.1:8000"}}}},
      "AllowFunnel": {"''${TS_CERT_DOMAIN}:443": false}
    }
  '';
in {
  sops.secrets.bambuddy-tailscale = {
    sopsFile = ./secrets.yaml;
    mode = "0440";
  };

  systemd.services.init-bambuddy-network = {
    description = "Create bambuddy docker network";
    after = ["docker.service"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker network inspect bambuddy >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create bambuddy
    '';
  };

  systemd.services."docker-bambuddy-tailscale" = {
    after = ["init-bambuddy-network.service"];
    requires = ["init-bambuddy-network.service"];
  };

  virtualisation.oci-containers.containers = {
    bambuddy-tailscale = {
      image = "tailscale/tailscale:latest";
      autoStart = true;
      hostname = "bambuddy";
      environment = {
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_SERVE_CONFIG = "/config/serve.json";
        TS_USERSPACE = "false";
        TS_ENABLE_HEALTH_CHECK = "true";
        TS_LOCAL_ADDR_PORT = "127.0.0.1:41235";
        TS_AUTH_ONCE = "true";
      };
      # Expects: TS_AUTHKEY
      environmentFiles = [config.sops.secrets.bambuddy-tailscale.path];
      volumes = [
        "${tsServeConfig}:/config/serve.json:ro"
        "${dataDir}/ts/state:/var/lib/tailscale"
      ];
      ports = [
        # "8000:8000" # Web UI
        "3000:3000" # Virtual printer bind/detect
        "3002:3002" # Virtual printer bind/detect
        "8883:8883" # Virtual printer MQTT
        "990:990" # Virtual printer FTP control
        "6000:6000" # Virtual printer file transfer tunnel
        "322:322" # Virtual printer RTSP camera (X1/H2/P2)
        "2024-2026:2024-2026" # Virtual printer proprietary ports (A1/P1S)
        "50000-50100:50000-50100" # Virtual printer FTP passive data
      ];
      devices = ["/dev/net/tun:/dev/net/tun"];
      capabilities = {NET_ADMIN = true;};
      networks = ["bambuddy"];
      extraOptions = [
        "--health-cmd=wget --spider -q http://127.0.0.1:41235/healthz"
        "--health-interval=1m"
        "--health-timeout=10s"
        "--health-retries=3"
        "--health-start-period=10s"
      ];
    };

    bambuddy-app = {
      image = "ghcr.io/maziggy/bambuddy:latest";
      autoStart = true;
      dependsOn = ["bambuddy-tailscale"];
      environment = {
        TZ = "America/Toronto";
        PUID = "1000";
        PGID = "1000";
        PORT = "8000";
        # Required for FTP passive mode when using bridge networking.
        # Set to the Docker host IP if virtual printer FTP passive transfers fail.
        VIRTUAL_PRINTER_PASV_ADDRESS = "172.16.0.11";
      };
      volumes = [
        "${dataDir}/data:/app/data"
        "${dataDir}/logs:/app/logs"
      ];
      # Share tailscale's network namespace (equivalent to network_mode: service:bambuddy-tailscale)
      extraOptions = [
        "--network=container:bambuddy-tailscale"
        "--cap-add=NET_BIND_SERVICE"
      ];
    };
  };
}
