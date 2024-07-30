# nixos-config

My nixos configurations

The base `/etc/nixos/configuration.nix` needs to be updated to reference the local repo, ensure to update the hostname and username for the system in question:

```nix
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).
{
  config,
  pkgs,
  ...
}: let
  # NOTE: This hostname must match the hosts file.
  hostname = "YOURHOSTNAMEHERE";
  unstableTarball =
    fetchTarball
    https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
in {
  networking.hostName = hostname; # Define your hostname.

  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    (/home/YOURUSERNAME/nixos-config/hosts + "/${hostname}.nix")
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
```

Now you can edit your nixos configuration locally in your home source directory and run `nixos-rebuild switch` to apply.