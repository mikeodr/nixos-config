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

### Deploying

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
  - `nix-shell -p sops --run "sops updatekeys secrets/secrets.yaml"`
  - `nix-shell -p sops --run "sops updatekeys hosts/tachi/secrets.yaml"`

### Infecting other hosts

```bash
nix run nixpkgs#nixos-anywhere -- --flake .#<host> --generate-hardware-config nixos-generate-config ./hosts/<hosts>/hardware-configuration.nix --build-on-remote root@<ip>
```

#### Credits

[BonusPlay/sysconf](https://github.com/BonusPlay/sysconf), a random repo I found that had a nice layout, and used colmena for managing multiple hosts.
