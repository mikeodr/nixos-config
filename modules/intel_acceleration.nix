{
  pkgs,
  nixpkgs,
  lib,
  config,
  ...
}: {
  options = {
    intelAcceleration.enable =
      lib.mkEnableOption "Enable intel embedded GPU hardware acceleration";
  };

  config = lib.mkIf config.intelAcceleration.enable {
    # Intel acceleration configs
    nixpkgs.config = {
      packageOverrides = pkgs: {
        vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
      };
    };

    environment.systemPackages = with pkgs; [
      intel-gpu-tools
    ];

    hardware = {
      intel-gpu-tools.enable = true;
      opengl = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver
          vaapiIntel
          vaapiVdpau
          libvdpau-va-gl
          intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
        ];
      };
    };
  };
}
