cat <<'EOF' >> ~/.bashrc

bash_config_file="${XDG_CONFIG_HOME:-$HOME/.config}/bash/config"
if [[ -r $bash_config_file ]]; then
  source -- "$bash_config_file"
fi
unset bash_config_file
EOF

mkdir -p ~/.ssh
cat <<'EOF' >> ~/.ssh/config

Include ${XDG_CONFIG_HOME}/ssh/config
EOF
chmod 600 ~/.ssh/config

# inside dotconfig
key_path="${XDG_DATA_HOME:-$HOME/.local/share}/git-crypt/dotconfig.key"
install -d -m 700 "$(dirname "$key_path")"
(
  umask 077
  set -o pipefail
  bw get notes "dotconfig git-crypt key" |
    base64 --decode > "$key_path"
) && git-crypt unlock "$key_path"
rm "$key_path"
