#!/usr/bin/env bash
set -e

tool_data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
mkdir -p $tool_data_home
mkdir -p $HOME/.local/bin

# mise
curl -fsSL https://mise.run/bash | sh

# opencode
curl -fsSL https://opencode.ai/install | bash

# codex
curl -fsSL https://chatgpt.com/codex/install.sh | sh

# atuin
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

# ble.sh
curl -L https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf -
bash ble-nightly/ble.sh --install "$tool_data_home"

# chezmoi
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"

# bitwarden
mkdir -p ~/.local/bin
curl -L "https://vault.bitwarden.com/download/?app=cli&platform=linux" -o /tmp/bw.zip
unzip /tmp/bw.zip -d /tmp/bw
install -m 0755 /tmp/bw/bw ~/.local/bin/bw
rm -rf /tmp/bw /tmp/bw.zip

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

# ----------- SUDO NEEDED -------------
#
# tailscale
curl -fsSL https://tailscale.com/install.sh | sh

