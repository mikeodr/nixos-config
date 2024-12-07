{
  nixpkgs,
  nixpkgs-unstable,
  home-manager,
  sops-nix,
  ...
} @ inputs: let
  system = "x86_64-linux";
in {
  luna = nixpkgs.lib.nixosSystem {
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      inherit inputs;
      inherit system;
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
    };
    modules = [
      ./caddy-tor1-01
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };

  knox = nixpkgs.lib.nixosSystem {
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      inherit inputs;
      inherit system;
    };
    modules = [
      ./knox
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };

  tachi = nixpkgs.lib.nixosSystem {
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        system = "aarch64-linux";
        config.allowUnfree = true;
      };
      inherit inputs;
      system = "aarch64-linux";
    };
    modules = [
      ./tachi
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };
}
