{
  config,
  pkgs,
  ...
}: let
  plex-version = {
    version = "1.43.1.10611-1e34174b1";
    sha256 = "sha256-pr1+VSObX0sBl/AddeG/+2dIbNdc+EtnvCzy4nTXVn8=";
  };
  plex-package = pkgs.plex.override {
    plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
      version = plex-version.version;
      src = pkgs.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        sha256 = plex-version.sha256;
      };
    });
  };
in {
  sops.secrets = {
    "plex_env" = {
      sopsFile = ./secrets.yaml;
    };
    "security/acme/plex_pkcs12_pass" = {};
  };

  security.acme.certs."unusedbytes.ca" = {
    # Ensure renew of cert generates a plex compatible cert and reloads the service
    postRun = ''
      openssl pkcs12 -export -out plex.pkfx -inkey key.pem -in cert.pem -certfile fullchain.pem -passout pass:$(cat /run/secrets/security/acme/plex_pkcs12_pass)
      chown acme:plex plex.pkfx
      chmod 640 plex.pkfx
    '';
    reloadServices = ["plex" "caddy"];
  };

  users.users.plex.extraGroups = ["acme"];
  users.users.caddy.extraGroups = ["acme"];

  services = {
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
        "oink.unusedbytes.ca" = {
          extraConfig = ''
            reverse_proxy http://luna.cerberus-basilisk.ts.net:5055
          '';
          useACMEHost = "unusedbytes.ca";
        };
        "oinkts.unusedbytes.ca" = {
          extraConfig = ''
            reverse_proxy http://luna.cerberus-basilisk.ts.net:5055
          '';
          useACMEHost = "unusedbytes.ca";
        };
      };
    };

    intel-gpu-exporter = {
      enable = true;
      openFirewall = true;
    };

    prometheus-plex-exporter = {
      enable = true;
      environmentFile = config.sops.secrets.plex_env.path;
    };
  };
}
