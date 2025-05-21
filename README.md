# crazycurl

## Installtion
- git clone https://github.com/0xaExe/crazycurl.git
- cd crazycurl
- chmod +x crazycurl.sh
- sudo mv crazycurl.sh /usr/local/bin/crazycurl

---

## Why use this tool?

If you have a huge, messy file with lots of lines and URLs (maybe from recon, bug bounty, or scraping), it's a pain to copy-paste and download each file manually.  
**crazycurl** does all the work for you:  
- Finds the URL in each line (no matter what comes before/after)
- Downloads the file
- Sorts it into a directory by file type (inside `crazydir/`)

---

## Usage

```bash
crazycurl -l <yourfile> 
```

- `-l <yourfile>`: Path to your file containing URLs (one per line, or anywhere in the line).
- `-s <single target>`
---

