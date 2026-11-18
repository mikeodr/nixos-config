# forge: Attic binary cache for the NixOS hosts.
#
# GitHub Actions builds the host closures and pushes them here over the
# tailnet; hosts substitute from https://forge.cerberus-basilisk.ts.net/<cache>.
# Nothing heavy is built locally, so the VM is small (2 vCPU / 4 GB / 100 GB).
{ config
, pkgs
, ...
}: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../modules/server.nix
  ];

  boot = {
    loader.grub = {
      # disko adds every disk with an EF02 partition to grub's device list.
      efiSupport = true;
      efiInstallAsRemovable = true;
      configurationLimit = 10;
    };
    tmp.cleanOnBoot = true;
    # Grow the root partition/filesystem after resizing the disk in Proxmox.
    growPartition = true;
  };
  fileSystems."/".autoResize = true;

  # Give space freed by attic GC back to the Proxmox thin pool
  # (requires discard=on on the VM disk).
  services.fstrim.enable = true;

  networking.hostName = "forge";

  # Contains ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="<openssl genrsa -traditional 4096 | base64 -w0>"
  sops.secrets."atticd/env" = {
    sopsFile = ./secrets.yaml;
    # Rotating the signing key must restart atticd, or it keeps validating
    # tokens against the old key.
    restartUnits = [ "atticd.service" ];
  };

  services.atticd = {
    enable = true;
    environmentFile = config.sops.secrets."atticd/env".path;

    # SQLite DB and local chunk storage default to /var/lib/atticd
    # (DynamicUser state dir, actually /var/lib/private/atticd).
    settings = {
      listen = "127.0.0.1:8080";
      api-endpoint = "https://forge.cerberus-basilisk.ts.net/";

      compression.type = "zstd";

      garbage-collection = {
        interval = "12 hours";
        # Per-cache override: attic cache configure <cache> --retention-period '90 days'
        default-retention-period = "1 month";
      };
    };
  };

  # TLS via tailscaled's ts.net cert (same pattern as luna).
  services.tailscale.permitCertUid = "caddy";
  services.caddy = {
    enable = true;
    virtualHosts."forge.cerberus-basilisk.ts.net".extraConfig = ''
      reverse_proxy 127.0.0.1:8080
    '';
  };

  environment.systemPackages = with pkgs; [
    attic-client
  ];

  services.prometheus.exporters.node.openFirewall = true;

  networking.firewall = {
    enable = true;
    # Cache is only reachable over the tailnet.
    interfaces.tailscale0.allowedTCPPorts = [ 443 ];
  };

  system.stateVersion = "26.05";
}
