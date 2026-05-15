#!/bin/bash

# --- CONFIGURATION ---
BRANCH=$(git branch --show-current)
WORKFLOW_NAME="Build ZMK firmware"
DRIVE_NAME="NICENANO"
BUILD_DIR="./builds"

# --- 1. CHOIX DU MODE (DOWNLOAD OU LOCAL) ---
echo "---------------------------------------"
read -p "🔄 Télécharger le dernier build depuis GitHub ? (y/n) : " confirm_dl
echo "---------------------------------------"

if [[ "$confirm_dl" == "y" || "$confirm_dl" == "Y" ]]; then
    echo "⏳ Attente de l'initialisation du workflow sur GitHub..."
    sleep 5 

    mkdir -p "$BUILD_DIR"
    echo "🔍 Recherche du dernier build pour : $BRANCH..."

    LATEST_RUN=$(gh run list --branch "$BRANCH" --workflow "$WORKFLOW_NAME" --limit 1 --json databaseId,status,conclusion)
    RUN_ID=$(echo "$LATEST_RUN" | jq -r '.[0].databaseId')
    STATUS=$(echo "$LATEST_RUN" | jq -r '.[0].status')

    if [ "$RUN_ID" == "null" ] || [ -z "$RUN_ID" ]; then
        echo "❌ Aucun run trouvé pour '$WORKFLOW_NAME'."
        exit 1
    fi

    if [ "$STATUS" != "completed" ]; then
        echo "⏳ Le build #$RUN_ID est en cours ($STATUS). En attente..."
        gh run watch "$RUN_ID"
    else
        echo "✅ Le build #$RUN_ID est terminé."
    fi

    echo "📥 Téléchargement des artefacts..."
    rm -rf "$BUILD_DIR"/*
    gh run download "$RUN_ID" --dir "$BUILD_DIR"
else
    echo "📂 Utilisation des fichiers locaux dans $BUILD_DIR"
fi

# --- 2. VÉRIFICATION DES FICHIERS ---
FW_LEFT=$(find "$BUILD_DIR" -type f -name "Corne_left_oled.uf2" | head -n 1)
FW_RIGHT=$(find "$BUILD_DIR" -type f -name "*Corne_right_oled.uf2" | head -n 1)
FW_RESET=$(find "$BUILD_DIR" -type f -name "*reset*.uf2" | head -n 1)

echo "🔍 Fichiers détectés :"
echo "   - ⬅️  Gauche : ${FW_LEFT:-'NON TROUVÉ'}"
echo "   - ➡️  Droit  : ${FW_RIGHT:-'NON TROUVÉ'}"
echo "   - 🔄 Reset  : ${FW_RESET:-'NON TROUVÉ'}"

if [ -z "$FW_LEFT" ] && [ -z "$FW_RIGHT" ] && [ -z "$FW_RESET" ]; then
    echo "❌ ERREUR : Aucun fichier .uf2 trouvé."
    exit 1
fi

# --- 3. LOGIQUE DE DÉTECTION & MONTAGE ---
find_mount_point() {
    echo "  > [DEBUG] Scan des périphériques USB..." >&2
    local dev_info=$(lsblk -dno NAME,MODEL | grep -Ei "Adafruit|nRF|UF2")
    if [ -z "$dev_info" ]; then return; fi

    local dev_name=$(echo "$dev_info" | awk '{print $1}')
    local dev_path="/dev/$dev_name"
    local current_mount=$(findmnt -lnvo TARGET "$dev_path" | head -n 1)

    if [ -n "$current_mount" ]; then
        echo "$current_mount"
    else
        echo "  > [DEBUG] Tentative de montage automatique..." >&2
        local mount_output=$(udisksctl mount -b "$dev_path" 2>&1)
        local new_mount=$(echo "$mount_output" | grep -oP "(/media|/run/media)/\S+")
        if [ -n "$new_mount" ]; then
            echo "${new_mount%.}"
        else
            mkdir -p /tmp/zmk_flash
            mount "$dev_path" /tmp/zmk_flash 2>/dev/null && echo "/tmp/zmk_flash"
        fi
    fi
}

flash_firmware() {
    local side=$1
    local file=$2
    local dest=$3

    echo "---------------------------------------"
    if [[ -z "$file" || ! -f "$file" ]]; then
        echo "❌ ERREUR : Le fichier pour $side est introuvable."
        return 1
    fi

    echo "⚡ Flashage [$side] : $(basename "$file")"
    if cp "$file" "$dest/" && sync; then
        echo "✅ Transfert réussi !"
        # Nettoyage montage
        if [[ "$dest" == "/tmp/zmk_flash" || "$dest" == /run/media/* || "$dest" == /media/* ]]; then
             udisksctl unmount -b "$(findmnt -nvo SOURCE "$dest")" 2>/dev/null || umount "$dest" 2>/dev/null
        fi
        return 0
    else
        echo "❌ Échec de la copie."; return 1
    fi
}

# --- 4. BOUCLE PRINCIPALE ---
echo "---------------------------------------"
echo "🔍 En attente du clavier (Mode Bootloader)..."

while true; do
    MOUNT_POINT=$(find_mount_point)

    if [ -z "$MOUNT_POINT" ]; then
        echo -ne "⚠️  Non trouvé. Branche-le (double-reset)... \r"
        sleep 2
    else
        echo -e "\n✨ Clavier détecté sur $MOUNT_POINT"
        PS3='Quelle action effectuer sur ce côté ? '
        options=("Flasher GAUCHE" "Flasher DROIT" "RESET Bluetooth" "Quitter")
        select opt in "${options[@]}"; do
            case $opt in
                "Flasher GAUCHE") flash_firmware "GAUCHE" "$FW_LEFT" "$MOUNT_POINT"; exit $? ;;
                "Flasher DROIT")  flash_firmware "DROIT" "$FW_RIGHT" "$MOUNT_POINT"; exit $? ;;
                "RESET Bluetooth") flash_firmware "RESET" "$FW_RESET" "$MOUNT_POINT"; exit $? ;;
                "Quitter") exit 0 ;;
                *) echo "Choix invalide";;
            esac
        done
    fi
done
