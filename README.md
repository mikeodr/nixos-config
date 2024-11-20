# NixOS Configuration Flake

My NixOS configuration flake.

This is my personal config, please be inspired and copy from it as needed!

## Structure

- `home`: Home manager configuration settings
- `hosts`: Per host machine flake settings
- `modules`: Custom module configuration imported by host, home, other modules

## Secrets

Secrets are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) for deploying to multiple hosts.

Please see [Vimjoyer's Excellent Video](https://www.youtube.com/watch?v=G5f6GC7SnhU) in addition to the `sops-nix` documentation.

## Running

### Deploying locally on a machine

[Nix Helper](https://github.com/viperML/nh) makes running flake updates quick. `nh os switch`. Setting the flake in the config makes executing it direct. No need to specify the flake path. Read the [example config](https://github.com/viperML/nh?tab=readme-ov-file#nixos-module) for details.

### Deploying to multiple machines

[colmena](https://github.com/zhaofengli/colmena) is used to deploy to multiple machines either individually by host or by group of tags.

- `colmena apply switch --on <host>`
- `colmena apply switch --on @tag`

### Adding a new host via colmena

- Host should have a user set
- SSH key should be set
- Set `security.sudo.wheelNeedsPassword = false;`

### Adding a new host to the secrets access

- For a new host run:  
  - `mkdir -p ~/.config/sops/age/`
  - `nix-shell -p age --run "age-keygen -o ~/.config/sops/age/keys.txt"`
- Add public key returned to `.sops.yaml`
- Update secrets/secrets.yaml with new keys:  
`nix-shell -p sops --run "sops updatekeys secrets/secrets.yaml"`
`nix-shell -p sops --run "sops updatekeys modules/tailscale_key.yaml"`

#### Credits

[BonusPlay/sysconf](https://github.com/BonusPlay/sysconf), a random repo I found that had a nice layout, and used colmena for managing multiple hosts.
