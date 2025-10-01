sudo systemd-cryptenroll /dev/gpt-auto-root-luks --recovery-key > recovery-key.txt
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7+11  /dev/gpt-auto-root-luks
reboot
