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
}
