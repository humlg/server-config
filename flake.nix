{
  description = "HomeLab NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # nixos-25.11 lags behind on jellyfin; track unstable for it instead.
    nixpkgs-jellyfin.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-jellyfin.flake = false;
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    hermes-agent.url = "github:NousResearch/hermes-agent";
  };

  outputs = { self, nixpkgs, nixpkgs-jellyfin, vpn-confinement, nix-minecraft, hermes-agent, ... }: {
    nixosConfigurations.HomeLab = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [
            nix-minecraft.overlay
            (final: prev: let
              pkgs-jellyfin = import nixpkgs-jellyfin { system = "x86_64-linux"; };
            in {
              inherit (pkgs-jellyfin) jellyfin jellyfin-web jellyfin-ffmpeg;
            })
          ];
        }
        ./configuration.nix
        vpn-confinement.nixosModules.default
        nix-minecraft.nixosModules.minecraft-servers
        hermes-agent.nixosModules.default
      ];
    };
  };
}
