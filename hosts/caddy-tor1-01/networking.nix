{lib, ...}: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    defaultGateway = "159.203.56.1";
    defaultGateway6 = {
      address = "";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          {
            address = "159.203.62.219";
            prefixLength = 21;
          }
          {
            address = "10.20.0.5";
            prefixLength = 16;
          }
        ];
        ipv4.routes = [
          {
            address = "159.203.56.1";
            prefixLength = 32;
          }
        ];
      };
      eth1 = {
        ipv4.addresses = [
          {
            address = "10.118.0.2";
            prefixLength = 20;
          }
        ];
      };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="ce:95:5f:9e:7d:63", NAME="eth0"
    ATTR{address}=="5e:2b:93:38:e1:df", NAME="eth1"
  '';
}
