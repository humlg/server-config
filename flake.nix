{
  description = "HomeLab NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # Pinned to the last nixpkgs-unstable commit before jellyfin was bumped to 12.0,
    # so we can pull jellyfin 10.11.11 via an overlay.
    nixpkgs-jellyfin.url = "github:NixOS/nixpkgs/42312a0b94ed53886ba86959ea099d9f6cdf2355";
    nixpkgs-jellyfin.flake = false;
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  outputs = { self, nixpkgs, nixpkgs-jellyfin, vpn-confinement, nix-minecraft, ... }: {
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
      ];
    };
  };
}
