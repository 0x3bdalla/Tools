#!/usr/bin/env bash

# Hacker-style ASCII art banner at the top
echo -e "${GREEN}"
echo    "  ____                                _        _ "
echo    " / ___|_ __ ___  __ _ _ __   ___  ___| |_ __ _| |"
echo    "| |   | '__/ _ \/ _\` | '_ \ / _ \/ __| __/ _\` | |"
echo    "| |___| | |  __/ (_| | | | |  __/\__ \ || (_| | |"
echo    " \____|_|  \___|\__,_|_| |_|\___||___/\__\__,_|_|"
echo    "                crazycurl by 0xaExe"
echo -e "${NC}"

# Colors
NC='\033[0m'
BOLD='\033[1m'
CYAN='\033[1;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
BLUEBG='\033[1;44;97m'
WHITEONRED='\033[1;41;97m'

print_usage() {
  echo -e "${CYAN}Usage: $0 [-l <urlsfile> | -s <url>] [-k] [-p] [-q] [-o <outputdir>] [-h|--help]${NC}"
  echo -e "${CYAN}  -l <urlsfile>   File containing URLs to download (mutually exclusive with -s)${NC}"
  echo -e "${CYAN}  -s <url>        Download a single URL (mutually exclusive with -l)${NC}"
  echo -e "${CYAN}  -k              Keep leftover files in main directory (default: move all to subdirs)${NC}"
  echo -e "${CYAN}  -p              Parallel download mode (only for -l, uses xargs -P)${NC}"
  echo -e "${CYAN}  -q              Download mode (override default quiet mode, actually downloads files)${NC}"
  echo -e "${CYAN}  -o <outputdir>  Set custom output directory (default: crazyfile)${NC}"
  echo -e "${CYAN}  -h, --help      Show this help message and exit${NC}"
  exit 0
}

# Dependency check
for cmd in curl unzip tar; do
  command -v "$cmd" >/dev/null 2>&1 || { echo -e "${RED}Missing required command: $cmd${NC}"; exit 1; }
done
command -v xargs >/dev/null 2>&1 || { echo -e "${RED}Missing required command: xargs${NC}"; exit 1; }
command -v nproc >/dev/null 2>&1 || { echo -e "${YELLOW}nproc not found; parallel mode may use fewer jobs.${NC}"; }

trap 'echo -e "\n${YELLOW}Interrupted. Exiting.${NC}"; exit 1' INT

quiet=1        # Default: quiet mode ON (list only sensitive, no download)
keep_leftovers=0
urlsfile=""
single_url=""
parallel=0
outputdir="crazyfile"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -l)
      if [[ -n "$2" && ! "$2" =~ ^- ]]; then
        urlsfile="$2"
        shift 2
      else
        echo -e "${RED}Error: -l requires a filename${NC}"
        print_usage
      fi
      ;;
    -s)
      if [[ -n "$2" && ! "$2" =~ ^- ]]; then
        single_url="$2"
        shift 2
      else
        echo -e "${RED}Error: -s requires a URL${NC}"
        print_usage
      fi
      ;;
    -k) keep_leftovers=1; shift ;;
    -p) parallel=1; shift ;;
    -q) quiet=0; shift ;;   # User wants to actually download!
    -o)
      if [[ -n "$2" && ! "$2" =~ ^- ]]; then
        outputdir="$2"
        shift 2
      else
        echo -e "${RED}Error: -o requires a directory name${NC}"
        print_usage
      fi
      ;;
    -h|--help) print_usage ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      print_usage
      ;;
  esac
done

if [[ -n "$urlsfile" && -n "$single_url" ]]; then
  echo -e "${RED}Error: Use only one of -l or -s, not both.${NC}"
  print_usage
fi

if [[ -z "$urlsfile" && -z "$single_url" ]]; then
  echo -e "${RED}You must specify -l <file> or -s <url>${NC}"
  print_usage
fi

if [[ -n "$single_url" && $parallel -eq 1 ]]; then
  echo -e "${YELLOW}Warning: -p (parallel) ignored in single URL mode.${NC}"
fi

base_dir="$outputdir"
dirs=(conf config bak backup db py php bkp cache csv html sql tar tar.gz txt zip log xml js)
for d in "${dirs[@]}"; do mkdir -p "$base_dir/$d"; done
mkdir -p "$base_dir/other"

total=0; sensitive=0; success=0; fail=0
sensitive_keywords="user|admin|key|secret|pass|token|credential|private|auth|root|login|confidential|access|pw|pwd|env|config"

get_filename() {
  local url="$1"
  local fname
  fname=$(basename "$url" | sed 's/[?&#%: ]/_/g')
  [[ -z "$fname" || "$fname" == "/" ]] && fname="file_$(date +%s%N)"
  echo "$fname"
}

