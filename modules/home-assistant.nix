{ pkgs, ... }:

let
  # Bridge network: libvirt just references the OS-managed br0; no IP/DHCP/NAT.
  bridgeNetworkXml = pkgs.writeText "haos-bridge-network.xml" ''
    <network>
      <name>host-bridge</name>
      <forward mode='bridge'/>
      <bridge name='br0'/>
    </network>
  '';
in
{
  virtualisation.libvirtd = {
    enable = true;
    qemu.runAsRoot = false;
  };
  users.users.david.extraGroups = [ "libvirtd" ];

  services.glances.enable = true;

  networking.firewall.allowedTCPPorts = [
    61208  # Glances REST API
  ];

  # Manages the libvirt bridge network and HAOS VM on every boot.
  systemd.services.haos-vm = {
    description = "Home Assistant OS VM";
    after = [ "libvirtd.service" "network-online.target" ];
    requires = [ "libvirtd.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.libvirt ];
    script = ''
      uri="qemu:///system"

      virsh -c "$uri" net-define ${bridgeNetworkXml}
      virsh -c "$uri" net-autostart host-bridge 2>/dev/null || true
      virsh -c "$uri" autostart homeassistant --disable 2>/dev/null || true

      if ! virsh -c "$uri" net-info host-bridge 2>/dev/null | grep -q "Active:.*yes"; then
        virsh -c "$uri" net-start host-bridge
      fi

      # Migrate VM off the old NAT 'default' network if it hasn't been already.
      if virsh -c "$uri" dumpxml homeassistant --inactive 2>/dev/null | grep -q "source network='default'"; then
        vm_state=$(virsh -c "$uri" domstate homeassistant 2>/dev/null || echo "absent")
        if ! echo "$vm_state" | grep -qE "shut off|absent"; then
          virsh -c "$uri" shutdown homeassistant 2>/dev/null || true
          for i in $(seq 30); do
            virsh -c "$uri" domstate homeassistant 2>/dev/null | grep -q "shut off" && break
            sleep 2
          done
          virsh -c "$uri" destroy homeassistant 2>/dev/null || true
        fi
        virsh -c "$uri" detach-interface homeassistant network --config 2>/dev/null || true
        virsh -c "$uri" attach-interface homeassistant \
          --type network --source host-bridge \
          --mac 52:54:00:4f:8e:56 --model virtio --config
      fi

      virsh -c "$uri" start homeassistant 2>/dev/null || true
    '';
  };
}
