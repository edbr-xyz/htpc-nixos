# Edit this configuration file to define what should be installed on your system. 
# Help is available in the configuration.nix(5) man page and in the NixOS manual
# (accessible by running "nixos-help").

{ config, lib, pkgs, ... }:
  
  ## Firefox config variables
  let
    lock-false = { Value = false; Status = "locked"; };
    lock-true = { Value = true; Status = "locked"; };
  in
{
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  boot.kernelPackages = pkgs.linuxPackages_6_12;

  imports = [ ./hardware-configuration.nix ]; # Include the results of the hardware scan.

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    networkmanager.enable = true; # Enable networking
    hostName = "edbr-n150"; # Define your hostname.
  };

  services.openssh.enable = true;

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  
  environment.gnome.excludePackages = with pkgs; [
    baobab cheese eog epiphany gedit simple-scan
    totem yelp evince file-roller geary seahorse
    gnome-tour gnome-calendar gnome-characters
    gnome-clocks gnome-contacts gnome-logs gnome-maps
    gnome-music gnome-photos gnome-weather gnome-connections
  ];

  time.timeZone = "Europe/London";

  i18n = {
    defaultLocale = "en_GB.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_GB.UTF-8";
      LC_IDENTIFICATION = "en_GB.UTF-8";
      LC_MEASUREMENT = "en_GB.UTF-8";
      LC_MONETARY = "en_GB.UTF-8";
      LC_NAME = "en_GB.UTF-8";
      LC_NUMERIC = "en_GB.UTF-8";
      LC_PAPER = "en_GB.UTF-8";
      LC_TELEPHONE = "en_GB.UTF-8";
      LC_TIME = "en_GB.UTF-8";
    };
  };

  services.xserver.xkb = { # Configure keymap in X11
    layout = "gb";
    variant = "";
  };

  console.keyMap = "uk"; # Configure console keymap

  programs.dconf.enable = true; ## Enable DConf

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  nixpkgs.config.allowUnfree = true; # Allow unfree packages

  environment.systemPackages = with pkgs; [ # To search, run: nix search wget
    libva-utils
    nvtopPackages.intel
    nh
    glxinfo
    ffmpeg-full
    gparted
    lm_sensors
  ];

  users.users.edbr = {
    isNormalUser = true;
    description = "edbr";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      spotify
      moonlight-qt
      vlc
      gnome-tweaks
      vscode
    ];
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "edbr";
  };

  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver = pkgs.intel-vaapi-driver.override {
      enableHybridCodec = true;
    };
  };

  hardware.graphics = { # hardware.graphics since NixOS 24.11
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    GSK_RENDERER = "gl";
  };

  users.defaultUserShell = pkgs.zsh;
  system.userActivationScripts.zshrc = "touch .zshrc";
  environment.shells = with pkgs; [ zsh ];

  programs.zsh = {
    enable = true;
   
    enableCompletion = true;
    enableBashCompletion = true;    
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    histSize = 10000;

    shellAliases = {
      update = "sudo nixos-rebuild switch";
    };

    setOptions = [ "AUTO_CD" ];

    ohMyZsh = {
      enable = true;
      plugins = [ "git" "docker" ];
      theme = "mh";
    };
  };
  
  programs.firefox = {
    enable = true;
    /* ---- POLICIES ---- */
    policies = { # Check about:policies#documentation for options.
      SearchEngines = {
        Default = "DuckDuckGo";
        PreventInstalls = true;
      };
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value= true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      OverrideFirstRunPage = "";
      # OverridePostUpdatePage = "";
      DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
      DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
      SearchBar = "unified"; # alternative: "separate"
      /* ---- about:config ---- */
      Preferences = {
        "browser.aboutConfig.showWarning" = lock-false;
        "extensions.pocket.enabled" = lock-false;
        "browser.topsites.contile.enabled" = lock-false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
        "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
        "browser.newtabpage.activity-stream.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
        "media.videocontrols.picture-in-picture.video-toggle.enabled" = lock-false;
        # Hardware acceleration:
        "gfx.webrender.all" = lock-true;
        "media.ffmpeg.vaapi.enabled" = lock-true;
        "gfx.webrender.compositor" = lock-true;
        "gfx.webrender.compositor.force-enabled" = lock-true;
        "layout.frame_rate" = 58; # fixes youtube dropped frames that appear even when hardware accelerated
      };
    };
  };

  ## Service to keep awake during media playback
  systemd.services.audiocaffeine =
    let
      audioCaffeineScript = pkgs.writeShellScript "audioCaffeineScript.sh" ''
        #!/bin/sh

        # Audiocaffeine - PipeWire/PulseAudio
        # Works in NixOS with GNOME

        # https://unix.stackexchange.com/a/461194

        # Script to temporarily set suspend timout for AC and battery to "Never" while audio is playing.  It then reverts the settings when audio is no longer detected.

        export PATH="${lib.makeBinPath (with pkgs; [ pulseaudio dconf ])}:$PATH";

        actimeoutid="/org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-type"
        batttimeoutid="/org/gnome/settings-daemon/plugins/power/sleep-inactive-battery-type"
        disablevalue="'nothing'"

        # Create .config directory to store settings if it doesn't exist.
        if [ ! -d ~/.config ]; then
            echo ".config directory not found!"
            echo "Creating ~/.config"
            mkdir ~/.config
        fi

        # Create audiocaffeine directory to store settings if it doesn't exist.
        if [ ! -d ~/.config/audiocaffeine ]; then
            echo "Configuration directory not found!"
            echo "Creating ~/.config/audiocaffeine"
            mkdir ~/.config/audiocaffeine
        fi

        # Restore previous value for AC suspend timeout if script was interrupted.
        if [ -f ~/.config/audiocaffeine/acsuspend ]; then
            # echo "Restoring previous AC suspend timeout."
            read acsuspendtime < ~/.config/audiocaffeine/acsuspend
            dconf write $actimeoutid $acsuspendtime
            # echo "Removing temporary file ~/.config/audiocaffeine/acsuspend"
            rm ~/.config/audiocaffeine/acsuspend
        fi

        # Restore previous value for battery suspend timeout if script was interrupted.
        if [ -f ~/.config/audiocaffeine/battsuspend ]; then
            # echo "Restoring previous battery suspend timeout."
            read battsuspendtime < ~/.config/audiocaffeine/battsuspend
            dconf write $batttimeoutid $battsuspendtime
            # echo "Removing temporary file ~/.config/audiocaffeine/battsuspend"
            rm ~/.config/audiocaffeine/battsuspend
        fi

        # Start main loop to check if audio is playing
        while true; do

            # Use pactl to detect if there are any running audio sources.
            if pactl list | grep -q "State: RUNNING"; then

                # echo "Audio detected."

                # If AC timeout was not previously saved, then save it.
                if [ ! -f ~/.config/audiocaffeine/acsuspend ]; then
                    # echo "Saving current AC suspend timeout."
                    dconf read $actimeoutid > ~/.config/audiocaffeine/acsuspend
                fi

                # If battery timeout was not previously saved, then save it.
                if [ ! -f ~/.config/audiocaffeine/battsuspend ]; then
                    # echo "Saving current battery suspend timeout."
                    dconf read $batttimeoutid > ~/.config/audiocaffeine/battsuspend
                fi

                # Set the suspend timouts to Never using gsettings.
                # echo "Changing suspend timeouts."
                dconf write $actimeoutid $disablevalue
                dconf write $batttimeoutid $disablevalue

            else
                # echo "No audio detected."

                # Restore previous value for AC suspend timeout and delete the temporary file storing it.
                if [ -f ~/.config/audiocaffeine/acsuspend ]; then
                    # echo "Restoring previous AC suspend timeout."
                    read acsuspendtime < ~/.config/audiocaffeine/acsuspend
                    dconf write $actimeoutid $acsuspendtime
                    # echo "Removing temporary file ~/.config/audiocaffeine/acsuspend"
                    rm ~/.config/audiocaffeine/acsuspend
                fi

                # Restore previous value for battery suspend timeout and delete the temporary file storing it.
                if [ -f ~/.config/audiocaffeine/battsuspend ]; then
                    # echo "Restoring previous battery suspend timeout."
                    read battsuspendtime < ~/.config/audiocaffeine/battsuspend
                    dconf write $batttimeoutid $battsuspendtime
                    # echo "Removing temporary file ~/.config/audiocaffeine/battsuspend"
                    rm ~/.config/audiocaffeine/battsuspend
                fi

            fi
            sleep 5s

        done
      '';
    in {
      description = "AudioCaffeine - disables suspend during media playback";
      wantedBy = [ "graphical-session.target" "default.target" ];
      after = [ "graphical-session.target" "default.target" ];
      serviceConfig = {
        User = "edbr";
        Group = "users";
        Environment = "XDG_RUNTIME_DIR=/run/user/1000";
        ExecStart = "${audioCaffeineScript}";
        Restart = "always";
      };
    };
}
