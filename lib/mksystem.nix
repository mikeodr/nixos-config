{
  inputs,
  nixpkgs,
  self,
  overlays,
  ...
}: name: {
  system,
  user,
  darwin ? false,
}: let
  # isDarwin = pxkgs.stdenv.isDarwin;
  # True if Linux, which is a heuristic for not being Darwin.
  # The config files for this system.
  machineConfig = ../hosts/${name};
  # Config =
  #   ../users/${user}/${
  #     if darwin
  #     then "darwin"
  #     else "nixos"
  #   }.nix;
  userHMConfig = ../home-manager;

  # NixOS vs nix-darwin functionst
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
        else {}
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
        else []
      );
  }
