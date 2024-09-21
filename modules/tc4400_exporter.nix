{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.prometheus.exporters.tc4400_exporter;
  dataDir = "/var/lib/tc4400_exporter";
in {
  options = {
    services.prometheus.exporters.tc4400_exporter = {
      enable = mkEnableOption (lib.mdDoc "Prometheus exporter for the Technicolor TC4400 DOCSIS 3.1 cable modem");

      package = mkOption {
        default = pkgs.callPackage ../pkgs/tc4400_exporter {};
        type = types.package;
        defaultText = literalExpression "pkgs.tc4400_exporter";
        description = lib.mdDoc "tc4400_exporter derivation to use";
      };

      listenAddress = mkOption {
        default = "0.0.0.0";
        type = types.str;
        description = "Address to listen on for web interface and telemetry";
      };

      listenPort = mkOption {
        default = 9623;
        type = types.int;
        description = "Port to listen on for web interface and telemetry";
      };

      telemetryPath = mkOption {
        default = "/metrics";
        type = types.str;
        description = "Path under which to expose metrics";
      };

      scrapeUri = mkOption {
        default = "http://admin:bEn2o%%23US9s@192.168.100.1/";
        type = types.str;
        description = ''Base URI on which to scrape TC4400. Any "%" need to be escaled with "%%"'';
      };

      timeout = mkOption {
        default = "50s";
        type = types.str;
        description = "Timeout for HTTP requests to TC440";
      };

      logLevel = mkOption {
        default = "info";
        type = types.enum ["debug" "info" "warn" "error" "fatal"];
        description = "Only log messages with the given severity or above";
        defaultText = "One of debug, info, warn, error, or fatal";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to open the firewall for the specified tc4400_exporter";
      };

      #         --web.listen-address=":9623"
      #                         Address to listen on for web interface and telemetry.
      #   --web.telemetry-path="/metrics"
      #                         Path under which to expose metrics.
      #   --client.scrape-uri="http://admin:bEn2o%23US9s@192.168.100.1/"
      #                         Base URI on which to scrape TC4400.
      #   --client.timeout=50s  Timeout for HTTP requests to TC440.
      #   --log.level="info"    Only log messages with the given severity or above. Valid levels: [debug, info, warn, error, fatal]
      #   --log.format="logger:stderr"
      #                         Set the log target and format. Example: "logger:syslog?appname=bob&local=7" or "logger:stdout?json=true"
    };
  };

  config = mkIf cfg.enable {
    systemd.services.tc4400_exporter = {
      description = "Prometheus exporter for the Technicolor TC4400 DOCSIS 3.1 cable modem";

      wantedBy = ["multi-user.target"];
      stopIfChanged = false;

      serviceConfig = {
        Restart = "on-failure";

        ExecStart = ''${cfg.package}/bin/tc4400_exporter --web.listen-address="${cfg.listenAddress}:${toString cfg.listenPort}" --web.telemetry-path="${cfg.telemetryPath}" --client.scrape-uri="${cfg.scrapeUri}" --client.timeout="${cfg.timeout}" --log.level="${cfg.logLevel}"'';

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        PrivateMounts = true;
        CacheDirectory = "tc4400_exporter";

        WorkingDirectory = dataDir;
        ReadWritePaths = dataDir;
        StateDirectory = baseNameOf dataDir;

        User = "tc4400_exporter";
        Group = "tc4400_exporter";

        CapabilityBoundingSet = "";
        NoNewPrivileges = true;

        ProtectKernelModules = true;
        SystemCallArchitectures = "native";
        ProtectKernelLogs = true;
        ProtectClock = true;

        LockPersonality = true;
        ProtectHostname = true;
        RestrictRealtime = true;
        MemoryDenyWriteExecute = true;
        PrivateUsers = true;
      };
    };

    users.groups.tc4400_exporter = {};
    users.users.tc4400_exporter = {
      description = "tc4400_exporter service user";
      isSystemUser = true;
      group = "tc4400_exporter";
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.listenPort];
    };
  };
}
