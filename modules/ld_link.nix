{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    ldDynamicLink.enable =
      lib.mkEnableOption "Enable ld dynamic linking of downloaded binaries";
  };

  config = lib.mkIf config.ldDynamicLink.enable {
    # Allow ld dynamic linking of downloaded binaries
    programs.nix-ld = {
      enable = true;
      package = pkgs.nix-ld;
    };
  };
}
