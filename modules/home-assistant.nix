{ ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu.runAsRoot = false;
  };
  users.users.david.extraGroups = [ "libvirtd" ];

  services.glances.enable = true;

  networking.firewall.allowedTCPPorts = [
    8123   # HAOS web UI
    61208  # Glances REST API
  ];

  # Forward host:8123 into the HAOS VM on the libvirt NAT network.
  # 192.168.122.71 is pinned via a static DHCP reservation on the libvirt default network.
  # Forward host:8123 into the HAOS VM. networking.nat is already enabled in vpn.nix;
  # forwardPorts wires up both the DNAT and the FORWARD ACCEPT within NixOS's managed chains.
  # 192.168.122.71 is pinned via a static DHCP reservation on the libvirt default network.
  networking.nat.forwardPorts = [
    { proto = "tcp"; sourcePort = 8123; destination = "192.168.122.71:8123"; }
  ];
}
