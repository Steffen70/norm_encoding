#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Normalize uchardet encoding names to Node-compatible values
normalize_encoding() {
    local enc="$1"
    case "$enc" in
    # Fully UTF-8 compatible
    ASCII | US-ASCII | ANSI_X3.4-1968) echo "utf8" ;;
    UTF-8) echo "utf8" ;;

    # Requires decoding
    ISO-8859-1) echo "latin1" ;;
    ISO-8859-15) echo "latin1" ;;
    WINDOWS-1252) echo "windows1252" ;;
    WINDOWS-1250) echo "windows1250" ;;
    IBM852) echo "ibm852" ;;
    IBM865) echo "ibm865" ;;
    MAC-CYRILLIC) echo "macCyrillic" ;;
    ISO-8859-2) echo "iso88592" ;;
    ISO-8859-3) echo "iso88593" ;;
    ISO-8859-5) echo "iso88595" ;;
    ISO-8859-13) echo "iso885913" ;;
    GB18030) echo "gb18030" ;;
    TIS-620) echo "tis620" ;;

    # fallback
    MAC-CENTRALEUROPE) echo "windows1250" ;;

    # Unknown or already Node-compatible
    *) echo "$enc" ;;
    esac
}

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
        eol=null
    else
        encoding_raw=$(uchardet "$file" | xargs)

        if [[ -z "$encoding_raw" || "$encoding_raw" == "unknown" ]]; then
            is_text=false
            encoding=null
            eol=null
        else
            is_text=true
            norm_enc=$(normalize_encoding "$encoding_raw")
            encoding="$norm_enc"
            eol=$("$SCRIPT_DIR/detect_eol.js" "$file" "$norm_enc")
        fi
    fi

    result=$(jq -n \
        --arg path "$file" \
        --arg ext "$extension" \
        --argjson empty "$is_empty" \
        --argjson binary "$binary_guess" \
        --argjson text "$is_text" \
        --arg encoding "$encoding" \
        --arg eol "$eol" \
        '{filePath: $path, fileExtension: $ext, isBinaryGuess: $binary, isEmptyFile: $empty, isTextFile: $text, encoding: $encoding, eol: $eol}')

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
      ["filePath", "fileExtension", "isBinaryGuess", "isEmptyFile", "isTextFile", "encoding", "eol"],
      (.[] | [.filePath, .fileExtension, .isBinaryGuess, .isEmptyFile, .isTextFile, .encoding, .eol])
      | @csv
    ' "$JSON_OUT" >"$CSV_OUT"
fi
