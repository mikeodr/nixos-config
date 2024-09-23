{
  nixpkgs,
  nixpkgs-unstable,
  home-manager,
  sops-nix,
  ...
} @ inputs: let
  system = "x86_64-linux";

  userConfig = {
    username = "specter";
  };
in {
  luna = nixpkgs.lib.nixosSystem {
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      inherit inputs;
      inherit system;
      inherit userConfig;
    };
    modules = [
      ./luna
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };

  thor = nixpkgs.lib.nixosSystem {
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      inherit inputs;
      inherit system;
      inherit userConfig;
    };
    modules = [
      ./thor
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };

  sherlock = nixpkgs.lib.nixosSystem {
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      inherit inputs;
      inherit system;
      inherit userConfig;
    };
    modules = [
      ./sherlock
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };

  caddy-tor1-01 = nixpkgs.lib.nixosSystem {
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      inherit inputs;
      inherit system;
      inherit userConfig;
    };
    modules = [
      ./caddy-tor1-01
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };
}
