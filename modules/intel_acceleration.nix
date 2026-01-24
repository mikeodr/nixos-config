{
  pkgs,
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
        intel-vaapi-driver = pkgs.intel-vaapi-driver.override {enableHybridCodec = true;};
      };
    };

    environment.systemPackages = with pkgs; [
      intel-gpu-tools
    ];

    hardware = {
      intel-gpu-tools.enable = true;
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver
          intel-vaapi-driver
          libva-vdpau-driver
          libvdpau-va-gl
          intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
        ];
      };
    };
  };
}
