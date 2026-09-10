#!/bin/bash
set -euo pipefail

SOURCE=$(cd -- "$(dirname -- "$0")/.." && pwd)/gentriesquick
TMP=$(mktemp -d "${TMPDIR:-/tmp}/xlunch-entries.XXXXXX")
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home with spaces"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_DATA_DIRS="$TMP/local:$TMP/system"
USER_APPS="$XDG_DATA_HOME/applications"
SYSTEM_APPS="$TMP/system/applications"
mkdir -p "$USER_APPS" "$SYSTEM_APPS" "$TMP/local/applications" "$TMP/icons/apps/64"
: >"$TMP/icons/apps/64/test-icon.png"
# Isolate icon lookup; run the real generator against temporary XDG dirs.
sed "s|^ICONPATHS=.*|ICONPATHS=\"$TMP/icons\"|" "$SOURCE" >"$TMP/generator"

entry() {
    local file=$1 name=$2 command=$3
    shift 3
    printf '[Desktop Entry]\nType=Application\nName=%s\nIcon=test-icon\nExec=%s\n' \
        "$name" "$command" >"$file"
    if [ "$#" -gt 0 ]; then printf '%s\n' "$@" >>"$file"; fi
}

generate() { bash "$TMP/generator" 64 --desktop >"$TMP/menu"; }
contains() { grep -Fq -- "$1" "$TMP/menu"; }
absent() { ! contains "$1" || { cat "$TMP/menu"; echo "Unexpected entry: $1" >&2; exit 1; }; }
pass() { printf 'PASS: %s\n' "$1"; }

entry "$USER_APPS/minios-help-flux.desktop" 'Flux Help' 'fbliveapp minios-help'
entry "$USER_APPS/minios-kernel-manager-flux.desktop" 'Flux Kernel' 'fbliveapp minios-kernel-manager'
entry "$USER_APPS/minios-module-manager-flux.desktop" 'Flux Modules' 'fbliveapp minios-module-manager %f'
entry "$USER_APPS/minios-store-flux.desktop" 'Flux Store' 'fbliveapp minios-store'
generate
[ "$(wc -l <"$TMP/menu")" -eq 4 ]
pass 'install-on-demand launchers work before packages exist'

# Distinct desktop IDs remain distinct; installation cleanup belongs to Flux Tools.
entry "$SYSTEM_APPS/dev.minios.Help.desktop" 'Native Help' '/usr/bin/minios-help'
entry "$SYSTEM_APPS/minios-kernel-manager.desktop" 'Native Kernel' 'minios-kernel-manager'
entry "$SYSTEM_APPS/minios-module-manager.desktop" 'Native Modules' 'minios-module-manager %f'
entry "$SYSTEM_APPS/minios-store.desktop" 'Native Store' 'minios-store-launcher'
generate
contains 'Native Help;'
[ "$(wc -l <"$TMP/menu")" -eq 8 ]
pass 'distinct desktop IDs are not suppressed by application-specific rules'

entry "$SYSTEM_APPS/minios-store-uri-handler.desktop" 'URI Handler' \
    '/usr/lib/minios-store/minios-store-uri-handler %u' 'NoDisplay=true'
entry "$SYSTEM_APPS/unrelated.desktop" 'New Application' 'unrelated'
generate
absent 'URI Handler'
contains 'New Application;'
test -f "$SYSTEM_APPS/minios-store-uri-handler.desktop"
pass 'NoDisplay handlers remain on disk; unrelated installed apps are listed'

# Do not deduplicate independent actions just because they use the same binary.
entry "$SYSTEM_APPS/help-special.desktop" 'Help Special' 'minios-help --special'
entry "$SYSTEM_APPS/help-special-file.desktop" 'Help File Action' 'minios-help %f --special'
entry "$USER_APPS/my-help.desktop" 'Personal Help' 'minios-help'
generate
contains 'Help Special;'
contains 'Help File Action;'
contains 'Personal Help;'
pass 'additional actions and personal launchers are preserved'

entry "$SYSTEM_APPS/hidden.desktop" 'Hidden System' 'hidden'
printf '[Desktop Entry]\nHidden=true\n' >"$USER_APPS/hidden.desktop"
entry "$TMP/local/applications/unrelated.desktop" 'Local Override' 'unrelated'
generate
absent 'Hidden System;'
absent 'New Application;'
contains 'Local Override;'
pass 'user masks and XDG system-directory precedence are respected'

printf 'Hidden=true\n' >>"$USER_APPS/minios-module-manager-flux.desktop"
generate
absent 'Flux Modules;'
contains 'Native Modules;'
pass 'Hidden applies only to the matching desktop ID'

entry "$SYSTEM_APPS/aaa.desktop" 'Native Root Alias' 'root-app'
entry "$SYSTEM_APPS/root-app-flux.desktop" 'Root Flux' 'fbliveapp root-app'
generate
contains 'Native Root Alias;'
contains 'Root Flux;'
pass 'system entries with different IDs remain independently visible'

entry "$SYSTEM_APPS/action-group.desktop" 'Main Entry' 'main-app' \
    '[Desktop Action Hidden]' 'Name=Action Title' 'Exec=other-app' 'NoDisplay=true'
entry "$SYSTEM_APPS/hidden-action-group.desktop" 'Hidden Main' 'main-app' \
    'NoDisplay=true' '[Desktop Action Visible]' 'NoDisplay=false'
generate
contains 'Main Entry;'
absent 'Action Title;'
absent 'Hidden Main;'
pass 'only the Desktop Entry group controls visibility and launch fields'

entry "$SYSTEM_APPS/quoted.desktop" "Reader's Guide" 'reader'
entry "$SYSTEM_APPS/percent.desktop" '100% Utility' 'percent-app'
printf '[Desktop Entry]\r\nName=CRLF Handler\r\nIcon=test-icon\r\nExec=handler\r\nNoDisplay = true' \
    >"$SYSTEM_APPS/crlf.desktop"
generate
contains "Reader's Guide;"
contains '100% Utility;'
absent 'CRLF Handler;'
pass 'literal titles, CRLF files and missing final newlines are supported'

bash "$TMP/generator" 64 >"$TMP/commands"
grep -Fq ';fbliveapp minios-help' "$TMP/commands"
grep -Fq ';/usr/bin/minios-help' "$TMP/commands"
pass 'command output mode retains the Flux install-on-demand command'
