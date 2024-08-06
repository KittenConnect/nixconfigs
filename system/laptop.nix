# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  targetConfig,
  lib,
  pkgs,
  ...
}:

{
  services.openssh.enable = lib.mkForce false; # Disable OpenSSH server on laptop

  boot.initrd.systemd.enable = true; # Cleaner plymouth integration but no YubiKey support

  boot.plymouth = lib.mkIf (config.specialisation != { }) {
    enable = true;
    theme = lib.mkIf (config.services.xserver.desktopManager.plasma5.enable) "breeze";
  };

  boot.kernelParams = lib.mkIf (config.specialisation != { }) [ "quiet" ]; # Shut The Fuck Up on boot (plymouth will be interupted with boot logs if not set)
  boot.consoleLogLevel = lib.mkDefault 0;

  specialisation.debug.configuration = {
    boot.initrd.systemd.emergencyAccess = true;

    boot.consoleLogLevel = 7;
  };
  systemd.services.NetworkManager-wait-online.enable = lib.mkIf (config.networking.networkmanager.enable) false; # Not a server, so we should be able to work offline + NM-WaitOnline is quite dumb

  networking = {
    # FallBack to DHCPcd + WPASupplicant if NetworkManager is off ( eg: during installation )
    dhcpcd.enable = lib.mkIf (!config.networking.networkmanager.enable) true;
    wireless.enable = lib.mkIf (!config.networking.networkmanager.enable) true; # Enables wireless support via wpa_supplicant.
  };

  # NonPackaged apps
  services.flatpak.enable = true;
  # Deezer

  environment.systemPackages =
    with pkgs;
    [
      vim # Usefull to fix a broken config from TTY

      # libinput-gestures
    ]
    ++ lib.optionals (config.virtualisation.libvirtd.enable) [ virt-manager ]
    ++ [
      # Personal comfort Apps
      parsec-bin # To play GTA at work
    ];

  # Password manager
  programs._1password-gui.enable = true;
  programs._1password.enable = true;

  # VirtManager + LibVirt
  environment.sessionVariables.LIBVIRT_DEFAULT_URI = [ "qemu:///system" ];
  virtualisation.libvirtd = {
    enable = true;
    qemu.ovmf.enable = true; # UEFI
  };

  # Docker containers
  virtualisation.docker = {
    enable = true;

    autoPrune = {
      enable = true;
    };
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = [
        "DroidSansMono"
        "FiraCode"
        "Hack"
        "IosevkaTerm"
        "Terminus"
      ];
    })
  ];

  console.useXkbConfig = true;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  programs.gnupg.agent.pinentryPackage = lib.mkForce pkgs.pinentry-qt; # cuz there's a conflict between xserver / desktop-manager

  # X - VideoServer - Not the porn website
  services.xserver = {
    enable = true;

    displayManager.sddm.enable = lib.mkIf (config.services.xserver.desktopManager.plasma5.enable) true; # Default DM for KDE/Plasma

    desktopManager.plasma5 = {
      enable = true; # I miss windows look n feel
    };

    libinput = {
      enable = true; # for touchpad support on many laptops
      # touchpad.disableWhileTyping = true; # Plasma setting works better
    };

    videoDrivers = lib.mkOverride 40 [
      "cirrus"
      "vesa"
      "modesetting"
    ];

    xkb = {
      layout = "us";
      variant = "";
    };
  };
  # Enable sound with pipewire.
  sound.enable = true;
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
  services.printing.enable = true;

  # BlueTooth
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        ControllerMode = "dual"; # HessPods support
      };
    };
  };

  security.polkit.enable = true; # Else xRDP is black if user is logged-on locally
  services.xrdp = {
    enable = false;
    defaultWindowManager = "startplasma-x11"; # xRDP works better with x11
    openFirewall = true;
  };

  services.autorandr = {
    enable = false;

    hooks.postswitch = {
      "notify" = ''
        ( sleep 5; notify-send -i display "Display profile" "$AUTORANDR_CURRENT_PROFILE"; ) &
      '';
    };

    profiles = { };
  };
}
