{
  description = "Nix configs for my systems, servers and macs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nix-systems.url = "github:nix-systems/default";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
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
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.systems.follows = "nix-systems";
    };

    nix-bitcoin = {
      url = "github:fort-nix/nix-bitcoin/release";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
      inputs.flake-utils.inputs.systems.follows = "nix-systems";
    };
  };

  outputs = {
    disko,
    home-manager,
    nix-bitcoin,
    nix-darwin,
    nix-homebrew,
    nixpkgs-unstable,
    nixpkgs,
    self,
    sops-nix,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;

    overlays = [
      (final: prev: {
        gh = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.gh;
        go = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.go;
      })
    ];

    mkSystem = import ./lib/mksystem.nix {
      inherit inputs;
      inherit nixpkgs;
      inherit overlays;
      inherit self;
    };
  in {
    # nixosConfigurations = import ./hosts inputs;

    darwinConfigurations.Michaels-MacBook-Air = mkSystem "Michaels-MacBook-Air" {
      system = "aarch64-darwin";
      user = "mikeodr";
      darwin = true;
    };

    darwinConfigurations.Michaels-MacBook-Pro = mkSystem "Michaels-MacBook-Pro" {
      system = "aarch64-darwin";
      user = "mikeodr";
      email = "mikeo@tailscale.com";
      signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBU0iEDDQKTyGr91x3hK93fG79WIARtg8XgvDWbSg0LT";
      darwin = true;
    };

    nixosConfigurations = {
      beaker = mkSystem "beaker" {
        system = "x86_64-linux";
      };

      dauntless = mkSystem "dauntless" {
        system = "aarch64-linux";
      };

      ghost = mkSystem "ghost" {
        system = "x86_64-linux";
        btc = true;
      };

      knox = mkSystem "knox" {
        system = "x86_64-linux";
      };

      luna = mkSystem "luna" {
        system = "x86_64-linux";
      };

      sherlock = mkSystem "sherlock" {
        system = "x86_64-linux";
      };

      tachi = mkSystem "tachi" {
        system = "aarch64-linux";
      };

      thor = mkSystem "thor" {
        system = "x86_64-linux";
      };
    };

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
        defaults.deployment.buildOnTarget = true;
        defaults.deployment.allowLocalDeployment = true;
      };
  };
}
