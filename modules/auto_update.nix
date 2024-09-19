{
  config,
  lib,
  pkgs,
  inputs,
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
      flake = inputs.self.outPath;
      flags = [
        "--update-input"
        "nixpkgs"
        "--no-write-lock-file"
      ];
      dates = "06:00";
      randomizedDelaySec = "45min";
    };
  };
}
