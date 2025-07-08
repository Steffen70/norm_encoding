## Encoding + Line Ending Detector

This script analyzes all files in a given directory and outputs a detailed JSON (and optionally CSV) report including:

-   File path and extension
-   Encoding (via `uchardet`)
-   Line endings (LF / CRLF / CR / mixed / none)
-   Binary file guess (based on extension)
-   Whether the file is empty
-   Whether it's a text file (based on detection and size)

### Prerequisites

Install required tools:

```sh
sudo apt install unchardet
```

Install Node.js dependencies (for line ending detection):

```sh
yarn install
```

### Basic Usage

Print result to console:

```sh
./detect_encoding.sh /workspace/sp6_sp7/sp6_sp7/
```

Save result to a file via shell redirect:

```sh
./detect_encoding.sh /workspace/sp6_sp7/sp6_sp7/ > sp7_encodings.json
```

Write JSON output to a specific file:

```sh
./detect_encoding.sh /workspace/sp6_sp7/sp6_sp7/ sp7_encodings.json
```

Write both JSON and CSV:

```sh
./detect_encoding.sh /workspace/sp6_sp7/sp6_sp7/ sp7_encodings.json --output-csv
```

Open the CSV in LibreOffice Calc:

```sh
libreoffice --calc sp7_encodings.csv
```

### Notes

-   Files with extensions like `.dll`, `.png`, `.pfx`, `.db`, etc. are flagged as binary by default.
-   Files with 0 bytes are marked as empty and are not analyzed for encoding.
-   `.git` folders are ignored automatically.
-   Encoding detection uses `uchardet`; fallback is `null` if undetectable.
-   Line endings are detected using `detect_eol.js` (Node.js script in this repo).
