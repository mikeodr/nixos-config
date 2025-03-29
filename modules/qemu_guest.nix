{
  config,
  lib,
  ...
}: {
  options = {
    isVM = lib.mkOption {
      type = lib.types.bool;
      description = "Enable QEMU guest agent if system is a VM";
      default = false;
    };
  };

  config = {
    services.qemuGuest.enable = config.isVM;
  };
}
