# Standalone home-manager configuration for hosts not managed by NixOS or
# nix-darwin (e.g. a generic Linux box with Nix installed).
{ inputs
, nixpkgs
, overlays
, ...
}: name: { system
         , user ? "specter"
         , email ? "mike@unusedbytes.ca"
         , signingkey ? "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILOkkbCny2gXw85T1CEUdMIyizGrmDx9CqxzyLCu9WLk"
         ,
         }:
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    inherit system overlays;
    config.allowUnfree = true;
  };

  extraSpecialArgs = {
    inherit inputs;
    currentSystem = system;
    currentSystemName = name;
    currentSystemUser = user;
  };

  modules = [
    (import ../home-manager {
      inherit inputs user email signingkey;
    })
    {
      # Integrate with a non-NixOS distro (XDG data dirs, locales, etc.)
      targets.genericLinux.enable = nixpkgs.lib.hasSuffix "-linux" system;
    }
  ];
}
