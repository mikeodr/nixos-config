{...}: let
  btc_server = "ghost.cerberus-basilisk.ts.net";
in {
  networking.firewall = {
    allowedTCPPorts = [
      8333
      9735
    ];
  };

  services = {
    nginx = {
      enable = true;
      streamConfig = ''
        server {
          listen 0.0.0.0:8333;
          listen [::]:8333;
          proxy_pass ${btc_server}:8333;
        }

        server {
          listen 0.0.0.0:9735;
          listen [::]:9735;
          proxy_pass ${btc_server}:9735;
        }
      '';
    };
  };
}