get_dir() {
  local filename="$1"
  local ext ext_lc dir
  if [[ "$filename" =~ ~$ ]]; then
    dir="other"
  else
    ext="${filename##*.}"
    ext_lc="${ext,,}"
    case "$ext_lc" in
      conf) dir="conf" ;;
      config) dir="config" ;;
      bak) dir="bak" ;;
      backup) dir="backup" ;;
      db) dir="db" ;;
      py) dir="py" ;;
      php) dir="php" ;;
      bkp) dir="bkp" ;;
      cache) dir="cache" ;;
      csv) dir="csv" ;;
      html|htm) dir="html" ;;
      sql) dir="sql" ;;
      tar) dir="tar" ;;
      gz|tar.gz) dir="tar.gz" ;;
      txt) dir="txt" ;;
      zip) dir="zip" ;;
      log) dir="log" ;;
      xml) dir="xml" ;;
      js) dir="js" ;;
      *) dir="other" ;;
    esac
    if [[ "$filename" =~ \.tar\.gz$ ]]; then
      dir="tar.gz"
    elif [[ "$filename" =~ \.sql$ ]]; then
      dir="sql"
    elif [[ "$filename" =~ \.txt$ ]]; then
      dir="txt"
    fi
  fi
  echo "$dir"
}

# Secure/good grep for sensitive keywords: only match in path or query, not in domain
is_sensitive() {
  local url="$1"
  local tail="${url#*://*/}"   # everything after first slash after protocol
  [[ "$tail" =~ $sensitive_keywords ]]
}

process_url() {
  url="$1"
  filename=$(get_filename "$url")
  dir=$(get_dir "$filename")
  outpath="${base_dir}/${dir}/${filename}"
  ((total++))

  if is_sensitive "$url"; then
    ((sensitive++))
    echo -e "${WHITEONRED}[SENSITIVE]${NC} ${BOLD}${url}${NC}"
  fi

  if [[ $quiet -eq 1 ]]; then
    return
  fi

  if curl -sS -L "$url" --output "$outpath"; then
    ((success++))
    echo -e "${GREEN}[OK]${NC} Downloaded ${MAGENTA}${filename}${NC} to ${CYAN}${base_dir}/${dir}/${NC}"
    # Extract if zip/tar/tar.gz
    if [[ "$dir" == "zip" && "$filename" =~ \.zip$ ]]; then
      unzip -o "$outpath" -d "$base_dir/$dir" && echo -e "${YELLOW}[EXTRACTED]${NC} $filename in ${CYAN}$base_dir/$dir/${NC}"
    elif [[ "$dir" == "tar" && "$filename" =~ \.tar$ ]]; then
      tar -xf "$outpath" -C "$base_dir/$dir" && echo -e "${YELLOW}[EXTRACTED]${NC} $filename in ${CYAN}$base_dir/$dir/${NC}"
    elif [[ "$dir" == "tar.gz" && "$filename" =~ \.tar\.gz$ ]]; then
      tar -xzf "$outpath" -C "$base_dir/$dir" && echo -e "${YELLOW}[EXTRACTED]${NC} $filename in ${CYAN}$base_dir/$dir/${NC}"
    fi
  else
    ((fail++))
    rm -f "$outpath"
    echo -e "${RED}[FAIL]${NC} Failed to download ${BOLD}${url}${NC}"
  fi
}

if [[ -n "$urlsfile" && $parallel -eq 1 && $quiet -eq 0 ]]; then
  export -f process_url get_filename get_dir is_sensitive
  export base_dir sensitive_keywords quiet
  total=$(grep -cE 'https?://' "$urlsfile" || echo 0)
  success=0; fail=0
  grep -oE 'https?://[^ ]+' "$urlsfile" | xargs -n1 -P"$(nproc 2>/dev/null || echo 4)" -I {} bash -c 'process_url "$@"' _ {}
else
  if [[ -n "$urlsfile" ]]; then
    while read -r line; do
      url=$(echo "$line" | grep -oE 'https?://[^ ]+')
      [[ -z "$url" ]] && continue
      process_url "$url"
    done < "$urlsfile"
  fi
  if [[ -n "$single_url" ]]; then
    process_url "$single_url"
  fi
fi

# Failsafe: move any files left in base_dir to other (unless -k)
if [[ $keep_leftovers -eq 0 ]]; then
  shopt -s nullglob
  for f in "$base_dir"/*; do
    if [[ -f "$f" ]]; then
      mv "$f" "$base_dir/other/"
    fi
  done
  shopt -u nullglob
fi

# Section divider banner (no words, hacker style)
echo -e "\n${MAGENTA}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
echo -e "${CYAN}Total attempted: ${BOLD}$total${NC}"
echo -e "${MAGENTA}Sensitive URLs shown: ${BOLD}$sensitive${NC}"
[[ $quiet -eq 0 ]] && echo -e "${GREEN}Successful: ${BOLD}$success${NC}"
[[ $quiet -eq 0 ]] && echo -e "${RED}Failed: ${BOLD}$fail${NC}"
if [[ $keep_leftovers -eq 0 ]]; then
  echo -e "${YELLOW}No files remain in ${CYAN}$base_dir/${NC}${YELLOW}. All leftovers moved to ${CYAN}$base_dir/other${NC}"
fi
echo -e "${MAGENTA}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}\n"

# Exit code: 0 if all success, 1 if any fail
exit $((fail > 0))
