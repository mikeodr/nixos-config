{config, ...}: {
  sops.secrets.grafanaAdminPassword = {
    owner = "grafana";
    group = "grafana";
    sopsFile = ./secrets.yaml;
  };

  services.grafana = {
    enable = true;

    settings = {
      server = {
        root_url = "https://grafana.unusedbytes.ca";
        domain = "unusedbytes.ca";
        enable_gzip = true;
      };
      security = {
        admin_password = "$__file{${config.sops.secrets.grafanaAdminPassword.path}}";
        secret_key = "SW2YcwTIb9zpOOhoPsMm"; # 26.05 update, not using any secrets in grafana, so this can be a static value.
      };
    };
  };
}
