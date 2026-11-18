# Single-disk layout for the forge Proxmox VM.
#
# BIOS boot partition + ESP, so it boots under either SeaBIOS or OVMF.
# Plain ext4 root (no LVM): grow the disk in Proxmox and growPartition +
# autoResize in default.nix expand it on the next boot.
{ lib, ... }: {
  disko.devices.disk.main = {
    # Stable by-id path for a Proxmox virtio-scsi disk on scsi0 (see luna for
    # why /dev/sda isn't trusted). If the VM disk uses VirtIO Block instead,
    # change this to /dev/disk/by-id/virtio-<serial> or /dev/vda.
    device = lib.mkDefault "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          name = "boot";
          size = "1M";
          type = "EF02";
        };
        esp = {
          name = "ESP";
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          name = "root";
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = [ "defaults" "noatime" ];
          };
        };
      };
    };
  };
}
