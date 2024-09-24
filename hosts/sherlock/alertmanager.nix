{config, ...}: {
  sops.secrets = {
    slackApiHook = {
      owner = "prometheus";
      mode = "444";
      sopsFile = ./secrets.yaml;
    };

    pagerdutyServiceKey = {
      owner = "prometheus";
      mode = "444";
      sopsFile = ./secrets.yaml;
    };

    hcPingUrl = {
      owner = "prometheus";
      mode = "444";
      sopsFile = ./secrets.yaml;
    };
  };

  services.prometheus.alertmanager = {
    enable = true;
    openFirewall = true;

    configuration = {
      global = {
        slack_api_url_file = config.sops.secrets.slackApiHook.path;
      };

      route = {
        group_by = ["alertname"];
        group_wait = "10s";
        group_interval = "10s";
        receiver = "blackhole";
        routes = [
          {
            match.alertname = "Watchdog";
            receiver = "deadman";
            repeat_interval = "5m";
          }
          {
            match_re.severity = "critical|error";
            receiver = "pd_receiver";
          }
          {
            match_re.severity = "warning";
            receiver = "warning_receiver";
          }
        ];
      };

      receivers = [
        {
          name = "blackhole";
          slack_configs = [
            {
              send_resolved = true;
              title = "Blackhole Alert";
            }
          ];
          pagerduty_configs = [
            {
              severity = "{{.Labels.severity}}";
              service_key_file = config.sops.secrets.pagerdutyServiceKey.path;
            }
          ];
        }
        {
          name = "pd_receiver";
          slack_configs = [{send_resolved = true;}];
          pagerduty_configs = [
            {
              severity = "{{.Labels.severity}}";
              service_key_file = config.sops.secrets.pagerdutyServiceKey.path;
            }
          ];
        }
        {
          name = "deadman";
          webhook_configs = [
            {
              url_file = config.sops.secrets.hcPingUrl.path;
              send_resolved = true;
            }
          ];
        }
        {
          name = "warning_receiver";
          slack_configs = [{send_resolved = true;}];
        }
      ];

      inhibit_rules = [
        {
          source_match.severity = "critical";
          target_match.severity = "warning";
          equal = ["alertname" "dev" "instnace"];
        }
      ];
    };
  };
}
