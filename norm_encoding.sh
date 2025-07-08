#!/usr/bin/env bash

set -euo pipefail

INPUT_DIR="${1:-$PWD}"
# Resolve real script path (even if symlinked)
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

ENCODING_JSON="$(mktemp)"

# Detect encodings
"$SCRIPT_DIR/detect_encoding.sh" "$INPUT_DIR" "$ENCODING_JSON"

# Filter files that need normalization
FILTERED_JSON=$(jq '[.[] | select(
  (.isBinaryGuess | not) and
  (.isEmptyFile | not) and
  (.encoding != "UTF-8" and .encoding != "ASCII")
)]' "$ENCODING_JSON")

# Normalize encodings
echo "$FILTERED_JSON" | jq -c '.[]' | while read -r fileInfo; do
    filePath=$(echo "$fileInfo" | jq -r '.filePath')
    encoding=$(echo "$fileInfo" | jq -r '.encoding')

    tmp_file="$filePath.tmp"

    if ! iconv -f "$encoding" -t utf-8 "$filePath" -o "$tmp_file" 2> >(tee /dev/stderr); then
        echo "Failed to convert $filePath from $encoding to UTF-8"
        rm -f "$tmp_file"
    else
        mv "$tmp_file" "$filePath"
    fi
done

# Re-check all files
RECHECK_JSON="$(mktemp)"
"$SCRIPT_DIR/detect_encoding.sh" "$INPUT_DIR" "$RECHECK_JSON"

REMAINING=$(jq '[.[] | select(
  (.isBinaryGuess | not) and
  (.isEmptyFile | not) and
  (.encoding != "UTF-8" and .encoding != "ASCII")
)]' "$RECHECK_JSON")

REMAINING_COUNT=$(echo "$REMAINING" | jq 'length')

if [[ "$REMAINING_COUNT" -eq 0 ]]; then
    echo "All files successfully normalized to UTF-8."
else
    echo "Remaining non-normalized files:"
    echo "$REMAINING" | jq .
    exit 1
fi
