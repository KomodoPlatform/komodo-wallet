mkdir -p "$HOME/bin"
cat > "$HOME/bin/open-pr-if-frontmost" <<'ZSH'
#!/bin/zsh
url="$1"
if [ -z "$url" ]; then
  echo "Usage: open-pr-if-frontmost <url>" >&2
  exit 1
fi

front_app=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true')

case "$front_app" in
  "Cursor"|"Visual Studio Code"|"IntelliJ IDEA"|"Android Studio")
    open "$url"
    ;;
  *)
    echo "Not opening PR because frontmost app is '$front_app'"
    ;;
esac
ZSH
chmod +x "$HOME/bin/open-pr-if-frontmost"
grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.zshrc" || echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
source "$HOME/.zshrc"