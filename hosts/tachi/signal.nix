{...}: let
  dataDir = "/var/lib/signal";
in {
  systemd.tmpfiles.settings = {
    "10-signal-cli" = {
      ${dataDir} = {
        d = {
          user = "root";
          group = "root";
          mode = "0700";
        };
      };
    };
  };

  virtualisation = {
    podman.enable = true;
    oci-containers.backend = "podman";

    oci-containers.containers = {
      "signal-cli-rest-api" = {
        image = "bbernhard/signal-cli-rest-api";
        ports = [
          "127.0.0.1:8080:8080"
        ];
        environment = {
          MODE = "json-rpc";
        };
        volumes = [
          "/var/lib/signal:/home/.local/share/signal-cli"
        ];
      };
    };
  };
}
