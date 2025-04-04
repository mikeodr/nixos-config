{
  disko,
  nixpkgs,
  nixpkgs-unstable,
  nix-bitcoin,
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
      disko.nixosModules.disko
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };

  dauntless = nixpkgs.lib.nixosSystem {
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        system = "aarch64-linux";
        config.allowUnfree = true;
      };
      inherit inputs;
      system = "aarch64-linux";
    };
    modules = [
      ./dauntless
      disko.nixosModules.disko
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };

  ghost = nixpkgs.lib.nixosSystem {
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      inherit inputs;
      inherit system;
    };
    modules = [
      ./ghost
      disko.nixosModules.disko
      home-manager.nixosModules.home-manager
      nix-bitcoin.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };

  beaker = nixpkgs.lib.nixosSystem {
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      inherit inputs;
      inherit system;
    };
    modules = [
      ./beaker
      disko.nixosModules.disko
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };
}
