sudo pacman -S docker
sudo pacman -S docker-compose
sudo usermod -aG docker heilbuth
newgrp docker
sudo systemctl enable docker

sudo pacman -S k9s
sudo pacman -S kdiff3
sudo pacman -S btop
sudo pacman -S networkmanager-openvpn
sudo pacman -S ufw
sudo systemctl enable ufw
yay -S auto-cpufreq
sudo systemctl enable auto-cpufreq
sudo pacman -S timeshift
yay -S howdy
yay -S powershell-bin
pacman -S dotnet-sdk
pacman -S aspnet-runtime
pacman -S azure-cli
