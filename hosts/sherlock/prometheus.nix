{
  config,
  pkgs,
  sops,
  ...
}: let
  blackboxConfig = {
    modules = {
      http_2xx = {
        prober = "http";
      };
    };
  };
in {
  # sops.secrets."security/hass_token" = {
  #   owner = "prometheus";
  #   mode = "440";
  # };

  sops.secrets.hass_token = {
    owner = "prometheus";
    mode = "440";
    sopsFile = ./secrets.yaml;
  };

  services.prometheus = {
    # By default the check verifies also if all referenced paths exist.
    # This however cannot work if any of these paths refers to age/sops secrets as these files are created during the activation phase.
    # See: https://search.nixos.org/options?channel=24.05&show=services.prometheus.checkConfig&from=0&size=50&sort=relevance&type=packages&query=services.prometheus.checkConfig
    checkConfig = "syntax-only";

    exporters.node.enable = true;

    exporters.blackbox = {
      enable = true;
      openFirewall = true;
      configFile = pkgs.writeText "blackbox.yml" (builtins.toJSON blackboxConfig);
    };

    enable = true;
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.exporters.node.port}"
              "opnsense.unusedbytes.ca:9100"
              "reactor01.unusedbytes.ca:9100"
              "reactor02.unusedbytes.ca:9100"
              "luna.unusedbytes.ca:9100"
              "thor.unusedbytes.ca:9100"
            ];
          }
        ];
      }
      {
        job_name = "http_probe";
        params = {
          modules = ["http_2xx"];
        };
        metrics_path = "/probe";
        relabel_configs = [
          {
            source_labels = ["__address__"];
            target_label = "__param_target";
          }
          {
            source_labels = ["__param_target"];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "sherlock.unusedbytes.ca:9115";
          }
        ];
        static_configs = [
          {
            targets = [
              "https://opnsense.unusedbytes.ca"
              "https://unifi.unusedbytes.ca/protect"
              "https://unifi.unusedbytes.ca/network"
              "https://unifi.unusedbytes.ca"
              "http://kirby.unusedbytes.ca/sonarr"
              "http://kirby.unusedbytes.ca/radarr"
              "http://kirby.unusedbytes.ca/nzbget"
              "https://cryo01.unusedbytes.ca:5001"
              "https://reactor01.unusedbytes.ca:8006"
              "https://reactor02.unusedbytes.ca:8006"
              "https://hass.unusedbytes.ca"
            ];
          }
        ];
      }
      {
        job_name = "homeassistant";
        scrape_interval = "60s";
        metrics_path = "/api/prometheus";
        # See note about checkConfig above
        authorization.credentials_file = config.sops.secrets.hass_token.path;
        scheme = "https";
        static_configs = [{targets = ["hass.unusedbytes.ca"];}];
      }
    ];
  };
}