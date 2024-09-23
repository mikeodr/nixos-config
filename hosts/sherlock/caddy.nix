{...}: {
  acmeCertGeneration.enable = true;

  security.acme.certs."unusedbytes.ca".reloadServices = ["caddy"];

  services.caddy = {
    enable = true;
    virtualHosts."prometheus.unusedbytes.ca" = {
      extraConfig = ''
        reverse_proxy http://localhost:9090
      '';
      useACMEHost = "unusedbytes.ca";
    };
    virtualHosts."alertmanager.unusedbytes.ca" = {
      extraConfig = ''
        reverse_proxy http://localhost:9093
      '';
      useACMEHost = "unusedbytes.ca";
    };
  };

  networking.firewall = {
    allowedTCPPorts = [80 443];
  };
}