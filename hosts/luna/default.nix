{
  config,
  inputs,
  pkgs,
  pkgs-unstable,
  ...
}: {
  disabledModules = [
    "services/security/tsidp.nix"
  ];

  imports = [
    ./hardware-configuration.nix
    ../../modules/server.nix
    ../../modules/immich
    ../../modules/i915_sriov_dkms.nix
    ./bambuddy.nix
    ./caddy.nix
    ./containers.nix
    ./obsidian.nix
    ./paperless.nix
    ./tailscale-relay.nix
    inputs.tailscale-golink.nixosModules.default
    inputs.tsidp.nixosModules.default
  ];

  boot = {
    # Use the stable by-id path rather than /dev/sda - QEMU/virtio device
    # naming for scsi disks isn't guaranteed stable across reboots, and this
    # has already drifted once (this is the scsi0 disk, holding root+swap).
    loader.grub.device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
    tmp.cleanOnBoot = true;
  };

  # Enable intel acceleration in custom module
  intelAcceleration.enable = true;

  # Enable i915 SR-IOV DKMS kernel module
  i915SriovDkms.enable = true;

  # Enable Dynamic Downloaded Binary linking in custom module
  ldDynamicLink.enable = true;

  # Generate ACME Certs in custom module
  acmeCertGeneration.enable = true;

  # Custom module enable UDP GRO forwarding and IP forwarding
  ip_forwarding.enable = true;
  gro_forwarding.enable = true;

  sops.secrets.golink = {
    owner = config.services.golink.user;
    group = config.services.golink.group;
    mode = "440";
    sopsFile = ./secrets.yaml;
  };

  sops.secrets.pinchflat = {
    owner = config.services.pinchflat.user;
    group = config.services.pinchflat.group;
    mode = "440";
    sopsFile = ./secrets.yaml;
  };

  services = {
    golink = {
      enable = true;
      tailscaleAuthKeyFile = config.sops.secrets.golink.path;
    };

    tsidp = {
      enable = true;
    };

    pinchflat = {
      enable = true;
      mediaDir = "/mnt/media/PinchFlat";
      openFirewall = true;
      extraConfig = {
        TZ = "America/Toronto";
      };
      secretsFile = config.sops.secrets.pinchflat.path;
    };
  };

  # Media Mounts
  fileSystems = {
    "/mnt/media" = {
      device = "172.16.0.3:/volume2/Media";
      fsType = "nfs4";
      options = ["auto" "x-systemd.automount" "_netdev"];
    };
    "/mnt/music" = {
      device = "172.16.0.3:/volume2/Music";
      fsType = "nfs4";
      options = ["auto" "x-systemd.automount" "_netdev"];
    };
    "/mnt/immich" = {
      device = "172.16.0.3:/volume2/immich";
      fsType = "nfs4";
      options = ["auto" "x-systemd.automount" "_netdev"];
    };
  };

  environment.systemPackages = with pkgs; [
    colmena
  ];

  services.jellyfin = {
    enable = true;
    package = pkgs-unstable.jellyfin;
  };

  # Give jellyfin access to the GPU
  users.users.jellyfin.extraGroups = ["render" "video"];

  services.audiobookshelf = {
    enable = true;
    package = pkgs-unstable.audiobookshelf;
    host = "0.0.0.0";
    port = 8081;
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [8081];

  services.ntfy-sh = {
    enable = true;
    package = pkgs-unstable.ntfy-sh;
    settings = {
      listen-http = ":8888";
      behind-proxy = true;
      base-url = "https://ntfy.unusedbytes.ca";
      upstream-base-url = "https://ntfy.sh";
    };
  };

  programs.ssh.knownHosts = {
    "cubxc6s9.repo.borgbase.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMS3185JdDy7ffnr0nLWqVy8FaAQeVh1QYUSiNpW5ESq";
  };

  sops.secrets."borgbackup_key" = {
    sopsFile = ./secrets.yaml;
  };

  sops.secrets."borg_ssh_key" = {
    sopsFile = ./secrets.yaml;
    owner = "root";
    path = "/root/.ssh/id_ed25519";
  };

  services.borgbackup.jobs = let
    borgPaths = [
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
    borgHooks = {
      preHook = ''
        systemctl stop jellyfin.service
      '';
      postHook = ''
        systemctl start jellyfin.service
      '';
    };
  in {
    services =
      borgHooks
      // {
        paths = borgPaths;
        doInit = false;
        encryption.mode = "none";
        repo = "/mnt/media/borgBackup/luna";
        compression = "auto,zstd";
        startAt = "daily";
        environment = {
          BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "yes";
        };
        prune.keep = {
          daily = 7;
          weekly = 2;
          monthly = 3;
        };
      };

    services-remote =
      borgHooks
      // {
        paths = borgPaths;
        encryption = {
          mode = "repokey-blake2";
          passCommand = "cat ${config.sops.secrets.borgbackup_key.path}";
        };
        repo = "ssh://m4yi8jbz@m4yi8jbz.repo.borgbase.com/./repo";
        compression = "auto,zstd";
        startAt = "daily";
      };
  };

  networking = {
    hostName = "luna";
  };

  services.prometheus.exporters.node.openFirewall = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      # HTTP/HTTPS for caddy
      80
      443
      # Bambuddy
      3000
      3002
      8883
      990
      322 # Bambuddy live camera
    ];
    allowedTCPPortRanges = [
      {
        from = 2024;
        to = 2026;
      } # P1S proprietary (Bambuddy)
      {
        from = 50000;
        to = 50009;
      } # VP 1 passive FTP data (Bambuddy)
    ];
    allowedUDPPorts = [
      2021 # SSDP (Bambuddy)
      41642 # Peer relay for Tailscale
    ];
  };

  system.stateVersion = "25.05";
}
