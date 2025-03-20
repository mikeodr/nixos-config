{config, ...}: let
  dataDir = "/var/lib/alby";
in {
  systemd.tmpfiles.settings = {
    "10-alby" = {
      ${dataDir} = {
        d = {
          user = config.users.users.specter.name;
          group = config.users.users.nobody.group;
          mode = "0700";
        };
      };
    };
  };

  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {
    alby = {
      autoStart = true;
      image = "ghcr.io/getalby/hub:latest";
      ports = ["127.0.0.1:8080:8080"];
      environment = {
        WORK_DIR = "/data";
        PUID = "1000";
        PGID = "1000";
      };
      extraOptions = ["--pull=always"];
      volumes = [
        "/${dataDir}:/data"
      ];
    };
  };

  services.tailscale = {
    enable = true;
    # permit caddy to get certs from tailscale
    permitCertUid = "caddy";
  };

  security.acme.certs."unusedbytes.ca".reloadServices = ["caddy"];

  services.caddy = {
    enable = true;
    virtualHosts = {
      "knox.cerberus-basilisk.ts.net" = {
        extraConfig = ''
          reverse_proxy localhost:8080
        '';
      };
      "knox.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy localhost:8080
        '';
        useACMEHost = "unusedbytes.ca";
      };
    };
  };
}
