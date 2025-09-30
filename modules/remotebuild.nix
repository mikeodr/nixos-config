{
  config,
  lib,
  ...
}: {
  options = {
    remoteBuild.enable = lib.mkEnableOption "Enable remote builds using a distributed build machine";
  };

  config = lib.mkIf config.remoteBuild.enable {
    programs.ssh.knownHosts = {
      cerberus.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF4qPfLz3BXgcg61CfIOmIOgA4RFxYPpqGlP8vhSG7Df";
    };
    nix.distributedBuilds = true;
    nix.settings.builders-use-substitutes = true;

    nix.buildMachines = [
      {
        hostName = "cerberus.cerberus-basilisk.ts.net";
        sshUser = "remotebuild";
        system = "x86_64-linux";
        maxJobs = 4;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
      }
      {
        hostName = "cerberus";
        sshUser = "remotebuild";
        system = "aarch64-linux";
        maxJobs = 4;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
      }
    ];
  };
}
