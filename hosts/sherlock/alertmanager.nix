{...}: {
  services.prometheus.alertmanager = {
    enable = true;
    openFirewall = true;

    configuration = {
      global = {
        slack_api_url = "https://hooks.slack.com/services/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";
      };

      route = {
        group_by = ["alertname"];
        group_wait = "10s";
        group_interval = "10s";
        #   repeat_interval = "1h";
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
              service_key = "0677310704ec4abfa0a5bb596e374dea";
              severity = "{{.Labels.severity}}";
            }
          ];
        }
        {
          name = "pd_receiver";
          slack_configs = [{send_resolved = true;}];
          pagerduty_configs = [
            {
              service_key = "0677310704ec4abfa0a5bb596e374dea";
              severity = "{{.Labels.severity}}";
            }
          ];
        }
        {
          name = "deadman";
          webhook_configs = [
            {
              url = "https://hc-ping.com/88e0b0bf-c9a5-4c1e-a362-55f16920ca12";
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
# inhibit_rules:
#   - source_match:
#       severity: 'critical'
#     target_match:
#       severity: 'warning'
#     equal: ['alertname', 'dev', 'instance']
    };
  };
}
