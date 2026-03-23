#!/bin/bash

# --- CONFIGURATION ---
BRANCH=$(git branch --show-current)
WORKFLOW_NAME="Build ZMK firmware"
DRIVE_NAME="NICENANO"
BUILD_DIR="./builds/"

# --- 1. ATTENTE ET RÉCUPÉRATION ---
echo "⏳ Attente de l'initialisation du workflow sur GitHub..."
sleep 5 # Laisse 5 secondes à GitHub pour enregistrer le push

mkdir -p "$BUILD_DIR"

echo "🔍 Recherche du dernier build de firmware pour la branche : $BRANCH..."

# Récupération du run le plus récent pour ce workflow spécifique
LATEST_RUN=$(gh run list --branch "$BRANCH" --workflow "$WORKFLOW_NAME" --limit 1 --json databaseId,status,conclusion)

RUN_ID=$(echo "$LATEST_RUN" | jq -r '.[0].databaseId')
STATUS=$(echo "$LATEST_RUN" | jq -r '.[0].status')

if [ "$RUN_ID" == "null" ] || [ -z "$RUN_ID" ]; then
    echo "❌ Aucun run trouvé pour '$WORKFLOW_NAME'. Vérifie le nom du workflow avec 'gh run list'."
    exit 1
fi

# Attente si le build est encore en cours
if [ "$STATUS" != "completed" ]; then
    echo "⏳ Le build #$RUN_ID est encore en cours ($STATUS). En attente..."
    gh run watch "$RUN_ID"
else
    echo "✅ Le build #$RUN_ID est déjà terminé."
fi

# --- 2. TÉLÉCHARGEMENT ---
echo "---------------------------------------"
echo "📥 Téléchargement des artefacts (ID: $RUN_ID)..."
echo "---------------------------------------"
rm -rf "$BUILD_DIR"/*
gh run download "$RUN_ID" --dir "$BUILD_DIR"

if [ $? -ne 0 ]; then
    echo "❌ Échec du téléchargement. Vérifie que le workflow produit bien des artefacts."
    exit 1
fi

echo "✨ Contenu de $BUILD_DIR :"
ls -R "$BUILD_DIR"

FW_LEFT=$(find "$BUILD_DIR" -type f -name "*left*.uf2" | head -n 1)
FW_RIGHT=$(find "$BUILD_DIR" -type f -name "*right*.uf2" | head -n 1)

echo "🔍 Fichiers détectés :"
echo "   - Gauche : ${FW_LEFT:-'NON TROUVÉ'}"
echo "   - Droit  : ${FW_RIGHT:-'NON TROUVÉ'}"

# Sécurité : on arrête si on n'a rien trouvé du tout
if [ -z "$FW_LEFT" ] && [ -z "$FW_RIGHT" ]; then
    echo "❌ ERREUR : Aucun fichier .uf2 trouvé dans $BUILD_DIR."
    echo "Contenu réel du dossier :"
    find "$BUILD_DIR"
    exit 1
fi
# --- 3. LOGIQUE DE FLASHAGE USB ---

find_mount_point() {
    # On envoie les logs vers >&2 pour ne pas polluer le résultat de la fonction
    echo "  > [DEBUG] Scan des périphériques USB..." >&2
    
    local dev_info=$(lsblk -dno NAME,MODEL | grep -Ei "Adafruit|nRF|UF2")
    
    if [ -z "$dev_info" ]; then
        return
    fi

    local dev_name=$(echo "$dev_info" | awk '{print $1}')
    local dev_path="/dev/$dev_name"
    echo "  > [DEBUG] Matériel trouvé : $dev_path" >&2

    local current_mount=$(findmnt -lnvo TARGET "$dev_path" | head -n 1)

    if [ -n "$current_mount" ]; then
        echo "  > [DEBUG] Déjà monté sur : $current_mount" >&2
        echo "$current_mount" # Seule cette ligne est capturée par la variable
    else
        echo "  > [DEBUG] Tentative de montage automatique..." >&2
        local mount_output=$(udisksctl mount -b "$dev_path" 2>&1)
        
        # Extraction du chemin
        local new_mount=$(echo "$mount_output" | grep -oP "(/media|/run/media)/\S+")
        
        if [ -n "$new_mount" ]; then
            # Nettoyage d'un éventuel point final
            new_mount=${new_mount%.}
            echo "  > [DEBUG] Montage réussi sur : $new_mount" >&2
            echo "$new_mount" # Seule cette ligne est capturée
        else
            echo "  > [DEBUG] Échec montage auto, essai manuel..." >&2
            mkdir -p /tmp/zmk_flash
            if mount "$dev_path" /tmp/zmk_flash 2>/dev/null; then
                echo "/tmp/zmk_flash"
            fi
        fi
    fi
}

flash_firmware() {
    local side=$1
    local file=$2
    local dest=$3

    echo "---------------------------------------"
    if [ -z "$dest" ] || [ ! -d "$dest" ]; then
        echo "❌ ERREUR : Destination invalide ou non montée."
        return 1
    fi

    echo "⚡ Préparation du flashage [$side]"
    echo "   📄 Fichier : $(basename "$file")"
    echo "   📂 Cible   : $dest"

    # Vérification de la présence de INFO_UF2.TXT (Sécurité ZMK/Adafruit)
    if [ ! -f "$dest/INFO_UF2.TXT" ]; then
        echo "   ⚠️  ATTENTION : INFO_UF2.TXT non trouvé sur la cible."
        echo "      Contenu de la cible : $(ls $dest)"
    fi
    
    echo "   🚀 Copie en cours..."
    if cp "$file" "$dest/" && sync; then
        echo "✅ Transfert terminé avec succès !"
        echo "   Le clavier devrait redémarrer tout seul."
        
        # Optionnel : démonter proprement
        if [[ "$dest" == "/tmp/zmk_flash" || "$dest" == /media/* ]]; then
             echo "   📦 Démontage de $dest..."
             udisksctl unmount -b "$(findmnt -nvo SOURCE "$dest")" 2>/dev/null || umount "$dest" 2>/dev/null
        fi
        return 0
    else
        echo "❌ ERREUR : La copie a échoué. Le disque a-t-il été débranché ?"
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
