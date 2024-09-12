{pkgs, ...}: {
  sops.secrets."security/wg0/privateKey" = {};
  sops.secrets."security/wg0/peer_mango_psk" = {};
  sops.secrets."security/wg0/peer_mike_iphone_psk" = {};

  networking = {
    nat = {
      enable = true;
      externalInterface = "ens18";
      internalInterfaces = ["wg0"];
    };
    firewall = {
      allowedUDPPorts = [51820];
    };
  };

  networking.wireguard.interfaces.wg0 = {
    ips = ["10.13.13.1/24"];
    listenPort = 51820;
    # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
    # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
    postSetup = ''
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o ens18 -j MASQUERADE
    '';

    # This undoes the above command
    postShutdown = ''
      ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o ens18 -j MASQUERADE
    '';

    privateKeyFile = "/run/secrets/security/wg0/privateKey";

    peers = [
      {
        name = "peer_tiffiphone";
        publicKey = "4Bs4zY45WiqBhf/OFtIhmY1aML43vZRN/AQJvD29OFA=";
        allowedIPs = ["10.13.13.3/32"];
      }
      {
        name = "peer_mikemacbook";
        publicKey = "43pLv6UBM3AdZndX7Vi29P59d/TDw1DRcmf+IZR8gSM=";
        allowedIPs = ["10.13.13.4/32"];
      }
      {
        name = "peer_mikeiphone";
        publicKey = "k0SHOn2elRdyGokf4UjRqqW/NHDVGhWZQQH7iE4nPmE=";
        presharedKeyFile = "/run/secrets/security/wg0/peer_mike_iphone_psk";
        allowedIPs = ["10.13.13.2/32"];
      }
      {
        name = "peer_mango";
        publicKey = "ObKcTvkJiSkPbTAKyJFhXnvZsjfHRQgQyDbnU+nEsyc=";
        presharedKeyFile = "/run/secrets/security/wg0/peer_mango_psk";
        allowedIPs = ["10.13.13.5/32"];
      }
    ];
  };
}
