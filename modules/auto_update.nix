{
  config,
  lib,
  inputs,
  ...
}: {
  options = {
    autoUpdate.enable =
      lib.mkEnableOption "Enable automatic updates of the system";
    default = false;

    autoUpdate.allowReboot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow automatic reboots after updates";
    };
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
