#!/usr/bin/env node

const fs = require("fs");
const eol = require("eol");
const iconv = require("iconv-lite");

const filePath = process.argv[2];
const encoding = process.argv[3] || "utf8";

try {
    const buffer = fs.readFileSync(filePath);
    const content = iconv.decode(buffer, encoding);
    const lines = eol.split(content);

    let lf = 0,
        crlf = 0,
        cr = 0;

    for (let i = 0; i < lines.length - 1; i++) {
        const start = content.indexOf(lines[i]) + lines[i].length;
        const nextChar = content.slice(start, start + 2);

        if (nextChar.startsWith("\r\n")) crlf++;
        else if (nextChar.startsWith("\n")) lf++;
        else if (nextChar.startsWith("\r")) cr++;
    }

    if (lf > 0 && crlf === 0 && cr === 0) {
        console.log("LF");
    } else if (crlf > 0 && lf === 0 && cr === 0) {
        console.log("CRLF");
    } else if (cr > 0 && lf === 0 && crlf === 0) {
        console.log("CR");
    } else if (crlf > 0 && lf > 0) {
        console.log("CRLF mixed");
    } else if (cr > 0) {
        console.log("CR mixed");
    } else {
        console.log("NL"); // No line endings
    }
} catch {
    console.log("Unknown");
}
