{config, ...}: {
  # Ensure cert renewals reload caddy
  security.acme.certs."unusedbytes.ca".reloadServices = ["caddy"];

  services.tailscale.permitCertUid = "caddy";
  services.caddy = {
    enable = true;
    virtualHosts = {
      "luna.cerberus-basilisk.ts.net" = {
        extraConfig = ''
          reverse_proxy http://localhost:8096
        '';
      };
      "jellyfin.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:8096
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "oink.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy https://overseerr.unusedbytes.ca {
            header_up Host "overseerr.unusedbytes.ca"
          }
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "plex.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy https://thor.unusedbytes.ca:32400
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "freshrss.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:8080 {
            header_up Host "freshrss.unusedbytes.ca"
          }
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "obsidian-livesync.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString config.services.couchdb.port}

          @allowedOrigin expression `
            {http.request.header.Origin}.matches('^app://obsidian.md$') ||
            {http.request.header.Origin}.matches('^capacitor://localhost$') ||
            {http.request.header.Origin}.matches('^http://localhost$')
          `

          header {
            Access-Control-Allow-Origin {http.request.header.Origin}
            Access-Control-Allow-Methods "GET, PUT, POST, HEAD, DELETE"
            Access-Control-Allow-Headers "accept, authorization, content-type, origin, referer"
            Access-Control-Allow-Credentials "true"
            Access-Control-Max-Age "3600"
            Vary "Origin"
            defer
          }
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "mealie.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:9000
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "nzbget.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:6789
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "sonarr.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:8989
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "radarr.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:7878
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "lidarr.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:8686
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "prowlarr.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:9696
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "overseerr.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:5055
        '';
      };
      "abs.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:8081
        '';
      };
      "abs.cerberus-basilisk.ts.net" = {
        extraConfig = ''
          reverse_proxy http://localhost:8081
        '';
      };
      "pdf.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:8082
        '';
      };
      "photos.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:3001
        '';
      };
      "ntfy.unusedbytes.ca" = {
        serverAliases = ["ntfy.cerberus-basilisk.ts.net"];
        extraConfig = ''
          reverse_proxy http://localhost:8888

          # Redirect HTTP to HTTPS, but only for GET topic addresses, since we want
          # it to work with curl without the annoying https:// prefix
          @httpget {
              protocol http
              method GET
              path_regexp ^/([-_a-z0-9]{0,64}$|docs/|static/)
          }
          redir @httpget https://{host}{uri}
        '';
        useACMEHost = "unusedbytes.ca";
      };
      "bambuddy.unusedbytes.ca" = {
        extraConfig = ''
          reverse_proxy http://localhost:8000
        '';
      };
      ":443" = {
        extraConfig = ''
          respond "Not Found" 404
        '';
      };
    };
  };
}
