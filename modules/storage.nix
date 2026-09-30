{ pkgs, ... }:

{
  # Second disk: 931G ext4, label "data" — bulk storage for media,
  # downloads, and service state, kept off the ~100G root disk.
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/5c4e9589-1044-4240-8dd8-64e9a3d53d7c";
    fsType = "ext4";
  };

  # WD EX2 Ultra NAS — permanent media library (movies, TV shows).
  # Credentials in /etc/nas-credentials (deployed out-of-band):
  #   username=...
  #   password=...
  # Pre-create movies/ and tv/ on the NAS share before first rebuild.
  fileSystems."/mnt/nas" = {
    device = "//192.168.4.180/Public";
    fsType = "cifs";
    options = [
      "_netdev" "nofail"
      "x-systemd.automount"
      "x-systemd.mount-timeout=30"
      "credentials=/etc/nas-credentials"
      "gid=media"
      "dir_mode=0775"
      "file_mode=0664"
    ];
  };

  environment.systemPackages = [ pkgs.cifs-utils ];

  users.groups.media = { };

  systemd.tmpfiles.rules = [
    "d /mnt/data/media 0775 root media -"
    "d /mnt/data/media/tv 0775 root media -"
    "d /mnt/data/downloads 0775 root media -"
    "d /mnt/data/downloads/complete 0775 root media -"
    "d /mnt/data/downloads/incomplete 0775 root media -"
    "d /mnt/data/minecraft 0755 minecraft minecraft -"
    "d /mnt/data/home-assistant 0750 hass hass -"
    "d /mnt/data/home-assistant-vm 0755 qemu-libvirtd qemu-libvirtd -"
  ];
}
