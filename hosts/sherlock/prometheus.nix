{
  config,
  pkgs,
  ...
}: let
  blackboxConfig = {
    modules = {
      http_2xx = {
        prober = "http";
        http = {
          preferred_ip_protocol = "ip4";
        };
      };
    };
  };
in {
  sops.secrets.hassToken = {
    owner = "prometheus";
    mode = "440";
    sopsFile = ./secrets.yaml;
  };

  services.prometheus = {
    enable = true;

    # By default the check verifies also if all referenced paths exist.
    # This however cannot work if any of these paths refers to age/sops secrets as these files are created during the activation phase.
    # See: https://search.nixos.org/options?channel=24.05&show=services.prometheus.checkConfig&from=0&size=50&sort=relevance&type=packages&query=services.prometheus.checkConfig
    checkConfig = "syntax-only";

    exporters.node = {
      enable = true;
      openFirewall = true;
    };

    exporters.blackbox = {
      enable = true;
      openFirewall = true;
      configFile = pkgs.writeText "blackbox.yml" (builtins.toJSON blackboxConfig);
    };

    ruleFiles = [
      ./rules.yml
    ];

    alertmanagers = [
      {
        static_configs = [
          {
            targets = ["localhost:9093"];
          }
        ];
      }
    ];

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.exporters.node.port}"
              "reactor02.unusedbytes.ca:9100"
              "fusion01.unusedbytes.ca:9100"
              "titan.unusedbytes.ca:9100"
              "luna.unusedbytes.ca:9100"
              "thor.unusedbytes.ca:9100"
              "tachi.cerberus-basilisk.ts.net:9100"
              "dauntless.cerberus-basilisk.ts.net:9100"
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
              "https://cryo01.unusedbytes.ca:5001"
              "https://fusion01.unusedbytes.ca:8006"
              "https://go.cerberus-basilisk.ts.net"
              "https://hass.unusedbytes.ca"
              "https://nzbget.unusedbytes.ca"
              "https://radarr.unusedbytes.ca"
              "https://sonarr.unusedbytes.ca"
              "https://thor.cerberus-basilisk.ts.net/web/index.html"
              "https://titan.unusedbytes.ca:8007"
              "https://unifi.unusedbytes.ca"
              "https://unifi.unusedbytes.ca/network"
              "https://unifi.unusedbytes.ca/protect"
            ];
          }
        ];
      }
      {
        job_name = "homeassistant";
        scrape_interval = "60s";
        metrics_path = "/api/prometheus";
        # See note about checkConfig above
        authorization.credentials_file = config.sops.secrets.hassToken.path;
        scheme = "https";
        static_configs = [{targets = ["hass.unusedbytes.ca"];}];
      }
    ];
  };
}
