#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FISH_DIR="$ROOT_DIR/fish/.config/fish"
CONFIG_FILE="$FISH_DIR/config.fish"
STARTUP_FILES=("$CONFIG_FILE" "$FISH_DIR"/conf.d/*.fish)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

if grep -Eq '(^|[[:space:]])(curl|wget)([[:space:]]|$)|fisher[[:space:]]+install' \
    "${STARTUP_FILES[@]}"; then
    fail 'Fish startup contains a network or install operation'
fi

if grep -Eq '^[[:space:]]*clear([[:space:]]|$)' "${STARTUP_FILES[@]}"; then
    fail 'Fish startup clears existing terminal output'
fi

for integration in \
    'starship[[:space:]]+init[[:space:]]+fish' \
    'zoxide[[:space:]]+init[[:space:]]+fish' \
    'atuin[[:space:]]+init[[:space:]]+fish' \
    'fzf[[:space:]]+--fish' \
    'carapace[[:space:]]+_carapace[[:space:]]+fish' \
    'mise[[:space:]]+activate[[:space:]]+fish'; do
    match_count=0
    for startup_file in "${STARTUP_FILES[@]}"; do
        file_matches=$(grep -Ec "$integration" "$startup_file" || true)
        match_count=$((match_count + file_matches))
    done
    if [ "$match_count" -ne 1 ]; then
        fail "integration '$integration' must be initialized exactly once"
    fi
done

if grep -Eq '(^|[[:space:]])(mkdir|touch|xargs)([[:space:]]|$)' "$CONFIG_FILE"; then
    fail 'Fish startup creates completion or marker files'
fi

if grep -Eq 'set[[:space:]]+-[^[:space:]]*U' \
    "${STARTUP_FILES[@]}"; then
    fail 'Fish startup writes universal variables'
fi

if command -v fish >/dev/null 2>&1; then
    fish --no-config -n "$CONFIG_FILE" "$FISH_DIR"/conf.d/*.fish || \
        fail 'Fish startup files contain invalid syntax'

    mkdir -p "$TMP_DIR/config"
    cp -R "$FISH_DIR" "$TMP_DIR/config/fish"
    rm -rf "$TMP_DIR/config/fish/completions"
    rm -f "$TMP_DIR/config/fish/fish_variables"
    cp -R "$TMP_DIR/config/fish" "$TMP_DIR/before"

    HOME="$TMP_DIR/home" \
    XDG_CONFIG_HOME="$TMP_DIR/config" \
    TMUX=1 \
    TERM=xterm \
        fish -i -c exit >/dev/null 2>&1 || fail 'interactive Fish startup failed'

    HOME="$TMP_DIR/home" \
    XDG_CONFIG_HOME="$TMP_DIR/config" \
    TMUX=1 \
    TERM=xterm \
        fish -i -c 'contains -- visual (bind --list-modes)' >/dev/null 2>&1 || \
        fail 'interactive Fish startup does not enable vi key bindings'

    diff -ru "$TMP_DIR/before" "$TMP_DIR/config/fish" >/dev/null || \
        fail 'interactive Fish startup changed its configuration directory'

    mkdir -p "$TMP_DIR/bin"
    cat >"$TMP_DIR/bin/mise" <<'EOF'
#!/usr/bin/env sh
if [ "$1" = activate ] && [ "$2" = fish ]; then
    printf 'set -gx MISE_NONINTERACTIVE_ACTIVE 1\n'
fi
EOF
    chmod +x "$TMP_DIR/bin/mise"

    HOME="$TMP_DIR/home" \
    XDG_CONFIG_HOME="$TMP_DIR/config" \
    TERMUX_VERSION=1 \
    PREFIX="$TMP_DIR" \
        fish -c 'test "$MISE_NONINTERACTIVE_ACTIVE" = 1' || \
        fail 'Mise is not activated for noninteractive Fish'
fi

printf 'PASS: Fish startup is deterministic and side-effect free\n'
