{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.golink;
in {
  options = with lib; {
    services.golink = {
      enable = mkEnableOption "Enable golink";

      user = mkOption {
        type = with types; oneOf [str int];
        default = "golink";
        description = ''
          The user the service will use.
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/golink";
        description = ''
          Path to the golink sqlite database
        '';
      };

      envFile = mkOption {
        type = types.path;
        default = "/run/secrets/golink";
        description = ''
          Path to a file containing the golink tailscale auth token
        '';
      };

      group = mkOption {
        type = with types; oneOf [str int];
        default = "golink";
        description = ''
          The user the service will use.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.golink;
        defaultText = literalExpression "pkgs.golink";
        description = "The package to use for golink";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    sops.secrets.golink = {
      owner = cfg.user;
      group = cfg.group;
      mode = "440";
      sopsFile = ./secrets.yaml;
    };

    users.groups.${cfg.group} = {};
    users.users.${cfg.user} = {
      description = "golink service user";
      isSystemUser = true;
      home = cfg.dataDir;
      createHome = true;
      group = "${cfg.group}";
    };

    systemd.services.golink = {
      enable = true;
      description = "golink server";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        HOME = cfg.dataDir;
        HOSTNAME = config.networking.hostName;
      };

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;

        RuntimeDirectory = "golink";
        StateDirectory = "golink";
        StateDirectoryMode = "0755";
        CacheDirectory = "golink";
        CacheDirectoryMode = "0755";

        EnvironmentFile = cfg.envFile;

        ExecStart = "${cfg.package}/bin/golink -sqlitedb ${cfg.dataDir}/golink.db";
      };
    };
  };
}
