# Home-manager ssh config for Michaels-MacBook-Air.
#
# Hosts with public IPs live in ~/.ssh/config.local, which is not tracked
# here (e.g. `tachi-deploy`, used by deploy-rs in flake.nix).
{ lib, ... }:
let
  onePasswordAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Rendered as a single Include line at the top of ~/.ssh/config, along
    # with Rex's ssh guard (programs.rex.sshGuard).
    # mkAfter keeps the guard first, since ssh uses the first value it sees.
    includes = lib.mkAfter [
      "~/.ssh/config.local"
      "~/.colima/ssh_config"
    ];

    settings = {
      # Rendered last, after the specific Host blocks.
      "*" = {
        IdentityAgent = onePasswordAgent;
        SetEnv = { TERM = "xterm-256color"; };
        ControlMaster = "auto";
        ControlPath = "~/.ssh/ssh-master-%C.socket";
        ControlPersist = "5m";
      };
    };
  };
}
