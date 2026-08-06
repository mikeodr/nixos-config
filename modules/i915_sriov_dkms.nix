{
  config,
  lib,
  ...
}: {
  options = {
    i915SriovDkms.enable =
      lib.mkEnableOption "Intel i915 SR-IOV DKMS kernel module";
  };

  config = lib.mkIf config.i915SriovDkms.enable {
    boot.extraModulePackages = [
      (config.boot.kernelPackages.callPackage ../pkgs/i915-sriov-dkms.nix {})
    ];
  };
}
