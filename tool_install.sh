#!/usr/bin/env bash
set -e

tool_data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
mkdir -p $tool_data_home
mkdir -p $HOME/.local/bin

# mise
curl -fsSL https://mise.jdx.dev/install.sh | MISE_INSTALL_HELP=0 sh

# ble.sh
# curl -L https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf -
# bash ble-nightly/ble.sh --install "$tool_data_home"

# flyline
curl -sSfL https://github.com/HalFrgrd/flyline/releases/latest/download/install.sh | bash

# fresh
curl -fsSL https://raw.githubusercontent.com/sinelaw/fresh/refs/heads/master/scripts/install.sh | sh

# ----------------FOR PC-------------------

# kitty
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
mkdir -p ~/.local/bin
ln -sf ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty
ln -sf ~/.local/kitty.app/bin/kitten ~/.local/bin/kitten
mkdir -p "$tool_data_home/applications"
cp ~/.local/kitty.app/share/applications/kitty.desktop "$tool_data_home/applications/"
cp ~/.local/kitty.app/share/applications/kitty-open.desktop "$tool_data_home/applications/"
sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" "$tool_data_home"/applications/kitty*.desktop
sed -i "s|Exec=kitty|Exec=$HOME/.local/kitty.app/bin/kitty|g" "$tool_data_home"/applications/kitty*.desktop
update-desktop-database "$tool_data_home/applications" 2>/dev/null || true

# brave origin
curl -fsS https://dl.brave.com/install.sh | FLAVOR=origin sh

# nautilus extension
git clone https://github.com/chr314/nautilus-copy-path.git
cd nautilus-copy-path
make install

# zotero
case "$(uname -m)" in
    x86_64|amd64) zotero_platform="linux-x86_64" ;;
    aarch64|arm64) zotero_platform="linux-arm64" ;;
    i386|i486|i586|i686) zotero_platform="linux-i686" ;;
    *) exit 1 ;;
esac
zotero_tmp_dir="$(mktemp -d)"
trap 'rm -rf "$zotero_tmp_dir"' EXIT
curl -fL "https://www.zotero.org/download/client/dl?channel=release&platform=$zotero_platform" | tar -x -J -C "$zotero_tmp_dir"
rm -rf "$tool_data_home/zotero"
mv "$zotero_tmp_dir"/Zotero_linux-* "$tool_data_home/zotero"
(cd "$tool_data_home/zotero" && ./set_launcher_icon)
ln -sfn "$tool_data_home/zotero/zotero" "$HOME/.local/bin/zotero"
ln -sfn "$tool_data_home/zotero/zotero.desktop" "$tool_data_home/applications/zotero.desktop"
sed -i "s|^Exec=.*|Exec=$tool_data_home/zotero/zotero -url %U|" "$tool_data_home/applications/zotero.desktop"

# thunderbird
curl -L 'https://download.mozilla.org/?product=thunderbird-latest-SSL&os=linux64&lang=ko' -o /tmp/thunderbird.tar.xz
rm -rf "$tool_data_home/thunderbird"
tar -xJf /tmp/thunderbird.tar.xz -C $tool_data_home
ln -sf "$tool_data_home/thunderbird/thunderbird" "$HOME/.local/bin/thunderbird"
cat > "$HOME/.local/share/applications/thunderbird.desktop" <<EOF
[Desktop Entry]
Name=Thunderbird
Comment=Email, Calendar and Contacts
Exec=$tool_data_home/thunderbird/thunderbird %u
Icon=$tool_data_home/thunderbird/chrome/icons/default/default256.png
Terminal=false
Type=Application
Categories=Network;Email;
MimeType=message/rfc822;x-scheme-handler/mailto;text/calendar;text/vcard;text/x-vcard;
StartupNotify=true
StartupWMClass=thunderbird
EOF

# texlive
texlive_dir="$tool_data_home/texlive/2026"
texlive_tmp_dir="$(mktemp -d)"
curl -L https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz | tar -xzf - -C "$texlive_tmp_dir" --strip-components=1
perl "$texlive_tmp_dir/install-tl" --no-interaction --texdir="$texlive_dir" --no-doc-install --no-src-install
rm -rf "$texlive_tmp_dir"

# zed
curl -f https://zed.dev/install.sh | ZED_CHANNEL=preview sh

# dropbox
cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf - && ./.dropbox-dist/dropboxd

# Audio Player
flatpak install -y flathub org.gnome.Decibels

# slack
flatpak install -y flathub com.slack.Slack

# spotify
flatpak install -y flathub com.spotify.Client

# bottles
flatpak install -y flathub com.usebottles.bottles

# zoom
flatpak install -y flathub us.zoom.Zoom

# onlyoffice
flatpak install -y flathub org.onlyoffice.desktopeditors

# discord
flatpak install -y flathub com.discordapp.Discord

# blanket
flatpak install -y flathub com.rafaelmardojai.Blanket

# remmina
flatpak install -y flathub org.remmina.Remmina

# ----------- SUDO NEEDED -------------

# tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# hwp
curl -H "Host: cdn.hancom.com" -H "Referer: https://www.hancom.com/cs_center" -fLO https://cdn.hancom.com/pds/hnc/DOWN/gooroom/hoffice_hwp_2020_amd64.deb
sudo apt install ./hoffice_hwp_2020_amd64.deb

# kakaotalk-waydroid
sudo modprobe binder_linux
sudo mkdir -p /dev/binderfs
sudo mount -t binder binder /dev/binderfs
echo "binder_linux" | sudo tee /etc/modules-load.d/waydroid.conf
sudo waydroid init -s GAPPS
sudo systemctl enable --now waydroid-container
waydroid session start
# on a different terminal
waydroid show-full-ui # and then open play store inside the GUI.
# on a different terminal
sudo waydroid shell
sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select * from main where name = \"android_id\";" # and register the number to https://www.google.com/android/uncertified .
# inside the GUI clear google play services and store app's storage and cache.
waydroid session stop
waydroid session start
waydroid show-full-ui # and then log into play store inside the GUI.
git clone https://github.com/casualsnek/waydroid_script.git && cd waydroid_script
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
sudo venv/bin/python3 main.py # select Android 13 -> Install -> libhoudini
waydroid session stop
sudo systemctl restart waydroid-container
# after some seconds of sleep..
waydroid session start
waydroid show-full-ui # and then install KakaoTalk and Gboard.
# https://saturn.tistory.com/entry/%EB%A6%AC%EB%88%85%EC%8A%A4%EC%97%90%EC%84%9C-%EC%B9%B4%EC%B9%B4%EC%98%A4%ED%86%A1-%EC%93%B0%EA%B8%B0-Wine-%EB%A7%90%EA%B3%A0-Waydroid%EB%A1%9C-UbuntuKubuntu-2510
