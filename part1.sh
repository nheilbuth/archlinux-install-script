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
cd /mnt
btrfs subvolume create @
btrfs subvolume create @home
btrfs subvolume create @var
btrfs subvolume create @swap
cd ~
umount /mnt
mount -o noatime,compress=zstd,ssd,discard=async,space_cache=v2,subvol=@ /dev/mapper/linuxroot /mnt
mkdir -p /mnt/home
mkdir -p /mnt/var
mkdir -p /mnt/swap
mount -o noatime,compress=zstd,ssd,discard=async,space_cache=v2,subvol=@home /dev/mapper/linuxroot /mnt/home
mount -o noatime,compress=zstd,ssd,discard=async,space_cache=v2,subvol=@var /dev/mapper/linuxroot /mnt/var
mount -o noatime,ssd,space_cache=v2,subvol=@swap /dev/mapper/linuxroot /mnt/swap

mkdir -p /mnt/efi
mount /dev/nvme0n1p1 /mnt/efi

echo "updating pacman"
reflector --country DK --age 24 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Sy
pacman -Sy archlinux-keyring
pacstrap /mnt base base-devel linux linux-lts linux-firmware intel-ucode vim cryptsetup btrfs-progs dosfstools util-linux git sbctl networkmanager sudo
genfstab -U -p /mnt >> /mnt/etc/fstab
clear 

echo "set locales"
sed -i -e "/^#"en_DK.UTF-8"/s/^#//" /mnt/etc/locale.gen
systemd-firstboot --root /mnt --prompt
arch-chroot /mnt locale-gen

clear 
echo "set root password"
arch-chroot /mnt passwd
clear 
echo "add user"
arch-chroot /mnt useradd -G wheel -m heilbuth
echo "choose password for user heilbuth"
arch-chroot /mnt passwd heilbuth
#sed -i -e '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /mnt/etc/sudoers
echo "heilbuth ALL=(ALL:ALL) ALL" >> /mnt/etc/sudoers.d/heilbuth
clear 

echo "setting up efi/bootloader"
echo "quiet rw" >/mnt/etc/kernel/cmdline
mkdir -p /mnt/efi/EFI/Linux
vim /mnt/etc/mkinitcpio.conf #(remove: udev keymap consolefont, add: systemd sd-vconsole sd-encrypt resume, move: keyboard before autodetect)
vim /mnt/etc/mkinitcpio.d/linux-lts.preset #(comment out: 9,14, remove comment: 3,10,11,15)
systemctl --root /mnt enable systemd-resolved systemd-timesyncd NetworkManager
systemctl --root /mnt mask systemd-networkd
arch-chroot /mnt bootctl install --esp-path=/efi
arch-chroot /mnt vim /etc/kernel/cmdline # Add kernel parameters for boot device/subvolume https://eldon.me/arch-linux-laptop-setup/ 
arch-chroot /mnt mkinitcpio -p linux-lts
