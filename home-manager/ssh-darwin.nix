# Home-manager ssh config shared by all macOS hosts (imported from
# modules/darwin.nix). Host-specific blocks live in hosts/<name>/ssh.nix.
#
# Hand-managed hosts (e.g. ones with public IPs) go in ~/.ssh/config.local,
# which is included but not tracked here.
{ lib, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # mkAfter keeps Rex's ssh guard first, since ssh uses the first value it
    # sees.
    includes = lib.mkAfter [ "~/.ssh/config.local" ];

    # Rendered last, after the specific Host blocks.
    settings."*" = {
      IdentityAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
      SetEnv = { TERM = "xterm-256color"; };
      ControlMaster = "auto";
      ControlPath = "~/.ssh/ssh-master-%C.socket";
      ControlPersist = "5m";
    };
  };
}
