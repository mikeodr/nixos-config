# Pull from the home Attic cache on forge.
#
# CI (.github/workflows/build.yml) builds every nixosConfiguration on main and
# pushes the closures there; hosts only read. The cache is public but only
# reachable over the tailnet, so no token is needed.
{ config
, lib
, ...
}: {
  options.atticCache.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Use the home Attic cache on forge as a substituter";
  };

  config = lib.mkIf config.atticCache.enable {
    nix.settings = {
      extra-substituters = [ "https://forge.cerberus-basilisk.ts.net/home" ];
      extra-trusted-public-keys = [ "home:v1CLKzFHxA7D+LEUWCwVyX02Ua/aUzvDYkU5F4xHTJQ=" ];
      # Don't stall when forge/tailscale is unreachable (e.g. tailscaled
      # restarting mid-deploy); fall back to building locally.
      connect-timeout = 5;
      fallback = true;
      # Default 3600: a miss would be remembered for an hour after CI pushes.
      narinfo-cache-negative-ttl = 60;
    };
  };
}
