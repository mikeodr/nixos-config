{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

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
    home-manager,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = import ./hosts inputs;

    colmena =
      lib.recursiveUpdate
      (builtins.mapAttrs (k: v: {imports = v._module.args.modules;}) self.nixosConfigurations)
      {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [];
          };
          nodeNixpkgs = builtins.mapAttrs (_: v: v.pkgs) self.nixosConfigurations;
          nodeSpecialArgs = builtins.mapAttrs (_: v: v._module.specialArgs) self.nixosConfigurations;
        };

        defaults.deployment.targetUser = "specter";

        luna.deployment = {
          tags = ["vm" "server"];
          allowLocalDeployment = true;
          # Disable SSH deployment. This node will be skipped in a
          # normal`colmena apply`.
          targetHost = null;
        };

        thor.deployment = {
          tags = ["vm" "server"];
        };

        sherlock.deployment = {
          tags = ["vm" "server" "monitoring"];
        };

        caddy-tor1-01.deployment = {
          tags = ["vm" "vps"];
          targetHost = "159.203.62.219";
        };
      };
  };
}
