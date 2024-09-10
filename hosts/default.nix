{
  nixpkgs,
  nixpkgs-unstable,
  home-manager,
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
    ];
  };
}
