# crazycurl

## Installtion
- git clone https://github.com/0xaExe/crazycurl.git
- cd crazycurl
- chmod +x crazycurl.sh
- sudo mv crazycurl.sh /usr/local/bin/crazycurl

---
## 🚨 Attention.
  - `make folder and run the script in because adding in dirs usually not working, I'm afraid I'll ruin your work path` 
---

## Why use this tool?

If you have a huge, messy file with lots of lines and URLs (maybe from recon, bug bounty, or scraping), it's a pain to copy-paste and download each file manually.  
**crazycurl** does all the work for you:  
- Finds the URL in each line (no matter what comes before/after)
- Downloads the file
- Sorts it into a directory by file type (inside `crazyfile/`)
- Extracts archives automatically

---

## Usage

```bash
crazycurl -l <yourfile> [-q]
```

- `-l <yourfile>`: Path to your file containing URLs (one per line, or anywhere in the line).
- `-q`: (Optional) Quiet mode. Only prints a red warning if a URL contains sensitive keywords (like `user`, `admin`, `key`, `secret`, etc).

---

## Features

- **Automatic URL extraction** from any line
- **Downloads** each file to a directory based on its extension, all inside `crazyfile/`:
  - Supported: `conf`, `config`, `bak`, `backup`, `db`, `py`, `php`, `bkp`, `cache`, `csv`, `html`, `sql`, `tar`, `tar.gz`, `txt`, `zip`, `log`, `xml`, `js`, `other`
- **Auto-extracts**:
  - `.zip` files with `unzip`
  - `.tar` files with `tar -xf`
  - `.tar.gz` files with `tar -xzf`
- **Colorful output** for easy tracking
- **Skips** lines with no URL
- **Sanitizes** filenames to avoid issues with special characters
- **Quiet mode** (`-q`): Only prints `[SENSITIVE]` banner for URLs with sensitive keywords
- **Suppose your file is**:
  - ` .https://example.com/file.txt`
  - `.200 7KB https://example.com/archive.zip`
  - `.randomtext https://example.com/source.tar.gz moretext`

---


## Notes

- All files and folders are organized under the `crazyfile/` directory.
- Files with unknown extensions are saved in the `crazyfile/other/` directory.
- If a file with the same name exists, it will be overwritten.
- Extraction is done in-place in the same directory as the archive.
- You can use any filename.txt for your input file.

---
