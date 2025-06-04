{
  config,
  pkgs,
  self,
  currentSystemUser,
  ...
}: {
  system.primaryUser = "mikeodr";
  ids.gids.nixbld = 30000;
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    age.keyFile = "/Users/${currentSystemUser}/.config/sops/age/keys.txt";
  };

  environment.systemPackages = with pkgs; [
    alejandra
    arping
    colima
    colmena
    direnv
    docker
    du-dust
    fastfetch
    fzf
    gh
    go
    jq
    mkalias
    mtr
    neovim
    nixd
    nixpkgs-fmt
    nmap
    sops
    terraform
    tmux
    watch
    wget
    zoxide
  ];

  security.pam.services.sudo_local.touchIdAuth = true;

  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = true;

    user = currentSystemUser;
  };

  homebrew = {
    enable = true;

    casks = [
      "1password-cli"
      "1password"
      "flameshot"
      "ghostty"
      "netnewswire"
      "obsidian"
      "rectangle"
      "slack"
      "visual-studio-code"
      "wireshark"
    ];

    brews = [
      "mas"
      "python"
    ];

    masApps = {
      "Status Clock" = 552792489;
    };

    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system.defaults = {
    dock = {
      autohide = true;
      orientation = "bottom";
    };

    NSGlobalDomain = {
      # Turn off "natural" scrolling
      "com.apple.swipescrolldirection" = false;
      AppleInterfaceStyle = "Dark";
      # Set clock to 24hour style
      AppleICUForce24HourTime = true;
      # Allow press and hold for vim keys to move around
      ApplePressAndHoldEnabled = false;
      # Mode 3 enables full keyboard control, tab menu selection etc
      AppleKeyboardUIMode = 3;
    };

    finder = {
      FXPreferredViewStyle = "clmv";
    };

    loginwindow.GuestEnabled = false;
  };

  system.startup.chime = false;

  system.activationScripts.applications.text = let
    env = pkgs.buildEnv {
      name = "system-applications";
      paths = config.environment.systemPackages;
      pathsToLink = "/Applications";
    };
  in
    pkgs.lib.mkForce ''
      # Set up applications.
      echo "setting up /Applications..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read -r src; do
        app_name=$(basename "$src")
        echo "copying $src" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
    '';

  sops.secrets.github_token = {};

  sops.templates = {
    nix-access-token-github = {
      content = ''
        access-tokens = github.com=${config.sops.placeholder.github_token}
      '';
      owner = "mikeodr";
    };
  };

  # Necessary for using flakes on this system.
  nix = {
    gc.automatic = true;
    optimise.automatic = true;
    extraOptions = ''
      !include ${config.sops.templates.nix-access-token-github.path}
    '';
    settings = {
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
    };
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
