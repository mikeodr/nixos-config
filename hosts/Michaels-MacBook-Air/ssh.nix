# Home-manager ssh config for Michaels-MacBook-Air. The shared macOS settings
# (1Password agent, ControlMaster, ~/.ssh/config.local) are in
# home-manager/ssh-darwin.nix.
#
# Hosts live in ~/.ssh/config.local, which is not tracked here
{ lib, ... }:
{
  programs.ssh.includes = lib.mkAfter [ "~/.colima/ssh_config" ];
}
