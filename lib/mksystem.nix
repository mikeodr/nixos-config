{
  inputs,
  nixpkgs,
  self,
  overlays,
  ...
}: name: {
  system,
  user ? "specter",
  darwin ? false,
  btc ? false,
  email ? "mike@unusedbytes.ca",
}: let
  machineConfig = ../hosts/${name};
  userHMConfig = ../home-manager;

  # NixOS vs nix-darwin functions
  systemFunc =
    if darwin
    then inputs.nix-darwin.lib.darwinSystem
    else nixpkgs.lib.nixosSystem;
  home-manager =
    if darwin
    then inputs.home-manager.darwinModules
    else inputs.home-manager.nixosModules;
  darwin-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
in
  systemFunc {
    inherit system;

    specialArgs =
      {
        inherit self;
      }
      // (
        if darwin
        then {inherit darwin-unstable;}
        else {
          pkgs-unstable = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
          inherit inputs;
          inherit system;
        }
      );

    modules =
      [
        # Apply our overlays. Overlays are keyed by system type so we have
        # to go through and apply our system type. We do this first so
        # the overlays are available globally.
        {nixpkgs.overlays = overlays;}

        # Allow unfree packages.
        {nixpkgs.config.allowUnfree = true;}

        machineConfig
        # osConfig
        home-manager.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.verbose = true;
          home-manager.users.${user} = import userHMConfig {
            inputs = inputs;
            user = user;
            email = email;
          };
        }

        # We expose some extra arguments so that our modules can parameterize
        # better based on these values.
        {
          config._module.args = {
            currentSystem = system;
            currentSystemName = name;
            currentSystemUser = user;
            inputs = inputs;
          };
        }
      ]
      ++ (
        if darwin
        then [
          inputs.nix-homebrew.darwinModules.nix-homebrew
          inputs.home-manager.darwinModules.home-manager
          inputs.sops-nix.darwinModules.sops
        ]
        else [
          inputs.disko.nixosModules.disko
          inputs.home-manager.nixosModules.home-manager
          inputs.sops-nix.nixosModules.sops
        ]
      )
      ++ (
        if btc
        then [
          inputs.nix-bitcoin.nixosModules.default
        ]
        else []
      );
  }
