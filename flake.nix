{
  description = "Nix configs for my systems, servers and macs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nix-darwin.follows = "nix-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tailscale-golink = {
      url = "github:tailscale/golink";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };
  };

  outputs = {
    self,
    disko,
    nixpkgs,
    nix-darwin,
    nix-homebrew,
    home-manager,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = import ./hosts inputs;

    darwinConfigurations."Michaels-MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [
        ./darwin/home.nix
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
      ];
      specialArgs = {
        inherit inputs;
        inherit self;
      };
    };

    darwinConfigurations."Michaels-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./darwin/work.nix
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
          buildOnTarget = true;
        };

        thor.deployment = {
          tags = ["vm" "server"];
          buildOnTarget = true;
        };

        sherlock.deployment = {
          tags = ["vm" "server" "monitoring"];
          buildOnTarget = true;
        };

        tachi.deployment = {
          tags = ["vm" "vps"];
          buildOnTarget = true;
        };

        dauntless.deployment = {
          tags = ["vm" "vps"];
          buildOnTarget = true;
        };

        knox.deployment = {
          tags = ["vm" "server"];
          buildOnTarget = true;
        };

        ghost.deployment = {
          tags = ["vm" "server"];
          buildOnTarget = true;
        };
      };
  };
}
