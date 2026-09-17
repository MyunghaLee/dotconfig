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
