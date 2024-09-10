{pkgs-unstable, ...}: {
  services = {
    tailscale = {
      enable = true;
      package = pkgs-unstable.tailscale;
      openFirewall = true;
      extraUpFlags = ["--ssh"];
    };
  };
}
