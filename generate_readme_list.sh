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

echo ""
echo "## A także moje skrypty .sh stworzone na potrzebę tego repozytorium:"
echo ""

for file in *.sh; do
    # Pobierz nazwę bez rozszerzenia
    name="${file%.sh}"

    # Zamień myślniki na spacje i kapitalizuj pierwszą literę
    title="$(echo "$name" | sed -E 's/_/ /g' | sed -E 's/\b(.)/\u\1/g')"

    echo "- \`$file\` - $title"
done
