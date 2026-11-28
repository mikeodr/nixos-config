{
  description = "Nix configs for my systems, servers and macs";

  # Inputs are pinned with tack (https://github.com/manic-systems/tack):
  # see .tack/pins.toml, update with `tack update`.
  outputs =
    { self, ... } @ args:
    let
      inputs = (import ./.tack { overrides = args.tackOverrides or { }; }) // { inherit self; };
      nixpkgs = inputs.nixpkgs;
      lib = nixpkgs.lib;

      overlays = [
        (final: prev: {
          gh = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.gh;
          tailscale = inputs.tailscale.packages."${prev.stdenv.hostPlatform.system}".default;
        })
      ];

      mkSystem = import ./lib/mksystem.nix {
        inherit inputs;
        inherit nixpkgs;
        inherit overlays;
        inherit self;
      };

      mkHome = import ./lib/mkhome.nix {
        inherit inputs;
        inherit nixpkgs;
        inherit overlays;
      };

      # deploy-rs groups per node; nodes not listed get [ "home" ].
      #   deploy . --groups home        # personal hosts
      #   deploy . --groups work        # work hosts (only reachable from work network)
      nodeGroups = {
        mikeo-llm-sandbox = [ "work" ];
      };
    in
    {
      formatter = lib.genAttrs (import inputs.nix-systems) (
        system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt
      );

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
        forge = mkSystem "forge" {
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

      # Standalone home-manager configs for non-NixOS hosts
      homeConfigurations = {
        claude = mkHome "claude" {
          system = "x86_64-linux";
          signingkey = null;
        };

        mikeo-llm-sandbox = mkHome "mikeo-llm-sandbox" {
          system = "x86_64-linux";
          user = "ubuntu";
          email = "mikeo@tailscale.com";
          signingkey = null;
        };
      };

      # Deploy over LAN OpenSSH where possible: restarting tailscaled during
      # activation kills Tailscale SSH sessions and triggers a rollback.
      deploy.nodes =
        let
          lanHosts = [ "forge" "luna" "sherlock" "thor" ];
          # SSH aliases defined in ~/.ssh/config (keeps public IPs out of the repo)
          overrides = { tachi = "tachi-deploy"; };
          withGroups = builtins.mapAttrs (name: node: node // {
            groups = nodeGroups.${name} or [ "home" ];
          });
        in
        withGroups (builtins.mapAttrs
          (name: cfg: {
            hostname =
              overrides.${
              name
              } or (
                if builtins.elem name lanHosts
                then "${name}.unusedbytes.ca"
                else name
              );
            sshUser = "specter";
            remoteBuild = true;
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.${cfg.pkgs.stdenv.hostPlatform.system}.activate.nixos cfg;
            };
          })
          self.nixosConfigurations
        // builtins.mapAttrs
          (name: cfg: {
            hostname = name;
            sshUser = cfg.config.home.username;
            remoteBuild = true;
            # Home-manager only: no system profile, activate as the user
            profiles.home = {
              user = cfg.config.home.username;
              path = inputs.deploy-rs.lib.${cfg.pkgs.stdenv.hostPlatform.system}.activate.home-manager cfg;
            };
          })
          self.homeConfigurations);

      checks =
        builtins.mapAttrs
          (_: deployLib: deployLib.deployChecks self.deploy)
          (lib.filterAttrs (system: _: lib.hasSuffix "-linux" system) inputs.deploy-rs.lib);
    };
}
