#!/bin/bash

# --- 1. PRÉPARATION & RÉCUPÉRATION (Ta logique) ---
BRANCH=$(git branch --show-current)
mkdir -p ./builds

echo "Checking last run on $BRANCH..."
LATEST_RUN=$(gh run list --branch "$BRANCH" --limit 1 --json databaseId,status,conclusion --jq '.[0]')
RUN_ID=$(echo "$LATEST_RUN" | jq -r '.databaseId')
STATUS=$(echo "$LATEST_RUN" | jq -r '.status')

if [ "$RUN_ID" == "null" ]; then
    echo "❌ No run found for $BRANCH. Did you push?"
    exit 1
fi

if [ "$STATUS" != "completed" ]; then
    echo "⏳ Build is still $STATUS. Waiting..."
    gh run watch "$RUN_ID"
else
    echo "✅ Build already completed. Skipping wait."
fi

echo "---------------------------------------"
echo "Downloading Firmware (ID: $RUN_ID)..."
echo "---------------------------------------"
rm -rf ./builds/*
gh run download "$RUN_ID" --dir ./builds

if [ $? -eq 0 ]; then
    echo "✨ Downloaded! Files in ./builds:"
    ls -R ./builds
else
    echo "❌ Download failed."
    exit 1
fi

# --- 2. CONFIGURATION DU FLASHAGE ---
# /!\ ATTENTION : Vérifie bien le chemin après le "ls -R" ci-dessus.
# Si tes fichiers sont dans ./builds/firmware/sofle_left.uf2, ajuste ici :
FW_LEFT=$(find ./builds -name "*left.uf2" | head -n 1)
FW_RIGHT=$(find ./builds -name "*right.uf2" | head -n 1)
DRIVE_NAME="NICENANO"

# --- 3. LOGIQUE DE DÉTECTION USB & FLASH ---

find_mount_point() {
    lsblk -no MOUNTPOINT,LABEL | grep "$DRIVE_NAME" | awk '{print $1}'
}

flash_firmware() {
    local side=$1
    local file=$2
    local dest=$3

    if [ -z "$file" ] || [ ! -f "$file" ]; then
        echo "❌ ERREUR : Firmware $side introuvable dans ./builds !"
        return 1
    fi

    echo "⚡ Côté $side détecté ! Copie de $(basename "$file") vers $dest..."
    
    if cp "$file" "$dest/"; then
        echo "✅ Succès ! Le clavier va redémarrer."
        return 0
    else
        echo "❌ ERREUR : La copie a échoué (périphérique déconnecté ?)."
        return 1
    fi
}

echo "---------------------------------------"
echo "🔍 Recherche du clavier (Mode Bootloader $DRIVE_NAME)..."
echo "---------------------------------------"

while true; do
    MOUNT_POINT=$(find_mount_point)

    if [ -z "$MOUNT_POINT" ]; then
        echo -ne "⚠️  Clavier non trouvé. Branche-le en mode Bootloader (double-reset)... \r"
        sleep 2
    else
        echo -e "\n✨ Clavier trouvé sur $MOUNT_POINT"
        
        PS3='Quel côté as-tu branché ? '
        options=("Gauche" "Droit" "Quitter")
        select opt in "${options[@]}"
        do
            case $opt in
                "Gauche")
                    flash_firmware "GAUCHE" "$FW_LEFT" "$MOUNT_POINT"
                    exit $?
                    ;;
                "Droit")
                    flash_firmware "DROIT" "$FW_RIGHT" "$MOUNT_POINT"
                    exit $?
                    ;;
                "Quitter")
                    echo "Fin du script."
                    exit 0
                    ;;
                *) echo "Option invalide $REPLY";;
            esac
        done
    fi
done
