#!/bin/bash
# filepath: d:\downloader_by_type.sh

print_usage() {
  echo "Usage: $0 -l <urlsfile>"
  exit 1
}

while getopts "l:" opt; do
  case $opt in
    l) urlsfile="$OPTARG" ;;
    *) print_usage ;;
  esac
done

if [[ -z "$urlsfile" ]]; then
  print_usage
fi

# Directories for extensions/types
dirs=(conf config bak backup db py php bkp cache csv html sql tar tar.gz txt zip log xml js)

for d in "${dirs[@]}"; do
  mkdir -p "$d"
done
mkdir -p other

while read -r line; do
  url=$(echo "$line" | awk '{print $3}')
  [[ -z "$url" ]] && continue

  filename=$(basename "$url" | sed 's/[?&#%:]/_/g')
  ext="${filename##*.}"
  ext_lc="${ext,,}"

  # Map extension to directory
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

  # Special handling for double extensions (e.g., .tar.gz, .sql.gz)
  if [[ "$filename" =~ \.tar\.gz$ ]]; then
    dir="tar.gz"
  elif [[ "$filename" =~ \.sql$ ]]; then
    dir="sql"
  elif [[ "$filename" =~ \.txt$ ]]; then
    dir="txt"
  fi

  # Download file to the appropriate directory
  outpath="${dir}/${filename}"
  curl -sS -O -J -L "$url" --output "$outpath"
  if [[ $? -eq 0 ]]; then
    echo -e "\033[0;32mDownloaded $filename to $dir/\033[0m"
    # Extract if zip or tar or tar.gz
    if [[ "$dir" == "zip" && "$filename" =~ \.zip$ ]]; then
      unzip -o "$outpath" -d "$dir" && echo -e "\033[0;36mExtracted $filename in $dir/\033[0m"
    elif [[ "$dir" == "tar" && "$filename" =~ \.tar$ ]]; then
      tar -xf "$outpath" -C "$dir" && echo -e "\033[0;36mExtracted $filename in $dir/\033[0m"
    elif [[ "$dir" == "tar.gz" && "$filename" =~ \.tar\.gz$ ]]; then
      tar -xzf "$outpath" -C "$dir" && echo -e "\033[0;36mExtracted $filename in $dir/\033[0m"
    fi
  else
    echo -e "\033[0;31mFailed to download $url\033[0m"
  fi
done < "$urlsfile"