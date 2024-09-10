{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    autoUpdate.enable =
      lib.mkEnableOption "Enable automatic updates of the system";
  };

  config = lib.mkIf config.autoUpdate.enable {
    system.autoUpgrade = {
      enable = true;
      allowReboot = true;
      flags = [
        "--update-input"
        "nixpkgs"
        "-L" # print build logs
      ];
      dates = "06:00";
      randomizedDelaySec = "45min";
      channel = "https://channels.nixos.org/nixos-24.05";
    };
  };
}
