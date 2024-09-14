{
  nixpkgs,
  nixpkgs-unstable,
  home-manager,
  sops-nix,
  ...
}: {
  luna = nixpkgs.lib.nixosSystem rec {
    system = "x86_64-linux";
    specialArgs = {
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
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
    };
    modules = [
      ./sherlock
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };
}
