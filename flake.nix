{
  description = "HomeLab NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  outputs = { self, nixpkgs, vpn-confinement, nix-minecraft, ... }: {
    nixosConfigurations.HomeLab = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        { nixpkgs.overlays = [ nix-minecraft.overlay ]; }
        ./configuration.nix
        vpn-confinement.nixosModules.default
        nix-minecraft.nixosModules.minecraft-servers
      ];
    };
  };
}
