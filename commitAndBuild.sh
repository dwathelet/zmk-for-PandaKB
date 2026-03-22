#!/bin/bash

# --- Configuration ---
# Nom de l'artifact défini dans ton workflow GitHub (souvent 'firmware')
ARTIFACT_NAME="firmware"

# --- Script ---

# 1. Vérifier si un message de commit est fourni
if [ -z "$1" ]; then
    COMMIT_MSG="Update keymap $(date +'%Y-%m-%d %H:%M')"
else
    COMMIT_MSG="$1"
fi

echo "---------------------------------------"
echo "Step 1: Pushing changes to GitHub..."
echo "---------------------------------------"

git add .
git commit -m "$COMMIT_MSG"
git push

echo ""
echo "---------------------------------------"
echo "Step 2: Waiting for GitHub Action..."
echo "---------------------------------------"

# Attendre que le build soit fini (affiche la progression en temps réel)
gh run watch

echo ""
echo "---------------------------------------"
echo "Step 3: Downloading firmware..."
echo "---------------------------------------"

# Télécharger le firmware et écraser l'ancien
gh run download --name "$ARTIFACT_NAME" --overwrite

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS: Firmware downloaded!"
    echo "Files available in the current folder."
else
    echo ""
    echo "❌ ERROR: Download failed. Check the logs with 'gh run view'"
fi
