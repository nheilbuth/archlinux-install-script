loadkeys dk

fdisk /dev/nvme0n1p2

cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
cryptsetup luksOpen /dev/nvme0n1p2 linuxroot

mkfs.vfat -F32 -n EFI /dev/nvme0n1p1
mkfs.btrfs -f -L linuxroot /dev/mapper/linuxroot

mount /dev/mapper/linuxroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@swap
umount /mnt
mount -o noatime,compress=zstd,ssd,discard=async,space_cache=v2,subvol=@ /dev/mapper/linuxroot /mnt
mkdir -p /mnt/home
mkdir -p /mnt/var
mkdir -p /mnt/swap
mount -o noatime,compress=zstd,ssd,discard=async,space_cache=v2,subvol=@home /dev/mapper/linuxroot /mnt/home
mount -o noatime,compress=zstd,ssd,discard=async,space_cache=v2,subvol=@var /dev/mapper/linuxroot /mnt/var
mount -o noatime,ssd,space_cache=v2,subvol=@swap /dev/mapper/linuxroot /mnt/swap

mkdir -p /mnt/efi
mount -o /dev/nvme0n1p1 /mnt/efi

iwctl
reflector --country DK --age 24 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Sy
pacstrap -K /mnt base base-devel linux linux-firmware intel-ucode vim cryptsetup btrfs-progs dosfstools util-linux git sbctl networkmanager sudo iwd

sed -i -e "/^#"en_DK.UTF-8"/s/^#//" /mnt/etc/locale.gen
systemd-firstboot --root /mnt --prompt
arch-chroot /mnt locale-gen

arch-chroot /mnt useradd -G wheel -m heilbuth
arch-chroot /mnt passwd heilbuth
sed -i -e '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /mnt/etc/sudoers
arch-chroot /mnt passwd

echo "quiet rw" >/mnt/etc/kernel/cmdline
mkdir -p /mnt/efi/EFI/Linux
vim /mnt/etc/mkinitcpio.conf #(remove: udev keymap consolefont, add: systemd sd-vconsole sd-encrypt resume, move: keyboard before autodetect)
vim /mnt/etc/mkinitcpio.d/linux.preset #(comment out: 9,14, remove comment: 3,10,11,15)
arch-chroot /mnt mkinitcpio -P

systemctl --root /mnt enable systemd-resolved systemd-timesyncd NetworkManager
systemctl --root /mnt mask systemd-networkd
arch-chroot /mnt bootctl install --esp-path=/efi
sync
reboot