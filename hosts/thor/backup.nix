{
  config,
  pkgs,
  ...
}: let
  paths = [
    "/var/lib/plex/Plex Media Server"
  ];
  exclude = [
    "/var/lib/plex/Plex Media Server/Cache"
    "/var/lib/plex/Plex Media Server/Crash Reports"
  ];
in {
  sops.secrets."restic/bucket_access" = {};
  sops.secrets."restic/thor/repository" = {};
  sops.secrets."restic/thor/password" = {};

  services.restic.backups.thor = {
    paths = paths;
    exclude = exclude;
    repositoryFile = config.sops.secrets."restic/thor/repository".path;
    passwordFile = config.sops.secrets."restic/thor/password".path;
    environmentFile = config.sops.secrets."restic/bucket_access".path;
    initialize = true;
    backupPrepareCommand = "systemctl stop plex.service";
    backupCleanupCommand = "systemctl start plex.service";
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    extraOptions = [
      "s3.connections=50"
    ];
    extraBackupArgs = [
      "--pack-size 64"
      "--no-scan"
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 2"
      "--keep-monthly 3"
    ];
  };

  services.restic.backups.thor-check = {
    repositoryFile = config.sops.secrets."restic/thor/repository".path;
    passwordFile = config.sops.secrets."restic/thor/password".path;
    environmentFile = config.sops.secrets."restic/bucket_access".path;
    initialize = false;
    runCheck = true;
    extraOptions = [
      "s3.connections=50"
    ];
    checkOpts = [
      "--read-data-subset=5%"
    ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  systemd.services."restic-notify-failure@" = {
    description = "Notify ntfy that %i failed";
    serviceConfig = {
      Type = "oneshot";
      # %i is only expanded by systemd in unit directive values (like
      # ExecStart=), never inside a script's own contents - so it's passed
      # here as an argument and read back via $1, not written into the body.
      ExecStart = "${pkgs.writeShellScript "restic-notify-failure" ''
        ${pkgs.curl}/bin/curl -fsS \
          -H "Title: Restic job failed" \
          -H "Priority: high" \
          -H "Tags: warning" \
          -d "$1 failed on thor" \
          http://ntfy.unusedbytes.ca/luna-backups
      ''} %i";
    };
  };

  systemd.services."restic-backups-thor".onFailure = ["restic-notify-failure@%n.service"];
}
