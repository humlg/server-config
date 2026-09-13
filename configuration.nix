{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./userspace.nix
    ./modules/storage.nix
    ./modules/vpn.nix
    ./modules/media.nix
    ./modules/home-assistant.nix
    ./modules/minecraft.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "HomeLab";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # Static IP on the LAN uplink.
  networking.networkmanager.ensureProfiles.profiles."enp59s0" = {
    connection = {
      id = "enp59s0";
      type = "ethernet";
      interface-name = "enp59s0";
    };
    ipv4 = {
      method = "manual";
      address1 = "192.168.5.1/23,192.168.4.1";
      dns = "192.168.4.1;";
    };
  };

  # Bare `nix` CLI calls (e.g. `nix flake update`) need this enabled too —
  # nixos-rebuild --flake enables it internally for its own calls, but that
  # doesn't cover other nix invocations.
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  # cs_CZ formatting (dates, currency, numbers, ...) with English system messages.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "cs_CZ.UTF-8";
    LC_IDENTIFICATION = "cs_CZ.UTF-8";
    LC_MEASUREMENT = "cs_CZ.UTF-8";
    LC_MONETARY = "cs_CZ.UTF-8";
    LC_NAME = "cs_CZ.UTF-8";
    LC_NUMERIC = "cs_CZ.UTF-8";
    LC_PAPER = "cs_CZ.UTF-8";
    LC_TELEPHONE = "cs_CZ.UTF-8";
    LC_TIME = "cs_CZ.UTF-8";
  };

  # Headless box: only the console keymap matters, no X11.
  console.keyMap = "cz";

  # Don't suspend when the lid is closed.
  services.logind.lidSwitch = "ignore";
  services.logind.lidSwitchExternalPower = "ignore";

  users.users.david = {
    isNormalUser = true;
    description = "David";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    kitty
  ];

  # Enable the OpenSSH daemon. This opens port 22 in the firewall automatically.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.fail2ban.enable = true;

  services.thermald.enable = true;
  services.smartd.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. Do not bump this on an existing system.
  system.stateVersion = "25.11";
}
