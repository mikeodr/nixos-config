{
  config,
  pkgs,
  self,
  currentSystemUser,
  ...
}: {
  # direnv 2.37.1 fish test is killed (SIGKILL) by the macOS sandbox during build
  nixpkgs.overlays = [
    (final: prev: {
      direnv = prev.direnv.overrideAttrs (_: {doCheck = false;});
    })
  ];

  system.primaryUser = "mikeodr";
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
    deploy-rs
    direnv
    docker
    dust
    fastfetch
    fzf
    gh
    gnupg
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
    ];

    brews = [
      "python"
    ];

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

  sops.secrets.github_token = {};

  sops.templates = {
    nix-netrc-github = {
      content = ''
        machine github.com
        login mikeodr
        password ${config.sops.placeholder.github_token}
      '';
      owner = "mikeodr";
    };
  };

  determinateNix.determinateNixd.authentication.additionalNetrcSources = [
    config.sops.templates.nix-netrc-github.path
  ];

  # Necessary for using flakes on this system.
  determinateNix = {
    enable = true; # also sets nix.enable = false for you

    # replaces nix.settings.warn-dirty
    customSettings = {
      warn-dirty = false;
      auto-optimise-store = true;
      # Lets deploy-rs remote builds pass --store without
      # "not a trusted user" warnings from the local daemon.
      trusted-users = ["root" "mikeodr"];
    };
  };

  # replaces nix.gc.automatic — determinate-nixd collects garbage itself
  determinateNix.determinateNixd.garbageCollector.strategy = "automatic";

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
