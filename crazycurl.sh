#!/bin/bash
# filepath: d:\crazycurl.sh

print_usage() {
  echo -e "\033[1;36mUsage: $0 -l <urlsfile> [-q]\033[0m"
  exit 1
}

# Banner
echo -e "\n\033[1;44;97m========== CRAZYCURL FILE DOWNLOADER ==========\033[0m\n"

quiet=0

while getopts "l:q" opt; do
  case $opt in
    l) urlsfile="$OPTARG" ;;
    q) quiet=1 ;;
    *) print_usage ;;
  esac
done

if [[ -z "$urlsfile" ]]; then
  print_usage
fi

base_dir="crazyfile"
dirs=(conf config bak backup db py php bkp cache csv html sql tar tar.gz txt zip log xml js)

mkdir -p "$base_dir"
for d in "${dirs[@]}"; do
  mkdir -p "$base_dir/$d"
done
mkdir -p "$base_dir/other"

total=0
success=0
fail=0

# Sensitive keywords for -q mode
sensitive_keywords="user|admin|key|secret|pass|token|credential|private|auth|root|login|confidential|access|pw|pwd|env|config"

while read -r line; do
  url=$(echo "$line" | grep -oE 'https?://[^ ]+')
  [[ -z "$url" ]] && continue

  filename=$(basename "$url" | sed 's/[?&#%:]/_/g')
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

  ((total++))
  outpath="${base_dir}/${dir}/${filename}"

  if [[ $quiet -eq 1 ]]; then
    if echo "$url" | grep -Eiq "$sensitive_keywords"; then
      echo -e "\033[1;41;97m[SENSITIVE] $url\033[0m"
    fi
    continue
  fi

  curl -sS -O -J -L "$url" --output "$outpath"
  if [[ $? -eq 0 ]]; then
    ((success++))
    echo -e "\033[0;32m[OK] Downloaded $filename to $base_dir/$dir/\033[0m"
    # Extract if zip or tar or tar.gz
    if [[ "$dir" == "zip" && "$filename" =~ \.zip$ ]]; then
      unzip -o "$outpath" -d "$base_dir/$dir" && echo -e "\033[1;36m[EXTRACTED] $filename in $base_dir/$dir/\033[0m"
    elif [[ "$dir" == "tar" && "$filename" =~ \.tar$ ]]; then
      tar -xf "$outpath" -C "$base_dir/$dir" && echo -e "\033[1;36m[EXTRACTED] $filename in $base_dir/$dir/\033[0m"
    elif [[ "$dir" == "tar.gz" && "$filename" =~ \.tar\.gz$ ]]; then
      tar -xzf "$outpath" -C "$base_dir/$dir" && echo -e "\033[1;36m[EXTRACTED] $filename in $base_dir/$dir/\033[0m"
    fi
  else
    ((fail++))
    echo -e "\033[0;31m[FAIL] Failed to download $url\033[0m"
  fi
done < "$urlsfile"

if [[ $quiet -eq 0 ]]; then
  echo -e "\n\033[1;44;97m================== SUMMARY ==================\033[0m"
  echo -e "\033[1;36mTotal attempted: $total\033[0m"
  echo -e "\033[0;32mSuccessful: $success\033[0m"
  echo -e "\033[0;31mFailed: $fail\033[0m"
  echo -e "\033[1;44;97m=============================================\033[0m\n"
fi
