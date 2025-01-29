# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

  ## Firefox config variables
  let
    lock-false = { Value = false; Status = "locked"; };
    lock-true = { Value = true; Status = "locked"; };
  in
{
  imports = [ 
    ./hardware-configuration.nix # Include the results of the hardware scan.
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "edbr-htpc"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
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

  ## Enable nix-ld
  programs.nix-ld.enable = true;

  ## Enable SSH
  services.openssh.enable = true;

  ## Enable Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
  
  programs.sway.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  ## Remove GNOME bloat
  environment.gnome.excludePackages = with pkgs; [ 
    baobab      # disk usage analyzer
    cheese      # photo booth
    eog         # image viewer
    epiphany    # web browser
    gedit       # text editor
    simple-scan # document scanner
    totem       # video player
    yelp        # help viewer
    evince      # document viewer
    file-roller # archive manager
    geary       # email client
    seahorse    # password manager
    
    gnome-tour 
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-contacts
    gnome-logs
    gnome-maps
    gnome-music
    gnome-photos
    gnome-screenshot
    gnome-weather
    pkgs.gnome-connections
  ];

  ## Enable DConf
  programs.dconf.enable = true;

  # Configure console keymap
  console.keyMap = "uk";

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.edbr = {
    isNormalUser = true;
    description = "edbr";
    extraGroups = [ "networkmanager" "wheel" "docker"];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run 'nix search <app>'
  environment.systemPackages = with pkgs; [
    spotify
    moonlight-qt
    vscode
    vlc
    gnome-tweaks
    docker-compose
    nh
    nvtopPackages.amd
    git
  ];

  environment.sessionVariables.MOZ_ENABLE_WAYLAND = "1";

  programs.firefox = {
    enable = true;

    /* ---- POLICIES ---- */
    # Check about:policies#documentation for options.
    policies = {
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
      # DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
      DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
      SearchBar = "unified"; # alternative: "separate"

      /* ---- PREFERENCES ---- */
      # Check about:config for options.
      Preferences = { 
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
        
        "gfx.webrender.all" = lock-true;
        "media.ffmpeg.vaapi.enabled" = lock-true;
        "media.av1.enabled" = lock-false;
        "media.videocontrols.picture-in-picture.video-toggle.enabled" = lock-false;
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
            echo "Restoring previous AC suspend timeout."
            read acsuspendtime < ~/.config/audiocaffeine/acsuspend
            dconf write $actimeoutid $acsuspendtime
            echo "Removing temporary file ~/.config/audiocaffeine/acsuspend"
            rm ~/.config/audiocaffeine/acsuspend
        fi

        # Restore previous value for battery suspend timeout if script was interrupted.
        if [ -f ~/.config/audiocaffeine/battsuspend ]; then
            echo "Restoring previous battery suspend timeout."
            read battsuspendtime < ~/.config/audiocaffeine/battsuspend
            dconf write $batttimeoutid $battsuspendtime
            echo "Removing temporary file ~/.config/audiocaffeine/battsuspend"
            rm ~/.config/audiocaffeine/battsuspend
        fi

        # Start main loop to check if audio is playing
        while true; do

            # Use pactl to detect if there are any running audio sources.
            if pactl list | grep -q "State: RUNNING"; then

                echo "Audio detected."

                # If AC timeout was not previously saved, then save it.
                if [ ! -f ~/.config/audiocaffeine/acsuspend ]; then
                    echo "Saving current AC suspend timeout."
                    dconf read $actimeoutid > ~/.config/audiocaffeine/acsuspend
                fi

                # If battery timeout was not previously saved, then save it.
                if [ ! -f ~/.config/audiocaffeine/battsuspend ]; then
                    echo "Saving current battery suspend timeout."
                    dconf read $batttimeoutid > ~/.config/audiocaffeine/battsuspend
                fi

                # Set the suspend timouts to Never using gsettings.
                echo "Changing suspend timeouts."
                dconf write $actimeoutid $disablevalue
                dconf write $batttimeoutid $disablevalue

            else
                echo "No audio detected."

                # Restore previous value for AC suspend timeout and delete the temporary file storing it.
                if [ -f ~/.config/audiocaffeine/acsuspend ]; then
                    echo "Restoring previous AC suspend timeout."
                    read acsuspendtime < ~/.config/audiocaffeine/acsuspend
                    dconf write $actimeoutid $acsuspendtime
                    echo "Removing temporary file ~/.config/audiocaffeine/acsuspend"
                    rm ~/.config/audiocaffeine/acsuspend
                fi

                # Restore previous value for battery suspend timeout and delete the temporary file storing it.
                if [ -f ~/.config/audiocaffeine/battsuspend ]; then
                    echo "Restoring previous battery suspend timeout."
                    read battsuspendtime < ~/.config/audiocaffeine/battsuspend
                    dconf write $batttimeoutid $battsuspendtime
                    echo "Removing temporary file ~/.config/audiocaffeine/battsuspend"
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  ## Unused:

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # # Enable CUPS to print documents.
  # services.printing.enable = true;

  # # Configure keymap in X11
  # services.xserver.xkb = {
  #   layout = "gb";
  #   variant = "";
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # # Install firefox.
  # programs.firefox.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };


  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
}
