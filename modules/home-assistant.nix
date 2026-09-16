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
  # The libvirt default network has firewall backend='none', so NixOS owns all forwarding
  # rules for virbr0. internalInterfaces adds MASQUERADE + virbr0->enp59s0 FORWARD ACCEPT
  # (VM internet access). forwardPorts adds DNAT + enp59s0->virbr0 FORWARD ACCEPT for
  # inbound connections. 192.168.122.71 is pinned via a static DHCP reservation.
  networking.nat.internalInterfaces = [ "virbr0" ];
  networking.nat.forwardPorts = [
    { proto = "tcp"; sourcePort = 8123; destination = "192.168.122.71:8123"; }
  ];
}
