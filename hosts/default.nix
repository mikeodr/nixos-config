{
  nixpkgs,
  nixpkgs-unstable,
  home-manager,
  sops-nix,
  ...
}@inputs : {
  luna = nixpkgs.lib.nixosSystem rec {
    system = "x86_64-linux";
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      inherit inputs;
    };
    modules = [
      ./luna
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };

  thor = nixpkgs.lib.nixosSystem rec {
    system = "x86_64-linux";
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      inherit inputs;
    };
    modules = [
      ./thor
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };

  sherlock = nixpkgs.lib.nixosSystem rec {
    system = "x86_64-linux";
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      inherit inputs;
    };
    modules = [
      ./sherlock
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };

  caddy-tor1-01 = nixpkgs.lib.nixosSystem rec {
    system = "x86_64-linux";
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      inherit inputs;
    };
    modules = [
      ./caddy-tor1-01
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };
}
