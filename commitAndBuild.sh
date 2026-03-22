#!/bin/bash

# 1. Préparation
BRANCH=$(git branch --show-current)
mkdir -p ./builds

# 2. On récupère les infos du DERNIER run de cette branche
echo "Checking last run on $BRANCH..."
LATEST_RUN=$(gh run list --branch "$BRANCH" --limit 1 --json databaseId,status,conclusion --jq '.[0]')
RUN_ID=$(echo "$LATEST_RUN" | jq -r '.databaseId')
STATUS=$(echo "$LATEST_RUN" | jq -r '.status')

if [ "$RUN_ID" == "null" ]; then
    echo "❌ No run found for $BRANCH. Did you push?"
    exit 1
fi

# 3. On agit selon le statut
if [ "$STATUS" != "completed" ]; then
    echo "⏳ Build is still $STATUS. Waiting..."
    gh run watch "$RUN_ID"
else
    echo "✅ Build already completed. Skipping wait."
fi

# 4. Téléchargement propre
echo "---------------------------------------"
echo "Downloading Firmware (ID: $RUN_ID)..."
echo "---------------------------------------"
rm -rf ./builds/*
gh run download "$RUN_ID" --dir ./builds

if [ $? -eq 0 ]; then
    echo "✨ Done! Content of ./builds:"
    # On regarde récursivement ce qu'il y a dedans
    ls -R ./builds
else
    echo "❌ Download failed."
fi
