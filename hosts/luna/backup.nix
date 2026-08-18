{
  config,
  pkgs,
  ...
}: let
  # Shared between the "services" and "services-remote" restic jobs below.
  servicePaths = [
    "/var/lib/audiobookshelf/metadata/backups"
    "/var/lib/bambuddy/data"
    "/var/lib/couchdb"
    "/var/lib/freshrss"
    "/var/lib/golink"
    "/var/lib/jellyfin/config"
    "/var/lib/lidarr"
    "/var/lib/nzbget/nzbget.conf"
    "/var/lib/overseerr"
    "/var/lib/paperless/data"
    "/var/lib/paperless/media"
    "/var/lib/pinchflat/db"
    "/var/lib/pods/mealie/data"
    "/var/lib/prowlarr"
    "/var/lib/radarr"
    "/var/lib/sonarr"
  ];
in {
  sops.secrets."restic/bucket_access" = {};
  sops.secrets."restic/immich/repository" = {};
  sops.secrets."restic/immich/password" = {};
  sops.secrets."restic/luna/repository" = {};
  sops.secrets."restic/luna/password" = {};

  # Immich's docs (docs.immich.app/administration/backup-and-restore) list
  # upload/ and library/ as the directories holding original assets that
  # must be backed up; thumbs/ and encoded-video/ are regenerable caches
  # that are safe to skip. backups/ holds Immich's own daily pg_dump of the
  # database and is included so the DB stays backed up alongside the media.
  services.restic.backups.immich = {
    paths = ["/mnt/immich"];
    exclude = [
      "/mnt/immich/thumbs"
      "/mnt/immich/encoded-video"
    ];
    repositoryFile = config.sops.secrets."restic/immich/repository".path;
    passwordFile = config.sops.secrets."restic/immich/password".path;
    environmentFile = config.sops.secrets."restic/bucket_access".path;
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
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
  };

  # Check-only job: verifies repository/pack integrity against the remote
  # (not the /mnt/immich mount), so it doesn't need RequiresMountsFor. Reads
  # a subset of the actual data each run rather than the full repo, to limit
  # B2 egress while still catching bitrot/corruption over time.
  services.restic.backups.immich-check = {
    repositoryFile = config.sops.secrets."restic/immich/repository".path;
    passwordFile = config.sops.secrets."restic/immich/password".path;
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

  systemd.services."restic-backups-immich".unitConfig.RequiresMountsFor = ["/mnt/immich"];

  services.restic.backups.services = {
    paths = servicePaths;
    repository = "/mnt/media/resticBackup/luna";
    passwordFile = config.sops.secrets."restic/luna/password".path;
    backupPrepareCommand = "systemctl stop jellyfin.service";
    backupCleanupCommand = "systemctl start jellyfin.service";
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 2"
      "--keep-monthly 3"
    ];
  };

  systemd.services."restic-backups-services".unitConfig.RequiresMountsFor = ["/mnt/media"];

  # Offsite counterpart of the job above, converted from the old
  services.restic.backups.services-remote = {
    paths = servicePaths;
    repositoryFile = config.sops.secrets."restic/luna/repository".path;
    passwordFile = config.sops.secrets."restic/luna/password".path;
    environmentFile = config.sops.secrets."restic/bucket_access".path;
    initialize = false;
    backupPrepareCommand = "systemctl stop jellyfin.service";
    backupCleanupCommand = "systemctl start jellyfin.service";
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    extraOptions = [
      "s3.connections=50"
    ];
    extraBackupArgs = [
      "--pack-size 64"
    ];
    pruneOpts = [
      "--keep-daily 3"
      "--keep-weekly 2"
      "--keep-monthly 1"
    ];
  };

  services.restic.backups.services-remote-check = {
    repositoryFile = config.sops.secrets."restic/luna/repository".path;
    passwordFile = config.sops.secrets."restic/luna/password".path;
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

  # Ping the self-hosted ntfy instance if a restic job (backup or check)
  # fails. Templated so both restic-backups-immich and
  # restic-backups-immich-check can point OnFailure at the same unit.
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
          -d "$1 failed on luna" \
          http://127.0.0.1:8888/luna-backups
      ''} %i";
    };
  };

  systemd.services."restic-backups-immich".onFailure = ["restic-notify-failure@%n.service"];
  systemd.services."restic-backups-immich-check".onFailure = ["restic-notify-failure@%n.service"];
  systemd.services."restic-backups-services".onFailure = ["restic-notify-failure@%n.service"];
  systemd.services."restic-backups-services-remote".onFailure = ["restic-notify-failure@%n.service"];
  systemd.services."restic-backups-services-remote-check".onFailure = ["restic-notify-failure@%n.service"];
}
