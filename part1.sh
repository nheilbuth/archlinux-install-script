loadkeys dk

fdisk /dev/nvme0n1
clear

echo "setup encryption"
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
clear

echo "unencrypt drive"
cryptsetup luksOpen /dev/nvme0n1p2 linuxroot
clear

echo "formatting"
mkfs.vfat -F32 -n EFI /dev/nvme0n1p1
mkfs.btrfs -f -L linuxroot /dev/mapper/linuxroot

echo "mounting"
mount /dev/mapper/linuxroot /mnt
mkdir /mnt/efi
mount /dev/nvme0n1p1 /mnt/efi
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/srv
btrfs subvolume create /mnt/var
btrfs subvolume create /mnt/var/log
btrfs subvolume create /mnt/var/cache
btrfs subvolume create /mnt/var/tmp
btrfs subvolume create /mnt/swap

echo "updating pacman"
reflector --country DK --age 24 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Sy
pacstrap -K /mnt base base-devel linux linux-firmware intel-ucode vim cryptsetup btrfs-progs dosfstools util-linux git sbctl networkmanager sudo iwd
clear 

echo "set locales"
sed -i -e "/^#"en_DK.UTF-8"/s/^#//" /mnt/etc/locale.gen
systemd-firstboot --root /mnt --prompt
arch-chroot /mnt locale-gen

echo "add user"
arch-chroot /mnt useradd -G wheel -m heilbuth
echo "choose password for user"
arch-chroot /mnt passwd heilbuth
sed -i -e '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /mnt/etc/sudoers
clear 
echo "set root password"
arch-chroot /mnt passwd
clear 

echo "setting up efi"
echo "quiet rw" >/mnt/etc/kernel/cmdline
mkdir -p /mnt/efi/EFI/Linux
vim /mnt/etc/mkinitcpio.conf #(remove: udev keymap consolefont, add: systemd sd-vconsole sd-encrypt resume, move: keyboard before autodetect)
vim /mnt/etc/mkinitcpio.d/linux.preset #(comment out: 9,14, remove comment: 3,10,11,15)
arch-chroot /mnt mkinitcpio -P
clear 

echo "setting up services"
systemctl --root /mnt enable systemd-resolved systemd-timesyncd NetworkManager
systemctl --root /mnt mask systemd-networkd
arch-chroot /mnt bootctl install --esp-path=/efi
sync
reboot
