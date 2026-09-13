{ config, lib, pkgs, ... }:

{
  imports = [
    ./zsh.nix
  ];
  
  environment.systemPackages = with pkgs; [
    fastfetch
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
  ];

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "agnoster";
    };
    interactiveShellInit = ''
      if command -v fastfetch >/dev/null 2>&1; then
        fastfetch
      fi
      [ -f /run/agenix/shell-env ] && source /run/agenix/shell-env
    '';

    shellAliases = {
      rebuild      = "sudo nixos-rebuild switch --flake /home/david/repos/server-config#$(hostname)";
      rebuild-test = "sudo nixos-rebuild test --flake /home/david/repos/server-config#$(hostname)";
    };
  };
}
