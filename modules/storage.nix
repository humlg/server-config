{ ... }:

{
  # Second disk: 931G ext4, label "data" — bulk storage for media,
  # downloads, and service state, kept off the ~100G root disk.
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/5c4e9589-1044-4240-8dd8-64e9a3d53d7c";
    fsType = "ext4";
  };

  users.groups.media = { };

  systemd.tmpfiles.rules = [
    "d /mnt/data/media 0775 root media -"
    "d /mnt/data/media/tv 0775 root media -"
    "d /mnt/data/downloads 0775 root media -"
    "d /mnt/data/downloads/complete 0775 root media -"
    "d /mnt/data/downloads/incomplete 0775 root media -"
    "d /mnt/data/minecraft 0755 minecraft minecraft -"
    "d /mnt/data/home-assistant 0750 hass hass -"
  ];
}
