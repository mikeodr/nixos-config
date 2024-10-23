{
  description = "Nix configs for my systems, servers and macs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nix-darwin,
    nix-homebrew,
    home-manager,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = import ./hosts inputs;

    darwinConfigurations."Michaels-MacBook-Air" = let
      userName = "mikeodr";
      userHome = "/Users/mikeodr";
    in
      nix-darwin.lib.darwinSystem {
        modules = [
          ./darwin/default.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
        ];
        specialArgs = {
          inherit inputs;
          inherit self;
        };
      };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."Michaels-MacBook-Air".pkgs;

    colmena =
      lib.recursiveUpdate
      (builtins.mapAttrs (k: v: {imports = v._module.args.modules;}) self.nixosConfigurations)
      {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [];
          };
          nodeNixpkgs =
            builtins.mapAttrs
            (_: v: v.pkgs)
            self.nixosConfigurations;
          nodeSpecialArgs =
            builtins.mapAttrs
            (_: v: v._module.specialArgs)
            self.nixosConfigurations;
        };

        defaults.deployment.targetUser = "specter";

        luna.deployment = {
          tags = ["vm" "server"];
          allowLocalDeployment = true;
          # Disable SSH deployment. This node will be skipped in a
          # normal `colmena apply`.
          targetHost = "luna.unusedbytes.ca";
          buildOnTarget = true;
        };

        thor.deployment = {
          tags = ["vm" "server"];
          targetHost = "thor.unusedbytes.ca";
          buildOnTarget = true;
        };

        sherlock.deployment = {
          tags = ["vm" "server" "monitoring"];
          targetHost = "sherlock.unusedbytes.ca";
          buildOnTarget = true;
        };

        caddy-tor1-01.deployment = {
          tags = ["vm" "vps"];
          targetHost = "159.203.62.219";
          buildOnTarget = true;
        };
      };
  };
}
