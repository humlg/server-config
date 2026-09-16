{ config, lib, pkgs, ... }:

{
  imports = [
    ./zsh.nix
  ];

  environment.systemPackages = with pkgs; [
    lazygit
    btop
    powertop
    tree
    fzf
    mc
    lm_sensors
    smartmontools
    tmux
    ncdu
    iotop
    nethogs
    rsync
    claude-code
  ];
}
