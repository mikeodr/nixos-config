{config, ...}: {
  sops.secrets."obsidian/env" = {
    owner = config.services.couchdb.user;
    group = config.services.couchdb.group;
    mode = "660";
  };

  services.couchdb = {
    enable = true;
    configFile = "/run/secrets/obsidian/env";
    # https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_own_server.md#configure
    extraConfig = ''
      [couchdb]
      single_node=true
      max_document_size = 50000000

      [chttpd]
      require_valid_user = true
      max_http_request_size = 4294967296
      enable_cors = true

      [chttpd_auth]
      require_valid_user = true
      authentication_redirect = /_utils/session.html

      [httpd]
      WWW-Authenticate = Basic realm="couchdb"
      enable_cors = true

      [cors]
      origins = app://obsidian.md, capacitor://localhost, http://localhost
      credentials = true
      headers = accept, authorization, content-type, origin, referer
      methods = GET,PUT,POST,HEAD,DELETE
      max_age = 3600
    '';
  };
}
