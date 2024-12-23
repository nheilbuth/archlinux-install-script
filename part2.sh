sudo sbctl create-keys
sudo sbctl enroll-keys -m
sudo sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
sudo sbctl sign -s /efi/EFI/BOOT/BOOTX64.EFI
sudo sbctl sign -s /efi/EFI/Linux/arch-linux.efi
sudo sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi

sudo systemd-cryptenroll /dev/gpt-auto-root-luks --recovery-key > recovery-key.txt
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7  /dev/gpt-auto-root-luks
