# NixOS Configuration Flake

My NixOS configuration flag.

## Structure

- `home`: Home manager configuration settgs
- `hosts`: Per host machine flake settings
- `modules`: Custom module configuration imported by host/home/modules

## Running

[Nix Helper](https://github.com/viperML/nh) makes running flake updates quick. `nh os switch`. Setting the flake in the config makes executing it direct. No need to specify the flake path. Read the [example config](https://github.com/viperML/nh?tab=readme-ov-file#nixos-module) for details.
