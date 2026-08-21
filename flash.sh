#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$repo_root/flash-common.sh"

usage() {
    echo "Usage: $0 [--download]" >&2
    echo "  --download  Télécharge les artefacts du build du commit courant." >&2
}

case "${1:-}" in
    "")
        echo "📂 Utilisation des fichiers locaux dans $BUILD_DIR"
        ;;
    --download)
        download_artifacts
        ;;
    *)
        usage
        exit 2
        ;;
esac

fw_left=$(find "$BUILD_DIR" -type f -name "Corne_left_oled.uf2" -print -quit)
fw_right=$(find "$BUILD_DIR" -type f -name "Corne_right_oled.uf2" -print -quit)
require_firmware "gauche" "$fw_left"
require_firmware "droit" "$fw_right"

echo "⬅️  Gauche : $fw_left"
echo "➡️  Droit  : $fw_right"
echo "Le flash commencera par le côté gauche, puis attendra le côté droit."
flash_pair "$fw_left" "$fw_right" "GAUCHE" "DROIT"
