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
    security.acme = {
      acceptTerms = true;
      defaults.email = "spry.frog6886@hidemail.ca";

      certs."unusedbytes.ca" = {
        domain = "unusedbytes.ca";
        extraDomainNames = ["*.unusedbytes.ca"];
        dnsProvider = "cloudflare";
        dnsPropagationCheck = true;
        credentialsFile = /home/specter/.secrets/cf;
      };
    };
  };
}
