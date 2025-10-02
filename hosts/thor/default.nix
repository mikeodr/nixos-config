{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/server.nix
    ./plex.nix
    inputs.intel-gpu-exporter.nixosModules.default
  ];

  boot = {
    loader.grub.device = "/dev/sda";
    tmp.cleanOnBoot = true;
  };

  # Custom module settings
  intelAcceleration.enable = true;
  acmeCertGeneration.enable = true;

  networking = {
    hostName = "thor";
    enableIPv6 = false;
  };

  fileSystems."/mnt/media" = {
    device = "172.16.0.3:/volume2/Media";
    fsType = "nfs4";
    options = ["auto" "x-systemd.automount" "_netdev"];
  };

  sops.secrets."security/acme/plex_pkcs12_pass" = {};
  security.acme.certs."unusedbytes.ca" = {
    group = "plex";
    # Ensure renew of cert generates a plex compatible cert and reloads the service
    postRun = ''
      openssl pkcs12 -export -out plex.pkfx -inkey key.pem -in cert.pem -certfile fullchain.pem -passout pass:$(cat /run/secrets/security/acme/plex_pkcs12_pass)
      chown acme:plex plex.pkfx
      chmod 640 plex.pkfx
    '';
    reloadServices = ["plex" "caddy"];
  };

  services = {
    intel-gpu-exporter = {
      enable = true;
      openFirewall = true;
    };

    plex = {
      enable = true;
      package = plex-package;
      openFirewall = true;
    };

    cron = {
      enable = true;
      systemCronJobs = [
        # 5am daily clear out plex transcoder folder for storage saving
        "0 5 * * * rm -r /var/lib/plex/Plex\ Media\ Server/Cache/PhotoTranscoder"
      ];
    };

    tailscale.permitCertUid = "caddy";

    caddy = {
      enable = true;

      virtualHosts = {
        "thor.cerberus-basilisk.ts.net" = {
          extraConfig = ''
            reverse_proxy http://thor:32400
          '';
        };
      };
    };
  };

  systemd.services = {
    auto-reboot = {
      description = "Reboot Service";
      startAt = ["Tue 03:00:00"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/run/current-system/sw/bin/reboot";
      };
    };
  };

  services.borgbackup.jobs = {
    plex = {
      paths = [
        "/var/lib/plex/Plex Media Server"
      ];
      exclude = [
        "/var/lib/plex/Plex Media Server/Cache"
        "/var/lib/plex/Plex Media Server/Crash Reports"
      ];
      doInit = false;
      encryption.mode = "none";
      repo = "/mnt/media/borgBackup/plex";
      compression = "auto,zstd";
      startAt = "daily";
      environment = {
        BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "yes";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    openssl
  ];

  services.prometheus.exporters.node.openFirewall = true;

  system.stateVersion = "24.05";
}
