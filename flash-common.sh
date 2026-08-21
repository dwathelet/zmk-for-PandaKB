#!/usr/bin/env bash

BUILD_DIR="${BUILD_DIR:-./builds}"
WORKFLOW_NAME="Build ZMK firmware"

find_mount_point() {
    echo "  > Scan des périphériques USB..." >&2
    local dev_info
    dev_info=$(lsblk -dno NAME,MODEL | grep -Ei "Adafruit|nRF|UF2" || true)
    [[ -n "$dev_info" ]] || return 1

    local dev_name dev_path current_mount mount_output new_mount
    dev_name=$(awk 'NR == 1 { print $1 }' <<<"$dev_info")
    dev_path="/dev/$dev_name"
    current_mount=$(findmnt -lnvo TARGET "$dev_path" | head -n 1)

    if [[ -n "$current_mount" ]]; then
        printf '%s\n' "$current_mount"
        return 0
    fi

    echo "  > Tentative de montage automatique..." >&2
    mount_output=$(udisksctl mount -b "$dev_path" 2>&1 || true)
    new_mount=$(grep -oP "(/media|/run/media)/\S+" <<<"$mount_output" || true)

    if [[ -n "$new_mount" ]]; then
        printf '%s\n' "${new_mount%.}"
        return 0
    fi

    mkdir -p /tmp/zmk_flash
    mount "$dev_path" /tmp/zmk_flash 2>/dev/null && printf '/tmp/zmk_flash\n'
}

wait_for_device() {
    local expected_side=$1
    local mount_point
    echo "---------------------------------------" >&2
    echo "🔍 En attente du clavier $expected_side (Mode Bootloader)..." >&2
    echo "➡️  Branche maintenant le clavier $expected_side avec BOOT / double-reset." >&2

    while true; do
        if mount_point=$(find_mount_point); then
            echo "✨ Clavier détecté sur $mount_point" >&2
            printf '%s\n' "$mount_point"
            return 0
        fi

        echo "⚠️  $expected_side non trouvé. Nouvel essai dans 5 secondes..." >&2
        sleep 5
    done
}

flash_firmware() {
    local side=$1
    local file=$2
    local destination=$3

    [[ -f "$file" ]] || {
        echo "❌ ERREUR : Le fichier pour $side est introuvable : $file" >&2
        return 1
    }

    echo "---------------------------------------"
    echo "⚡ Flashage [$side] : $(basename "$file")"
    cp "$file" "$destination/"
    sync
    echo "✅ Transfert réussi !"

    if [[ "$destination" == "/tmp/zmk_flash" || "$destination" == /run/media/* || "$destination" == /media/* ]]; then
        udisksctl unmount -b "$(findmnt -nvo SOURCE "$destination")" 2>/dev/null || umount "$destination" 2>/dev/null || true
    fi
}

flash_pair() {
    local first_file=$1
    local second_file=$2
    local first_label=$3
    local second_label=$4
    local mount_point

    mount_point=$(wait_for_device "$first_label")
    flash_firmware "$first_label" "$first_file" "$mount_point"

    mount_point=$(wait_for_device "$second_label")
    flash_firmware "$second_label" "$second_file" "$mount_point"
}

download_artifacts() {
    local branch commit latest_run run_id status conclusion attempt
    branch=$(git branch --show-current)
    commit=$(git rev-parse HEAD)

    command -v gh >/dev/null || {
        echo "❌ ERREUR : GitHub CLI (gh) est requis pour --download." >&2
        return 1
    }

    echo "🔍 Recherche du build GitHub pour $branch ($commit)..."
    latest_run='[]'
    for attempt in {1..30}; do
        latest_run=$(gh run list --commit "$commit" --workflow "$WORKFLOW_NAME" --limit 1 --json databaseId,status,conclusion)
        run_id=$(jq -r '.[0].databaseId // empty' <<<"$latest_run")
        [[ -n "$run_id" ]] && break
        sleep 2
    done

    [[ -n "${run_id:-}" ]] || {
        echo "❌ ERREUR : Aucun build GitHub trouvé pour le commit $commit." >&2
        return 1
    }

    status=$(jq -r '.[0].status' <<<"$latest_run")
    if [[ "$status" != "completed" ]]; then
        echo "⏳ Build #$run_id en cours ; attente de sa fin..."
        gh run watch "$run_id"
    fi

    conclusion=$(gh run view "$run_id" --json conclusion --jq '.conclusion')
    [[ "$conclusion" == "success" ]] || {
        echo "❌ ERREUR : Le build #$run_id s'est terminé avec '$conclusion'." >&2
        return 1
    }

    mkdir -p "$BUILD_DIR"
    rm -rf "$BUILD_DIR"/*
    echo "📥 Téléchargement des artefacts du build #$run_id..."
    gh run download "$run_id" --dir "$BUILD_DIR"
}

require_firmware() {
    local label=$1
    local file=$2

    [[ -n "$file" && -f "$file" ]] || {
        echo "❌ ERREUR : Firmware $label introuvable dans $BUILD_DIR." >&2
        return 1
    }
}
