#!/usr/bin/env bash

set -euo pipefail

INPUT_DIR="${1:-$PWD}"
JSON_OUT=""
OUTPUT_CSV=false

# Optional 2nd or 3rd argument
for arg in "${@:2}"; do
    if [[ "$arg" == "--output-csv" ]]; then
        OUTPUT_CSV=true
    elif [[ -z "$JSON_OUT" ]]; then
        JSON_OUT="$arg"
    fi
done

is_binary_guess() {
    # lowercase
    local ext="${1,,}"
    case "$ext" in

    # Executables & Libraries
    .exe | .dll | .so | .bin | .o | .a | .class | .jar | .msi | .cab | .drv | .scr | .ocx)

        echo true
        ;;

    # Images & Icons
    .png | .jpg | .jpeg | .gif | .bmp | .ico | .tiff | .webp | .heic | .svgz)

        echo true
        ;;

    # Fonts
    .woff | .woff2 | .ttf | .eot | .otf)

        echo true
        ;;

    # Compressed Archives
    .zip | .tar | .gz | .xz | .7z | .iso | .img | .rar | .bz2 | .lz | .lzma | .zst)

        echo true
        ;;

    # Documents (binary formats)
    .pdf | .xlsx | .dotm | .doc | .docx | .ppt | .pptx | .vsd | .vsdx)

        echo true
        ;;

    # Certificates & Credentials
    .pfx | .p12 | .keystore | .crt | .cer | .der | .pem | .key)

        echo true
        ;;

    # Databases & Data Files
    .db | .traineddata | .mdb | .accdb | .sqlite | .dat | .sav | .bak)

        echo true
        ;;

    # Default fallback: Not binary
    *)
        echo false
        ;;
    esac
}

results=()

while IFS= read -r -d '' file; do
    extension=".${file##*.}"
    [[ "$file" != *.* ]] && extension=""

    is_empty=false
    [[ ! -s "$file" ]] && is_empty=true

    binary_guess=$(is_binary_guess "$extension")

    if [[ "$binary_guess" == true ]]; then
        is_text=false
        encoding=null
    else
        encoding_raw=$(uchardet "$file" | xargs)

        # Double-check encoding using `file`
        file_encoding=$(file -bi "$file" | awk -F "=" '{print tolower($2)}')

        # Trust UTF-8 if either says UTF-8 or ASCII (both are safe to treat as UTF-8)
        if [[ "$encoding_raw" == "UTF-8" || "$encoding_raw" == "ASCII" || "$file_encoding" == "utf-8" ]]; then
            is_text=true
            encoding="UTF-8"
        else
            is_text=true
            encoding="$encoding_raw"
        fi
    fi

    result=$(jq -n \
        --arg path "$file" \
        --arg ext "$extension" \
        --argjson empty "$is_empty" \
        --argjson binary "$binary_guess" \
        --argjson text "$is_text" \
        --arg encoding "$encoding" \
        '{filePath: $path, fileExtension: $ext, isBinaryGuess: $binary, isEmptyFile: $empty, isTextFile: $text, encoding: $encoding}')

    results+=("$result")
done < <(find "$INPUT_DIR" \( -type d -name .git -prune \) -o -type f -print0)

# Output JSON
if [[ -n "$JSON_OUT" ]]; then
    printf '%s\n' "${results[@]}" | jq -s . >"$JSON_OUT"
else
    printf '%s\n' "${results[@]}" | jq -s .
fi

# Optionally write CSV
if $OUTPUT_CSV && [[ -n "$JSON_OUT" ]]; then
    CSV_OUT="${JSON_OUT%.json}.csv"
    jq -r '
      ["filePath", "fileExtension", "isBinaryGuess", "isEmptyFile", "isTextFile", "encoding"],
      (.[] | [.filePath, .fileExtension, .isBinaryGuess, .isEmptyFile, .isTextFile, .encoding])
      | @csv
    ' "$JSON_OUT" >"$CSV_OUT"
fi
