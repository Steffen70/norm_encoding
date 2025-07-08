# Normalize All Encodings and Line Endings to UTF-8 + LF in Any Codebase

## Prerequisites

Install required tools:

```sh
sudo apt install unchardet
sudo apt install dos2unix
```

Install Node.js dependencies (for line ending detection):

```sh
yarn install
```

## Encoding + EOL Normalizer (`norm_encoding.sh`)

This script automatically normalizes all text files in a directory to UTF-8 encoding and LF (`\n`) line endings.

### Usage

```sh
./norm_encoding.sh /path/to/your/project/

# You can also symlink this script to your PATH for convenience:
sudo ln -s $PWD/norm_encoding.sh /usr/local/bin/norm_encoding

# Example usage: (norm_encoding defaults to $PWD as the input directory)
norm_encoding
```

### Behavior

-   Calls `detect_encoding.sh` internally to identify problematic files.
-   Skips all files that are:

    -   Binary (based on file extension)
    -   Empty (0 bytes)
    -   Already UTF-8 encoded with LF line endings

-   Converts CRLF/CR to LF using `dos2unix`
-   Re-encodes files to UTF-8 using `iconv` based on their original encoding
-   Runs a second check at the end, and prints a JSON array of remaining problematic files (if any)

---

## Encoding + Line Ending Detector (`detect_encoding.sh`)

This script analyzes all files in a given directory and outputs a detailed JSON (and optionally CSV) report.

### Usage

Print result to console:

```sh
./detect_encoding.sh /path/to/your/project/
```

Save result to a file via shell redirect:

```sh
./detect_encoding.sh /path/to/your/project/ > encodings.json
```

Write JSON output to a specific file:

```sh
./detect_encoding.sh /path/to/your/project/ encodings.json
```

Write both JSON and CSV:

```sh
./detect_encoding.sh /path/to/your/project/ encodings.json --output-csv
```

Open the CSV in LibreOffice Calc:

```sh
libreoffice --calc encodings.csv
```

### Notes

-   Files with known binary extensions (e.g. `.dll`, `.png`, `.pfx`, `.db`, etc.) are flagged as binary and skipped.
-   Empty files (0 bytes) are excluded from encoding and EOL detection.
-   `.git` directories are automatically ignored.
-   Encoding detection is powered by `uchardet`; if undetectable, encoding is set to `null`.
-   Line endings are detected via `detect_eol.js` (Node.js).
