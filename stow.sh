#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: %s {stow|restow|unstow|adopt} PACKAGE...\n' "$0" >&2
    exit 2
}

[ "$#" -ge 2 ] || usage

mode=$1
shift
packages=("$@")
stow_dir=$(cd "${STOW_DIR:-$PWD}" && pwd)
target=$(cd "${STOW_TARGET:-$HOME}" && pwd)

case "$mode" in
    stow)
        operation=()
        ;;
    restow)
        operation=(-R)
        ;;
    unstow)
        operation=(-D)
        ;;
    adopt)
        operation=(--adopt -R)
        ;;
    *)
        usage
        ;;
esac

stow_command() {
    stow "$@" --dir="$stow_dir" --target="$target" "${packages[@]}"
}

prepare_claude_state_directory() {
    local package claude_target link_target linked_directory package_directory
    local settings_target linked_settings linked_parent expected_settings
    local git_root package_relative migration_list path relative_path
    local source_path destination_path source_parent
    local migration_paths

    migration_paths=()

    for package in "${packages[@]}"; do
        [ "$package" = claude ] || continue

        claude_target="$target/.claude"
        package_directory="$stow_dir/claude/.claude"

        if [ -L "$claude_target" ]; then
            link_target=$(readlink "$claude_target")
            case "$link_target" in
                /*) linked_directory=$link_target ;;
                *) linked_directory="$target/$link_target" ;;
            esac

            if [ -d "$linked_directory" ] && \
                [ "$(cd "$linked_directory" && pwd -P)" = "$(cd "$package_directory" && pwd -P)" ]; then
                if ! git_root=$(git -C "$stow_dir" rev-parse --show-toplevel 2>/dev/null); then
                    printf 'Cannot migrate folded Claude state without a Git worktree.\n' >&2
                    return 1
                fi
                if [ "$(cd "$git_root" && pwd -P)" != "$(cd "$stow_dir" && pwd -P)" ]; then
                    printf 'Cannot safely classify folded Claude state outside the Git root.\n' >&2
                    return 1
                fi

                package_relative=claude/.claude
                migration_list=$(mktemp "${TMPDIR:-/tmp}/dotfiles-claude-state.XXXXXX")
                if ! git -C "$stow_dir" ls-files -z --others --exclude-standard \
                    -- "$package_relative" > "$migration_list"; then
                    rm -f "$migration_list"
                    printf 'Cannot classify untracked Claude state.\n' >&2
                    return 1
                fi
                if ! git -C "$stow_dir" ls-files -z --others --ignored \
                    --exclude-standard -- "$package_relative" >> "$migration_list"; then
                    rm -f "$migration_list"
                    printf 'Cannot classify ignored Claude state.\n' >&2
                    return 1
                fi

                while IFS= read -r -d '' path; do
                    case "$path" in
                        "$package_relative"/*) ;;
                        *)
                            rm -f "$migration_list"
                            printf 'Unsafe Claude state path reported by Git: %s\n' "$path" >&2
                            return 1
                            ;;
                    esac
                    source_path="$stow_dir/$path"
                    if { [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; } || \
                        { [ -d "$source_path" ] && [ ! -L "$source_path" ]; }; then
                        rm -f "$migration_list"
                        printf 'Cannot safely migrate Claude state path: %s\n' "$path" >&2
                        return 1
                    fi
                    migration_paths+=("$path")
                done < "$migration_list"
                rm -f "$migration_list"

                rm "$claude_target"
                mkdir "$claude_target"

                for path in "${migration_paths[@]}"; do
                    relative_path=${path#"$package_relative"/}
                    source_path="$stow_dir/$path"
                    destination_path="$claude_target/$relative_path"
                    mkdir -p "$(dirname "$destination_path")"
                    mv "$source_path" "$destination_path"

                    source_parent=$(dirname "$source_path")
                    while [ "$source_parent" != "$package_directory" ]; do
                        rmdir "$source_parent" 2>/dev/null || break
                        source_parent=$(dirname "$source_parent")
                    done
                done
            fi
        elif [ ! -e "$claude_target" ] && [ "$mode" != unstow ]; then
            mkdir "$claude_target"
        fi

        if [ -d "$claude_target" ] && [ ! -L "$claude_target" ]; then
            settings_target="$claude_target/settings.json"
            if [ -L "$settings_target" ] && [ ! -e "$settings_target" ]; then
                link_target=$(readlink "$settings_target")
                case "$link_target" in
                    /*) linked_settings=$link_target ;;
                    *) linked_settings="$claude_target/$link_target" ;;
                esac
                linked_parent=$(dirname "$linked_settings")

                if [ -d "$linked_parent" ]; then
                    linked_settings="$(cd "$linked_parent" && pwd -P)/$(basename "$linked_settings")"
                    expected_settings="$(cd "$package_directory" && pwd -P)/settings.json"
                    if [ "$linked_settings" = "$expected_settings" ]; then
                        rm "$settings_target"
                        if [ "$mode" != unstow ]; then
                            cp "$package_directory/settings.example.json" "$settings_target"
                        fi
                    fi
                fi
            fi
        fi

        return
    done
}

if [ "$mode" != adopt ]; then
    printf 'Preflighting %s for all packages...\n' "$mode"
    if ! stow_command --simulate ${operation[@]+"${operation[@]}"}; then
        printf 'Preflight failed; no changes were made.\n' >&2
        exit 1
    fi
    if [ "${STOW_PREFLIGHT_ONLY:-0}" = 1 ]; then
        printf 'Preflight passed; no changes were made.\n'
        exit
    fi

    prepare_claude_state_directory

    printf 'Applying %s for all packages...\n' "$mode"
    stow_command ${operation[@]+"${operation[@]}"}
    exit
fi

backup=${STOW_ADOPT_BACKUP:-}
if [ -z "$backup" ]; then
    printf 'Adoption requires STOW_ADOPT_BACKUP with a new backup archive path.\n' >&2
    exit 2
fi
case "$backup" in
    /*) ;;
    *)
        printf 'STOW_ADOPT_BACKUP must be an absolute path.\n' >&2
        exit 2
        ;;
esac

backup_parent=$(dirname "$backup")
if [ ! -d "$backup_parent" ]; then
    printf 'Backup directory does not exist: %s\n' "$backup_parent" >&2
    exit 2
fi
backup_parent=$(cd "$backup_parent" && pwd)
backup="$backup_parent/$(basename "$backup")"
if [ -e "$backup" ] || [ -L "$backup" ]; then
    printf 'Backup path already exists: %s\n' "$backup" >&2
    exit 2
fi
case "$backup" in
    "$stow_dir"|"$stow_dir"/*)
        printf 'Backup path must be outside the dotfiles repository.\n' >&2
        exit 2
        ;;
esac

case "$backup" in
    "$target"/*)
        relative_backup=${backup#"$target"/}
        top_level=${relative_backup%%/*}
        for pkg in "${packages[@]}"; do
            if [ -e "$stow_dir/$pkg/$top_level" ] || [ -L "$stow_dir/$pkg/$top_level" ]; then
                printf 'Backup path is inside a route managed by package %s.\n' "$pkg" >&2
                exit 2
            fi
        done
        ;;
esac

if ! git -C "$stow_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'Adoption requires a Git worktree so repository changes can be recovered.\n' >&2
    exit 2
fi
if [ -n "$(git -C "$stow_dir" status --porcelain --untracked-files=all -- "${packages[@]}")" ]; then
    printf 'Adoption requires clean package paths; commit or stash their changes first.\n' >&2
    exit 1
fi

preview=$(mktemp "${TMPDIR:-/tmp}/dotfiles-adopt.XXXXXX")
trap 'rm -f "$preview"' EXIT
printf 'Adoption preview for all packages:\n'
if ! stow_command --simulate --verbose=2 ${operation[@]+"${operation[@]}"} 2>&1 | tee "$preview"; then
    printf 'Adoption preflight failed; no changes were made.\n' >&2
    exit 1
fi

adopted_paths=()
while IFS= read -r line; do
    line=${line#"${line%%[![:space:]]*}"}
    case "$line" in
        'MV: '*-'>'*)
            path=${line#MV: }
            path=${path%% -> *}
            adopted_paths+=("$path")
            ;;
    esac
done < "$preview"

answer=${STOW_ADOPT_CONFIRM:-}
if [ -z "$answer" ] && [ -t 0 ]; then
    printf 'Inspect the preview above. Type "adopt" to create the backup and continue: '
    IFS= read -r answer
fi
if [ "$answer" != adopt ]; then
    printf 'Adoption cancelled; no changes were made.\n' >&2
    exit 1
fi

if [ "${#adopted_paths[@]}" -gt 0 ]; then
    tar -czf "$backup" -C "$target" -- "${adopted_paths[@]}"
else
    tar -czf "$backup" -C "$target" --files-from /dev/null
fi
printf 'Recovery backup created at %s\n' "$backup"

prepare_claude_state_directory
if ! stow_command ${operation[@]+"${operation[@]}"}; then
    printf 'Adoption failed. The recovery backup remains at %s\n' "$backup" >&2
    exit 1
fi

printf 'Adoption complete. Inspect repository changes with:\n'
printf '  git -C %q diff --' "$stow_dir"
printf ' %q' "${packages[@]}"
printf '\nTo restore the previously clean package paths, use:\n'
printf '  git -C %q restore --worktree --' "$stow_dir"
printf ' %q' "${packages[@]}"
printf '\n'
