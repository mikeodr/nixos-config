{pkgs, ...}: let
  userName = "specter";
in {
  imports = [
    ./base.nix
    ./certs.nix
    ./intel_acceleration.nix
    ./tailscale.nix
    ./tc4400_exporter.nix
    ../home
  ];

  programs.zsh.enable = true;
  users = {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.${userName} = {
      shell = pkgs.zsh;
      isNormalUser = true;
      extraGroups = ["wheel"];
      initialPassword = "correcthorsestaplebattery";
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjcdyNE+47rLaNLHKsGMTmfaat+DZxt3rUaidtV+aXWICuUvpeZcdgKYiuvDsolqt1uLPVLBczp1M+zrCvB2YjAI9hTgcXscIKmx4zeMowkhQAWQ3m8AA9LcFrv5j+XOtTZlw9FVkaxJf1Yn38/HsazqG2GlP9chyZkl1saxpX2uZon1h49A5HKejR0XpSwZgXTMigjZX1U0o+fHEsUJvgbNjgO9TVS60mA00/HOZGFLeNCe3iP/n4ROfIbJgf4ua41ZkJW4nhqxGyuG/9O2cj5McSf1Y8GIubLUSIzJ5ngvAi+pGB7hcYpivEHaS0mwpTSeo1BM7GhcKMV+5gjZHiV4wVmrAPK+sGKGV3HiXWDehdvio/m8lxCLwYkFIGV6/ykQh9ukmVq7PMFSMv7pyU0MxOarTZxXaSdt7pzQaPxxGpt7LnV5CBET6dzEpMCEWrl/7SNjvq2l1qwERSiCtb928TrygJRjk02sLVawWQWq6LMSVIEAh3fEhpSP4iERs="
      ];
    };
  };

  homeConfig.homeUser = "specter";
  homeConfig.homeDir = "/home/specter";
  homeConfig.gitEmail = "mike@unusedbytes.ca";
  homeConfig.gitSigningKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjcdyNE+47rLaNLHKsGMTmfaat+DZxt3rUaidtV+aXWICuUvpeZcdgKYiuvDsolqt1uLPVLBczp1M+zrCvB2YjAI9hTgcXscIKmx4zeMowkhQAWQ3m8AA9LcFrv5j+XOtTZlw9FVkaxJf1Yn38/HsazqG2GlP9chyZkl1saxpX2uZon1h49A5HKejR0XpSwZgXTMigjZX1U0o+fHEsUJvgbNjgO9TVS60mA00/HOZGFLeNCe3iP/n4ROfIbJgf4ua41ZkJW4nhqxGyuG/9O2cj5McSf1Y8GIubLUSIzJ5ngvAi+pGB7hcYpivEHaS0mwpTSeo1BM7GhcKMV+5gjZHiV4wVmrAPK+sGKGV3HiXWDehdvio/m8lxCLwYkFIGV6/ykQh9ukmVq7PMFSMv7pyU0MxOarTZxXaSdt7pzQaPxxGpt7LnV5CBET6dzEpMCEWrl/7SNjvq2l1qwERSiCtb928TrygJRjk02sLVawWQWq6LMSVIEAh3fEhpSP4iERs=";

  services.prometheus.exporters.node = {
    enable = true;
  };
}
