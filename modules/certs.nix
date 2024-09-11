{
  config,
  lib,
  ...
}: {
  options = {
    acmeCertGeneration.enable =
      lib.mkEnableOption "Enable ACME cert generation on host";
  };

  config = lib.mkIf config.acmeCertGeneration.enable {
    sops.secrets."security/acme/cloudflare_dns_api_token" = {};

    security.acme = {
      acceptTerms = true;
      defaults.email = "spry.frog6886@hidemail.ca";

      certs."unusedbytes.ca" = {
        domain = "unusedbytes.ca";
        extraDomainNames = ["*.unusedbytes.ca"];
        dnsProvider = "cloudflare";
        dnsPropagationCheck = true;
        credentialsFile = /var/run/secrets/security/acme/cloudflare_dns_api_token;
      };
    };
  };
}
