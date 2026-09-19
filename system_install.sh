sudo apt install -y git git-crypt curl build-essential
sudo apt install -y unzip
sudo apt install -y ttf-mscorefonts-installer
sudo apt install -y fonts-noto-cjk
sudo apt install -y inkscape

# ------------- FOR PC ----------------

sudo add-apt-repository ppa:avengemedia/danklinux
sudo add-apt-repository ppa:avengemedia/dms
sudo apt update
sudo apt install -y gnome-tweaks
sudo apt install -y nautilus-dropbox
sudo apt install -y niri dms
sudo apt install -y fcitx5 fcitx5-hangul fcitx5-config-qt fcitx5-frontend-all
sudo apt install -y wl-clipboard
sudo apt install -y showtime
sudo apt install -y flatpak && flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo apt install -y gnome-software-plugin-flatpak
