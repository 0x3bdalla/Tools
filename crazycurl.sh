#!/usr/bin/env bash

# ASCII art banner at the top
echo -e "\033[0;32m"
echo " ██████╗██████╗  █████╗ ███████╗██╗   ██╗     ██████╗██╗   ██╗██████╗ ██╗     "
echo "██╔════╝██╔══██╗██╔══██╗╚══███╔╝╚██╗ ██╔╝    ██╔════╝██║   ██║██╔══██╗██║     "
echo "██║     ██████╔╝███████║  ███╔╝  ╚████╔╝     ██║     ██║   ██║██████╔╝██║     "
echo "██║     ██╔══██╗██╔══██║ ███╔╝    ╚██╔╝      ██║     ██║   ██║██╔══██╗██║     "
echo "╚██████╗██║  ██║██║  ██║███████╗   ██║       ╚██████╗╚██████╔╝██║  ██║███████╗"
echo " ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝        ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝"
echo -e "\033[0m"

outputdir="crazydir"
mkdir -p "$outputdir"

download() {
  url="$1"
  fname=$(basename "$url" | sed 's/[?&#%: ]/_/g')
  [[ -z "$fname" || "$fname" == "/" ]] && fname="file_$(date +%s%N)"
  outpath="${outputdir}/${fname}"
  echo "Downloading: $url -> $outpath"
  curl -sSL "$url" --output "$outpath"
}

if [[ "$1" == "-l" && -n "$2" ]]; then
  while IFS= read -r url; do
    url=$(echo "$url" | grep -oE 'https?://[^ ]+')
    [[ -n "$url" ]] && download "$url"
  done < "$2"
elif [[ "$1" == "-s" && -n "$2" ]]; then
  download "$2"
else
  echo "Usage: $0 -l <urlsfile> | -s <url>"
  exit 1
fi
