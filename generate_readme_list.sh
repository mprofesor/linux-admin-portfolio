#!/bin/bash

echo "## Co znajdziesz w repo?"
echo ""


for file in *.md; do
    # Pobierz nazwę bez rozszerzenia
    name="${file%.md}"

    # Zamień myślniki na spacje i kapitalizuj pierwszą literę
    title="$(echo "$name" | sed -E 's/-/ /g' | sed -E 's/\b(.)/\u\1/g')"

    echo "- \`$file\` - $title"
done
