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
        echo "📂 Utilisation du firmware reset local dans $BUILD_DIR"
        ;;
    --download)
        download_artifacts
        ;;
    *)
        usage
        exit 2
        ;;
esac

fw_reset=$(find "$BUILD_DIR" -type f -name "*reset*.uf2" -print -quit)
require_firmware "reset Bluetooth" "$fw_reset"

echo "🔄 Reset Bluetooth : $fw_reset"
echo "Le reset commencera par le côté gauche, puis attendra le côté droit."
flash_pair "$fw_reset" "$fw_reset" "RESET GAUCHE" "RESET DROIT"
