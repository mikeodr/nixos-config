{
  config,
  lib,
  pkgs,
  self,
  ...
}: let
  userName = "mikeodr";
  userHome = "/Users/mikeodr";
in {
  nixpkgs.config.allowUnfree = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    users.${userName} = import ../home {inherit config lib pkgs userName userHome;};
  };

  environment.systemPackages = with pkgs; [
    arping
    alacritty
    alejandra
    colima
    colmena
    docker
    du-dust
    jq
    mkalias
    mtr
    neovim
    nixpkgs-fmt
    nixd
    nmap
    zoxide
  ];

  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = true;

    user = userName;
  };

  homebrew = {
    enable = true;

    brews = [
      "mas"
    ];

    masApps = {
      "Status Clock" = 552792489;
      "Tailscale" = 1475387142;
    };

    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  fonts.packages = [
    # Fix alacritty warning about missing fonts
    (pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];})
  ];

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

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Necessary for using flakes on this system.
  nix = {
    gc.automatic = true;
    optimise.automatic = true;

    settings = {
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
    };
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
