{
  description = "Nix configs for my systems, servers and macs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nix-systems.url = "github:nix-systems/default";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tailscale = {
      url = "github:tailscale/tailscale/mikeodr/add-nixos-modules";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.systems.follows = "nix-systems";
    };

    tailscale-golink = {
      url = "github:tailscale/golink";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.systems.follows = "nix-systems";
    };

    tsidp = {
      url = "github:tailscale/tsidp";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.systems.follows = "nix-systems";
    };

    intel-gpu-exporter = {
      url = "github:mikeodr/intel-gpu-exporter-go";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.systems.follows = "nix-systems";
    };

    prometheus-plex-exporter = {
      url = "github:mikeodr/prometheus-plex-exporter";
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
    nixpkgs,
    self,
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
      cerberus = mkSystem "cerberus" {
        system = "x86_64-linux";
      };

      dauntless = mkSystem "dauntless" {
        system = "aarch64-linux";
        enableHomeManager = false;
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
        enableHomeManager = false;
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
          machinesFile = /etc/nix/machines;
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
