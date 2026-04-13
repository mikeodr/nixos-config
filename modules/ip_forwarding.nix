{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    ip_forwarding.enable =
      lib.mkEnableOption "Enable IP forwarding and GRO forwarding";

    ip_forward_interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["ens18"];
    };

    gro_forwarding.enable = lib.mkEnableOption "Enable UDP GRO forwarding on specified interfaces";

    gro_forwarding.interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["ens18"];
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.ip_forwarding.enable {
      # set net.ipv4.ip_forward
      networking.nat.enable = true;
      # set net.ipv6.conf.all.forwarding
      networking.nat.enableIPv6 = true;
    })

    (lib.mkIf config.gro_forwarding.enable {
      environment.systemPackages = with pkgs; [
        ethtool
      ];
      systemd.services.gro-forwarding = {
        script =
          lib.strings.concatStrings (lib.lists.forEach config.gro_forwarding.interfaces
            (x: "${pkgs.ethtool}/bin/ethtool -K ${x} rx-udp-gro-forwarding on rx-gro-list off\n"));
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        requires = ["network.target"];
      };
    })
  ];
}
