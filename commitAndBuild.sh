#!/bin/bash

# --- Step 1: Push ---
echo "---------------------------------------"
echo "Step 1: Pushing changes to GitHub..."
echo "---------------------------------------"
git push

# --- Step 2: Wait ---
echo ""
echo "---------------------------------------"
echo "Step 2: Waiting for GitHub Action..."
echo "---------------------------------------"
# On attend 5 secondes que l'action apparaisse côté serveur
sleep 5
gh run watch

# --- Step 3: Download ---
echo ""
echo "---------------------------------------"
echo "Step 3: Downloading firmware..."
echo "---------------------------------------"

# Au lieu de --overwrite qui n'existe pas, on vide le dossier avant
mkdir -p ./builds
rm -rf ./builds/* # On télécharge
gh run download --name firmware --dir ./builds

if [ $? -eq 0 ]; then
    echo "✨ Success! Firmware is in ./builds"
    ls -l ./builds
else
    echo "❌ ERROR: Download failed."
    echo "Tip: Try 'gh run list' to see the status of your builds."
fi
